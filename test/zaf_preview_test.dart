import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_explorer/app/atlas_app.dart';
import 'package:world_explorer/app/services.dart';
import 'package:world_explorer/data/database/atlas_database.dart';
import 'package:world_explorer/map_engine/atlas_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final (family, path) in [
      ('NotoSansSC', 'assets/images/NotoSansSC.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(path))).load();
    }
    await AtlasGeometry.load();
  });

  void viewport(WidgetTester tester, Size size, {double scale = 1}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 75)),
    );
    await tester.pumpAndSettle();
  }

  Future<AtlasServices> createServices(WidgetTester tester) async {
    final services = (await tester.runAsync(
      () => AtlasServices.load(
        database: AtlasDatabase(NativeDatabase.memory()),
        migrate: false,
      ),
    ))!;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(services.dispose);
    });
    return services;
  }

  Future<void> open(
    WidgetTester tester,
    AtlasServices services,
    String route, {
    GlobalKey? boundary,
  }) async {
    final app = WorldAtlasApp(
      key: ValueKey(route),
      services: services,
      initialLocation: route,
    );
    await tester.pumpWidget(app);
    await settle(tester);
  }

  testWidgets('South Africa preview routes fit phone and large text', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844), scale: 1.3);
    final services = await createServices(tester);
    for (final p in [
      'home',
      'contents',
      'penguins',
      'cape',
      'daily',
      'facts',
      'map',
      'note',
    ]) {
      await open(tester, services, '/preview/zaf?page=$p');
      expect(tester.takeException(), isNull, reason: p);
    }
  });
  testWidgets('South Africa note saves and draft restores', (tester) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    await open(tester, services, '/preview/zaf?page=note');
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '保存我的发现'))
          .onPressed,
      isNull,
    );
    final input = find.byType(TextField).first;
    await tester.ensureVisible(input);
    await tester.enterText(input, '海边有企鹅。');
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '保存我的发现'));
    await settle(tester);
    expect(services.journal.notes.single['text'], contains('海边有企鹅。'));
    await open(tester, services, '/preview/zaf?page=home');
    await open(tester, services, '/preview/zaf?page=note');
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '海边有企鹅。',
    );
  });
  testWidgets('South Africa reading answer persists and home capture', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    await open(tester, services, '/preview/zaf?page=penguins');
    final choice = find.widgetWithText(ChoiceChip, '海里');
    await tester.ensureVisible(choice);
    await settle(tester);
    await tester.tap(choice);
    await settle(tester);
    final confirm = find.widgetWithText(FilledButton, '确认');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await settle(tester);
    expect(
      services.preferences.values['zaf-preview-answer-penguins']['correct'],
      true,
    );
    if (const bool.fromEnvironment('CAPTURE_ZAF')) {
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: WorldAtlasApp(
            services: services,
            initialLocation: '/preview/zaf',
          ),
        ),
      );
      await settle(tester);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final f = File('docs/countries/zaf/implemented/home.png');
        await f.parent.create(recursive: true);
        await f.writeAsBytes(bytes!.buffer.asUint8List());
      });
    }
  });
}
