import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dtr/data/chat_api.dart';
import 'package:dtr/data/database.dart';
import 'package:dtr/domain/budget.dart';
import 'package:dtr/domain/conversation.dart';
import 'package:dtr/ui/conversation.dart';

class FakeChat extends ChatApi {
  int calls = 0;
  bool fail = false;
  List<Map<String, String>> sent = [];
  final pending = Completer<String>();
  @override
  Future<String> reply({
    required String token,
    required List<Map<String, String>> messages,
    required Map<String, Object> context,
  }) {
    calls++;
    sent = messages;
    if (fail) throw const ChatFailure('연결 실패');
    return pending.future;
  }
}

void main() {
  final now = DateTime(2026, 11, 18);
  final plan = BudgetPlan(
    amount: 150000,
    savings: 30000,
    start: now,
    payday: now.add(const Duration(days: 10)),
    fixedCosts: [FixedCost(id: 'rent', name: '고정', amount: 20000)],
  );
  final ledger = LedgerState(1, plan, [], calculateBudget(plan, [], now));
  test('구매 예상은 저축·고정지출을 보호하고 기록을 변경하지 않는다', () {
    final result = previewPurchase(ledger, 15000);
    expect(result.before.remaining, 10000);
    expect(result.after.remaining, -5000);
    expect(result.after.hp, 0);
    expect(result.tomorrow!.allocated, 85000 ~/ 9);
    expect(ledger.expenses, isEmpty);
    expect(ledger.today.balance, 150000);
  });
  test('마지막 날·만료·잘못된 금액 처리', () {
    final last = LedgerState(
      1,
      plan,
      [],
      calculateBudget(plan, [], plan.payday.subtract(const Duration(days: 1))),
    );
    expect(previewPurchase(last, 1000).tomorrow, isNull);
    expect(() => previewPurchase(ledger, 0), throwsArgumentError);
    final expired = LedgerState(
      1,
      plan,
      [],
      calculateBudget(plan, [], plan.payday),
    );
    expect(() => previewPurchase(expired, 1000), throwsStateError);
  });
  test('기본 대화는 API를 호출하지 않으며 AI 활성화 이전 대화를 보내지 않는다', () async {
    final api = FakeChat();
    final container = ProviderContainer(
      overrides: [chatApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    final chat = container.read(conversationProvider.notifier);
    await chat.send('예산 알려줘', ledger);
    expect(api.calls, 0);
    expect(
      container.read(conversationProvider).lines.last.text,
      contains('10,000원'),
    );
    chat.configure('beta-test-token');
    final task = chat.send('충동구매 고민', ledger);
    expect(api.calls, 1);
    expect(api.sent.length, 1);
    chat.configure('');
    api.pending.complete('늦은 AI 답변');
    await task;
    expect(container.read(conversationProvider).lines, isEmpty);
  });
  test('AI 실패 후 입력 문맥을 되돌리고 기본 모드로 전환 가능', () async {
    final api = FakeChat()..fail = true;
    final container = ProviderContainer(
      overrides: [chatApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    final chat = container.read(conversationProvider.notifier)
      ..configure('beta-test-token');
    await chat.send('고민이 있어', ledger);
    expect(container.read(conversationProvider).busy, false);
    expect(container.read(conversationProvider).error, '연결 실패');
    expect(container.read(conversationProvider).lines, isEmpty);
    chat.configure('');
    await chat.send('소비 돌아보기', ledger);
    expect(
      container.read(conversationProvider).lines.last.text,
      contains('0건'),
    );
  });
  test('HTTPS 연결만 허용하며 기본 빌드는 미연결', () {
    expect(const ChatApi().configured, false);
    expect(
      const ChatApi(endpoint: 'http://example.com/chat').configured,
      false,
    );
    expect(
      const ChatApi(endpoint: 'https://example.com/chat').configured,
      true,
    );
  });
}
