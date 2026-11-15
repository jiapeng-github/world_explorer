import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_explorer/app/atlas_app.dart';
import 'package:world_explorer/app/services.dart';
import 'package:world_explorer/data/database/atlas_database.dart';
import 'package:world_explorer/design/components.dart';
import 'package:world_explorer/map_engine/atlas_map.dart';
import 'package:world_explorer/map_engine/usa_learning_map.dart';
import 'package:world_explorer/map_engine/usa_map_data.dart';

const _mapRoute =
    '/atlas?country=usa&region=conus&layer=water&place=usa-grand-canyon';
const _routes = {
  'us01-overview': '/countries/usa',
  'us02-contents': '/countries/usa/contents',
  'us04-map-phone': _mapRoute,
  'us05-canyon-reader': '/articles/usa-grand-canyon-geology',
  'us06-canyon-place': '/places/usa-grand-canyon',
  'us07-timeline': '/countries/usa/timeline',
  'us08-jazz': '/articles/usa-new-orleans-jazz',
  'us09-daily': '/countries/usa/sections/daily',
  'us10-yellowstone': '/articles/usa-yellowstone-geyser',
  'us11-explore': '/countries/usa/explore',
  'us12-discoveries': '/me/countries/usa',
  'us13-journey': '/countries/usa/journeys/landforms',
  'us14-observation':
      '/countries/usa/observe/place/usa-grand-canyon?media=usa-m02',
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
    await UsaMapData.load();
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
    if (!const bool.fromEnvironment('CAPTURE_USA')) return;
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('docs/countries/usa/implemented/$fileName.png');
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
      'USA routes fit ${size.width.toInt()} × ${size.height.toInt()} at ${scale}x',
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
              size.width == 1194 ? 'us03-map-tablet' : route.key,
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

  test('state, river and lake hits use projected geometry and Alaska wraps the date line', () async {
    final data = await UsaMapData.load();
    final conus = data.regions[UsaRegion.conus]!;
    expect(conus.relief?.width, 1450);
    expect(conus.features.where((f) => f.kind == 'state').length, 48);
    expect(
      conus.features.where((f) => f.kind == 'district').single.id,
      'usa-district-11',
    );
    expect(
      conus.hit(
        UsaRegion.conus.project(34.5, -111.7),
        water: false,
        kmPerPixel: 1,
      ),
      'usa-state-04',
    );
    expect(
      conus.hit(UsaRegion.conus.project(47.5, -87), water: true, kmPerPixel: 1),
      'usa-feature-lake-superior',
    );
    final river = conus.feature('usa-feature-colorado-river')!;
    expect(
      river.waterway!.distanceTo(UsaRegion.conus.project(36.0326, -111.8516)),
      lessThan(16),
    );
    expect(conus.hit(river.anchor, water: true, kmPerPixel: 1), river.id);
    expect(
      conus.boundsFor(usaGreatLakes)!.contains(conus.lakes.first.anchor),
      isTrue,
    );
    final east = UsaRegion.ak.project(52, 179.5);
    final west = UsaRegion.ak.project(52, -179.5);
    expect((east - west).distance, lessThan(85));
    final alaska = data.regions[UsaRegion.ak]!;
    expect(alaska.feature('usa-state-02')!.bounds.width, lessThan(3900));
    expect(UsaRegion.conus.project(23, -96).distance, lessThan(.001));
  });

  testWidgets(
    'world preview opens USA, canyon route saves the inline exercise and follows the map',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final services = await createServices(tester);
      await open(tester, services, '/atlas?country=usa');
      // Explicit country links intentionally enter the regional atlas; the
      // world selection keeps the world map open until Explore is tapped.
      expect(find.byType(UsaLearningMap), findsOneWidget);
      await tester.tap(find.byTooltip('返回世界地图'));
      await settle(tester);
      expect(find.byType(AtlasMap), findsOneWidget);

      await open(tester, services, '/countries/usa');
      await tester.tap(find.text('从大峡谷开始'));
      await settle(tester);
      expect(find.text('沿着山河走'), findsOneWidget);
      await tester.tap(find.text('从第一站开始'));
      await settle(tester);
      final confirm = find.widgetWithText(FilledButton, '确认');
      await tester.ensureVisible(confirm);
      await settle(tester);
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      final valley = find.widgetWithText(ChoiceChip, '峡谷底部');
      await tester.ensureVisible(valley);
      await tester.tap(valley);
      await settle(tester);
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await settle(tester);
      expect(
        services.journal.attempts['usa-canyon-find-channel']?['answer_id'],
        'valley',
      );
      final mapAction = find.widgetWithText(TextButton, '在地图上看看');
      await tester.ensureVisible(mapAction);
      await tester.tap(mapAction);
      await settle(tester);
      final map = tester.widget<UsaLearningMap>(find.byType(UsaLearningMap));
      expect(
        (map.region, map.layer, map.selection),
        (UsaRegion.conus, 'water', 'usa-grand-canyon'),
      );
    },
  );

  testWidgets(
    'atlas keeps regional layer and selection and distinguishes Washington names',
    (tester) async {
      viewport(tester, const Size(1194, 834));
      final services = await createServices(tester);
      final mapFinder = find.byType(UsaLearningMap);
      UsaLearningMap map() => tester.widget<UsaLearningMap>(mapFinder);
      await open(tester, services, _mapRoute);
      await tester.tap(find.text('阿拉斯加'));
      await settle(tester);
      expect((map().region, map().layer), (UsaRegion.ak, 'terrain'));
      await tester.tap(find.text('返回全美概览'));
      await settle(tester);
      expect(
        (map().region, map().layer, map().selection),
        (UsaRegion.conus, 'water', 'usa-grand-canyon'),
      );
      await tester.tap(find.text('找州、河流或地点'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Washington');
      await settle(tester);
      expect(find.text('州 · 美国西北部'), findsOneWidget);
      expect(find.text('联邦特区 · 美国东部'), findsOneWidget);
      await tester.tap(find.text('州 · 美国西北部'));
      await settle(tester);
      expect(map().selection, 'usa-state-53');
      await open(
        tester,
        services,
        '/atlas?country=usa&region=ak&place=usa-hawaii-volcanoes',
      );
      expect(
        (map().region, map().selection),
        (UsaRegion.hi, 'usa-hawaii-volcanoes'),
      );
      await open(
        tester,
        services,
        '/atlas?country=usa&region=hi&feature=usa-state-99',
      );
      expect(map().region, UsaRegion.hi);
    },
  );

  testWidgets(
    'USA map quizzes select an Arizona surface and a Hawaii pin across regions',
    (tester) async {
      viewport(tester, const Size(430, 932));
      final services = await createServices(tester);
      final finder = find.byType(UsaLearningMap);
      UsaLearningMap map() => tester.widget<UsaLearningMap>(finder);
      Future<void> tapOnInitialMap(double latitude, double longitude) async {
        final frame = tester.getRect(finder);
        final bounds = map().data.bounds;
        final scale = math.min(
          (frame.width - 36) / bounds.width,
          (frame.height - 56) / bounds.height,
        );
        final pixel =
            frame.center +
            (map().region.project(latitude, longitude) - bounds.center) * scale;
        await tester.tapAt(pixel);
        await settle(tester);
      }

      await open(tester, services, '/exercises/usa-locate-arizona');
      await tapOnInitialMap(34.5, -111.7);
      expect(map().selection, 'usa-state-04');
      await tester.tap(find.text('确认'));
      await settle(tester);
      expect(services.journal.attempts['usa-locate-arizona']?['correct'], 1);

      await open(tester, services, '/exercises/usa-locate-hawaii-volcano');
      await tester.tap(find.widgetWithText(ChoiceChip, '夏威夷'));
      await settle(tester);
      final place = services.content.place('usa-hawaii-volcanoes')!;
      await tapOnInitialMap(place.latitude, place.longitude);
      expect(map().selection, place.id);
      await tester.tap(find.widgetWithText(ChoiceChip, '阿拉斯加'));
      await settle(tester);
      expect((map().region, map().selection), (UsaRegion.ak, place.id));
      await tester.tap(find.text('确认'));
      await settle(tester);
      expect(
        services.journal.attempts['usa-locate-hawaii-volcano']?['correct'],
        1,
      );
    },
  );

  testWidgets(
    'canyon observation keeps the selected source and restores an incomplete draft',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final services = await createServices(tester);
      await open(tester, services, '/places/usa-grand-canyon');
      await tester.tap(find.widgetWithText(ChoiceChip, '细节'));
      await settle(tester);
      await tester.tap(find.text('记下我的发现'));
      await settle(tester);
      expect(
        tester.widget<MediaPhoto>(find.byType(MediaPhoto).first).id,
        'usa-m03',
      );
      final save = find.widgetWithText(FilledButton, '保存我的发现');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      final field = find.byType(TextField).first;
      tester.view.viewInsets = const FakeViewPadding(bottom: 245);
      addTearDown(tester.view.resetViewInsets);
      await tester.ensureVisible(field);
      await tester.enterText(field, '我看到一条深色的岩层。');
      await settle(tester);
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.tap(find.byTooltip('返回'));
      await settle(tester);
      await tester.tap(find.text('记下我的发现'));
      await settle(tester);
      expect(tester.widget<TextField>(field).controller!.text, '我看到一条深色的岩层。');
      await tester.tap(save);
      await settle(tester);
      expect(services.journal.notes.single['entity_id'], 'usa-grand-canyon');
      expect(services.journal.notes.single['text'], '我看见：我看到一条深色的岩层。');
      expect(
        services.preferences.values['observation-draft-usa-grand-canyon'],
        isNull,
      );
      expect(find.text('我的美国发现'), findsOneWidget);
    },
  );
}
