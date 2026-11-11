import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dtr/main.dart';
import 'package:dtr/ui/state.dart';
import 'package:dtr/data/database.dart';

void main() {
  testWidgets('예산 설정 → 지출 저장 → HP 갱신', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const DontoriApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '현재 관리 금액'),
      '300000',
    );
    await tester.scrollUntilVisible(
      find.text('내 예산 시작하기'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('내 예산 시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('10,000원'), findsNWidgets(2));
    await tester.tap(find.text('지출 입력'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '사용한 금액'),
      '4000',
    );
    await tester.scrollUntilVisible(
      find.text('저장하기'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();
    expect(find.text('6,000원'), findsOneWidget);
    expect(find.textContaining('HP 60%'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
