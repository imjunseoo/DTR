import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../domain/budget.dart';
import '../platform/android_bridge.dart';
import 'backup_screen.dart';
import 'budget_change_screen.dart';
import 'state.dart';
import 'setup.dart';
import 'expense.dart';
import 'growth.dart';
import 'design.dart';

import 'package:flutter/foundation.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  Timer? timer;
  DateTime currentDay = day(DateTime.now());
  int page = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (AndroidBridge.supported) {
      AndroidBridge.channel.setMethodCallHandler((call) async {
        if (call.method == 'quickEntry') {
          await openFromWidget();
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => openFromWidget());
    }
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      final next = day(DateTime.now());
      if (next != currentDay) {
        currentDay = next;
        ref.invalidate(ledgerProvider);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(ledgerProvider);
  }

  @override
  void dispose() {
    if (AndroidBridge.supported) {
      AndroidBridge.channel.setMethodCallHandler(null);
    }
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool openingFromWidget = false;
  Future<void> openFromWidget() async {
    if (openingFromWidget) return;
    openingFromWidget = true;
    try {
      if (!await AndroidBridge.consumeQuickEntry()) return;
      ref.invalidate(ledgerProvider);
      final data = await ref.read(ledgerProvider.future);
      if (mounted && data != null && !data.today.expired) {
        await edit(null, data);
      }
    } catch (_) {
      /* Opening the app still leaves the normal input button available. */
    } finally {
      openingFromWidget = false;
    }
  }

  Future<void> edit(Expense? e, LedgerState data, {FixedCost? fixed}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ExpenseScreen(state: data, expense: e, fixed: fixed),
        ),
      );
  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider);
    final widgetSync = ref.watch(widgetSyncProvider);
    return Scaffold(
      persistentFooterButtons: widgetSync.asData?.value == false
          ? [const Text('기록은 저장됐어요. 위젯 갱신은 앱을 다시 열 때 재시도합니다.')]
          : null,
      body: SafeArea(
        bottom: false,
        child: page == 2
            ? const GrowthScreen()
            : ledger.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('기록을 불러오지 못했어요. 데이터를 지우지 않고 다시 시도합니다.'),
                        const SizedBox(height: 12),
                        Text('$e'),
                        TextButton(
                          onPressed: () => ref.invalidate(ledgerProvider),
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (data) => data == null
                    ? const SetupScreen()
                    : page == 0
                    ? dashboard(data)
                    : history(data),
              ),
      ),
      bottomNavigationBar: ledger.asData?.value == null
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(22, 12, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (page != 2 &&
                      ledger.asData?.value != null &&
                      !ledger.asData!.value!.today.expired) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: DtrDesign.peach,
                          foregroundColor: DtrDesign.accent,
                        ),
                        onPressed: () => edit(null, ledger.asData!.value!),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DtrDesign.asset('add', 20),
                            const SizedBox(width: 9),
                            Text(
                              '지출 입력',
                              style: DtrDesign.text(
                                15,
                                color: DtrDesign.accent,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  DtrNavigation(
                    index: page,
                    onChanged: (i) => setState(() => page = i),
                  ),
                ],
              ),
            ),
    );
  }

  Widget dashboard(LedgerState data) {
    final b = data.today;
    final savings = data.plan.savingsAt(b.date);
    final deficit = b.balance - savings - b.reserved;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
      children: [
        SizedBox(
          height: 42,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onLongPress: kDebugMode
                      ? () => showQaTools(context, ref)
                      : null,
                  child: Text(
                    ref.watch(qaModeProvider) ? 'DTR (돈토리) · QA' : 'DTR (돈토리)',
                    style: DtrDesign.text(22, weight: FontWeight.w700),
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: DtrDesign.soft,
                  foregroundColor: DtrDesign.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 29),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const BackupScreen()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DtrDesign.asset('folder', 17),
                    const SizedBox(width: 6),
                    Text(
                      '백업',
                      style: DtrDesign.text(
                        12,
                        color: DtrDesign.accent,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (b.expired) ...[
          Text(
            '새 생활비를 설정할 시간이에요',
            style: DtrDesign.text(22, weight: FontWeight.w700),
          ),
          const Text('이전 기록은 보관됩니다. 현재 관리할 실제 금액을 확인해 주세요.'),
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(
                  body: SafeArea(child: SetupScreen(closeAfterSave: true)),
                ),
              ),
            ),
            child: const Text('새 예산 설정'),
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(19),
            decoration: DtrDesign.panel(color: DtrDesign.peach, radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '오늘 남은 예산',
                      style: DtrDesign.text(15, weight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(
                      '${b.date.month}월 ${b.date.day}일',
                      style: DtrDesign.text(13, color: DtrDesign.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    won(b.remaining),
                    style: DtrDesign.text(
                      41,
                      height: 59 / 41,
                      color: DtrDesign.accent,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: b.hp,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0xFF9D390E),
                  backgroundColor: const Color(0xFFD9AC80),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '생활비 HP ${(b.hp * 100).round()}%',
                        style: DtrDesign.text(
                          15,
                          color: DtrDesign.accent,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '수입일까지 ${b.daysLeft}일',
                      style: DtrDesign.text(
                        13,
                        color: DtrDesign.muted,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (b.overspent > 0)
                  Text(
                    '오늘 예산보다 ${won(b.overspent)} 더 사용했어요.',
                    style: DtrDesign.text(13, color: DtrDesign.accent),
                  ),
                if (b.allocated == 0)
                  const Text('배분할 예산이 없어요. 지출은 계속 기록할 수 있어요.'),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            DtrDesign.asset(
              (ref.watch(petPointsProvider).asData?.value.level ?? 1) >= 5
                  ? 'bloom'
                  : (ref.watch(petPointsProvider).asData?.value.level ?? 1) >= 2
                  ? 'sprout'
                  : 'idle',
              24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                data.expenses.any((e) => day(e.date) == b.date)
                    ? '가계부에 한 알 담았어요!'
                    : '한 알, 두 알, 모이면 큰 도토리.',
                style: DtrDesign.text(
                  13,
                  color: Colors.black,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: metric('오늘 배정', won(b.allocated))),
            const SizedBox(width: 10),
            Expanded(child: metric('오늘 쓴 돈', won(b.spent))),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: DtrDesign.panel(outlined: true),
          child: Column(
            children: [
              detail('관리 잔액', won(b.balance)),
              const SizedBox(height: 9),
              detail('보호할 저축', won(savings)),
              const SizedBox(height: 9),
              detail('남은 고정지출', won(b.reserved)),
              const SizedBox(height: 9),
              detail(
                '다음 수입일',
                '${data.plan.payday.month}월 ${data.plan.payday.day}일',
              ),
              if (deficit < 0)
                Text(
                  '저축·고정지출을 확보하려면 ${won(-deficit)} 부족해요.',
                  style: DtrDesign.text(13, color: DtrDesign.accent),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!b.expired)
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              minimumSize: const Size(0, 36),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BudgetChangeScreen(savings: savings),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '추가 수입 · 저축 목표 변경',
                    style: DtrDesign.text(
                      14,
                      color: DtrDesign.accent,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
                Text('›', style: DtrDesign.text(18, color: DtrDesign.accent)),
              ],
            ),
          ),
        if (data.plan.fixedCosts.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('예정 고정지출', style: DtrDesign.text(15, weight: FontWeight.w700)),
          const SizedBox(height: 7),
        ],
        ...data.plan.fixedCosts.map((cost) {
          final paid = data.expenses.any((e) => e.fixedCostId == cost.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Material(
              color: DtrDesign.soft,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: paid || b.expired
                    ? null
                    : () => edit(null, data, fixed: cost),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          cost.name,
                          style: DtrDesign.text(14, weight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '${won(cost.amount)}${paid ? ' · 결제 완료' : ''}',
                        style: DtrDesign.text(14, weight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        ...data.plan.changes.reversed.map(
          (c) => ListTile(
            dense: true,
            title: Text('${dateLabel(c.date)} 예산 조정'),
            subtitle: Text(
              '추가 수입 ${won(c.income)} · 저축 ${won(c.savings ?? data.plan.savingsAt(c.date))}\n${c.reason}',
            ),
          ),
        ),
      ],
    );
  }

  Widget metric(String title, String value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: DtrDesign.panel(radius: 14, outlined: true),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: DtrDesign.text(13, color: DtrDesign.muted)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: DtrDesign.text(21, weight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  Widget detail(String title, String value) => Row(
    children: [
      Expanded(
        child: Text(title, style: DtrDesign.text(14, color: DtrDesign.muted)),
      ),
      Text(value, style: DtrDesign.text(15, weight: FontWeight.w500)),
    ],
  );
  Widget history(LedgerState data) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
    children: [
      DtrHeader(
        'DTR (돈토리)',
        onTitleLongPress: kDebugMode ? () => showQaTools(context, ref) : null,
        trailing: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: DtrDesign.soft,
            foregroundColor: DtrDesign.accent,
          ),
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const BackupScreen())),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DtrDesign.asset('folder', 17),
              const SizedBox(width: 6),
              const Text('백업'),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text('이번 예산 기간의 기록', style: DtrDesign.text(27, weight: FontWeight.w700)),
      const SizedBox(height: 16),
      if (data.expenses.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Text(
              '첫 지출을 기록해 보세요.',
              style: DtrDesign.text(16, color: DtrDesign.muted),
            ),
          ),
        ),
      ...data.expenses.map(
        (e) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: DtrDesign.panel(radius: 14, outlined: true),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: data.today.expired ? null : () => edit(e, data),
                onLongPress: data.today.expired ? null : () => removeExpense(e),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              won(e.amount),
                              style: DtrDesign.text(
                                21,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${e.date.month}월 ${e.date.day}일 · ${e.category.isEmpty ? '미분류' : e.category}',
                              style: DtrDesign.text(
                                13,
                                color: DtrDesign.muted,
                                weight: FontWeight.w500,
                              ),
                            ),
                            if (e.memo.isNotEmpty)
                              Text(e.memo, style: DtrDesign.text(14)),
                          ],
                        ),
                      ),
                      Text(
                        '›',
                        style: DtrDesign.text(
                          20,
                          color: DtrDesign.muted,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
  Future<void> removeExpense(Expense e) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지출을 삭제할까요?'),
        content: Text('${won(e.amount)} · ${e.category}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (remove != true || !mounted) return;
    try {
      await ref.read(databaseProvider).deleteExpense(e.id, DateTime.now());
      ref.invalidate(ledgerProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('지출을 삭제했어요.'),
          action: SnackBarAction(
            label: '실행 취소',
            onPressed: () async {
              try {
                await ref.read(databaseProvider).saveExpense(e, DateTime.now());
                ref.invalidate(ledgerProvider);
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('복원하지 못했어요: $error')));
                }
              }
            },
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}
