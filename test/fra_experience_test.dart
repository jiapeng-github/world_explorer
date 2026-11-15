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
import 'package:world_explorer/map_engine/fra_learning_map.dart';
import 'package:world_explorer/map_engine/fra_map_data.dart';

const _mapRoute =
    '/atlas?country=fra&region=metropole&layer=water&place=fra-seine-paris';
const _routes = {
  'fr01-overview': '/countries/fra',
  'fr02-contents': '/countries/fra/contents',
  'fr04-map-phone': _mapRoute,
  'fr05-columns': '/articles/fra-bay-tides',
  'fr06-causeway': '/places/fra-mont-saint-michel',
  'fr07-timeline': '/countries/fra/timeline',
  'fr08-bilingual': '/articles/fra-light-painting',
  'fr09-daily': '/countries/fra/sections/daily',
  'fr10-puffin': '/articles/fra-moving-glacier',
  'fr11-explore': '/countries/fra/explore',
  'fr12-discoveries': '/me/countries/fra',
  'fr13-journey': '/countries/fra/journeys/changing-land',
  'fr14-observation':
      '/countries/fra/observe/place/fra-mont-saint-michel?media=fra-m07',
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
    await FraMapData.load();
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
    if (!const bool.fromEnvironment('CAPTURE_FRA')) return;
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('docs/countries/fra/implemented/$fileName.png');
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
      'FRA routes fit ${size.width.toInt()} × ${size.height.toInt()} at ${scale}x',
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
              size.width == 1194 ? 'fr03-map-tablet' : route.key,
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

  test('France geometry separates Europe, Corsica and overseas with correct projection', () async {
    final data = await FraMapData.load();
    expect(data.regions.length, 6);
    for (final (region, lat, lon, id) in [
      (FraRegion.metropole, 48.86, 2.35, 'metropole'),
      (FraRegion.metropole, 42.3, 9.15, 'corsica'),
      (FraRegion.reunion, -21.1, 55.5, 'reunion'),
      (FraRegion.guiana, 4.0, -53.2, 'guiana'),
      (FraRegion.martinique, 14.65, -61.0, 'martinique'),
      (FraRegion.mayotte, -12.8, 45.15, 'mayotte'),
    ]) {
      expect(
        data.regions[region]!.hitLayer(
          region.project(lat, lon),
          layer: 'terrain',
          kmPerPixel: .1,
        ),
        'fra-part-$id',
      );
    }
    final paris = FraRegion.metropole.project(48.8566, 2.3522);
    expect(paris.dx, closeTo(652.469, .1));
    expect(paris.dy, closeTo(-6862.035, .1));
    expect(data.all.bounds.width, lessThan(1600));
    expect(fraRegionFor('fra-fournaise'), FraRegion.reunion);
  });
  testWidgets('France all exercises render at phone size', (tester) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    for (final e in services.content.exercises.where(
      (e) => e.countryId == 'fra',
    )) {
      await open(tester, services, '/exercises/${e.id}');
      expect(tester.takeException(), isNull, reason: e.id);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -350));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: e.id);
    }
  });
  testWidgets(
    'France overseas navigation keeps map and place in matching region',
    (tester) async {
      viewport(tester, const Size(1194, 834));
      final services = await createServices(tester);
      await open(
        tester,
        services,
        '/atlas?country=fra&region=reunion&place=fra-fournaise',
      );
      expect(
        tester.widget<FraLearningMap>(find.byType(FraLearningMap)).region,
        FraRegion.reunion,
      );
      expect(find.text('留尼汪 · 富尔奈斯火山'), findsOneWidget);
      final boundary = GlobalKey();
      await open(
        tester,
        services,
        '/atlas?country=fra&region=reunion&place=fra-fournaise',
        boundary: boundary,
      );
      await capture(tester, boundary, 'fr04-reunion-tablet');
      await open(tester, services, '/atlas?country=fra&region=unknown');
      expect(find.text('请选择地图范围'), findsOneWidget);
    },
  );
  testWidgets('France tide inline answer and note persist', (tester) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    await open(tester, services, '/articles/fra-bay-tides');
    final answer = find.widgetWithText(ChoiceChip, '同一地点、可比视角的不同潮位');
    await tester.ensureVisible(answer);
    await settle(tester);
    await tester.tap(answer);
    await settle(tester);
    final confirm = find.widgetWithText(FilledButton, '确认');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await settle(tester);
    expect(services.journal.attempts['fra-p01']?['answer_id'], 'option-1');
    await open(
      tester,
      services,
      '/countries/fra/observe/place/fra-mont-saint-michel?media=fra-m07',
    );
    final field = find.byType(TextField).first;
    await tester.ensureVisible(field);
    await tester.enterText(field, '建筑在岩石高处。');
    await settle(tester);
    final save = find.widgetWithText(FilledButton, '保存我的发现');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await settle(tester);
    expect(services.journal.notes.single['text'], contains('建筑在岩石高处。'));
  });
}
