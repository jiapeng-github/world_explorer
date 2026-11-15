import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_explorer/app/atlas_app.dart';
import 'package:world_explorer/app/services.dart';
import 'package:world_explorer/data/database/atlas_database.dart';
import 'package:world_explorer/map_engine/atlas_map.dart';
import 'package:world_explorer/map_engine/country_learning_map.dart';

const _mapRoute =
    '/atlas?country=japan&region=all&layer=water&place=japan-tokyo';
const _routes = {
  'jp01-overview': '/countries/japan',
  'jp02-contents': '/countries/japan/contents',
  'jp04-map-phone': _mapRoute,
  'jp05-volcano': '/articles/japan-volcano',
  'jp06-fuji': '/places/japan-fuji',
  'jp07-timeline': '/countries/japan/timeline',
  'jp08-ainu': '/articles/japan-ainu',
  'jp09-daily': '/countries/japan/sections/daily',
  'jp10-forest': '/articles/japan-forest',
  'jp11-explore': '/countries/japan/explore',
  'jp12-discoveries': '/me/countries/japan',
  'jp13-journey': '/countries/japan/journeys/islands',
  'jp15-southwest': '/atlas?country=japan&place=japan-naha',
  'jp16-ogasawara': '/atlas?country=japan&feature=japan-chichijima',
  'jp14-observation':
      '/countries/japan/observe/place/japan-fuji?media=mount-fuji',
};

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
    await CountryMapData.load(japanMapProfile);
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
    await tester.pumpWidget(
      boundary == null ? app : RepaintBoundary(key: boundary, child: app),
    );
    await settle(tester);
  }

  Future<void> capture(
    WidgetTester tester,
    GlobalKey boundary,
    String fileName,
  ) async {
    if (!const bool.fromEnvironment('CAPTURE_JAPAN')) return;
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('docs/countries/japan/implemented/$fileName.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  for (final (size, scale) in [
    (const Size(390, 844), 1.0),
    (const Size(1194, 834), 1.0),
    (const Size(320, 568), 1.5),
  ]) {
    testWidgets(
      'JAPAN routes fit ${size.width.toInt()} × ${size.height.toInt()} at ${scale}x',
      (tester) async {
        viewport(tester, size, scale: scale);
        final services = await createServices(tester);
        for (final route in _routes.entries) {
          if (size.width == 1194 && route.value != _mapRoute) continue;
          final boundary = GlobalKey();
          await open(tester, services, route.value, boundary: boundary);
          expect(tester.takeException(), isNull, reason: route.key);
          if (size.width != 320) {
            await capture(
              tester,
              boundary,
              size.width == 1194 ? 'jp03-map-tablet' : route.key,
            );
          }
          if (!route.value.startsWith('/atlas')) {
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -450),
            );
            await settle(tester);
            expect(
              tester.takeException(),
              isNull,
              reason: '${route.key} after scrolling',
            );
          }
        }
      },
    );
  }

  testWidgets('Japan all exercises render and references are complete', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    final questions = services.content.exercises
        .where((e) => e.countryId == 'japan')
        .toList();
    expect(questions.length, 24);
    for (final e in questions) {
      await open(tester, services, '/exercises/${e.id}');
      expect(tester.takeException(), isNull, reason: e.id);
    }
  });
  testWidgets(
    'Japan answer feedback and observation survive repository reload',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final services = await createServices(tester);
      await open(tester, services, '/exercises/japan-volcano-check');
      final option = find.widgetWithText(RadioListTile<String>, '机构观测与公告');
      await tester.ensureVisible(option);
      await tester.tap(option);
      await settle(tester);
      final confirm = find.widgetWithText(FilledButton, '看看我的想法');
      await tester.tap(confirm);
      await settle(tester);
      expect(
        services.journal.attempts['japan-volcano-check']?['answer_id'],
        'a',
      );
      expect(services.journal.attempts['japan-volcano-check']?['correct'], 1);
      await open(
        tester,
        services,
        '/countries/japan/observe/place/japan-fuji?media=mount-fuji',
      );
      final field = find.byType(TextField).first;
      await tester.ensureVisible(field);
      await tester.enterText(field, '湖面映出了山的轮廓。');
      await settle(tester);
      final save = find.widgetWithText(FilledButton, '保存我的发现');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await settle(tester);
      await tester.runAsync(services.journal.load);
      expect(services.journal.notes.single['text'], contains('湖面映出了山的轮廓。'));
      expect(services.journal.notes.single['entity_id'], 'japan-fuji');
    },
  );

  testWidgets('Japan regional switches retain navigation without overflow', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    await open(tester, services, '/atlas?country=japan&place=japan-naha');
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '西南岛屿'))
          .selected,
      isTrue,
    );
    for (final title in ['主要列岛', '小笠原', '西南岛屿']) {
      await tester.tap(find.widgetWithText(ChoiceChip, title));
      await settle(tester);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, title))
            .selected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'Every Japan article and place opens with valid media and controls',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final services = await createServices(tester);
      for (final article in services.content.articlesIn('japan')) {
        await open(tester, services, '/articles/${article.id}');
        expect(tester.takeException(), isNull, reason: article.id);
      }
      for (final place in services.content.placesIn('japan')) {
        await open(tester, services, '/places/${place.id}');
        expect(tester.takeException(), isNull, reason: place.id);
      }
    },
  );
}
