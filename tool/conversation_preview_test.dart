// Isolated Flutter render, not an Android launcher screenshot.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dtr/main.dart';
import 'package:dtr/data/database.dart';
import 'package:dtr/domain/budget.dart';
import 'package:dtr/ui/state.dart';
import 'package:dtr/platform/android_bridge.dart';

void main() {
  testWidgets('Render conversation and purchase preview', (tester) async {
    final font = FontLoader('NotoSansKR')
      ..addFont(rootBundle.load('assets/fonts/NotoSansKR.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      AndroidBridge.channel,
      (_) async => null,
    );
    final now = DateTime.now();
    final db = AppDatabase(NativeDatabase.memory());
    await db.startCycle(
      BudgetPlan(
        amount: 300000,
        savings: 0,
        start: now,
        payday: now.add(const Duration(days: 30)),
      ),
      now,
    );
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const DontoriApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('대화'));
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final path = Platform.environment['DTR_PREVIEW_DIR'] ?? 'work';
        Directory(path).createSync(recursive: true);
        File('$path/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('conversation');
    await tester.tap(find.text('이거 사도 될까?'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '구매 예정 금액'),
      '15000',
    );
    await tester.tap(find.text('예산 확인'));
    await tester.pumpAndSettle();
    await capture('conversation-purchase');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await db.close();
  });
}
