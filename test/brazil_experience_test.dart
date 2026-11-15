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
import 'package:world_explorer/features/reader/brazil_diagrams.dart';
import 'package:world_explorer/features/reader/brazil_interactions.dart';
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
    await AtlasGeometry.load();
    await CountryMapData.load(brazilMapProfile);
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

  Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
    if (!const bool.fromEnvironment('CAPTURE_BRAZIL')) return;
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('docs/countries/brazil/implemented/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('Brazil overview and three reading journeys render', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    for (final route in [
      '/countries/brazil',
      '/countries/brazil/contents',
      '/countries/brazil/journeys/river-forest',
      '/countries/brazil/journeys/city-life',
      '/countries/brazil/journeys/nature-rhythm',
    ]) {
      await open(tester, services, route);
      expect(tester.takeException(), isNull, reason: route);
    }
    await open(tester, services, '/countries/brazil');
    final discoveries = find.widgetWithText(TextButton, '我的发现');
    await tester.ensureVisible(discoveries);
    await tester.tap(discoveries);
    await settle(tester);
    expect(find.text('我的巴西发现'), findsOneWidget);
    expect(find.text('我的法国发现'), findsNothing);
  });
  testWidgets('Brazil river article answer persists and map links to Manaus', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    await open(tester, services, '/articles/brazil-meeting-waters');
    final answer = find.widgetWithText(ChoiceChip, '不能，还需要取样与测量');
    await tester.ensureVisible(answer);
    await settle(tester);
    await tester.tap(answer);
    await settle(tester);
    final confirm = find.widgetWithText(FilledButton, '确认');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await settle(tester);
    expect(
      services.journal.attempts['brazil-meeting-waters-check']?['answer_id'],
      'evidence',
    );
    final mapLink = find.widgetWithText(TextButton, '在地图上看看');
    await tester.ensureVisible(mapLink);
    await tester.tap(mapLink);
    await settle(tester);
    expect(find.byType(CountryLearningMap), findsOneWidget);
    expect(
      tester
          .widget<CountryLearningMap>(find.byType(CountryLearningMap))
          .profile
          .id,
      'brazil',
    );
    var map = tester.widget<CountryLearningMap>(
      find.byType(CountryLearningMap),
    );
    expect(map.selectedId, 'brazil-manaus-meeting-waters');
    expect(map.layer, '河流');
    final localCamera = map.controller!.camera!;
    expect(localCamera.entry(0, 0), greaterThan(20));
    final placesLayer = find.widgetWithText(ChoiceChip, '地点');
    await tester.tap(placesLayer);
    await settle(tester);
    map = tester.widget<CountryLearningMap>(find.byType(CountryLearningMap));
    expect(map.controller!.camera!.storage, localCamera.storage);
    map.controller!.reset();
    await settle(tester);
    expect(
      map.controller!.camera!.entry(0, 0),
      lessThan(localCamera.entry(0, 0)),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Brazil new content and observation routes fit small screen', (
    tester,
  ) async {
    viewport(tester, const Size(320, 568), scale: 1.3);
    final services = await createServices(tester);
    for (final route in [
      '/articles/brazil-six-biomes',
      '/articles/brazil-water-evidence',
      '/articles/brazil-brasilia',
      '/places/brasilia',
      '/exercises/brazil-brasilia-check',
      '/places/brazil-manaus-meeting-waters',
      '/exercises/brazil-six-biomes-check',
      '/countries/brazil/observe/brazil-water-evidence',
    ]) {
      await open(tester, services, route);
      expect(tester.takeException(), isNull, reason: route);
    }
  });
  test('Brazil waterways retain two nonempty real river geometries', () async {
    final data = await CountryMapData.load(brazilMapProfile);
    expect(
      data.rivers.map((r) => r.id),
      containsAll(['brazil-amazon-river', 'brazil-negro-river']),
    );
    expect(
      data.rivers.every((r) => r.lines.expand((l) => l).length > 30),
      isTrue,
    );
  });

  testWidgets('Brazil observation saves a real note and restores a draft', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    const route = '/countries/brazil/observe/brazil-water-evidence';
    await open(tester, services, route);
    expect(find.byType(TextField), findsNWidgets(3));
    final save = find.widgetWithText(FilledButton, '保存我的发现');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.enterText(find.byType(TextField).first, '两条河有深浅不同的水色。');
    await settle(tester);
    await open(tester, services, '/countries/brazil');
    await open(tester, services, route);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '两条河有深浅不同的水色。',
    );
    await tester.tap(save);
    await settle(tester);
    await tester.runAsync(services.journal.load);
    final notes = services.journal.notes.where(
      (n) => n['entity_id'] == 'brazil-water-evidence',
    );
    expect(notes, hasLength(1));
    expect(notes.single['text'], contains('两条河有深浅不同的水色。'));
    expect(
      services.preferences.values['observation-draft-brazil-water-evidence'],
      isNull,
    );
    expect(find.text('我的巴西发现'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Brazil biome choices update explanations without answering quiz',
    (tester) async {
      viewport(tester, const Size(320, 568), scale: 1.3);
      final services = await createServices(tester);
      await open(tester, services, '/articles/brazil-six-biomes');
      expect(find.byType(BrazilBiomesDiagram), findsOneWidget);
      final choice = find.widgetWithText(ChoiceChip, '潘塔纳尔');
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await settle(tester);
      expect(find.text('潘塔纳尔 · 季节性湿地'), findsOneWidget);
      expect(services.journal.attempts['brazil-six-biomes-check'], isNull);
      expect(tester.takeException(), isNull);
    },
  );

  test('IBGE biome polygons contain known inland reference points', () async {
    final data = await CountryMapData.load(brazilMapProfile);
    expect(data.biomes, hasLength(6));
    for (final (slug, lat, lon) in [
      ('amazon', -4.0, -63.0),
      ('cerrado', -14.0, -48.0),
      ('caatinga', -8.0, -39.0),
      ('atlantic', -22.5, -43.0),
      ('pampa', -30.5, -54.0),
      ('pantanal', -18.0, -56.5),
    ]) {
      expect(
        data.biomes['brazil-biome-$slug']!.contains(project(lat, lon)),
        isTrue,
        reason: slug,
      );
    }
    expect(
      data.biomes.values.any((s) => s.contains(project(-18, -30))),
      isFalse,
    );
  });

  testWidgets(
    'Ecology hit testing selects polygon interiors away from labels',
    (tester) async {
      viewport(tester, const Size(800, 700));
      final services = await createServices(tester);
      final controller = CountryMapController();
      String? chosen;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountryLearningMap(
              profile: brazilMapProfile,
              countries: services.content.countries,
              places: services.content.placesIn('brazil'),
              layer: '生态',
              controller: controller,
              showControls: false,
              onSelect: (id) => chosen = id,
            ),
          ),
        ),
      );
      await settle(tester);
      final position = MatrixUtils.transformPoint(
        controller.camera!,
        project(-7, -68),
      );
      final origin = tester.getTopLeft(find.byType(CountryLearningMap));
      await tester.tapAt(origin + position);
      await settle(tester);
      expect(chosen, 'brazil-biome-amazon');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Timeline and photo hotspots have meaningful destinations', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    await open(tester, services, '/countries/brazil/timeline');
    expect(find.text('《黄金法》废除奴隶制'), findsOneWidget);
    await tester.ensureVisible(find.text('《黄金法》废除奴隶制'));
    await tester.tap(find.text('《黄金法》废除奴隶制'));
    await settle(tester);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('一份废奴法律能改变所有现实吗？'),
      ),
      findsOneWidget,
    );
    await open(tester, services, '/places/brazil-pantanal');
    final point = find.widgetWithText(ChoiceChip, '1 水豚与水面');
    await tester.scrollUntilVisible(
      point.hitTestable(),
      250,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await settle(tester);
    await tester.tap(point);
    await settle(tester);
    expect(find.text('水豚身体靠近水面，岸边的陆地仍是环境的一部分。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Full Brazil edition fits 320px with large text', (tester) async {
    viewport(tester, const Size(320, 568), scale: 1.5);
    final services = await createServices(tester);
    final country = services.content.country('brazil')!;
    final ids = country.sections.values.expand((v) => v).toSet();
    expect(ids, hasLength(30));
    final routes = [
      '/countries/brazil',
      '/countries/brazil/contents',
      '/countries/brazil/timeline',
      '/countries/brazil/explore',
      '/atlas?country=brazil&layer=biomes',
      for (final id in ids) '/articles/$id',
      for (final p in services.content.placesIn('brazil')) '/places/${p.id}',
      for (final e in services.content.exercises.where(
        (e) => e.countryId == 'brazil',
      ))
        '/exercises/${e.id}',
    ];
    for (final route in routes) {
      await open(tester, services, route);
      expect(tester.takeException(), isNull, reason: route);
    }
  });

  testWidgets('Ecology layer preserves camera and opens a biome reading', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    await open(
      tester,
      services,
      '/atlas?country=brazil&layer=biomes&feature=brazil-biome-pantanal',
    );
    var map = tester.widget<CountryLearningMap>(
      find.byType(CountryLearningMap),
    );
    expect(map.layer, '生态');
    expect(map.selectedId, 'brazil-biome-pantanal');
    final camera = List<double>.from(map.controller!.camera!.storage);
    await tester.tap(find.widgetWithText(ChoiceChip, '水系'));
    await settle(tester);
    map = tester.widget<CountryLearningMap>(find.byType(CountryLearningMap));
    expect(map.controller!.camera!.storage, camera);
    await tester.tap(find.widgetWithText(ChoiceChip, '生态'));
    await settle(tester);
    expect(find.textContaining('IBGE 2019'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Wetland switching changes water without answering the question',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final services = await createServices(tester);
      await open(tester, services, '/articles/brazil-capybara');
      final dry = find.widgetWithText(ChoiceChip, '较干时期');
      await tester.ensureVisible(dry);
      await tester.tap(dry);
      await settle(tester);
      final painters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .whereType<BrazilHabitatPainter>();
      expect(painters.single.selected, 1);
      expect(services.journal.attempts['brazil-capybara-check'], isNull);
      final answer = find.widgetWithText(ChoiceChip, '动物可以使用的水面与陆地空间');
      await tester.ensureVisible(answer);
      await tester.tap(answer);
      await settle(tester);
      final confirm = find.widgetWithText(FilledButton, '确认');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await settle(tester);
      expect(
        services.journal.attempts['brazil-capybara-check']?['answer_id'],
        'evidence',
      );
      final mapLink = find.widgetWithText(TextButton, '在地图上看看');
      await tester.ensureVisible(mapLink);
      await tester.tap(mapLink);
      await settle(tester);
      final map = tester.widget<CountryLearningMap>(
        find.byType(CountryLearningMap),
      );
      expect(map.selectedId, 'brazil-biome-pantanal');
      expect(map.layer, '生态');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Rhythm playback stops after four beats and disposes cleanly', (
    tester,
  ) async {
    viewport(tester, const Size(320, 568), scale: 1.5);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BrazilInteraction('brazil-rhythm'),
          ),
        ),
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, '播放四拍'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '第2拍'))
          .selected,
      isTrue,
    );
    await tester.pump(const Duration(milliseconds: 1800));
    expect(find.text('播放四拍'), findsOneWidget);
    await tester.ensureVisible(find.text('轻点回应'));
    await tester.tap(find.text('轻点回应'));
    await tester.pump();
    expect(find.text('本轮已回应 1 / 4 拍'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '播放四拍'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 1194.0]) {
    testWidgets('Brazil key screens render at $width', (tester) async {
      viewport(tester, Size(width, 844));
      final services = await createServices(tester);
      for (final (name, route) in [
        ('overview', '/countries/brazil'),
        ('contents', '/countries/brazil/contents'),
        ('river-reader', '/articles/brazil-meeting-waters'),
        ('biomes-reader', '/articles/brazil-six-biomes'),
        ('brasilia-reader', '/articles/brazil-brasilia'),
        ('water-map', '/atlas?country=brazil&layer=water'),
        ('ecology-map', '/atlas?country=brazil&layer=biomes'),
        ('wetland-reader', '/articles/brazil-capybara'),
        ('frevo-reader', '/articles/brazil-frevo'),
        ('timeline', '/countries/brazil/timeline'),
        ('explore', '/countries/brazil/explore'),
        ('pantanal-place', '/places/brazil-pantanal'),
        ('discoveries', '/me/countries/brazil'),
        (
          'manaus-map',
          '/atlas?country=brazil&place=brazil-manaus-meeting-waters&layer=water',
        ),
        ('observation', '/countries/brazil/observe/brazil-water-evidence'),
      ]) {
        final key = GlobalKey();
        await open(tester, services, route, boundary: key);
        expect(tester.takeException(), isNull, reason: route);
        await capture(tester, key, '${width.toInt()}/$name');
        if (name == 'wetland-reader') {
          await tester.ensureVisible(find.byType(BrazilInteraction));
          await settle(tester);
          await capture(tester, key, '${width.toInt()}/wetland-diagram');
        }
        if (name == 'river-reader' || name == 'biomes-reader') {
          final diagram = name == 'river-reader'
              ? find.byType(BrazilMeetingDiagram)
              : find.byType(BrazilBiomesDiagram);
          await tester.ensureVisible(diagram);
          await settle(tester);
          await capture(tester, key, '${width.toInt()}/$name-diagram');
        }
      }
    });
  }
}
