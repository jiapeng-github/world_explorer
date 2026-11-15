import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_explorer/features/reader/learning_diagrams.dart';

void main() {
  testWidgets(
    'Australia coral explanation switches and resets between topics',
    (tester) async {
      Future<void> open(String kind) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: LearningDiagram(kind)),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await open('aus-coral');
      expect(find.textContaining('珊瑚虫是动物'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, '3 珊瑚礁'));
      await tester.pumpAndSettle();
      expect(find.textContaining('不是一只珊瑚虫瞬间'), findsOneWidget);
      await open('aus-seasons');
      expect(find.textContaining('地球自转轴'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Noninteractive diagram exposes all explanations', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LearningDiagram('aus-coast-erosion', interactive: false),
          ),
        ),
      ),
    );
    expect(find.textContaining('单张照片不能计算'), findsOneWidget);
    for (final chip in tester.widgetList<ChoiceChip>(find.byType(ChoiceChip))) {
      expect(chip.onSelected, isNull);
    }
  });
}
