import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_explorer/features/reader/deu_diagrams.dart';

void main() {
  testWidgets('Germany diagrams fit small screens and reset active controls', (
    tester,
  ) async {
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
            body: SingleChildScrollView(child: DeuDiagram('deu-$kind')),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: kind);
    }

    for (final kind in [
      'river',
      'landscapes',
      'transfer',
      'food-flow',
      'deadwood',
    ]) {
      await open(kind);
    }
    await open('type');
    final rearrange = find.widgetWithText(ChoiceChip, '重新排列');
    await tester.ensureVisible(rearrange);
    await tester.tap(rearrange);
    await tester.pump();
    expect(tester.widget<ChoiceChip>(rearrange).selected, isTrue);
    await open('tides');
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '低潮')).selected,
      isTrue,
    );
    final high = find.widgetWithText(ChoiceChip, '高潮');
    await tester.ensureVisible(high);
    await tester.tap(high);
    await tester.pump();
    expect(tester.widget<ChoiceChip>(high).selected, isTrue);
    await open('rhythm');
    final play = find.text('播放四拍');
    await tester.ensureVisible(play);
    await tester.tap(play);
    await tester.pump(const Duration(milliseconds: 650));
    await open('river');
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
    await open('rhythm');
    await tester.ensureVisible(find.text('播放四拍'));
    await tester.tap(find.text('播放四拍'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
  });
}
