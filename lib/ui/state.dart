import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import 'design.dart';
import '../domain/budget.dart';
import '../platform/android_bridge.dart';

final qaModeProvider = NotifierProvider<QaMode, bool>(QaMode.new);

class QaMode extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() {
    if (kDebugMode) state = !state;
  }
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(
    ref.watch(qaModeProvider) ? NativeDatabase.memory() : null,
  );
  ref.onDispose(db.close);
  return db;
});
final ledgerProvider = FutureProvider<LedgerState?>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  await db.refreshSnapshots(now);
  return db.load(now);
});
final petPointsProvider = FutureProvider<PetStatus>((ref) async {
  final db = ref.watch(databaseProvider);
  await ref.watch(ledgerProvider.future);
  return db.petStatus(DateTime.now());
});
final widgetSyncProvider = FutureProvider<bool>((ref) async {
  final state = await ref.watch(ledgerProvider.future);
  try {
    final pet = await ref.watch(petPointsProvider.future);
    await AndroidBridge.sync(state, pet.upgrades.clamp(0, 4) * 5);
    return true;
  } catch (_) {
    return false;
  }
});
String won(int n) =>
    '${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';
String dateLabel(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
Widget moneyField(
  TextEditingController controller,
  String label, {
  bool allowZero = true,
}) => dtrField(
  TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(13),
    ],
    style: DtrDesign.text(17, weight: FontWeight.w500),
    decoration: InputDecoration(labelText: label, suffixText: '원'),
    validator: (s) {
      final n = int.tryParse(s ?? '');
      return n == null || n < (allowZero ? 0 : 1) || n > maxWon
          ? '${allowZero ? 0 : 1}~${won(maxWon)} 사이 정수를 입력해 주세요.'
          : null;
    },
  ),
);
