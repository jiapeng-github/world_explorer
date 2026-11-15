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
import 'package:world_explorer/design/components.dart';
import 'package:world_explorer/map_engine/atlas_map.dart';
import 'package:world_explorer/map_engine/country_learning_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final (family, path) in [
      ('NotoSansSC', 'assets/images/NotoSansSC.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(path))).load();
    }
    await CountryMapData.load(egyptMapProfile);
  });

  void viewport(WidgetTester tester, Size size, [double scale = 1]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 85)),
    );
    await tester.pumpAndSettle();
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

  final routes = <String, String>{
    'eg01-overview': '/countries/egypt',
    'eg02-directory': '/countries/egypt/contents',
    'eg04-map': '/atlas?country=egypt&layer=water&place=nile-delta',
    'eg05-nile-reader': '/articles/egypt-geography',
    'eg06-giza': '/places/giza',
    'eg07-timeline': '/countries/egypt/timeline',
    'eg08-papyrus': '/articles/egypt-papyrus',
    'eg09-daily': '/countries/egypt/sections/daily',
    'eg10-reef': '/articles/egypt-redsea-reef',
    'eg11-tasks': '/countries/egypt/explore',
    'eg12-discoveries': '/me/countries/egypt',
    'eg13-journey': '/countries/egypt/journeys/nile',
    'eg14-observation': '/countries/egypt/observe/egypt-people',
  };

  for (final (size, textScale) in [
    (const Size(390, 844), 1.0),
    (const Size(430, 932), 1.0),
    (const Size(1024, 768), 1.0),
    (const Size(1194, 834), 1.0),
    (const Size(320, 568), 1.5),
  ]) {
    testWidgets(
      'Egypt designed routes fit ${size.width.toInt()} × ${size.height.toInt()} at ${textScale}x',
      (tester) async {
        viewport(tester, size, textScale);
        final services = await createServices(tester);
        for (final entry in routes.entries) {
          final boundary = GlobalKey();
          await open(tester, services, entry.value, boundary: boundary);
          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} at start',
          );
          final capture =
              const bool.fromEnvironment('CAPTURE_EGYPT') &&
              (size.width == 390 ||
                  size.width == 1194 && entry.key == 'eg04-map');
          if (capture) {
            await tester.runAsync(() async {
              final render =
                  boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary;
              final image = await render.toImage(pixelRatio: 2);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              final name = size.width == 1194 ? 'eg03-map-tablet' : entry.key;
              final file = File(
                'docs/countries/egypt/implemented/${size.width.toInt()}/$name.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
            });
          }
          if (entry.key != 'eg04-map') {
            final scroller = find.byType(Scrollable).first;
            await tester.drag(scroller, const Offset(0, -540));
            await settle(tester);
            expect(
              tester.takeException(),
              isNull,
              reason: '${entry.key} while scrolling',
            );
          }
        }
      },
    );
  }

  testWidgets(
    'Nile journey leads to an inline answer, evidence and the delta',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final services = await createServices(tester);
      await open(tester, services, '/countries/egypt');
      await tester.tap(find.text('从尼罗河开始'));
      await settle(tester);
      expect(find.text('沿着尼罗河'), findsOneWidget);
      await tester.tap(find.text('从第一站开始'));
      await settle(tester);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('尼罗河流向哪里？'),
        ),
        findsOneWidget,
      );
      final confirm = find.widgetWithText(FilledButton, '确认');
      await tester.ensureVisible(confirm);
      await settle(tester);
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      final north = find.widgetWithText(ChoiceChip, '朝地中海');
      await tester.ensureVisible(north);
      await tester.tap(north);
      await settle(tester);
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await settle(tester);
      expect(
        services.journal.attempts['egypt-nile-flow']?['answer_id'],
        'north',
      );
      final delta = find.text('下一站 · 尼罗河三角洲');
      await tester.ensureVisible(delta);
      await tester.tap(delta);
      await settle(tester);
      final map = tester.widget<CountryLearningMap>(
        find.byType(CountryLearningMap),
      );
      expect(
        (map.profile.id, map.layer, map.selectedId),
        ('egypt', '河流', 'nile-delta'),
      );
      await tester.tap(find.byTooltip('返回埃及'));
      await settle(tester);
      expect(find.text('下一站 · 尼罗河三角洲'), findsOneWidget);
    },
  );

  testWidgets(
    'regional map keeps its camera after returning and finds an alias',
    (tester) async {
      viewport(tester, const Size(1194, 834));
      final services = await createServices(tester);
      await open(tester, services, routes['eg04-map']!);
      final finder = find.byType(CountryLearningMap);
      final controller = tester.widget<CountryLearningMap>(finder).controller!;
      await tester.tap(find.byTooltip('放大埃及地图'));
      await settle(tester);
      final camera = controller.camera!.storage.toList();
      await tester.tap(find.text('查看地点'));
      await settle(tester);
      expect(find.text('仔细看一看'), findsOneWidget);
      await tester.tap(find.byTooltip('返回'));
      await settle(tester);
      final map = tester.widget<CountryLearningMap>(finder);
      expect(map.selectedId, 'nile-delta');
      expect(map.controller!.camera!.storage, orderedEquals(camera));
      await tester.tap(find.byTooltip('埃及地点列表'));
      await settle(tester);
      await tester.enterText(find.byType(TextField).last, '阿布辛贝勒');
      await settle(tester);
      await tester.tap(find.text('阿布辛拜勒').last);
      await settle(tester);
      expect(
        tester.widget<CountryLearningMap>(finder).selectedId,
        'abu-simbel',
      );
    },
  );

  testWidgets(
    'world and local map questions select real points and return to evidence',
    (tester) async {
      viewport(tester, const Size(430, 932));
      final services = await createServices(tester);
      Future<void> tapPoint(Finder map, double lat, double lon) async {
        final viewer = find
            .descendant(of: map, matching: find.byType(InteractiveViewer))
            .first;
        final transform = tester
            .widget<InteractiveViewer>(viewer)
            .transformationController!;
        final pixel = MatrixUtils.transformPoint(
          transform.value,
          project(lat, lon),
        );
        await tester.tapAt(tester.getTopLeft(viewer) + pixel);
        await settle(tester);
      }

      await open(tester, services, '/exercises/egypt-location');
      final world = find.byType(AtlasMap);
      expect(tester.widget<AtlasMap>(world).candidateIds, [
        'china',
        'egypt',
        'brazil',
      ]);
      final egypt = services.content.country('egypt')!;
      await tapPoint(world, egypt.latitude, egypt.longitude);
      expect(tester.widget<AtlasMap>(world).selectedId, 'egypt');
      await tester.tap(find.text('确认'));
      await settle(tester);
      expect(services.journal.attempts['egypt-location']?['correct'], 1);
      final evidence = find.textContaining('回读相关内容');
      await tester.ensureVisible(evidence);
      await tester.tap(evidence);
      await settle(tester);
      expect(find.text('从非洲的东北角找').hitTestable(), findsOneWidget);
      await tester.tap(find.byTooltip('返回'));
      await settle(tester);
      expect(find.text('你找到了关键线索！'), findsOneWidget);

      await open(tester, services, '/exercises/egypt-find-karnak');
      final local = find.byType(CountryLearningMap);
      final karnak = services.content.place('egypt-karnak')!;
      expect(tester.widget<CountryLearningMap>(local).fitCandidates, isTrue);
      await tapPoint(local, karnak.latitude, karnak.longitude);
      expect(tester.widget<CountryLearningMap>(local).selectedId, karnak.id);
      await tester.tap(find.text('确认'));
      await settle(tester);
      expect(services.journal.attempts['egypt-find-karnak']?['correct'], 1);
    },
  );

  testWidgets(
    'Giza carries the selected photo into a draft and saves a place note',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final services = await createServices(tester);
      await open(tester, services, '/places/giza');
      await tester.ensureVisible(find.text('石块接缝'));
      await tester.tap(find.text('石块接缝'));
      await settle(tester);
      await tester.tap(find.text('记下我的发现'));
      await settle(tester);
      expect(
        tester.widget<MediaPhoto>(find.byType(MediaPhoto).first).id,
        'egypt-giza-blocks',
      );
      final save = find.widgetWithText(FilledButton, '保存我的发现');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      final field = find.byType(TextField).first;
      tester.view.viewInsets = const FakeViewPadding(bottom: 245);
      addTearDown(tester.view.resetViewInsets);
      await settle(tester);
      await tester.ensureVisible(field);
      await tester.enterText(field, '我在近景里看到一条横线。');
      await settle(tester);
      expect(tester.getBottomRight(save).dy, lessThan(844 - 245));
      tester.view.resetViewInsets();
      await tester.tap(find.byTooltip('返回'));
      await settle(tester);
      await tester.tap(find.text('记下我的发现'));
      await settle(tester);
      expect(tester.widget<TextField>(field).controller!.text, '我在近景里看到一条横线。');
      await tester.tap(save);
      await settle(tester);
      expect(services.journal.notes.single['entity_id'], 'giza');
      expect(services.journal.notes.single['text'], '我看见：我在近景里看到一条横线。');
      expect(services.preferences.values['observation-draft-giza'], isNull);
      expect(find.text('我的埃及发现'), findsOneWidget);
    },
  );

  test(
    'the offline raster and named waterways load as geographic data',
    () async {
      final data = await CountryMapData.load(egyptMapProfile);
      expect((data.relief?.width, data.relief?.height), (1360, 1200));
      final rivers = {for (final river in data.rivers) river.id: river};
      expect(
        rivers.keys,
        unorderedEquals([
          'egypt-nile',
          'egypt-delta-rosetta',
          'egypt-delta-damietta',
          'egypt-suez-waterway',
        ]),
      );
      expect(rivers['egypt-suez-waterway']!.canal, isTrue);
      final main = rivers['egypt-nile']!;
      expect(main.distanceTo(project(24.09, 32.89)), lessThan(0.6));
      expect(
        main.bounds.bottom,
        greaterThan(project(21.7, 31).dy),
        reason: 'the Nile must continue south of Egypt',
      );
    },
  );

  testWidgets('unpublished countries stay on the disabled world preview', (
    tester,
  ) async {
    viewport(tester, const Size(1194, 834));
    final services = await createServices(tester);
    final unpublished = services.content.countries.firstWhere(
      (c) => services.content.articlesIn(c.id).isEmpty,
    );
    await open(tester, services, '/atlas?country=${unpublished.id}');
    expect(find.byType(AtlasMap), findsOneWidget);
    final upcoming = find.widgetWithText(FilledButton, '即将上线');
    expect(tester.widget<FilledButton>(upcoming).onPressed, isNull);
    await open(tester, services, '/atlas?country=egypt');
    final egypt = tester.widget<CountryLearningMap>(
      find.byType(CountryLearningMap),
    );
    expect(egypt.profile.id, 'egypt');
    expect(egypt.selectedId, isNull);
  });
}
