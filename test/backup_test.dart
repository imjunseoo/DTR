import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dtr/data/database.dart';
import 'package:dtr/domain/budget.dart';
import 'package:dtr/domain/backup.dart';

void main() {
  final now = DateTime(2026, 11, 10);
  Future<AppDatabase> populated() async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.startCycle(
      BudgetPlan(
        amount: 400000,
        savings: 50000,
        start: now,
        payday: DateTime(2026, 11, 25),
        fixedCosts: [FixedCost(id: 'phone', name: '통신비', amount: 50000)],
      ),
      now,
    );
    await db.saveExpense(
      Expense(id: 'food', amount: 8000, date: now, memo: '점심'),
      now,
    );
    return db;
  }

  test('백업 왕복 시 설정·고정지출·내역 복구', () async {
    final source = await populated();
    final target = AppDatabase(NativeDatabase.memory());
    try {
      final backup = await source.exportBackup();
      await target.restoreBackup(backup.encode(), now);
      final state = (await target.load(now))!;
      expect(state.plan.savings, 50000);
      expect(state.plan.fixedCosts.single.amount, 50000);
      expect(state.expenses.single.memo, '점심');
      expect(state.today.remaining, 12000);
      expect((await target.select(target.dailySnapshots).get()).length, 1);
    } finally {
      await source.close();
      await target.close();
    }
  });
  test('손상·미지원·미래·중복 파일은 기존 기록 유지', () async {
    final db = await populated();
    try {
      final original = (await db.exportBackup()).encode();
      final duplicate = jsonDecode(original) as Map<String, dynamic>;
      (duplicate['cycles'] as List).add((duplicate['cycles'] as List).first);
      for (final bad in [
        '{broken',
        jsonEncode({
          ...jsonDecode(original) as Map<String, dynamic>,
          'version': 999,
        }),
        jsonEncode(duplicate),
        original.replaceFirst('"amount":8000', '"amount":-1'),
      ]) {
        await expectLater(db.restoreBackup(bad, now), throwsFormatException);
        expect((await db.exportBackup()).encode(), original);
      }
    } finally {
      await db.close();
    }
  });
  test('파일 크기 제한 및 필수 필드 확인', () {
    expect(
      () => BackupData.decode('x' * (10 * 1024 * 1024 + 1), now),
      throwsFormatException,
    );
    expect(
      () => BackupData.decode('{"app":"dontori","version":1}', now),
      throwsFormatException,
    );
  });
  test('도토리 5개를 동시에 두 번 쓸 수 없고 강화 결과는 복원된다', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final restored = AppDatabase(NativeDatabase.memory());
    try {
      final start = now.subtract(const Duration(days: 2));
      await db.startCycle(
        BudgetPlan(
          amount: 300000,
          savings: 0,
          start: start,
          payday: now.add(const Duration(days: 10)),
        ),
        start,
      );
      for (var i = 0; i < 3; i++) {
        await db.saveExpense(
          Expense(
            id: 'qa$i',
            amount: 1000,
            date: start.add(Duration(days: i)),
          ),
          now,
        );
      }
      expect((await db.petStatus(now)).balance, 5);
      final results = await Future.wait([db.trainPet(now), db.trainPet(now)]);
      expect(results.where((ok) => ok).length, 1);
      await restored.restoreBackup((await db.exportBackup()).encode(), now);
      final pet = await restored.petStatus(now);
      expect(pet.level, 2);
      expect(pet.balance, 0);
    } finally {
      await db.close();
      await restored.close();
    }
  });
}
