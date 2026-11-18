import '../data/database.dart';
import 'budget.dart';

class PurchasePreview {
  const PurchasePreview(this.before, this.after, this.tomorrow);
  final DailyBudget before, after;
  final DailyBudget? tomorrow;
}

/// A simulation only: never writes to the ledger or earns pet points.
PurchasePreview previewPurchase(LedgerState ledger, int amount) {
  validateWon(amount, allowZero: false);
  if (ledger.today.expired) throw StateError('새 예산을 먼저 설정해 주세요.');
  var id = 'purchase-preview';
  while (ledger.expenses.any((e) => e.id == id)) {
    id += '-';
  }
  final expenses = [
    ...ledger.expenses,
    Expense(id: id, amount: amount, date: ledger.today.date),
  ];
  final after = calculateBudget(ledger.plan, expenses, ledger.today.date).last;
  final tomorrow = after.daysLeft > 1
      ? calculateBudget(
          ledger.plan,
          expenses,
          after.date.add(const Duration(days: 1)),
        ).last
      : null;
  return PurchasePreview(ledger.today, after, tomorrow);
}

String money(int n) =>
    '${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';

String basicReply(String text, LedgerState ledger) {
  if (ledger.today.expired) {
    return '예산 기간이 끝났어요. 오늘 탭에서 새 예산을 설정하면 다시 함께 확인할 수 있어요.';
  }
  if (text.contains('돌아보기') || text.contains('내역')) {
    final start = ledger.today.date.subtract(const Duration(days: 6));
    final recent = ledger.expenses.where((e) => !e.date.isBefore(start));
    final total = recent.fold(0, (int sum, e) => sum + e.amount);
    return '현재 예산 기간에 기록된 최근 7일 지출은 ${recent.length}건, ${money(total)}이에요. '
        '고정지출도 포함된 금액이에요. 그중 만족스러웠던 소비와 아쉬웠던 소비를 하나씩 떠올려 볼까요?';
  }
  if (text.contains('스트레스') || text.contains('사고 싶') || text.contains('충동')) {
    return '사고 싶은 마음이 드는군요. 원래 필요했던 물건인지, 지금 기분 때문에 끌리는지 잠깐 생각해 볼까요? '
        '「이거 사도 될까?」에서 금액을 넣으면 예산에 미칠 영향을 확인할 수 있어요.';
  }
  if (text.contains('예산') || text.contains('얼마')) {
    return '기록 기준 오늘 남은 예산은 ${money(ledger.today.remaining)}, '
        'HP는 ${(ledger.today.hp * 100).round()}%예요. 아직 기록하지 않은 지출이 있다면 먼저 반영해 주세요.';
  }
  return '지금은 기본 대화로 함께하고 있어요. 구매 전 예산 확인이나 소비 돌아보기를 도와줄 수 있어요. '
      '자유롭게 고민을 나누고 싶다면 상단에서 AI 대화를 켜 주세요.';
}

Map<String, Object> conversationContext(LedgerState ledger) => {
  'date': ledger.today.date.toIso8601String().split('T').first,
  'remainingWon': ledger.today.remaining,
  'hpPercent': (ledger.today.hp * 100).round(),
  'daysLeft': ledger.today.daysLeft,
  'expired': ledger.today.expired,
};
