import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/budget.dart';
import 'state.dart';
import 'design.dart';

class BudgetChangeScreen extends ConsumerStatefulWidget {
  const BudgetChangeScreen({super.key, required this.savings});
  final int savings;
  @override
  ConsumerState<BudgetChangeScreen> createState() => _ChangeState();
}

class _ChangeState extends ConsumerState<BudgetChangeScreen> {
  final form = GlobalKey<FormState>();
  final income = TextEditingController(text: '0');
  late final savings = TextEditingController(text: widget.savings.toString());
  final reason = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    income.dispose();
    savings.dispose();
    reason.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final now = DateTime.now();
      await ref
          .read(databaseProvider)
          .addBudgetChange(
            BudgetChange(
              id: now.microsecondsSinceEpoch.toString(),
              recordedAt: now,
              date: now,
              income: int.parse(income.text),
              savings: int.parse(savings.text),
              reason: reason.text,
            ),
            now,
          );
      ref.invalidate(ledgerProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          children: [
            const DtrHeader('예산 조정', back: true),
            const SizedBox(height: 16),
            const Text(
              '변경은 오늘부터 반영돼요',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text('추가로 받은 돈과 저축 목표를 반영해 오늘 배정액부터 다시 계산해요.'),
            const SizedBox(height: 16),
            moneyField(income, '추가 수입'),
            const SizedBox(height: 16),
            moneyField(savings, '보호할 저축액'),
            const SizedBox(height: 16),
            dtrField(
              TextFormField(
                controller: reason,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: '변경 메모 (선택)',
                  counterText: '',
                ),
              ),
            ),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy ? null : save,
              child: Text(busy ? '반영 중…' : '오늘 예산에 반영'),
            ),
          ],
        ),
      ),
    ),
  );
}
