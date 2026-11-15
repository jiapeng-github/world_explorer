import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_explorer/features/reader/norway_diagrams.dart';

void main() {
  testWidgets(
    'Norway eight diagrams fit large text and season controls reset',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      Future<void> open(String kind) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: NorwayDiagram('norway-$kind')),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: kind);
      }

      for (final kind in [
        'fjord',
        'climate',
        'transfer',
        'lunch',
        'cod',
        'aurora',
        'sea-ice',
        'daylight',
      ]) {
        await open(kind);
      }
      final winter = find.widgetWithText(ChoiceChip, '冬季示意');
      await tester.ensureVisible(winter);
      await tester.tap(winter);
      await tester.pump();
      expect(tester.widget<ChoiceChip>(winter).selected, isTrue);
      await open('fjord');
      await open('daylight');
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '夏季示意'))
            .selected,
        isTrue,
      );
    },
  );
}
