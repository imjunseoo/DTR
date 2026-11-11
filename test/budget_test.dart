import 'package:flutter_test/flutter_test.dart';
import 'package:dtr/domain/budget.dart';

void main() {
  test('추가 수입·저축 변경은 적용일 이후만 재계산', () {
    final p = BudgetPlan(
      amount: 300000,
      savings: 0,
      start: DateTime(2026, 11, 10),
      payday: DateTime(2026, 11, 25),
      changes: [
        BudgetChange(
          id: 'income',
          recordedAt: DateTime(2026, 11, 11, 12),
          date: DateTime(2026, 11, 11),
          income: 14000,
          savings: 14000,
        ),
        BudgetChange(
          id: 'save',
          recordedAt: DateTime(2026, 11, 12, 12),
          date: DateTime(2026, 11, 12),
          savings: 27000,
        ),
      ],
    );
    final days = calculateBudget(p, [
      Expense(id: 'food', amount: 20000, date: DateTime(2026, 11, 10)),
    ], DateTime(2026, 11, 12));
    expect(days[0].allocated, 20000);
    expect(days[1].allocated, 20000);
    expect(days[2].allocated, 267000 ~/ 13);
    expect(days[2].balance, 294000);
  });
  final start = DateTime(2026, 11, 10);
  BudgetPlan plan({
    int amount = 300000,
    int savings = 0,
    List<FixedCost> fixed = const [],
  }) => BudgetPlan(
    amount: amount,
    savings: savings,
    start: start,
    payday: DateTime(2026, 11, 25),
    fixedCosts: fixed,
  );
  Expense spend(
    int amount, {
    String id = 'one',
    DateTime? date,
    String? fixed,
  }) =>
      Expense(id: id, amount: amount, date: date ?? start, fixedCostId: fixed);
  test('계획서 예시: 30만원/15일, 8천원 소비 후 60%', () {
    final b = calculateBudget(plan(), [spend(8000)], start).last;
    expect(b.allocated, 20000);
    expect(b.remaining, 12000);
    expect(b.hp, .6);
  });
  test('같은 날 지출이 증가해도 배정액 유지', () {
    final b = calculateBudget(plan(), [
      spend(8000),
      spend(4000, id: 'two'),
    ], start).last;
    expect(b.allocated, 20000);
    expect(b.remaining, 8000);
  });
  test('미실행 기간 복구와 다음날 재배분', () {
    final days = calculateBudget(plan(), [spend(8000)], DateTime(2026, 11, 12));
    expect(days.length, 3);
    expect(days[1].allocated, 292000 ~/ 14);
    expect(days.last.allocated, 292000 ~/ 13);
  });
  test('고정지출 결제와 예약 해제 이중 차감 방지', () {
    final p = plan(
      amount: 400000,
      fixed: [FixedCost(id: 'rent', name: '월세', amount: 100000)],
    );
    final days = calculateBudget(p, [
      spend(100000, fixed: 'rent'),
    ], DateTime(2026, 11, 11));
    expect(days.first.allocated, 20000);
    expect(days.first.spent, 0);
    expect(days.last.balance, 300000);
    expect(days.last.reserved, 0);
    expect(days.last.allocated, 300000 ~/ 14);
  });
  test('고정지출 실제 금액 차이는 다음날 반영', () {
    final p = plan(
      amount: 400000,
      fixed: [FixedCost(id: 'rent', name: '월세', amount: 100000)],
    );
    expect(
      calculateBudget(p, [
        spend(110000, fixed: 'rent'),
      ], DateTime(2026, 11, 11)).last.allocated,
      290000 ~/ 14,
    );
  });
  test('저축 초과와 0예산에서 나눗셈 오류 없이 지출 허용', () {
    final b = calculateBudget(plan(amount: 100, savings: 200), [
      spend(500),
    ], start).last;
    expect(b.hp, 0);
    expect(b.overspent, 500);
    expect(b.balance, -400);
  });
  test('당일 예산 초과 시 음수 잔여와 HP 하한', () {
    final b = calculateBudget(plan(), [spend(25000)], start).last;
    expect(b.remaining, -5000);
    expect(b.hp, 0);
    expect(b.overspent, 5000);
  });
  test('과거 수정과 삭제 시 이후 배정 재계산', () {
    final tomorrow = DateTime(2026, 11, 11);
    expect(
      calculateBudget(plan(), [spend(15000)], tomorrow).last.allocated,
      285000 ~/ 14,
    );
    expect(calculateBudget(plan(), [], tomorrow).last.allocated, 300000 ~/ 14);
  });
  test('수입일 기간 만료, 자동 수입 없음', () {
    final b = calculateBudget(plan(), [
      spend(8000),
    ], DateTime(2026, 11, 25)).last;
    expect(b.expired, true);
    expect(b.daysLeft, 0);
    expect(b.balance, 292000);
  });
  test('원 단위 나머지 보존', () {
    final p = BudgetPlan(
      amount: 10,
      savings: 0,
      start: start,
      payday: DateTime(2026, 11, 13),
    );
    final days = calculateBudget(p, [
      spend(3),
      spend(3, id: 'two', date: DateTime(2026, 11, 11)),
    ], DateTime(2026, 11, 12));
    expect(days.map((e) => e.allocated), [3, 3, 4]);
  });
  test('윤년 달력 계산', () {
    final p = BudgetPlan(
      amount: 300,
      savings: 0,
      start: DateTime(2028, 2, 28),
      payday: DateTime(2028, 3, 2),
    );
    expect(calculateBudget(p, [], DateTime(2028, 2, 29)).last.daysLeft, 2);
  });
  test('중복 ID와 중복 고정지출 결제 거부', () {
    expect(
      () => calculateBudget(plan(), [spend(1), spend(1)], start),
      throwsArgumentError,
    );
    final p = plan(
      fixed: [FixedCost(id: 'x', name: '통신', amount: 100)],
    );
    expect(
      () => calculateBudget(p, [
        spend(100, fixed: 'x'),
        spend(100, id: 'two', fixed: 'x'),
      ], start),
      throwsArgumentError,
    );
  });
  test('미래 날짜와 잘못된 금액 거부', () {
    expect(
      () => calculateBudget(plan(), [
        spend(1, date: DateTime(2026, 11, 11)),
      ], start),
      throwsArgumentError,
    );
    expect(() => spend(0), throwsArgumentError);
    expect(() => spend(-1), throwsArgumentError);
    expect(() => plan(amount: maxWon + 1), throwsArgumentError);
  });
}
