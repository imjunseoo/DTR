import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'design.dart';
import 'state.dart';

class UsageSettings extends ConsumerStatefulWidget {
  const UsageSettings({super.key});
  @override
  ConsumerState<UsageSettings> createState() => _UsageSettingsState();
}

class _UsageSettingsState extends ConsumerState<UsageSettings> {
  final code = TextEditingController();
  bool agreed = false, busy = false;
  String? message;
  @override
  void initState() {
    super.initState();
    ref.read(usageProvider).initialize();
  }

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(() => message = '연결하지 못했어요. 초대 코드와 인터넷 연결을 확인해 주세요.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usage = ref.watch(usageProvider);
    final qa = ref.watch(qaModeProvider);
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: usage,
          builder: (_, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const DtrHeader('베타 사용 데이터', back: true),
              const SizedBox(height: 20),
              Text(
                '돈토리를 더 쓰기 좋게',
                style: DtrDesign.text(26, weight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text('선택 사항이에요. 동의하지 않아도 예산·위젯·대화를 그대로 이용할 수 있어요.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: DtrDesign.panel(color: DtrDesign.peach),
                child: Text(
                  usage.status,
                  style: DtrDesign.text(18, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '수집 항목\n무작위 설치 ID, 앱 사용·지출 저장·위젯 클릭의 날짜와 세션, 앱 버전, 진입 경로. 처음 동의한 이후의 사용만 수집해요.\n\n수집하지 않는 항목\n소비 금액, 지출 메모·분류, 대화 내용, 이름·연락처, 광고 ID.\n\n목적과 보관\n재방문율·주간 기록일·위젯 이용률 확인에 사용해요. DTR 운영자가 관리하는 Cloudflare 서버에서 처리하며 이벤트는 90일 후 자동 삭제해요. 설치 ID는 마지막 활동 후 최대 90일 보관해요.\n\n인터넷이 없을 때\n최대 1,000개 이벤트를 기기에 보관했다가 연결 후 전송해요. 30일이 지난 미전송 기록은 제외해요.\n\n동의 철회\n아래에서 수집을 중지하고 기존 서버 데이터를 삭제할 수 있어요. 오프라인이면 삭제 요청만 보관하고 다음 연결 때 처리해요.',
              ),
              const SizedBox(height: 16),
              if (qa) const Text('QA 모드에서는 사용 데이터를 수집하거나 전송하지 않아요.'),
              if (!usage.enabled && !usage.deletePending) ...[
                TextField(
                  controller: code,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  maxLength: 128,
                  decoration: const InputDecoration(
                    labelText: '베타 초대 코드',
                    helperText: 'AI 대화 초대 코드와 같아요. API 키가 아닙니다.',
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: agreed,
                  onChanged: busy
                      ? null
                      : (v) => setState(() => agreed = v ?? false),
                  title: const Text('안내를 확인하고 사용 데이터 수집에 동의해요 (선택)'),
                ),
                FilledButton(
                  onPressed: busy || !agreed || qa
                      ? null
                      : () => run(() async {
                          await usage.enable(
                            code.text,
                            hasBudget:
                                ref.read(ledgerProvider).asData?.value != null,
                          );
                          code.clear();
                        }),
                  child: const Text('동의하고 베타 참여'),
                ),
              ],
              if (usage.enabled)
                OutlinedButton(
                  onPressed: busy ? null : () => run(usage.withdraw),
                  child: const Text('수집 중지하고 서버 데이터 삭제'),
                ),
              if (usage.enabled || usage.deletePending)
                TextButton(
                  onPressed: busy || qa ? null : () => run(usage.flush),
                  child: Text(
                    usage.deletePending
                        ? '삭제 다시 시도'
                        : '대기 데이터 전송 (${usage.queued}개)',
                  ),
                ),
              if (busy) const Center(child: CircularProgressIndicator()),
              if (message != null || usage.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    message ?? usage.error!,
                    style: DtrDesign.text(14, color: DtrDesign.accent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class UsageEntry extends ConsumerWidget {
  const UsageEntry({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(usageProvider);
    return ListenableBuilder(
      listenable: usage,
      builder: (_, _) => TextButton.icon(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const UsageSettings())),
        icon: const Icon(Icons.insights_outlined, size: 18),
        label: Text(
          usage.enabled
              ? '베타 사용 데이터 · 참여 중'
              : usage.deletePending
              ? '베타 데이터 삭제 대기'
              : '베타 테스트 참여 · 사용 데이터 설정',
        ),
      ),
    );
  }
}
