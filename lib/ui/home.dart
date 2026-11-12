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
      appBar: AppBar(
        title: Text(
          ref.watch(qaModeProvider) ? 'DTR · QA' : 'DTR',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'QA 개발자 도구',
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () => showQaTools(context, ref),
            ),
          IconButton(
            tooltip: '백업 및 복원',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BackupScreen()),
            ),
            icon: const Icon(Icons.folder_copy_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Chip(label: Text(dateLabel(DateTime.now()))),
          ),
        ],
      ),
      persistentFooterButtons: widgetSync.asData?.value == false
          ? [const Text('기록은 저장됐어요. 위젯 갱신은 앱을 다시 열 때 재시도합니다.')]
          : null,
      body: page == 2
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
      floatingActionButton:
          page != 2 &&
              ledger.asData?.value != null &&
              !ledger.asData!.value!.today.expired
          ? FloatingActionButton.extended(
              onPressed: () => edit(null, ledger.asData!.value!),
              icon: const Icon(Icons.add),
              label: const Text('지출 입력'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (i) => setState(() => page = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            label: '오늘',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: '내역',
          ),
          NavigationDestination(icon: Icon(Icons.eco_outlined), label: '성장'),
        ],
      ),
    );
  }

  Widget dashboard(LedgerState data) {
    final b = data.today;
    final protectedSavings = data.plan.savingsAt(b.date);
    final deficit = b.balance - protectedSavings - b.reserved;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        const Text('오늘도 내 속도대로'),
        const SizedBox(height: 8),
        if (b.expired)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '새 생활비를 설정할 시간이에요',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Text('이전 기록은 보관됩니다. 현재 관리할 실제 금액을 확인해 주세요.'),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const Scaffold(
                          body: SafeArea(
                            child: SetupScreen(closeAfterSave: true),
                          ),
                        ),
                      ),
                    ),
                    child: const Text('새 예산 설정'),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            color: const Color(0xFFE2EEDD),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('오늘 남은 예산'),
                  const SizedBox(height: 12),
                  Text(
                    won(b.remaining),
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: b.hp),
                    duration: const Duration(milliseconds: 350),
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 18,
                      borderRadius: BorderRadius.circular(12),
                      color: b.hp < 0.25
                          ? Colors.deepOrange
                          : const Color(0xFF216B52),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '생활비 HP ${(b.hp * 100).round()}% · 수입일까지 ${b.daysLeft}일',
                  ),
                  if (b.overspent > 0)
                    Text(
                      '오늘 예산보다 ${won(b.overspent)} 더 사용했어요.',
                      style: const TextStyle(color: Colors.deepOrange),
                    ),
                  if (b.allocated == 0)
                    const Text('배분할 예산이 없어요. 지출은 계속 기록할 수 있어요.'),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (ref.watch(petPointsProvider).asData case final points?)
          Builder(
            builder: (context) {
              final pet = points.value;
              final stage = pet.sprite;
              final logged = data.expenses.any((e) => day(e.date) == b.date);
              return Row(
                children: [
                  Image.asset(
                    'android/app/src/main/res/drawable-nodpi/dori_$stage.png',
                    width: 48,
                    height: 48,
                    filterQuality: FilterQuality.none,
                    semanticLabel: '돈토리',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lv. ${pet.level} · ${pet.balance} 도토리\n'
                      '${logged ? "가계부에 한 알 담았어요!" : "한 알, 두 알, 모이면 큰 도토리."}',
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: metric('오늘 배정', won(b.allocated))),
            const SizedBox(width: 12),
            Expanded(child: metric('오늘 쓴 돈', won(b.spent))),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                detail('관리 잔액', won(b.balance)),
                detail('보호할 저축', won(protectedSavings)),
                detail('남은 고정지출', won(b.reserved)),
                detail('다음 수입일', dateLabel(data.plan.payday)),
                if (deficit < 0)
                  Text(
                    '저축·고정지출을 확보하려면 ${won(-deficit)} 부족해요.',
                    style: const TextStyle(color: Colors.deepOrange),
                  ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            '오늘 배정액은 지출해도 유지돼요. 남은 생활비는 다음 날 다시 나눕니다.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
        if (!b.expired)
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BudgetChangeScreen(savings: protectedSavings),
              ),
            ),
            icon: const Icon(Icons.tune),
            label: const Text('추가 수입 · 저축 목표 변경'),
          ),
        ...data.plan.changes.reversed.map(
          (c) => ListTile(
            dense: true,
            leading: const Icon(Icons.history),
            title: Text('${dateLabel(c.date)} 예산 조정'),
            subtitle: Text(
              '추가 수입 ${won(c.income)} · 저축 ${won(c.savings ?? data.plan.savingsAt(c.date))}\n${c.reason}',
            ),
          ),
        ),
        if (data.plan.fixedCosts.isNotEmpty)
          const Text(
            '예정 고정지출',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ...data.plan.fixedCosts.map((cost) {
          final paid = data.expenses.any((e) => e.fixedCostId == cost.id);
          return Card(
            child: ListTile(
              title: Text(cost.name),
              subtitle: Text(won(cost.amount)),
              trailing: paid
                  ? const Chip(label: Text('결제 완료'))
                  : TextButton(
                      onPressed: b.expired
                          ? null
                          : () => edit(null, data, fixed: cost),
                      child: const Text('결제 기록'),
                    ),
            ),
          );
        }),
      ],
    );
  }

  Widget metric(String title, String value) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
  Widget detail(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(title), Text(value)],
    ),
  );
  Widget history(LedgerState data) => data.expenses.isEmpty
      ? const Center(child: Text('첫 지출을 기록해 보세요.'))
      : ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                '이번 예산 기간의 기록',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ...data.expenses.map(
              (e) => ListTile(
                leading: Icon(
                  e.fixedCostId == null
                      ? Icons.shopping_bag_outlined
                      : Icons.event_repeat,
                ),
                title: Text(won(e.amount)),
                subtitle: Text(
                  '${dateLabel(e.date)} · ${e.category.isEmpty ? '미분류' : e.category}${e.memo.isEmpty ? '' : '\n${e.memo}'}',
                ),
                onTap: data.today.expired ? null : () => edit(e, data),
                trailing: data.today.expired
                    ? null
                    : IconButton(
                        tooltip: '지출 삭제',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          try {
                            await ref
                                .read(databaseProvider)
                                .deleteExpense(e.id, DateTime.now());
                            ref.invalidate(ledgerProvider);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('지출을 삭제했어요.'),
                                action: SnackBarAction(
                                  label: '실행 취소',
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(databaseProvider)
                                          .saveExpense(e, DateTime.now());
                                      ref.invalidate(ledgerProvider);
                                    } catch (error) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('복원하지 못했어요: $error'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            );
                          } catch (error) {
                            if (mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text('$error')));
                            }
                          }
                        },
                      ),
              ),
            ),
          ],
        );
}
