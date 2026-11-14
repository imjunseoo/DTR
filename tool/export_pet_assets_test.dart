// Rasterize the original Figma SVGs for Android RemoteViews (no SVG support).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dtr/ui/design.dart';

void main() {
  testWidgets('Export exact Figma pet assets for Android', (tester) async {
    tester.view.physicalSize = const Size(48, 48);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final stage in [
      'seed',
      'sprout',
      'bloom',
      'bloom-inhale',
      'bloom-record',
      'bloom-save',
      'bloom-rest',
    ]) {
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: DtrDesign.asset(stage, 48),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 4);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'android/app/src/main/res/drawable-nodpi/dori_${stage.replaceAll('-', '_')}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
