import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/budget.dart';
import 'state.dart';

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
  Widget build(BuildContext context) => Form(
    key: form,
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          '생활비의 기준을\n함께 정해볼까요?',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text('다음 수입일까지 관리할 현재 금액을 입력해 주세요.\n저축과 아직 낼 고정지출은 미리 보호할게요.'),
        const SizedBox(height: 24),
        moneyField(amount, '현재 관리 금액'),
        const SizedBox(height: 16),
        moneyField(saving, '보호할 저축액'),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('다음 수입일'),
          subtitle: Text(dateLabel(payday)),
          trailing: const Icon(Icons.calendar_month),
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
                  if (picked != null) setState(() => payday = day(picked));
                },
        ),
        const Divider(),
        const Text(
          '아직 낼 고정지출',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ...costs.map(
          (e) => ListTile(
            title: Text(e.name),
            subtitle: Text(won(e.amount)),
            trailing: IconButton(
              onPressed: busy ? null : () => setState(() => costs.remove(e)),
              icon: const Icon(Icons.close),
            ),
          ),
        ),
        TextField(
          controller: fixedName,
          maxLength: 40,
          decoration: const InputDecoration(labelText: '이름 (예: 통신비)'),
        ),
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
        TextButton.icon(
          onPressed: busy
              ? null
              : () {
                  try {
                    final cost = FixedCost(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      name: fixedName.text.trim(),
                      amount: int.tryParse(fixedAmount.text) ?? 0,
                    );
                    setState(() {
                      costs.add(cost);
                      fixedName.clear();
                      fixedAmount.clear();
                      error = null;
                    });
                  } catch (e) {
                    setState(() => error = '고정지출 이름과 1원 이상의 금액을 입력해 주세요.');
                  }
                },
          icon: const Icon(Icons.add),
          label: const Text('고정지출 추가'),
        ),
        if (error != null)
          Text(error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(busy ? '저장 중…' : '내 예산 시작하기'),
        ),
        const SizedBox(height: 12),
        const Text(
          '기록은 이 기기에 저장돼요. 저축액은 예산에서 보호하며 실제 이체는 하지 않아요.',
          style: TextStyle(color: Colors.black54),
        ),
      ],
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
