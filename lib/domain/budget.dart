/// Calendar dates use UTC only as a date container, never elapsed local hours.
DateTime day(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);

const maxWon = 1000000000000;

void validateWon(int amount, {bool allowZero = true}) {
  if (amount < (allowZero ? 0 : 1) || amount > maxWon) {
    throw ArgumentError('금액은 ${allowZero ? 0 : 1}~$maxWon원이어야 합니다.');
  }
}

class BudgetPlan {
  BudgetPlan({
    required this.amount,
    required this.savings,
    required DateTime start,
    required DateTime payday,
    this.fixedCosts = const [],
    this.changes = const [],
  }) : start = day(start),
       payday = day(payday) {
    validateWon(amount);
    validateWon(savings);
    final duration = this.payday.difference(this.start).inDays;
    if (duration < 1 || duration > 366) {
      throw ArgumentError('다음 수입일은 시작일 다음 날부터 366일 이내여야 합니다.');
    }
    if (fixedCosts.map((e) => e.id).toSet().length != fixedCosts.length) {
      throw ArgumentError('중복된 고정지출입니다.');
    }
  }
  final int amount;
  final int savings;
  final DateTime start;
  final DateTime payday;
  final List<FixedCost> fixedCosts;
  final List<BudgetChange> changes;
  int savingsAt(DateTime date) {
    var value = savings;
    for (final c in changes) {
      if (!c.date.isAfter(day(date)) && c.savings != null) value = c.savings!;
    }
    return value;
  }

  BudgetPlan withChange(BudgetChange change) => BudgetPlan(
    amount: amount,
    savings: savings,
    start: start,
    payday: payday,
    fixedCosts: fixedCosts,
    changes: [...changes, change],
  );
  Map<String, Object?> toJson() => {
    'amount': amount,
    'savings': savings,
    'start': start.toIso8601String(),
    'payday': payday.toIso8601String(),
    'fixedCosts': fixedCosts.map((e) => e.toJson()).toList(),
    'changes': changes.map((e) => e.toJson()).toList(),
  };
  factory BudgetPlan.fromJson(Map<String, dynamic> j) => BudgetPlan(
    amount: j['amount'] as int,
    savings: j['savings'] as int,
    start: DateTime.parse(j['start'] as String),
    payday: DateTime.parse(j['payday'] as String),
    fixedCosts: (j['fixedCosts'] as List)
        .map((e) => FixedCost.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    changes: ((j['changes'] ?? []) as List)
        .map((e) => BudgetChange.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

class BudgetChange {
  BudgetChange({
    required this.id,
    required this.recordedAt,
    required DateTime date,
    this.income = 0,
    this.savings,
    this.reason = '',
  }) : date = day(date) {
    validateWon(income);
    if (savings != null) validateWon(savings!);
    if (id.isEmpty || reason.length > 200) {
      throw ArgumentError('변경 이력을 확인해 주세요.');
    }
  }
  final String id;
  final DateTime recordedAt;
  final DateTime date;
  final int income;
  final int? savings;
  final String reason;
  Map<String, Object?> toJson() => {
    'id': id,
    'recordedAt': recordedAt.toIso8601String(),
    'date': date.toIso8601String(),
    'income': income,
    'savings': savings,
    'reason': reason,
  };
  factory BudgetChange.fromJson(Map<String, dynamic> j) => BudgetChange(
    id: j['id'] as String,
    recordedAt: DateTime.parse(j['recordedAt'] as String),
    date: DateTime.parse(j['date'] as String),
    income: j['income'] as int,
    savings: j['savings'] as int?,
    reason: j['reason'] as String,
  );
}

class FixedCost {
  FixedCost({required this.id, required this.name, required this.amount}) {
    validateWon(amount, allowZero: false);
    if (id.isEmpty || name.trim().isEmpty) {
      throw ArgumentError('고정지출 이름이 필요합니다.');
    }
  }
  final String id;
  final String name;
  final int amount;
  Map<String, Object> toJson() => {'id': id, 'name': name, 'amount': amount};
  factory FixedCost.fromJson(Map<String, dynamic> j) => FixedCost(
    id: j['id'] as String,
    name: j['name'] as String,
    amount: j['amount'] as int,
  );
}

class Expense {
  Expense({
    required this.id,
    required this.amount,
    required DateTime date,
    this.category = '',
    this.memo = '',
    this.fixedCostId,
  }) : date = day(date) {
    validateWon(amount, allowZero: false);
    if (id.isEmpty || memo.length > 500 || category.length > 40) {
      throw ArgumentError('지출 입력값을 확인해 주세요.');
    }
  }
  final String id;
  final int amount;
  final DateTime date;
  final String category;
  final String memo;
  final String? fixedCostId;
  Map<String, Object?> toJson() => {
    'id': id,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category,
    'memo': memo,
    'fixedCostId': fixedCostId,
  };
  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
    id: j['id'] as String,
    amount: j['amount'] as int,
    date: DateTime.parse(j['date'] as String),
    category: j['category'] as String,
    memo: j['memo'] as String,
    fixedCostId: j['fixedCostId'] as String?,
  );
}

class DailyBudget {
  const DailyBudget({
    required this.date,
    required this.allocated,
    required this.spent,
    required this.balance,
    required this.reserved,
    required this.daysLeft,
    required this.expired,
  });
  final DateTime date;
  final int allocated;
  final int spent;
  final int balance;
  final int reserved;
  final int daysLeft;
  final bool expired;
  int get remaining => allocated - spent;
  int get overspent => remaining < 0 ? -remaining : 0;
  double get hp => allocated <= 0 ? 0 : (remaining / allocated).clamp(0.0, 1.0);
}

/// Replay authoritative expenses; snapshots are disposable derived data.
/// Normal expenses never change their own day's allocation. A fixed payment
/// releases its reservation on the following day's allocation (net zero if exact).
List<DailyBudget> calculateBudget(
  BudgetPlan plan,
  List<Expense> expenses,
  DateTime now,
) {
  final today = day(now);
  if (today.isBefore(plan.start)) throw ArgumentError('예산 시작일 이전입니다.');
  final changeIds = <String>{};
  DateTime? previousChange;
  for (final c in plan.changes) {
    if (!changeIds.add(c.id) ||
        c.date.isBefore(plan.start) ||
        !c.date.isBefore(plan.payday) ||
        c.date.isAfter(today) ||
        (previousChange != null && c.recordedAt.isBefore(previousChange))) {
      throw ArgumentError('변경 이력의 날짜 또는 ID가 잘못되었습니다.');
    }
    previousChange = c.recordedAt;
  }
  final ids = <String>{};
  final paid = <String>{};
  final fixed = {for (final cost in plan.fixedCosts) cost.id: cost};
  for (final e in expenses) {
    if (!ids.add(e.id)) throw ArgumentError('중복 지출입니다.');
    if (e.date.isBefore(plan.start) ||
        !e.date.isBefore(plan.payday) ||
        e.date.isAfter(today)) {
      throw ArgumentError('지출 날짜가 현재 예산 기간을 벗어났습니다.');
    }
    if (e.fixedCostId != null &&
        (!fixed.containsKey(e.fixedCostId) || !paid.add(e.fixedCostId!))) {
      throw ArgumentError('알 수 없거나 이미 결제한 고정지출입니다.');
    }
  }
  final byDay = <DateTime, List<Expense>>{};
  for (final e in expenses) {
    byDay.putIfAbsent(e.date, () => []).add(e);
  }
  var balance = plan.amount;
  var reserved = plan.fixedCosts.fold(0, (int sum, e) => sum + e.amount);
  final result = <DailyBudget>[];
  final last = today.isBefore(plan.payday)
      ? today
      : plan.payday.subtract(const Duration(days: 1));
  for (
    var date = plan.start;
    !date.isAfter(last);
    date = date.add(const Duration(days: 1))
  ) {
    for (final change in plan.changes.where((c) => c.date == date)) {
      balance += change.income;
    }
    final days = plan.payday.difference(date).inDays;
    final distributable = balance - plan.savingsAt(date) - reserved;
    final allocation = distributable > 0 ? distributable ~/ days : 0;
    var spent = 0;
    for (final e in byDay[date] ?? <Expense>[]) {
      balance -= e.amount;
      if (e.fixedCostId == null) {
        spent += e.amount;
      } else {
        reserved -= fixed[e.fixedCostId]!.amount;
      }
    }
    result.add(
      DailyBudget(
        date: date,
        allocated: allocation,
        spent: spent,
        balance: balance,
        reserved: reserved,
        daysLeft: days,
        expired: false,
      ),
    );
  }
  if (!today.isBefore(plan.payday)) {
    result.add(
      DailyBudget(
        date: today,
        allocated: 0,
        spent: 0,
        balance: balance,
        reserved: reserved,
        daysLeft: 0,
        expired: true,
      ),
    );
  }
  return result;
}
