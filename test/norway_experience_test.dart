import 'dart:io';
import 'dart:convert';

import 'package:world_explorer/data/content/content_repository.dart';
import 'package:world_explorer/data/database/user_repositories.dart';

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
import 'package:world_explorer/map_engine/norway_learning_map.dart';
import 'package:world_explorer/map_engine/norway_map_data.dart';

const _mapRoute =
    '/atlas?country=norway&region=mainland&layer=coast&place=norway-geiranger';
const _routes = {
  'no03-map-mainland': '/atlas?country=norway&region=mainland',
  'no03-map-svalbard': '/atlas?country=norway&region=svalbard',
  'no03-map-jan-mayen': '/atlas?country=norway&region=jan-mayen',
  'no01-overview': '/countries/norway',
  'no02-contents': '/countries/norway/contents',
  'no04-map-phone': '/atlas?country=norway&layer=places&place=norway-bryggen',
  'no05-fjord-reader': '/articles/norway-geography',
  'no06-geiranger': '/places/norway-geiranger',
  'no07-timeline': '/countries/norway/timeline',
  'no08-bryggen': '/articles/norway-history',
  'no09-daily': '/countries/norway/sections/daily',
  'no10-daylight': '/articles/norway-nature',
  'no11-explore': '/countries/norway/explore',
  'no12-discoveries': '/me/countries/norway',
  'no13-journey': '/countries/norway/journeys/fjord-wood',
  'no14-observation':
      '/countries/norway/observe/place/norway-bryggen?media=norway-m04',
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
    await NorwayMapData.load();
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
    if (!const bool.fromEnvironment('CAPTURE_NORWAY')) return;
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('docs/countries/norway/implemented/$fileName.png');
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
      'NORWAY routes fit ${size.width.toInt()} × ${size.height.toInt()} at ${scale}x',
      (tester) async {
        viewport(tester, size, scale: scale);
        final services = await createServices(tester);
        for (final route in _routes.entries) {
          if (size.width == 1194 && route.key != 'no04-map-phone') continue;
          final boundary = GlobalKey();
          final pageServices = route.key == 'no12-discoveries'
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
              size.width == 1194 ? 'no03-map-tablet' : route.key,
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

  test('Norway LAEA matches PROJ; regions include Bear Island; reference lines hit', () async {
    final data = await NorwayMapData.load();
    final raw = jsonDecode(
      File('assets/atlas/norway-regions.json').readAsStringSync(),
    );
    for (final row in raw['projectionChecks']) {
      final r = NorwayRegion.parse(row['region'])!;
      final p = r.project(
        (row['lat'] as num).toDouble(),
        (row['lon'] as num).toDouble(),
      );
      expect(p.dx, closeTo((row['xy'][0] as num).toDouble(), .001));
      expect(p.dy, closeTo((row['xy'][1] as num).toDouble(), .001));
      expect(r.northRotation(p).isFinite, isTrue);
    }
    final sval = data.regions[NorwayRegion.svalbard]!;
    expect(
      sval
          .feature('norway-part-svalbard')!
          .path
          .contains(NorwayRegion.svalbard.project(74.44, 19.0)),
      isTrue,
    );
    final lat = (raw['arcticCircle']['latitude'] as num).toDouble();
    expect(
      data.all.hitLayer(
        NorwayRegion.mainland.project(lat, 15),
        layer: 'coast',
        kmPerPixel: .1,
        allowedIds: {'norway-arctic-circle'},
      ),
      'norway-arctic-circle',
    );
    expect(data.all.feature('norway-border')!.waterway!.lines, isNotEmpty);
    expect(data.all.feature('norway-coast')!.waterway!.lines, isNotEmpty);
    expect(norwayRegionFor('norway-longyearbyen'), NorwayRegion.svalbard);
    expect(norwayRegionFor('norway-invalid'), isNull);
  });
  testWidgets('Norway all exercises render at phone size', (tester) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    for (final e in services.content.exercises.where(
      (e) => e.countryId == 'norway',
    )) {
      await open(tester, services, '/exercises/${e.id}');
      expect(tester.takeException(), isNull, reason: e.id);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -350));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: e.id);
    }
  });
  testWidgets('Norway all articles, places and open observations render', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    for (final a in services.content.articlesIn('norway')) {
      await open(tester, services, '/articles/${a.id}');
      expect(tester.takeException(), isNull, reason: a.id);
      if (a.activity.isNotEmpty) {
        await open(tester, services, '/countries/norway/observe/${a.id}');
        expect(find.byType(TextField), findsNWidgets(3));
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, '保存我的发现'))
              .onPressed,
          isNull,
        );
      }
    }
    for (final p in services.content.placesIn('norway')) {
      await open(tester, services, '/places/${p.id}');
      expect(tester.takeException(), isNull, reason: p.id);
    }
  });
  testWidgets('Norway deep link and unknown region fallback', (tester) async {
    viewport(tester, const Size(1194, 834));
    final services = await createServices(tester);
    await open(tester, services, _mapRoute);
    expect(
      tester
          .widget<NorwayLearningMap>(find.byType(NorwayLearningMap))
          .selection,
      'norway-geiranger',
    );
    await open(tester, services, '/atlas?country=norway&region=unknown');
    expect(find.text('请选择地图范围'), findsOneWidget);
  });
  testWidgets(
    'Norway answer and observation persist without inventing progress',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final services = await createServices(tester);
      expect(services.journal.attempts, isEmpty);
      expect(services.journal.notes, isEmpty);
      await open(tester, services, '/articles/norway-geography');
      final answer = find.widgetWithText(ChoiceChip, '海洋');
      await tester.ensureVisible(answer);
      await settle(tester);
      await tester.tap(answer);
      await settle(tester);
      final confirm = find.widgetWithText(FilledButton, '确认');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await settle(tester);
      expect(services.journal.attempts['norway-c02']?['answer_id'], 'option-1');
      await open(tester, services, '/exercises/norway-c02');
      expect(find.text('再试一次'), findsNothing);
      expect(services.journal.attempts, hasLength(1));
      await open(
        tester,
        services,
        '/countries/norway/observe/place/norway-bryggen?media=norway-m04',
      );
      final save = find.widgetWithText(FilledButton, '保存我的发现');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      final field = find.byType(TextField).first;
      await tester.ensureVisible(field);
      await tester.enterText(field, '我看见门楣上重复的图形。');
      await settle(tester);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await settle(tester);
      expect(services.journal.notes.single['text'], contains('我看见门楣上重复的图形。'));
    },
  );
  testWidgets(
    'Norway four task filters and discovery counts reflect real activity',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final services = await createServices(tester);
      await open(tester, services, '/me/countries/norway');
      expect(find.text('0'), findsNWidgets(3));
      await open(
        tester,
        services,
        '/atlas?country=norway&place=norway-bryggen',
      );
      expect(
        services.journal.history.where((h) => h['kind'] == 'place'),
        isEmpty,
      );
      await open(tester, services, '/countries/norway/explore');
      final filter = find.text('写观察');
      await tester.ensureVisible(filter);
      await tester.tap(filter);
      await settle(tester);
      expect(find.text('今天的萨米文化'), findsOneWidget);
      await open(tester, services, '/places/norway-bryggen');
      await open(tester, services, '/me/countries/norway');
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(2));
      await tester.ensureVisible(find.text('走进布吕根  ›'));
      await tester.tap(find.text('走进布吕根  ›'));
      await settle(tester);
      expect(find.text('布吕根历史港区'), findsOneWidget);
    },
  );
  testWidgets('Norway region switch does not submit a location answer', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    await open(tester, services, '/exercises/norway-l05');
    final chip = find.widgetWithText(ChoiceChip, '斯瓦尔巴');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await settle(tester);
    final map = tester.widget<NorwayLearningMap>(
      find.byType(NorwayLearningMap),
    );
    expect(map.region, NorwayRegion.svalbard);
    expect(map.selection, isNull);
    expect(services.journal.attempts, isEmpty);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '确认'))
          .onPressed,
      isNull,
    );
    map.onSelect!('norway-part-svalbard');
    await settle(tester);
    final confirm = find.widgetWithText(FilledButton, '确认');
    await tester.tap(confirm);
    await settle(tester);
    expect(
      services.journal.attempts['norway-l05']?['answer_id'],
      'norway-part-svalbard',
    );
    await open(tester, services, '/exercises/norway-l05');
    expect(
      tester.widget<NorwayLearningMap>(find.byType(NorwayLearningMap)).region,
      NorwayRegion.svalbard,
    );
  });
  test('rewritten content restarts stale progress without deleting notes or bookmarks', () async {
    final db = AtlasDatabase(NativeDatabase.memory());
    final content = ContentRepository.fromJson(
      jsonDecode(File('assets/atlas/catalog.json').readAsStringSync()),
    );
    final journal = JournalRepository(db);
    await journal.load();
    await journal.recordReading(
      'norway-nature',
      'norway-nature-b2',
      .8,
      completed: true,
    );
    await journal.toggle('article', 'norway-nature', '旧版极昼');
    await journal.saveNote(
      id: 'kept',
      kind: 'discovery',
      text: '我的旧发现',
      question: '',
      entityId: 'norway-nature',
      title: '旧版标题快照',
    );
    await journal.reconcileContent(content);
    expect(journal.progress['norway-nature']?['completed'], 0);
    expect(
      journal.progress['norway-nature']?['block_id'],
      content.article('norway-nature')!.blocks.first.id,
    );
    expect(journal.bookmarks, hasLength(1));
    expect(journal.notes.single['title'], '旧版标题快照');
    expect(
      (await db.preferences()).keys.any(
        (key) => key.startsWith('reading-archive-norway-nature'),
      ),
      isTrue,
    );
    await journal.reconcileContent(content);
    expect(journal.notes, hasLength(1));
    journal.dispose();
    content.dispose();
    await db.close();
  });

  test('old installed country pack cannot replace a newer bundled edition', () {
    final raw = jsonDecode(
      File('assets/atlas/catalog.json').readAsStringSync(),
    );
    final content = ContentRepository.fromJson(raw);
    final oldCountry =
        Map<String, dynamic>.from(
            (raw['countries'] as List).firstWhere((c) => c['id'] == 'norway'),
          )
          ..['revision'] = 1
          ..['editorial'] = {};
    content.applyDownloaded([
      {
        'country': oldCountry,
        'articles': [],
        'places': [],
        'exercises': [],
        'media': [],
      },
    ], {});
    expect(content.articlesIn('norway'), hasLength(30));
    expect(content.country('norway')!.editorial, isNotEmpty);
    content.dispose();
  });
}
