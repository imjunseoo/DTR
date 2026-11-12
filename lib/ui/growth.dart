import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/backup.dart';
import '../domain/budget.dart';
import 'state.dart';

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
              ? '성장'
              : pet.level >= 2
              ? '새싹'
              : '씨앗';
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('내 돈토리', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xfff6e8c8),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: Image.asset(
                          'android/app/src/main/res/drawable-nodpi/dori_${pet.sprite}.png',
                          key: ValueKey(pet.level),
                          width: 120,
                          height: 120,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                      Text(
                        'Lv. ${pet.level}  ·  $name 돈토리',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pet.level >= 5
                            ? '한 알씩 모아 이만큼 자랐어요.'
                            : pet.level >= 2
                            ? 'Lv. 5에 다 자란 모습이 돼요.'
                            : 'Lv. 2에 새싹이 돋아요.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '보유 도토리  ${pet.balance}개',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: pet.balance.clamp(0, 5) / 5),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: pet.balance >= 5 && !busy ? train : null,
                icon: const Icon(Icons.eco),
                label: Text(
                  busy
                      ? '강화 중…'
                      : pet.balance >= 5
                      ? '도토리 5개로 레벨 업'
                      : '강화까지 도토리 ${5 - pet.balance}개',
                ),
              ),
              const SizedBox(height: 16),
              const Text('도토리 모으기'),
              const Text('지출을 기록한 날에는 1개, 그날 예산보다 적게 썼다면 다음 날 1개를 더 받아요.'),
            ],
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
