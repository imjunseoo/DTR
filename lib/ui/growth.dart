import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/backup.dart';
import '../domain/budget.dart';
import 'state.dart';
import 'design.dart';

class GrowthScreen extends ConsumerStatefulWidget {
  const GrowthScreen({super.key});
  @override
  ConsumerState<GrowthScreen> createState() => _GrowthState();
}

class _GrowthState extends ConsumerState<GrowthScreen> {
  bool busy = false;
  Future<void> train() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final ok = await ref.read(databaseProvider).trainPet(DateTime.now());
      if (!mounted) return;
      ref.invalidate(petPointsProvider);
      final pet = await ref.read(petPointsProvider.future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? '레벨 업! 돈토리가 Lv. ${pet.level}이 되었어요.' : '도토리가 더 필요해요.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('강화 결과를 불러오지 못했어요. 다시 확인해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ref
      .watch(petPointsProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(petPointsProvider),
            child: const Text('성장 정보 다시 불러오기'),
          ),
        ),
        data: (pet) {
          final name = pet.level >= 5
              ? '단풍 왕관'
              : pet.level >= 2
              ? '새싹'
              : '씨앗';
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 24).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 42,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onLongPress: () => showQaTools(context, ref),
                            child: Text(
                              '돈토리 성장',
                              style: DtrDesign.text(
                                23,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        height: 344,
                        decoration: DtrDesign.panel(
                          color: DtrDesign.peach,
                          radius: 24,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Lv. ${pet.level}',
                              style: DtrDesign.text(
                                18,
                                color: DtrDesign.accent,
                                weight: FontWeight.w700,
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              child: SizedBox(
                                key: ValueKey(pet.sprite),
                                width: 168,
                                height: 168,
                                child: DtrDesign.asset(
                                  '${pet.sprite}-hero',
                                  168,
                                ),
                              ),
                            ),
                            Text(
                              '$name 돈토리',
                              style: DtrDesign.text(
                                26,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 54,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '보유 도토리',
                              style: DtrDesign.text(
                                17,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${pet.balance}개',
                              style: DtrDesign.text(
                                24,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 24,
                        child: Text(
                          '성장 단계',
                          style: DtrDesign.text(17, weight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                height: 100,
                                decoration: DtrDesign.panel(
                                  color:
                                      (pet.level >= 5
                                              ? 2
                                              : pet.level >= 2
                                              ? 1
                                              : 0) ==
                                          i
                                      ? const Color(0xFFFFE1BC)
                                      : DtrDesign.growthSoft,
                                  radius: 15,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    DtrDesign.asset(
                                      ['seed', 'sprout', 'bloom'][i],
                                      48,
                                    ),
                                    Text(
                                      ['Lv.1 씨앗', 'Lv.2 새싹', 'Lv.5 성장'][i],
                                      style: DtrDesign.text(
                                        14,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Spacer(),
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: DtrDesign.accent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFF0E3D4),
                            disabledForegroundColor: const Color(0xFF70533D),
                          ),
                          onPressed: pet.balance >= 5 && !busy ? train : null,
                          child: Text(
                            busy
                                ? '강화 중…'
                                : pet.balance >= 5
                                ? '도토리 5개로 레벨업'
                                : '도토리 ${5 - pet.balance}개 필요',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

Future<void> showQaTools(BuildContext context, WidgetRef ref) async {
  final active = ref.read(qaModeProvider);
  final choice = await showDialog<int>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('QA 개발자 도구'),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'QA 모드에서는 임시 가계부를 사용합니다. 예시를 선택하면 임시 기록이 교체됩니다. 성장 탭에서 강화하고 오늘·내역·홈 위젯에서도 결과를 확인하세요. QA 종료 시 원래 기록으로 돌아갑니다.',
          ),
        ),
        if (active) ...[
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 1),
            child: const Text('예시 · 도토리 5개 / 첫 강화'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 2),
            child: const Text('예시 · Lv. 4 / 최종 외형 직전'),
          ),
        ],
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, 0),
          child: Text(active ? 'QA 종료 · 원래 가계부로' : 'QA 시작 · 빈 임시 가계부'),
        ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return;
  if (choice == 0) {
    ref.read(qaModeProvider.notifier).toggle();
    return;
  }
  if (!ref.read(qaModeProvider)) return;
  final db = ref.read(databaseProvider);
  final now = day(DateTime.now());
  final start = now.subtract(Duration(days: choice == 1 ? 2 : 10));
  final plan = BudgetPlan(
    amount: 300000,
    savings: 0,
    start: start,
    payday: now.add(const Duration(days: 10)),
  );
  final entries = <Expense>[];
  for (
    var d = start;
    choice == 1 ? !d.isAfter(now) : d.isBefore(now);
    d = d.add(const Duration(days: 1))
  ) {
    entries.add(
      Expense(
        id: 'qa-${d.toIso8601String()}',
        amount: 1000,
        date: d,
        category: 'QA',
      ),
    );
  }
  try {
    await db.restoreBackup(
      BackupData([
        BackupCycle(1, plan, start, entries),
      ], upgrades: choice == 1 ? 0 : 3).encode(),
      now,
    );
    if (!context.mounted) return;
    ref.invalidate(ledgerProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('예시가 준비됐어요. 성장 탭에서 강화하세요.')));
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('QA 예시를 불러오지 못했어요.')));
    }
  }
}
