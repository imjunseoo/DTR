import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../domain/budget.dart';
import 'state.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({
    super.key,
    required this.state,
    this.expense,
    this.fixed,
  });
  final LedgerState state;
  final Expense? expense;
  final FixedCost? fixed;
  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseState();
}

class _ExpenseState extends ConsumerState<ExpenseScreen> {
  final form = GlobalKey<FormState>();
  late final amount = TextEditingController(
    text:
        widget.expense?.amount.toString() ??
        widget.fixed?.amount.toString() ??
        '',
  );
  late final memo = TextEditingController(text: widget.expense?.memo ?? '');
  late String category =
      widget.expense?.category ?? (widget.fixed == null ? '' : '고정지출');
  late DateTime date = widget.expense?.date ?? day(DateTime.now());
  late final String id =
      widget.expense?.id ?? '${DateTime.now().microsecondsSinceEpoch}';
  bool busy = false;
  String? error;
  @override
  void dispose() {
    amount.dispose();
    memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.expense == null ? '빠른 지출 입력' : '지출 수정')),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.fixed != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('${widget.fixed!.name} 결제 · 예약금과 중복 차감하지 않아요.'),
            ),
          moneyField(amount, '사용한 금액', allowZero: false),
          const SizedBox(height: 20),
          if (widget.fixed == null && widget.expense?.fixedCostId == null)
            Wrap(
              spacing: 8,
              children: ['식사', '커피', '교통', '쇼핑', '기타']
                  .map(
                    (e) => ChoiceChip(
                      label: Text(e),
                      selected: category == e,
                      onSelected: busy
                          ? null
                          : (selected) =>
                                setState(() => category = selected ? e : ''),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: memo,
            maxLength: 500,
            decoration: const InputDecoration(labelText: '메모 (선택)'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(dateLabel(date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: busy
                ? null
                : () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: widget.state.plan.start,
                      lastDate: day(DateTime.now()),
                    );
                    if (picked != null) setState(() => date = day(picked));
                  },
          ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy ? null : save,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(busy ? '저장 중…' : '저장하기'),
            ),
          ),
        ],
      ),
    ),
  );
  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(databaseProvider)
          .saveExpense(
            Expense(
              id: id,
              amount: int.parse(amount.text),
              date: date,
              category: category,
              memo: memo.text,
              fixedCostId: widget.expense?.fixedCostId ?? widget.fixed?.id,
            ),
            DateTime.now(),
          );
      ref.invalidate(ledgerProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = '저장하지 못했어요. $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
