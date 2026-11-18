import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dtr/main.dart';
import 'package:dtr/data/database.dart';
import 'package:dtr/domain/budget.dart';
import 'package:dtr/platform/android_bridge.dart';
import 'package:dtr/ui/state.dart';

void main() {
  Future<AppDatabase> boot(WidgetTester tester, {String? action}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AndroidBridge.channel, (call) async {
          if (call.method == 'consumeWidgetAction') {
            final value = action;
            action = null;
            return value;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AndroidBridge.channel, null),
    );
    final db = AppDatabase(NativeDatabase.memory());
    final now = DateTime.now();
    await db.startCycle(
      BudgetPlan(
        amount: 300000,
        savings: 0,
        start: now,
        payday: now.add(const Duration(days: 30)),
      ),
      now,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const DontoriApp(),
      ),
    );
    await tester.pumpAndSettle();
    return db;
  }

  testWidgets('대화 탭 구매 예상은 기록을 쓰지 않고 탭 전환 후 대화를 유지', (tester) async {
    final db = await boot(tester);
    await tester.tap(find.text('대화'));
    await tester.pumpAndSettle();
    expect(find.text('돈토리와 대화'), findsOneWidget);
    await tester.tap(find.text('이거 사도 될까?'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '구매 예정 금액'),
      '15000',
    );
    await tester.tap(find.text('예산 확인'));
    await tester.pumpAndSettle();
    expect(find.textContaining('구매 후 오늘 남은 예산은 -5,000원'), findsOneWidget);
    expect((await db.load(DateTime.now()))!.expenses, isEmpty);
    await tester.tap(find.text('오늘'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대화'));
    await tester.pumpAndSettle();
    expect(find.textContaining('구매 후 오늘 남은 예산은 -5,000원'), findsOneWidget);
    await tester.tap(find.text('간편 지출 입력'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '사용한 금액'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await db.close();
  });

  testWidgets('위젯 캐릭터 콜드 시작과 실행 중 대화 진입', (tester) async {
    final db = await boot(tester, action: 'chat');
    expect(find.text('돈토리와 대화'), findsOneWidget);
    await tester.tap(find.text('오늘'));
    await tester.pumpAndSettle();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          AndroidBridge.channel,
          (call) async => call.method == 'consumeWidgetAction' ? 'chat' : null,
        );
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          AndroidBridge.channel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('widgetAction'),
          ),
          (_) {},
        );
    await tester.pumpAndSettle();
    expect(find.text('돈토리와 대화'), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(320, 800);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('위젯 지출 입력 경로 유지', (tester) async {
    final db = await boot(tester, action: 'expense');
    expect(find.widgetWithText(TextFormField, '사용한 금액'), findsOneWidget);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          AndroidBridge.channel,
          (call) async => call.method == 'consumeWidgetAction' ? 'chat' : null,
        );
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          AndroidBridge.channel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('widgetAction'),
          ),
          (_) {},
        );
    await tester.pumpAndSettle();
    expect(find.text('돈토리와 대화'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '사용한 금액'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('작은 화면과 키보드에서도 대화 입력 가능', (tester) async {
    final db = await boot(tester, action: 'chat');
    tester.view.physicalSize = const Size(320, 640);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '예산 알려줘');
    await tester.tap(find.byTooltip('보내기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('기록 기준 오늘 남은 예산은 10,000원'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
