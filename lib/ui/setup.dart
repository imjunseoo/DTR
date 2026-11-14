import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/budget.dart';
import 'state.dart';
import 'design.dart';
import 'growth.dart';

import 'package:flutter/foundation.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key, this.closeAfterSave = false});
  final bool closeAfterSave;
  @override
  ConsumerState<SetupScreen> createState() => _SetupState();
}

class _SetupState extends ConsumerState<SetupScreen> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  final saving = TextEditingController(text: '0');
  final fixedName = TextEditingController();
  final fixedAmount = TextEditingController();
  final costs = <FixedCost>[];
  DateTime payday = day(DateTime.now()).add(const Duration(days: 30));
  bool busy = false;
  bool addingCost = false;
  String? error;
  @override
  void dispose() {
    amount.dispose();
    saving.dispose();
    fixedName.dispose();
    fixedAmount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Form(
      key: form,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 36).clamp(0, double.infinity),
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DtrHeader(
                  ref.watch(qaModeProvider) ? 'DTR (돈토리) · QA' : 'DTR (돈토리)',
                  onTitleLongPress: kDebugMode
                      ? () => showQaTools(context, ref)
                      : null,
                ),
                const SizedBox(height: 16),
                const Text(
                  '생활비의 기준을\n함께 정해볼까요?',
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  '다음 수입일까지 관리할 금액을 정해 주세요.',
                  style: DtrDesign.text(14, color: DtrDesign.muted),
                ),
                const SizedBox(height: 16),
                moneyField(amount, '현재 관리 금액'),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                    side: const BorderSide(color: DtrDesign.border),
                  ),
                  tileColor: DtrDesign.card,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  title: Text(
                    '다음 수입일',
                    style: DtrDesign.text(12, color: DtrDesign.muted),
                  ),
                  subtitle: Text(
                    '${payday.year}년 ${payday.month}월 ${payday.day}일',
                    style: DtrDesign.text(17, weight: FontWeight.w500),
                  ),
                  onTap: busy
                      ? null
                      : () async {
                          final today = day(DateTime.now());
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: payday,
                            firstDate: today.add(const Duration(days: 1)),
                            lastDate: today.add(const Duration(days: 366)),
                          );
                          if (picked != null) {
                            setState(() => payday = day(picked));
                          }
                        },
                ),
                const SizedBox(height: 16),
                moneyField(saving, '보호할 저축액'),
                const SizedBox(height: 16),
                const Text(
                  '아직 낼 고정지출',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ...costs.map(
                  (e) => ListTile(
                    title: Text(e.name),
                    subtitle: Text(won(e.amount)),
                    trailing: IconButton(
                      onPressed: busy
                          ? null
                          : () => setState(() => costs.remove(e)),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ),
                if (addingCost) ...[
                  const SizedBox(height: 8),
                  dtrField(
                    TextField(
                      controller: fixedName,
                      maxLength: 40,
                      decoration: const InputDecoration(
                        labelText: '이름 (예: 통신비)',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  dtrField(
                    TextField(
                      controller: fixedAmount,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(13),
                      ],
                      decoration: const InputDecoration(
                        labelText: '고정지출 금액',
                        suffixText: '원',
                      ),
                    ),
                  ),
                ],
                TextButton.icon(
                  onPressed: busy
                      ? null
                      : () {
                          if (!addingCost) {
                            setState(() => addingCost = true);
                            return;
                          }
                          try {
                            final cost = FixedCost(
                              id: DateTime.now().microsecondsSinceEpoch
                                  .toString(),
                              name: fixedName.text.trim(),
                              amount: int.tryParse(fixedAmount.text) ?? 0,
                            );
                            setState(() {
                              costs.add(cost);
                              addingCost = false;
                              fixedName.clear();
                              fixedAmount.clear();
                              error = null;
                            });
                          } catch (e) {
                            setState(
                              () => error = '고정지출 이름과 1원 이상의 금액을 입력해 주세요.',
                            );
                          }
                        },
                  icon: const Icon(Icons.add),
                  label: Text(addingCost ? '고정지출 저장' : '고정지출 추가'),
                ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                const Spacer(),
                FilledButton(
                  onPressed: busy ? null : save,
                  child: Text(busy ? '저장 중…' : '내 예산 시작하기'),
                ),
                const SizedBox(height: 5),
                const Text(
                  '저축액은 생활비 계산에서 보호해요. 실제 이체는 하지 않아요.',
                  style: TextStyle(fontSize: 12, color: DtrDesign.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (fixedName.text.trim().isNotEmpty || fixedAmount.text.isNotEmpty) {
      setState(() => error = '입력 중인 고정지출을 추가하거나 입력란을 비워 주세요.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final now = DateTime.now();
      await ref
          .read(databaseProvider)
          .startCycle(
            BudgetPlan(
              amount: int.parse(amount.text),
              savings: int.parse(saving.text),
              start: now,
              payday: payday,
              fixedCosts: List.of(costs),
            ),
            now,
          );
      ref.invalidate(ledgerProvider);
      if (mounted && widget.closeAfterSave) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
