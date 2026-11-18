import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

typedef UsageTransport = Future<int> Function(
  String path,
  String token,
  Map<String, Object?> body,
);
typedef UsageLoad = Future<Map<String, dynamic>> Function();
typedef UsageSave = Future<void> Function(Map<String, dynamic> data);

String usageDay(DateTime time) => time
    .toUtc()
    .add(const Duration(hours: 9))
    .toIso8601String()
    .substring(0, 10);
String randomUsageId(int bytes) => List.generate(
  bytes,
  (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();

class UsageAnalytics extends ChangeNotifier {
  UsageAnalytics({
    this.endpoint = const String.fromEnvironment('DTR_ANALYTICS_URL'),
    this.version = const String.fromEnvironment(
      'DTR_APP_VERSION',
      defaultValue: 'dev',
    ),
    required this.isQa,
    this._transport,
    this._load,
    this._save,
    DateTime Function()? clock,
  }) : now = clock ?? DateTime.now;
  final String endpoint, version;
  final bool Function() isQa;
  final DateTime Function() now;
  final UsageTransport? _transport;
  final UsageLoad? _load;
  final UsageSave? _save;
  Map<String, dynamic> _data = {};
  Future<void>? _ready;
  Future<void> _serial = Future.value();
  bool _sending = false, _revoking = false, _disposed = false;
  int _generation = 0;
  String _session = '', _sessionDay = '';
  DateTime? _pausedAt;
  HttpClient? _client;
  String? error;
  bool get configured => Uri.tryParse(endpoint)?.scheme == 'https';
  bool get enabled => !_revoking && _data['enabled'] == true;
  bool get deletePending => _data['deletePending'] == true;
  int get queued => (_data['queue'] as List?)?.length ?? 0;
  String get status => deletePending
      ? '수집 중지 · 서버 삭제 대기'
      : enabled
      ? '수집 동의함'
      : '수집하지 않음';
  String get _id => _data['installId'] as String? ?? '';
  String get _secret => _data['deviceSecret'] as String? ?? '';
  List<Map<String, dynamic>> get _queue => ((_data['queue'] as List?) ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  void changed() {
    if (!_disposed) notifyListeners();
  }

  Future<File> _file() async =>
      File('${(await getApplicationSupportDirectory()).path}/beta-usage.json');
  Future<void> initialize() => _ready ??= (() async {
    if (!configured) return;
    try {
      if (_load != null) {
        _data = await _load();
      } else {
        final file = await _file();
        if (await file.exists()) {
          _data = Map<String, dynamic>.from(
            jsonDecode(await file.readAsString()) as Map,
          );
        }
      }
    } catch (_) {
      _data = {};
      error = '수집 설정을 읽지 못해 수집을 중지했어요.';
    }
    changed();
  })();
  Future<void> _persist() async {
    if (_save != null) {
      await _save(jsonDecode(jsonEncode(_data)) as Map<String, dynamic>);
      return;
    }
    final file = await _file();
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(_data), flush: true);
    await temp.rename(file.path);
  }

  Future<void> _locked(Future<void> Function() task) {
    final result = _serial.then((_) => task());
    _serial = result.catchError((Object _) {});
    return result;
  }

  Future<int> _request(
    String path,
    String token,
    Map<String, Object?> body,
  ) async {
    if (_transport != null) return _transport(path, token, body);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    _client = client;
    try {
      return await (() async {
        final request = await client.postUrl(Uri.parse('$endpoint$path'));
        request.followRedirects = false;
        request.headers.contentType = ContentType.json;
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        request.write(jsonEncode(body));
        final response = await request.close();
        await response.drain<void>();
        return response.statusCode;
      })().timeout(const Duration(seconds: 10));
    } finally {
      client.close(force: true);
      if (_client == client) _client = null;
    }
  }

  Future<void> enable(String invitation, {required bool hasBudget}) async {
    await initialize();
    if (!configured || isQa()) throw StateError('QA 모드에서는 수집하지 않아요.');
    if (deletePending) {
      await flush();
      if (deletePending) throw StateError('기존 데이터 삭제가 끝난 뒤 다시 참여해 주세요.');
    }
    if (invitation.trim().length < 24 ||
        invitation.trim().startsWith('sk-ant-')) {
      throw StateError('베타 초대 코드를 입력해 주세요.');
    }
    await _locked(() async {
      if (_id.isEmpty) {
        _data = {
          'installId': randomUsageId(16),
          'deviceSecret': randomUsageId(32),
          'queue': [],
        };
      }
      await _persist();
      final result = await _request('/telemetry/enroll', invitation.trim(), {
        'installId': _id,
        'deviceSecret': _secret,
        'consentVersion': 1,
      });
      if (result != 200) throw StateError('초대 코드와 인터넷 연결을 확인해 주세요.');
      _data['enabled'] = true;
      _data['deletePending'] = false;
      _revoking = false;
      error = null;
      await _persist();
    });
    changed();
    await active();
    if (hasBudget) await budgetReady();
  }

  void pause() {
    _pausedAt ??= now();
  }

  void _ensureSession() {
    final date = usageDay(now());
    if (_session.isEmpty ||
        _sessionDay != date ||
        (_pausedAt != null &&
            now().difference(_pausedAt!) >= const Duration(minutes: 30))) {
      _session = randomUsageId(16);
      _sessionDay = date;
      _append('session_start');
    }
    _pausedAt = null;
  }

  void _append(String type, {String source = 'app'}) {
    final queue = _queue
      ..add({
        'id': randomUsageId(16),
        'type': type,
        'at': now().toUtc().toIso8601String(),
        'session': _session,
        'source': source,
        'version': version,
      });
    // Bound storage and upload only recent data, never reconstruct old ledger contents.
    final cutoff = now().toUtc().subtract(const Duration(days: 29));
    final recent = queue
        .where((e) => DateTime.parse(e['at'] as String).isAfter(cutoff))
        .toList();
    _data['queue'] = recent.length > 1000
        ? recent.sublist(recent.length - 1000)
        : recent;
  }

  Future<void> _record(String type, {String source = 'app'}) async {
    try {
      await initialize();
      if (!configured || !enabled || isQa()) return;
      await _locked(() async {
        if (!enabled || isQa()) return;
        _ensureSession();
        if (type == 'app_active') {
          final date = usageDay(now());
          if (_data['lastActive'] != date) {
            _append(type);
            _data['lastActive'] = date;
          }
        } else if (type == 'budget_ready') {
          if (_data['budgetReady'] != true) {
            _append(type);
            _data['budgetReady'] = true;
          }
        } else {
          _append(type, source: source);
        }
        if (_data['budgetReady'] == true &&
            _data['budgetAcknowledged'] != true &&
            !_queue.any((e) => e['type'] == 'budget_ready')) {
          _append('budget_ready');
        }
        await _persist();
      });
      changed();
      unawaited(flush());
    } catch (_) {
      error = '사용 데이터는 전송 대기 중이에요. 가계부는 정상 이용할 수 있어요.';
      changed();
    }
  }

  Future<void> active() async {
    if (isQa()) {
      _session = '';
      return;
    }
    await _record('app_active');
    unawaited(flush());
  }

  Future<void> budgetReady() => _record('budget_ready');
  Future<void> expenseSaved() => _record('expense_saved');
  Future<void> widgetOpened(String action) => _record(
    'widget_open',
    source: action == 'chat' ? 'widget_chat' : 'widget_expense',
  );

  Future<void> withdraw() async {
    // Stop immediately, including a request that is still in flight.
    _revoking = true;
    _generation++;
    _client?.close(force: true);
    await initialize();
    await _locked(() async {
      _data['enabled'] = false;
      _data['queue'] = [];
      _data['deletePending'] = _id.isNotEmpty;
      await _persist();
    });
    changed();
    // Existing send unwinds before deletion; server revocation also rejects late arrivals.
    while (_sending) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    await flush();
  }

  Future<void> flush() async {
    await initialize();
    if (_sending || !configured || isQa() || _disposed) return;
    _sending = true;
    final generation = _generation;
    try {
      if (deletePending) {
        final result = await _request('/telemetry/delete', _secret, {
          'installId': _id,
        });
        if ([200, 401, 410].contains(result)) {
          await _locked(() async {
            _data = {'enabled': false, 'queue': []};
            await _persist();
          });
          error = null;
        } else {
          error = '서버 삭제가 대기 중이에요. 연결 후 다시 시도해 주세요.';
        }
        return;
      }
      for (
        var batch = 0;
        batch < 20 && enabled && !isQa() && generation == _generation;
        batch++
      ) {
        final events = _queue.take(50).toList();
        if (events.isEmpty) break;
        final result = await _request('/telemetry/events', _secret, {
          'installId': _id,
          'events': events,
        });
        if (generation != _generation) break;
        if (result != 200) {
          error = '사용 데이터 전송 대기 · 인터넷 연결이나 초대 설정을 확인해 주세요.';
          break;
        }
        final ids = events.map((e) => e['id']).toSet();
        await _locked(() async {
          _data['queue'] = _queue.where((e) => !ids.contains(e['id'])).toList();
          if (events.any((e) => e['type'] == 'budget_ready')) {
            _data['budgetAcknowledged'] = true;
          }
          await _persist();
        });
        error = null;
      }
    } catch (_) {
      error = deletePending
          ? '수집은 중지됐어요. 인터넷 연결 후 서버 데이터 삭제를 재시도해요.'
          : '오프라인 기록은 다음 연결 때 전송해요.';
    } finally {
      _sending = false;
      changed();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _client?.close(force: true);
    super.dispose();
  }
}
