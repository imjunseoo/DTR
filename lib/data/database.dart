import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/budget.dart';
import '../domain/backup.dart';
part 'database.g.dart';

class BudgetCycles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get configuration => text()();
  DateTimeColumn get createdAt => dateTime()();
}

class LedgerEntries extends Table {
  TextColumn get id => text()();
  IntColumn get cycleId => integer().references(BudgetCycles, #id)();
  TextColumn get payload => text()();
  @override
  Set<Column> get primaryKey => {id};
}

class DailySnapshots extends Table {
  IntColumn get cycleId => integer().references(BudgetCycles, #id)();
  TextColumn get date => text()();
  IntColumn get allocated => integer()();
  IntColumn get spent => integer()();
  @override
  Set<Column> get primaryKey => {cycleId, date};
}

class LedgerState {
  const LedgerState(this.cycleId, this.plan, this.expenses, this.days);
  final int cycleId;
  final BudgetPlan plan;
  final List<Expense> expenses;
  final List<DailyBudget> days;
  DailyBudget get today => days.last;
}

class PetStatus {
  const PetStatus(this.earned, this.upgrades);
  final int earned, upgrades;
  int get balance => upgrades > earned ~/ 5 ? 0 : earned - upgrades * 5;
  int get level => upgrades + 1;
  String get sprite => level >= 5
      ? "bloom"
      : level >= 2
      ? "sprout"
      : "seed";
}

@DriftDatabase(tables: [BudgetCycles, LedgerEntries, DailySnapshots])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            LazyDatabase(() async {
              final directory = await getApplicationSupportDirectory();
              return NativeDatabase.createInBackground(
                File(p.join(directory.path, 'dontori.sqlite')),
              );
            }),
      );
  @override
  int get schemaVersion => 2;
  static const petTable =
      'CREATE TABLE pet_growth(id INTEGER PRIMARY KEY CHECK(id=1), upgrades INTEGER NOT NULL CHECK(upgrades>=0))';
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(petTable);
    },
    onUpgrade: (m, from, to) async {
      if (from == 1) {
        await customStatement(petTable);
        await _setUpgrades((await _earned(DateTime.now())) ~/ 5);
      }
    },
  );
  Future<void> _setUpgrades(int value) =>
      customStatement('INSERT OR REPLACE INTO pet_growth VALUES(1,?)', [value]);
  Future<int> _upgrades() async => (await customSelect(
    'SELECT coalesce(max(upgrades),0) AS n FROM pet_growth',
  ).getSingle()).read<int>('n');
  Future<int> _earned(DateTime now) async {
    final today = day(now).toIso8601String().substring(0, 10);
    final row = await customSelect(
      r"""WITH records AS (
    SELECT DISTINCT cycle_id,substr(json_extract(payload,'$.date'),1,10) AS d FROM ledger_entries
  ), rewards AS (SELECT r.d,max(CASE WHEN r.d<? AND s.allocated>s.spent THEN 1 ELSE 0 END) AS saved
    FROM records r LEFT JOIN daily_snapshots s ON s.cycle_id=r.cycle_id AND substr(s.date,1,10)=r.d
    WHERE r.d<=? GROUP BY r.d)
    SELECT coalesce(sum(1+saved),0) AS points FROM rewards""",
      variables: [Variable.withString(today), Variable.withString(today)],
    ).getSingle();
    return row.read<int>('points');
  }

  Future<PetStatus> petStatus(DateTime now) async =>
      PetStatus(await _earned(now), await _upgrades());
  Future<bool> trainPet(DateTime now) => transaction(() async {
    final pet = await petStatus(now);
    if (pet.balance < 5) return false;
    await _setUpgrades(pet.upgrades + 1);
    return true;
  });

  Future<void> addBudgetChange(BudgetChange change, DateTime now) =>
      transaction(() async {
        final state = await load(now);
        if (state == null || state.today.expired) {
          throw StateError('진행 중인 예산이 필요합니다.');
        }
        if (change.date != day(now)) throw ArgumentError('변경은 오늘부터 적용합니다.');
        final updated = state.plan.withChange(change);
        calculateBudget(updated, state.expenses, now);
        await (update(
          budgetCycles,
        )..where((t) => t.id.equals(state.cycleId))).write(
          BudgetCyclesCompanion(
            configuration: Value(jsonEncode(updated.toJson())),
          ),
        );
        await refreshSnapshots(now);
      });

  Future<BackupData> exportBackup() => transaction(() async {
    final cycles = await select(budgetCycles).get();
    final entries = await select(ledgerEntries).get();
    return BackupData(
      cycles
          .map(
            (c) => BackupCycle(
              c.id,
              BudgetPlan.fromJson(
                jsonDecode(c.configuration) as Map<String, dynamic>,
              ),
              c.createdAt,
              entries
                  .where((e) => e.cycleId == c.id)
                  .map(
                    (e) => Expense.fromJson(
                      jsonDecode(e.payload) as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
      upgrades: await _upgrades(),
    );
  });

  Future<void> restoreBackup(String source, DateTime now) async {
    // Validate the entire file before touching the current database.
    final backup = BackupData.decode(source, now);
    await transaction(() async {
      await delete(dailySnapshots).go();
      await delete(ledgerEntries).go();
      await delete(budgetCycles).go();
      for (final cycle in backup.cycles) {
        await into(budgetCycles).insert(
          BudgetCyclesCompanion.insert(
            id: Value(cycle.id),
            configuration: jsonEncode(cycle.plan.toJson()),
            createdAt: cycle.createdAt,
          ),
        );
        for (final e in cycle.expenses) {
          await into(ledgerEntries).insert(
            LedgerEntriesCompanion.insert(
              id: e.id,
              cycleId: cycle.id,
              payload: jsonEncode(e.toJson()),
            ),
          );
        }
        final days = calculateBudget(cycle.plan, cycle.expenses, now);
        await batch(
          (b) => b.insertAll(
            dailySnapshots,
            days
                .map(
                  (d) => DailySnapshotsCompanion.insert(
                    cycleId: cycle.id,
                    date: d.date.toIso8601String(),
                    allocated: d.allocated,
                    spent: d.spent,
                  ),
                )
                .toList(),
          ),
        );
      }
      await _setUpgrades(backup.upgrades ?? ((await _earned(now)) ~/ 5));
    });
  }

  Future<LedgerState?> load(DateTime now) async {
    final cycle =
        await (select(budgetCycles)
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .getSingleOrNull();
    if (cycle == null) return null;
    final plan = BudgetPlan.fromJson(
      jsonDecode(cycle.configuration) as Map<String, dynamic>,
    );
    final entries = await (select(
      ledgerEntries,
    )..where((t) => t.cycleId.equals(cycle.id))).get();
    final expenses =
        entries
            .map(
              (e) => Expense.fromJson(
                jsonDecode(e.payload) as Map<String, dynamic>,
              ),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return LedgerState(
      cycle.id,
      plan,
      expenses,
      calculateBudget(plan, expenses, now),
    );
  }

  Future<void> startCycle(BudgetPlan plan, DateTime now) =>
      transaction(() async {
        final old = await load(now);
        if (old != null && !old.today.expired) {
          throw StateError('현재 예산 기간이 아직 끝나지 않았습니다.');
        }
        if (plan.start != day(now)) throw ArgumentError('새 예산은 오늘부터 시작합니다.');
        await into(budgetCycles).insert(
          BudgetCyclesCompanion.insert(
            configuration: jsonEncode(plan.toJson()),
            createdAt: now,
          ),
        );
        await refreshSnapshots(now);
      });
  Future<void> saveExpense(
    Expense expense,
    DateTime now,
  ) => transaction(() async {
    final state = await load(now);
    if (state == null) throw StateError('예산을 먼저 설정해 주세요.');
    if (state.today.expired) throw StateError('수입일이 도래했습니다. 새 예산을 설정해 주세요.');
    final existing = await (select(
      ledgerEntries,
    )..where((t) => t.id.equals(expense.id))).getSingleOrNull();
    if (existing != null && existing.cycleId != state.cycleId) {
      throw StateError('다른 주기의 기록입니다.');
    }
    final next = [...state.expenses.where((e) => e.id != expense.id), expense];
    calculateBudget(state.plan, next, now);
    await into(ledgerEntries).insertOnConflictUpdate(
      LedgerEntriesCompanion.insert(
        id: expense.id,
        cycleId: state.cycleId,
        payload: jsonEncode(expense.toJson()),
      ),
    );
    await refreshSnapshots(now);
  });
  Future<void> deleteExpense(String id, DateTime now) => transaction(() async {
    final state = await load(now);
    if (state == null) return;
    await (delete(
      ledgerEntries,
    )..where((t) => t.id.equals(id) & t.cycleId.equals(state.cycleId))).go();
    await refreshSnapshots(now);
  });
  Future<void> refreshSnapshots(DateTime now) => transaction(() async {
    final state = await load(now);
    if (state == null) return;
    await (delete(
      dailySnapshots,
    )..where((t) => t.cycleId.equals(state.cycleId))).go();
    await batch(
      (b) => b.insertAll(
        dailySnapshots,
        state.days
            .map(
              (d) => DailySnapshotsCompanion.insert(
                cycleId: state.cycleId,
                date: d.date.toIso8601String(),
                allocated: d.allocated,
                spent: d.spent,
              ),
            )
            .toList(),
      ),
    );
  });
}
