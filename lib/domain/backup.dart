import 'dart:convert';

import 'budget.dart';

class BackupCycle {
  const BackupCycle(this.id, this.plan, this.createdAt, this.expenses);
  final int id;
  final BudgetPlan plan;
  final DateTime createdAt;
  final List<Expense> expenses;
  Map<String, Object?> toJson() => {
    'id': id,
    'plan': plan.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'expenses': expenses.map((e) => e.toJson()).toList(),
  };
}

class BackupData {
  const BackupData(this.cycles, {this.upgrades});
  final int? upgrades;
  final List<BackupCycle> cycles;
  int get expenseCount => cycles.fold(0, (n, c) => n + c.expenses.length);
  String encode() => jsonEncode({
    'app': 'dontori',
    'version': upgrades == null ? 1 : 2,
    if (upgrades != null) 'petUpgrades': upgrades,
    'cycles': cycles.map((c) => c.toJson()).toList(),
  });
  factory BackupData.decode(String source, DateTime now) {
    if (utf8.encode(source).length > 10 * 1024 * 1024) {
      throw const FormatException('백업 파일은 10MB 이하여야 합니다.');
    }
    try {
      final j = jsonDecode(source) as Map<String, dynamic>;
      if (j['app'] != 'dontori' || ![1, 2].contains(j['version'])) {
        throw const FormatException('지원하지 않는 백업 형식입니다.');
      }
      final raw = j['cycles'] as List;
      if (raw.length > 1000) throw const FormatException('예산 기간이 너무 많습니다.');
      final cycleIds = <int>{};
      final expenseIds = <String>{};
      final cycles = <BackupCycle>[];
      for (final item in raw) {
        final c = Map<String, dynamic>.from(item as Map);
        final id = c['id'] as int;
        if (id < 1 || !cycleIds.add(id)) {
          throw const FormatException('예산 기간 ID가 잘못되었습니다.');
        }
        final plan = BudgetPlan.fromJson(
          Map<String, dynamic>.from(c['plan'] as Map),
        );
        final created = DateTime.parse(c['createdAt'] as String);
        final entries = (c['expenses'] as List)
            .map((e) => Expense.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        for (final e in entries) {
          if (!expenseIds.add(e.id)) throw const FormatException('중복 기록입니다.');
        }
        if (expenseIds.length > 100000) {
          throw const FormatException('기록이 너무 많습니다.');
        }
        calculateBudget(plan, entries, now);
        cycles.add(BackupCycle(id, plan, created, entries));
      }
      cycles.sort((a, b) => a.id.compareTo(b.id));
      for (var i = 1; i < cycles.length; i++) {
        if (cycles[i].plan.start.isBefore(cycles[i - 1].plan.payday)) {
          throw const FormatException('예산 기간이 겹칩니다.');
        }
      }
      final u = j['version'] == 2 ? j['petUpgrades'] as int : null;
      if (u != null && (u < 0 || u > 1000000)) {
        throw const FormatException('잘못된 성장 정보');
      }
      return BackupData(cycles, upgrades: u);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('백업 파일의 필드 또는 값이 잘못되었습니다.');
    }
  }
}
