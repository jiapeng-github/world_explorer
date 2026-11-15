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
import 'package:world_explorer/map_engine/deu_learning_map.dart';
import 'package:world_explorer/map_engine/deu_map_data.dart';

const _mapRoute = '/atlas?country=deu&region=all&layer=water&place=deu-koblenz';
const _routes = {
  'de01-overview': '/countries/deu',
  'de02-contents': '/countries/deu/contents',
  'de04-map-phone': '/atlas?country=deu&layer=places&place=deu-wadden',
  'de05-river-reader': '/articles/deu-rhine',
  'de06-koblenz': '/places/deu-koblenz',
  'de07-timeline': '/countries/deu/timeline',
  'de08-printing': '/articles/deu-printing',
  'de09-daily': '/countries/deu/sections/daily',
  'de10-deadwood': '/articles/deu-deadwood',
  'de11-explore': '/countries/deu/explore',
  'de12-discoveries': '/me/countries/deu',
  'de13-journey': '/countries/deu/journeys/forest-coast',
  'de14-observation': '/countries/deu/observe/place/deu-wadden?media=deu-m20',
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
    await DeuMapData.load();
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
    await tester.runAsync(() async {
      await Future.wait([
        for (final element in find.byType(Image).evaluate())
          precacheImage((element.widget as Image).image, element),
      ]);
    });
    await tester.pumpAndSettle();
  }

  Future<void> capture(
    WidgetTester tester,
    GlobalKey boundary,
    String fileName,
  ) async {
    if (!const bool.fromEnvironment('CAPTURE_DEU')) return;
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('docs/countries/deu/implemented/$fileName.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  for (final (size, scale) in [
    (const Size(390, 844), 1.0),
    (const Size(430, 932), 1.0),
    (const Size(1194, 834), 1.0),
    (const Size(320, 568), 1.5),
  ]) {
    testWidgets(
      'DEU routes fit ${size.width.toInt()} × ${size.height.toInt()} at ${scale}x',
      (tester) async {
        viewport(tester, size, scale: scale);
        final services = await createServices(tester);
        for (final route in _routes.entries) {
          if (size.width == 1194 && route.key != 'de04-map-phone') continue;
          final boundary = GlobalKey();
          final pageServices = route.key == 'de12-discoveries'
              ? await createServices(tester)
              : services;
          await open(
            tester,
            pageServices,
            size.width == 1194 ? _mapRoute : route.value,
            boundary: boundary,
          );
          expect(tester.takeException(), isNull, reason: route.key);
          if (size.width == 390 || size.width == 1194) {
            await capture(
              tester,
              boundary,
              size.width == 1194 ? 'de03-map-tablet' : route.key,
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

  test('Germany projection, borders and selectable teaching regions', () async {
    final data = await DeuMapData.load();
    final berlin = DeuRegion.all.project(52.52, 13.405);
    expect(berlin.dx, closeTo(4552.03645, .001));
    expect(berlin.dy, closeTo(-3273.26827, .001));
    expect(data.all.feature('deu-part-germany')!.path.contains(berlin), isTrue);
    for (final (lat, lon, id) in [
      (53.55, 10.0, 'north'),
      (51.18, 14.42, 'lusatia'),
      (47.56, 12.98, 'alps'),
    ]) {
      final target = 'deu-terrain-$id';
      expect(
        data.all.hitLayer(
          DeuRegion.all.project(lat, lon),
          layer: 'terrain',
          kmPerPixel: .1,
          allowedIds: {target},
        ),
        target,
      );
    }
    expect(
      data.all
          .feature('deu-feature-moselle')!
          .waterway!
          .distanceTo(DeuRegion.all.project(50.364, 7.607)),
      lessThan(8),
    );
    expect(
      data.all
          .feature('deu-feature-elbe')!
          .waterway!
          .distanceTo(DeuRegion.all.project(53.54, 9.97)),
      lessThan(8),
    );
    expect(
      data.all.feature('deu-feature-rhine')!.waterway!.lines.length,
      greaterThan(0),
    );
  });
  testWidgets('Germany all exercises render at phone size', (tester) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    for (final e in services.content.exercises.where(
      (e) => e.countryId == 'deu',
    )) {
      await open(tester, services, '/exercises/${e.id}');
      expect(tester.takeException(), isNull, reason: e.id);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -350));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: e.id);
    }
  });
  testWidgets('Germany deep link and unknown region fallback', (tester) async {
    viewport(tester, const Size(1194, 834));
    final services = await createServices(tester);
    await open(tester, services, _mapRoute);
    expect(
      tester.widget<DeuLearningMap>(find.byType(DeuLearningMap)).selection,
      'deu-koblenz',
    );
    await open(tester, services, '/atlas?country=deu&region=unknown');
    expect(find.text('请选择地图范围'), findsOneWidget);
  });
  testWidgets(
    'Germany answer and observation persist without inventing progress',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final services = await createServices(tester);
      expect(services.journal.attempts, isEmpty);
      expect(services.journal.notes, isEmpty);
      await open(tester, services, '/articles/deu-rhine');
      final answer = find.widgetWithText(ChoiceChip, '不一定，河流可以跨越国界');
      await tester.ensureVisible(answer);
      await settle(tester);
      await tester.tap(answer);
      await settle(tester);
      final confirm = find.widgetWithText(FilledButton, '确认');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await settle(tester);
      expect(services.journal.attempts['deu-c02']?['answer_id'], 'option-1');
      await open(
        tester,
        services,
        '/countries/deu/observe/place/deu-wadden?media=deu-m20',
      );
      final save = find.widgetWithText(FilledButton, '保存我的发现');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      final field = find.byType(TextField).first;
      await tester.ensureVisible(field);
      await tester.enterText(field, '我看见弯曲的潮沟。');
      await settle(tester);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await settle(tester);
      expect(services.journal.notes.single['text'], contains('我看见弯曲的潮沟。'));
    },
  );
  testWidgets(
    'Germany four task filters and discovery counts reflect real activity',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final services = await createServices(tester);
      await open(tester, services, '/me/countries/deu');
      expect(find.text('0'), findsNWidgets(3));
      await open(tester, services, '/atlas?country=deu&place=deu-wadden');
      expect(
        services.journal.history.where((h) => h['kind'] == 'place'),
        isEmpty,
      );
      await open(tester, services, '/countries/deu/explore');
      final filter = find.text('写观察');
      await tester.ensureVisible(filter);
      await tester.tap(filter);
      await settle(tester);
      expect(find.text('城市中的语言'), findsOneWidget);
      await open(tester, services, '/places/deu-wadden');
      await open(tester, services, '/me/countries/deu');
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(2));
    },
  );
}
