import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dtr/data/usage_analytics.dart';

class Harness {
  DateTime time = DateTime.utc(2026, 11, 18, 3);
  bool qa = false, offline = false;
  Map<String, dynamic> saved = {};
  final calls = <({String path, Map<String, Object?> body})>[];
  late UsageAnalytics usage;
  Harness() {
    restart();
  }
  void restart() {
    usage = UsageAnalytics(
      endpoint: 'https://example.test',
      version: 'test',
      isQa: () => qa,
      clock: () => time,
      load: () async => jsonDecode(jsonEncode(saved)) as Map<String, dynamic>,
      save: (data) async => saved = data,
      transport: (path, token, body) async {
        calls.add((
          path: path,
          body: jsonDecode(jsonEncode(body)) as Map<String, Object?>,
        ));
        if (offline) throw StateError('offline');
        return 200;
      },
    );
  }

  Future<void> settle() async {
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    await usage.flush();
  }

  List<Map> get events => calls
      .where((c) => c.path == '/telemetry/events')
      .expand((c) => (c.body['events'] as List).cast<Map>())
      .toList();
}

void main() {
  test('no identifier, storage, or network before optional consent', () async {
    final h = Harness();
    addTearDown(h.usage.dispose);
    await h.usage.active();
    await h.usage.expenseSaved();
    await h.usage.widgetOpened('chat');
    await h.settle();
    expect(h.saved, isEmpty);
    expect(h.calls, isEmpty);
    expect(h.usage.enabled, false);
  });
  test('session denominator and widget numerator share session; resume within 30min does not duplicate', () async {
    final h = Harness();
    addTearDown(h.usage.dispose);
    await h.usage.enable('a' * 32, hasBudget: true);
    await h.settle();
    h.usage.pause();
    h.time = h.time.add(const Duration(minutes: 5));
    await h.usage.active();
    await h.usage.widgetOpened('chat');
    await h.settle();
    final sessions = h.events
        .where((e) => e['type'] == 'session_start')
        .toList();
    expect(sessions.length, 1);
    expect(
      h.events.firstWhere((e) => e['type'] == 'widget_open')['session'],
      sessions.single['session'],
    );
    h.usage.pause();
    h.time = h.time.add(const Duration(minutes: 31));
    await h.usage.active();
    await h.settle();
    expect(h.events.where((e) => e['type'] == 'session_start').length, 2);
    expect(h.events.where((e) => e['type'] == 'app_active').length, 1);
  });
  test('offline retries keep event IDs; withdrawal clears queue and persists remote deletion only', () async {
    final h = Harness();
    await h.usage.enable('a' * 32, hasBudget: true);
    await h.settle();
    h.offline = true;
    await h.usage.expenseSaved();
    await h.settle();
    final queued = (h.saved['queue'] as List).single['id'];
    await h.usage.flush();
    expect((h.saved['queue'] as List).single['id'], queued);
    await h.usage.withdraw();
    expect(h.usage.enabled, false);
    expect(h.usage.queued, 0);
    expect(h.usage.deletePending, true);
    h.usage.dispose();
    h.offline = false;
    h.calls.clear();
    h.restart();
    addTearDown(h.usage.dispose);
    await h.usage.active();
    await h.settle();
    expect(h.calls.map((c) => c.path).toSet(), {'/telemetry/delete'});
    expect(h.usage.deletePending, false);
    expect(h.saved.containsKey('deviceSecret'), false);
  });
  test(
    'QA activity is excluded; Korean date rollover emits a new active day',
    () async {
      final h = Harness();
      addTearDown(h.usage.dispose);
      await h.usage.enable('a' * 32, hasBudget: true);
      await h.settle();
      h.calls.clear();
      h.qa = true;
      await h.usage.active();
      await h.usage.expenseSaved();
      await h.usage.widgetOpened('expense');
      await h.settle();
      expect(h.calls, isEmpty);
      h.qa = false;
      h.time = DateTime.utc(2026, 11, 18, 15);
      await h.usage.active();
      await h.settle();
      expect(usageDay(h.time), '2026-11-19');
      expect(h.events.where((e) => e['type'] == 'app_active').length, 1);
      expect(
        h.events.every(
          (e) => e.keys.toSet().difference({
            'id',
            'type',
            'at',
            'session',
            'source',
            'version',
          }).isEmpty,
        ),
        true,
      );
    },
  );
}
