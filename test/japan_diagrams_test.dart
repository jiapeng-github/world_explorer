import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_explorer/features/reader/japan_diagrams.dart';

void main() {
  testWidgets(
    'All eight Japan diagrams change explanatory state and fit large text',
    (tester) async {
      await (FontLoader(
        'NotoSansSC',
      )..addFont(rootBundle.load('assets/images/NotoSansSC.ttf'))).load();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final kind in [
        'volcano',
        'transfer',
        'rice',
        'miso',
        'woodblock',
        'forest',
        'scale',
        'river',
      ]) {
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'NotoSansSC'),
            home: RepaintBoundary(
              key: key,
              child: Scaffold(
                body: SafeArea(
                  child: SingleChildScrollView(
                    child: JapanDiagram('japan-$kind', key: ValueKey(kind)),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final chips = find.byType(ChoiceChip);
        expect(chips, findsNWidgets(3));
        await tester.tap(chips.at(2));
        await tester.pumpAndSettle();
        expect(tester.widget<ChoiceChip>(chips.at(2)).selected, isTrue);
        expect(tester.widget<ChoiceChip>(chips.first).selected, isFalse);
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('CAPTURE_JAPAN')) {
          await tester.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            image.dispose();
            final file = File(
              'docs/countries/japan/implemented/diagram-$kind.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
          });
        }
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      }
    },
  );
}
