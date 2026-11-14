// Render the existing app with isolated sample data. Not a device screenshot.
// Run explicitly: ./flutter.ps1 test tool/preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dtr/data/database.dart';
import 'package:dtr/domain/budget.dart';
import 'package:dtr/main.dart';
import 'package:dtr/platform/android_bridge.dart';
import 'package:dtr/ui/state.dart';
import 'package:dtr/ui/design.dart';
import 'package:dtr/ui/backup_screen.dart';
import 'package:dtr/ui/budget_change_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('NotoSansKR');
    font.addFont(rootBundle.load('assets/fonts/NotoSansKR.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  for (final seeded in [false, true]) {
    testWidgets(
      seeded ? 'Render sample budget and entry' : 'Render first setup',
      (tester) async {
        debugDisableShadows = false;
        addTearDown(() => debugDisableShadows = true);
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          AndroidBridge.channel,
          (call) async => call.method == 'consumeQuickEntry' ? false : null,
        );
        final db = AppDatabase(NativeDatabase.memory());
        final now = DateTime.now();
        if (seeded) {
          await db.startCycle(
            BudgetPlan(
              amount: 400000,
              savings: 50000,
              start: now,
              payday: day(now).add(const Duration(days: 15)),
              fixedCosts: [FixedCost(id: 'phone', name: '통신비', amount: 50000)],
            ),
            now,
          );
          /*await db.saveExpense(
            Expense(
              id: 'sample-lunch',
              amount: 8000,
              date: now,
              category: '식사',
              memo: '점심 식사',
            ),
            now,
          );*/
        }
        var previewPet = const PetStatus(20, 0);
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: ProviderScope(
              overrides: [
                databaseProvider.overrideWithValue(db),
                petPointsProvider.overrideWith((ref) async => previewPet),
              ],
              child: const DontoriApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Future<void> capture(String filename) async {
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final output = File('dist/preview/$filename.png');
            await output.parent.create(recursive: true);
            await output.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        await capture(seeded ? '02-home' : '01-setup');
        if (seeded) {
          final previewContainer = ProviderScope.containerOf(
            tester.element(find.byType(DtrNavigation)),
          );
          await db.saveExpense(
            Expense(
              id: 'sample-lunch',
              amount: 8000,
              date: now,
              category: '식사',
              memo: '점심 식사',
            ),
            now,
          );
          previewContainer.invalidate(ledgerProvider);
          await tester.pumpAndSettle();
          await tester.tap(find.text('지출 입력'));
          await tester.pumpAndSettle();
          await capture('03-expense');
          await tester.tap(find.text('‹'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('내역'));
          await tester.pumpAndSettle();
          await capture('04-history');
          await tester.tap(find.text('8,000원'));
          await tester.pumpAndSettle();
          await capture('08-expense-edit');
          await tester.tap(find.text('‹'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('성장'));
          await tester.pumpAndSettle();
          await capture('05-growth');
          final container = ProviderScope.containerOf(
            tester.element(find.byType(DtrNavigation)),
          );
          for (final upgrade in [1, 4]) {
            previewPet = PetStatus(20, upgrade);
            container.invalidate(petPointsProvider);
            await tester.pumpAndSettle();
            await capture('growth-lv${upgrade + 1}');
          }

          for (final size in [const Size(360, 800), const Size(320, 640)]) {
            tester.view.physicalSize = size;
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await capture('growth-${size.width.toInt()}');
          }
          tester.view.physicalSize = const Size(430, 932);
          await tester.tap(find.text('오늘'));
          await tester.pumpAndSettle();
          final navigator = tester.state<NavigatorState>(
            find.byType(Navigator).first,
          );
          navigator.push(
            MaterialPageRoute<void>(builder: (_) => const BackupScreen()),
          );
          await tester.pumpAndSettle();
          await capture('06-backup');
          await tester.tap(find.text('‹'));
          await tester.pumpAndSettle();
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => const BudgetChangeScreen(savings: 50000),
            ),
          );
          await tester.pumpAndSettle();
          await capture('07-budget-change');
          await tester.tap(find.text('‹'));
          await tester.pumpAndSettle();
          for (final width in [320.0, 360.0, 430.0]) {
            tester.view.physicalSize = Size(width, 800);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        }
        await tester.pumpWidget(const SizedBox());
        await db.close();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          AndroidBridge.channel,
          null,
        );
        debugDisableShadows = true;
      },
    );
  }
}
