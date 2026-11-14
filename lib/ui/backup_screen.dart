import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/backup.dart';
import '../platform/android_bridge.dart';
import 'state.dart';
import 'design.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});
  @override
  ConsumerState<BackupScreen> createState() => _BackupState();
}

class _BackupState extends ConsumerState<BackupScreen> {
  bool busy = false;
  String? message;
  Future<void> export() async {
    setState(() => busy = true);
    try {
      final data = await ref.read(databaseProvider).exportBackup();
      final saved = await AndroidBridge.export(data.encode());
      if (mounted) {
        setState(() => message = saved ? '백업 파일을 저장했어요.' : '저장을 취소했어요.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => message = '파일을 저장하지 못했어요. 저장 위치를 확인하고 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> restore() async {
    setState(() => busy = true);
    try {
      final source = await AndroidBridge.import();
      if (source == null) return;
      final data = BackupData.decode(source, DateTime.now());
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('이 백업으로 복원할까요?'),
          content: Text(
            '예산 ${data.cycles.length}개 · 지출 ${data.expenseCount}건\n현재 기기의 모든 예산과 지출을 이 파일로 교체합니다. 먼저 현재 기록을 백업해 두세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('교체 후 복원'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await ref.read(databaseProvider).restoreBackup(source, DateTime.now());
      ref.invalidate(ledgerProvider);
      if (mounted) setState(() => message = '복원했어요. 오늘 예산을 다시 계산했습니다.');
    } catch (e) {
      if (mounted) setState(() => message = '복원하지 못했어요. 기존 기록은 유지됩니다.\n$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        children: [
          const DtrHeader('백업 및 복원', back: true),
          const SizedBox(height: 16),
          Text(
            '내 기록을 안전하게 보관해요',
            style: DtrDesign.text(27, weight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            '예산, 저축 설정, 고정지출과 지출 내역을 파일로 보관할 수 있어요.',
            style: DtrDesign.text(14, color: DtrDesign.muted),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: DtrDesign.panel(color: DtrDesign.soft, radius: 13),
            child: Text(
              '백업 파일은 암호화되지 않아요. 개인 저장 공간에 보관해 주세요.',
              style: DtrDesign.text(14, color: DtrDesign.muted),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : export,
            child: const Text('백업 파일 저장'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: busy ? null : restore,
            child: const Text('파일에서 복원'),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(20),
              child: LinearProgressIndicator(),
            ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(message!),
            ),
        ],
      ),
    ),
  );
}
