import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_api.dart';
import '../data/database.dart';
import '../domain/conversation.dart';
import 'design.dart';
import 'state.dart';
import 'growth.dart';

final chatApiProvider = Provider<ChatApi>((ref) => const ChatApi());
final conversationProvider = NotifierProvider<Conversation, ConversationState>(
  Conversation.new,
);

class ChatLine {
  const ChatLine(this.text, {this.user = false, this.ai = false});
  final String text;
  final bool user, ai;
}

class ConversationState {
  const ConversationState({
    this.lines = const [],
    this.token = '',
    this.busy = false,
    this.error,
    this.failedText,
  });
  final List<ChatLine> lines;
  final String token;
  final bool busy;
  final String? error;
  final String? failedText;
}

class Conversation extends Notifier<ConversationState> {
  int generation = 0;
  @override
  ConversationState build() {
    ref.watch(qaModeProvider);
    generation++;
    ref.onDispose(() => generation++);
    return const ConversationState();
  }

  void configure(String token) {
    generation++;
    // Changing consent starts a fresh context: basic conversations are not uploaded.
    state = ConversationState(token: token);
  }

  void clear() {
    generation++;
    state = ConversationState(token: state.token);
  }

  void local(String question, String reply) {
    if (state.busy) return;
    state = ConversationState(
      token: state.token,
      lines: [
        ...state.lines,
        ChatLine(question, user: true),
        ChatLine(reply),
      ].takeLast(40),
    );
  }

  Future<void> send(String text, LedgerState ledger) async {
    text = text.trim();
    if (text.isEmpty || text.length > 1000 || state.busy) return;
    if (state.token.isEmpty) {
      local(text, basicReply(text, ledger));
      return;
    }
    final ticket = generation;
    final lines = [
      ...state.lines,
      ChatLine(text, user: true, ai: true),
    ].takeLast(40);
    state = ConversationState(token: state.token, lines: lines, busy: true);
    try {
      final reply = await ref
          .read(chatApiProvider)
          .reply(
            token: state.token,
            messages: lines
                .where((line) => line.ai)
                .toList()
                .takeLast(10)
                .map(
                  (line) => {
                    'role': line.user ? 'user' : 'assistant',
                    'content': line.text,
                  },
                )
                .toList(),
            context: conversationContext(ledger),
          );
      if (ticket != generation) return;
      state = ConversationState(
        token: state.token,
        lines: [...lines, ChatLine(reply, ai: true)].takeLast(40),
      );
    } on ChatFailure catch (e) {
      if (ticket != generation) return;
      // Remove the failed turn from AI context; keep a visible failure, never fake an AI reply.
      state = ConversationState(
        token: state.token,
        lines: lines.sublist(0, lines.length - 1),
        error: e.message,
        failedText: text,
      );
    }
  }
}

extension<T> on List<T> {
  List<T> takeLast(int count) =>
      length <= count ? this : sublist(length - count);
}

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({
    super.key,
    required this.ledger,
    required this.onExpense,
  });
  final LedgerState ledger;
  final VoidCallback onExpense;
  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send([String? prompt]) async {
    final text = prompt ?? input.text;
    if (text.trim().isEmpty) return;
    input.clear();
    final task = ref
        .read(conversationProvider.notifier)
        .send(text, widget.ledger);
    scrollDown();
    await task;
    if (!mounted) return;
    if (ref.read(conversationProvider).error != null &&
        prompt == null &&
        input.text.isEmpty) {
      input.text = text;
    }
    scrollDown();
  }

  void scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && scroll.hasClients) {
      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  });

  Future<void> enableAi() async {
    final session = ref.read(conversationProvider);
    if (session.token.isNotEmpty) {
      ref.read(conversationProvider.notifier).configure('');
      return;
    }
    if (!ref.read(chatApiProvider).configured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI 연결 준비 중이에요. 기본 대화와 예산 확인은 바로 이용할 수 있어요.'),
        ),
      );
      return;
    }
    final code = TextEditingController();
    final codeForm = GlobalKey<FormState>();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('돈토리 AI 대화'),
        content: SingleChildScrollView(
          child: Form(
            key: codeForm,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '동의 후 작성하는 최근 대화와 오늘 남은 예산·HP·남은 일수가 DTR 서버와 Anthropic(Claude)으로 전송돼요. 지출 메모와 전체 내역은 보내지 않아요.\n\n대화는 앱을 종료하면 사라져요. AI는 기록을 직접 변경하지 않으며, 답변에 오류가 있을 수 있어요. 기본 대화로 돌아가면 전송을 멈춰요.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: code,
                  validator: (value) =>
                      value == null ||
                          value.trim().length < 24 ||
                          value.trim().startsWith('sk-ant-')
                      ? '전달받은 베타 초대 코드를 입력해 주세요.'
                      : null,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  maxLength: 128,
                  decoration: const InputDecoration(
                    labelText: '베타 초대 코드',
                    helperText: 'Claude API 키를 입력하지 마세요',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('기본 대화 유지'),
          ),
          TextButton(
            onPressed: () {
              if (codeForm.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('동의하고 시작'),
          ),
        ],
      ),
    );
    final token = code.text.trim();
    // Dialog animation may still be using its controller.
    Future<void>.delayed(const Duration(seconds: 1), code.dispose);
    if (accepted == true && mounted) {
      ref.read(conversationProvider.notifier).configure(token);
    }
  }

  Future<void> purchase() async {
    final amount = TextEditingController();
    final form = GlobalKey<FormState>();
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이거 사도 될까?'),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('일반 지출을 가정해 계산해요. 지출로 저장되지는 않아요.'),
                moneyField(amount, '구매 예정 금액', allowZero: false),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(ctx, int.parse(amount.text));
              }
            },
            child: const Text('예산 확인'),
          ),
        ],
      ),
    );
    Future<void>.delayed(const Duration(seconds: 1), amount.dispose);
    if (value == null || !mounted) return;
    final ledger = ref.read(ledgerProvider).asData?.value;
    if (ledger == null || ledger.today.expired) return;
    final preview = previewPurchase(ledger, value);
    ref
        .read(conversationProvider.notifier)
        .local(
          '${won(value)}을 쓰면 어떻게 될까?',
          '구매 후 오늘 남은 예산은 ${won(preview.after.remaining)}, HP는 ${(preview.after.hp * 100).round()}%예요. '
              '${preview.after.remaining < 0 ? '오늘 예산을 ${won(-preview.after.remaining)} 초과해요.' : '오늘 기록 기준 예산 안에 들어와요.'}\n'
              '${preview.tomorrow == null ? '다음 수입일 전 마지막 날이에요.' : '추가 지출이 없다고 가정한 내일 배정액은 ${won(preview.tomorrow!.allocated)}이에요.'}\n'
              '미기록 지출도 확인해 주세요. 이 계산은 지출 내역에 저장되지 않아요.',
        );
    scrollDown();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(conversationProvider);
    final sprite = ref.watch(petPointsProvider).asData?.value.sprite ?? 'seed';
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final horizontal = MediaQuery.sizeOf(context).width <= 360 ? 16.0 : 20.0;
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scroll,
            padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onLongPress: kDebugMode
                            ? () => showQaTools(context, ref)
                            : null,
                        child: Text(
                          '돈토리와 대화',
                          style: DtrDesign.text(22, weight: FontWeight.w700),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '대화 지우기',
                      onPressed: session.busy
                          ? null
                          : () =>
                                ref.read(conversationProvider.notifier).clear(),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.zero,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.token.isEmpty
                            ? '기본 대화 · 기기 안에서만'
                            : 'AI 대화 · Claude',
                        style: DtrDesign.text(13, color: DtrDesign.muted),
                      ),
                    ),
                    TextButton(
                      onPressed: session.busy ? null : enableAi,
                      child: Text(
                        session.token.isEmpty ? 'AI 대화 켜기' : '기본 대화로',
                      ),
                    ),
                  ],
                ),
              ),
              if (!keyboard)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: DtrDesign.panel(color: DtrDesign.peach),
                  child: Row(
                    children: [
                      DtrDesign.asset('$sprite-hero', 48),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.ledger.today.expired
                                  ? '새 예산을 설정해 주세요'
                                  : '오늘 남은 예산',
                              style: DtrDesign.text(13),
                            ),
                            if (!widget.ledger.today.expired) ...[
                              Text(
                                won(widget.ledger.today.remaining),
                                style: DtrDesign.text(
                                  24,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              LinearProgressIndicator(
                                value: widget.ledger.today.hp,
                                color: DtrDesign.accent,
                                backgroundColor: DtrDesign.card,
                                minHeight: 8,
                              ),
                              Text(
                                '생활비 HP ${(widget.ledger.today.hp * 100).round()}% · 기록 기준',
                                style: DtrDesign.text(13),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              if (keyboard)
                Text(
                  widget.ledger.today.expired
                      ? '새 예산을 설정해 주세요'
                      : '남음 ${won(widget.ledger.today.remaining)} · HP ${(widget.ledger.today.hp * 100).round()}%',
                  style: DtrDesign.text(13),
                ),
              if (session.lines.isEmpty)
                bubble(const ChatLine('사고 싶은 게 있나요? 금액부터 같이 확인해 봐요.')),
              ...session.lines.map(bubble),
              if (session.busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('돈토리가 생각하고 있어요…'),
                ),
              if (session.error != null)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      session.error!,
                      style: DtrDesign.text(14, color: DtrDesign.accent),
                    ),
                  ),
                ),
              if (session.error != null)
                Wrap(
                  children: [
                    TextButton(
                      onPressed: session.failedText == null
                          ? null
                          : () => send(session.failedText),
                      child: const Text('다시 보내기'),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.read(conversationProvider.notifier).configure(''),
                      child: const Text('기본 대화 계속'),
                    ),
                  ],
                ),
              if (!keyboard)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton(
                      onPressed: session.busy || widget.ledger.today.expired
                          ? null
                          : purchase,
                      child: const Text('이거 사도 될까?'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: session.busy
                          ? null
                          : () => send('지금 뭔가 사고 싶어'),
                      child: const Text('지금 뭔가 사고 싶어'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: session.busy
                          ? null
                          : () {
                              ref
                                  .read(conversationProvider.notifier)
                                  .local(
                                    '소비 돌아보기',
                                    basicReply('소비 돌아보기', widget.ledger),
                                  );
                              scrollDown();
                            },
                      child: const Text('소비 돌아보기'),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (!keyboard)
          TextButton(
            onPressed: widget.ledger.today.expired ? null : widget.onExpense,
            child: const Text('간편 지출 입력'),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 6),
          child: Container(
            decoration: DtrDesign.panel(outlined: true),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1000,
                    inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                    decoration: const InputDecoration(
                      hintText: '돈토리에게 이야기해 주세요',
                      counterText: '',
                    ),
                    onSubmitted: session.busy ? null : (_) => send(),
                  ),
                ),
                IconButton(
                  tooltip: '보내기',
                  onPressed: session.busy ? null : () => send(),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget bubble(ChatLine line) => Align(
    alignment: line.user ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(
        maxWidth: (MediaQuery.sizeOf(context).width - 40) * .85,
      ),
      decoration: DtrDesign.panel(
        color: line.user ? DtrDesign.peach : DtrDesign.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!line.user)
            Text(
              line.ai ? '돈토리 · AI' : '돈토리 · 기본',
              style: DtrDesign.text(13, color: DtrDesign.muted),
            ),
          SelectableText(line.text, style: DtrDesign.text(16)),
        ],
      ),
    ),
  );
}
