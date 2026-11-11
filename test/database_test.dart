import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dtr/data/database.dart';
import 'package:dtr/domain/budget.dart';

void main() {
  final now = DateTime(2026, 11, 10);
  BudgetPlan plan() => BudgetPlan(
    amount: 300000,
    savings: 0,
    start: now,
    payday: DateTime(2026, 11, 25),
  );
  test('SQLite 종료·재개 후 기록과 계산 유지', () async {
    final directory = Directory.systemTemp.createTempSync('dontori-test-');
    final file = File('${directory.path}/test.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    try {
      await db.startCycle(plan(), now);
      await db.saveExpense(Expense(id: 'one', amount: 8000, date: now), now);
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      final state = await db.load(now);
      expect(state!.expenses.length, 1);
      expect(state.today.remaining, 12000);
      await db.saveExpense(Expense(id: 'one', amount: 9000, date: now), now);
      expect((await db.load(now))!.expenses.length, 1);
      expect((await db.load(now))!.today.remaining, 11000);
      await db.deleteExpense('one', now);
      expect((await db.load(now))!.today.remaining, 20000);
    } finally {
      await db.close();
      directory.deleteSync(recursive: true);
    }
  });
  test('실패 입력은 기존 DB 보존', () async {
    final db = AppDatabase(NativeDatabase.memory());
    try {
      await db.startCycle(plan(), now);
      await expectLater(
        db.saveExpense(
          Expense(id: 'future', amount: 8000, date: DateTime(2026, 11, 11)),
          now,
        ),
        throwsArgumentError,
      );
      expect((await db.load(now))!.expenses, isEmpty);
      expect((await db.load(now))!.today.remaining, 20000);
    } finally {
      await db.close();
    }
  });
}
