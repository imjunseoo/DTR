import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dtr/data/usage_analytics.dart';
import 'package:dtr/ui/state.dart';
import 'package:dtr/ui/usage_settings.dart';

void main() {
  testWidgets('small screen starts opted out and consent remains explicit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var requests = 0;
    final usage = UsageAnalytics(
      endpoint: 'https://example.test',
      isQa: () => false,
      load: () async => {},
      save: (_) async {},
      transport: (_, _, _) async {
        requests++;
        return 200;
      },
    );
    addTearDown(usage.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [usageProvider.overrideWithValue(usage)],
        child: const MaterialApp(home: UsageSettings()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('수집하지 않음'), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(CheckboxListTile), 300, scrollable: find.byType(Scrollable).first);
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      false,
    );
    await tester.scrollUntilVisible(find.byType(FilledButton), 150, scrollable: find.byType(Scrollable).first);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(requests, 0);
    expect(tester.takeException(), isNull);
  });
}
