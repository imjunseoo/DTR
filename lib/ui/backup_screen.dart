import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/backup.dart';
import '../platform/android_bridge.dart';
import 'state.dart';

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
    appBar: AppBar(title: const Text('백업 및 복원')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.folder_copy_outlined, size: 56),
        const SizedBox(height: 20),
        const Text(
          '내 기록을 안전하게 보관해요',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          '백업에는 예산·저축 설정, 고정지출, 지출 내역이 포함됩니다. 백업 파일은 암호화되지 않으므로 개인 저장 공간에 보관해 주세요. 앱을 삭제하면 기기 내 기록도 삭제됩니다.',
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: busy ? null : export,
          icon: const Icon(Icons.save_alt),
          label: const Text('백업 파일 저장'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: busy ? null : restore,
          icon: const Icon(Icons.restore),
          label: const Text('파일에서 복원'),
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
  );
}
