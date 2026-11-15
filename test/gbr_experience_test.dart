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
import 'package:world_explorer/map_engine/gbr_learning_map.dart';
import 'package:world_explorer/map_engine/gbr_map_data.dart';

const _mapRoute =
    '/atlas?country=gbr&region=all&layer=water&place=gbr-thames-london';
const _routes = {
  'gb01-overview': '/countries/gbr',
  'gb02-contents': '/countries/gbr/contents',
  'gb04-map-phone': _mapRoute,
  'gb05-columns': '/articles/gbr-causeway-columns',
  'gb06-causeway': '/places/gbr-giants-causeway',
  'gb07-timeline': '/countries/gbr/timeline',
  'gb08-bilingual': '/articles/gbr-welsh-signs',
  'gb09-daily': '/countries/gbr/sections/daily',
  'gb10-puffin': '/articles/gbr-puffin-coast',
  'gb11-explore': '/countries/gbr/explore',
  'gb12-discoveries': '/me/countries/gbr',
  'gb13-journey': '/countries/gbr/journeys/river-city',
  'gb14-observation':
      '/countries/gbr/observe/place/gbr-giants-causeway?media=gbr-m05',
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
    await GbrMapData.load();
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
    if (!const bool.fromEnvironment('CAPTURE_GBR')) return;
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('docs/countries/gbr/implemented/$fileName.png');
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
      'GBR routes fit ${size.width.toInt()} × ${size.height.toInt()} at ${scale}x',
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
              size.width == 1194 ? 'gb03-map-tablet' : route.key,
            );
          }
          if (route.value != _mapRoute) {
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

  test(
    'UK map separates four parts, independent Ireland and geographic islands',
    () async {
      final data = await GbrMapData.load();
      expect(data.all.features.where((f) => f.kind == 'part').length, 4);
      for (final (lat, lon, id) in [
        (51.5, -.12, 'england'),
        (56.7, -4.9, 'scotland'),
        (52.1, -3.5, 'wales'),
        (54.6, -6.5, 'northern-ireland'),
      ]) {
        expect(
          data.all.hitLayer(
            gbrProject(lat, lon),
            layer: 'terrain',
            kmPerPixel: 1,
          ),
          'gbr-part-$id',
        );
      }
      expect(
        data.all.hitLayer(
          gbrProject(53.3, -7.5),
          layer: 'terrain',
          kmPerPixel: 1,
        ),
        isNull,
      );
      expect(
        data.all.hitLayer(
          gbrProject(53.3, -7.5),
          layer: 'islands',
          kmPerPixel: 1,
        ),
        'gbr-island-ireland',
      );
      expect(
        data.all.hitLayer(
          gbrProject(54.6, -6.5),
          layer: 'islands',
          kmPerPixel: 1,
        ),
        'gbr-island-ireland',
      );
      expect(
        data.all.hitLayer(
          gbrProject(52.1, -3.5),
          layer: 'islands',
          kmPerPixel: 1,
        ),
        'gbr-island-great-britain',
      );
      expect(gbrRegionFor('gbr-cardiff'), GbrRegion.wales);
    },
  );
  testWidgets(
    'puffin inline answer persists and map opens the correct country',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final services = await createServices(tester);
      await open(tester, services, '/articles/gbr-puffin-coast');
      final answer = find.widgetWithText(ChoiceChip, '海里');
      await tester.ensureVisible(answer);
      await settle(tester);
      await tester.tap(answer);
      await settle(tester);
      final confirm = find.widgetWithText(FilledButton, '确认');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await settle(tester);
      expect(services.journal.attempts['gbr-c10']?['answer_id'], 'option-1');
      await open(tester, services, _mapRoute);
      expect(find.byType(GbrLearningMap), findsOneWidget);
      expect(
        tester.widget<GbrLearningMap>(find.byType(GbrLearningMap)).region,
        GbrRegion.all,
      );
      await tester.tap(find.byTooltip('返回世界地图'));
      await settle(tester);
      expect(find.byType(AtlasMap), findsOneWidget);
    },
  );

  testWidgets(
    'UK exercises support map and photographic options without layout errors',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final services = await createServices(tester);
      for (final id in [
        'gbr-l01',
        'gbr-l03',
        'gbr-l06',
        'gbr-p02',
        'gbr-p03',
        'gbr-p04',
        'gbr-p05',
        'gbr-p06',
        'gbr-c04',
      ]) {
        await open(tester, services, '/exercises/$id');
        expect(tester.takeException(), isNull, reason: id);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -360));
        await settle(tester);
        expect(tester.takeException(), isNull, reason: id);
      }
    },
  );
  testWidgets(
    'UK search distinguishes Ireland island and country, and accepts UK alias',
    (tester) async {
      viewport(tester, const Size(1194, 834));
      final services = await createServices(tester);
      await open(tester, services, _mapRoute);
      await tester.tap(find.text('找地区、河流或地点'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), '爱尔兰');
      await settle(tester);
      expect(find.text('爱尔兰岛'), findsOneWidget);
      expect(find.widgetWithText(ListTile, '爱尔兰'), findsOneWidget);
      expect(find.text('北爱尔兰'), findsAtLeastNWidgets(1));
      await tester.enterText(find.byType(TextField), 'UK');
      await settle(tester);
      await tester.tap(find.text('英国'));
      await settle(tester);
      final map = tester.widget<GbrLearningMap>(find.byType(GbrLearningMap));
      expect(map.region, GbrRegion.all);
      expect(map.selection, isNull);
    },
  );
  testWidgets('UK observation saves a child-written note', (tester) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    await open(
      tester,
      services,
      '/countries/gbr/observe/place/gbr-giants-causeway?media=gbr-m05',
    );
    final field = find.byType(TextField).first;
    await tester.ensureVisible(field);
    await tester.enterText(field, '石柱之间有竖直的裂缝。');
    await settle(tester);
    final save = find.widgetWithText(FilledButton, '保存我的发现');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await settle(tester);
    expect(services.journal.notes.single['entity_id'], 'gbr-giants-causeway');
    expect(services.journal.notes.single['text'], contains('石柱之间有竖直的裂缝。'));
  });
}
