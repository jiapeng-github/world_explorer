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
import 'package:world_explorer/map_engine/kenya_learning_map.dart';
import 'package:world_explorer/map_engine/kenya_map_data.dart';

const _mapRoute =
    '/atlas?country=kenya&region=all&layer=water&place=kenya-mount-kenya';
const _routes = {
  'ke01-overview': '/countries/kenya',
  'ke02-contents': '/countries/kenya/contents',
  'ke04-map-phone': '/atlas?country=kenya&layer=places&place=kenya-lamu',
  'ke05-mountain-reader': '/articles/kenya-geography',
  'ke06-mountain': '/places/kenya-mount-kenya',
  'ke07-timeline': '/countries/kenya/timeline',
  'ke08-lamu': '/articles/kenya-history',
  'ke09-daily': '/countries/kenya/sections/daily',
  'ke10-habitat': '/articles/kenya-nature',
  'ke11-explore': '/countries/kenya/explore',
  'ke12-discoveries': '/me/countries/kenya',
  'ke13-journey': '/countries/kenya/journeys/city-coast',
  'ke14-observation':
      '/countries/kenya/observe/place/kenya-lamu?media=kenya-m06',
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
    await KenyaMapData.load();
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
    if (!const bool.fromEnvironment('CAPTURE_KENYA')) return;
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('docs/countries/kenya/implemented/$fileName.png');
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
      'KENYA routes fit ${size.width.toInt()} × ${size.height.toInt()} at ${scale}x',
      (tester) async {
        viewport(tester, size, scale: scale);
        final services = await createServices(tester);
        for (final route in _routes.entries) {
          if (size.width == 1194 && route.key != 'ke04-map-phone') continue;
          final boundary = GlobalKey();
          final pageServices = route.key == 'ke12-discoveries'
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
              size.width == 1194 ? 'ke03-map-tablet' : route.key,
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

  test('Kenya projection, cross-border lakes and reference lines', () async {
    final data = await KenyaMapData.load();
    final nairobi = KenyaRegion.all.project(-1.286, 36.817);
    expect(nairobi.dx, closeTo(-131.663961, .001));
    expect(nairobi.dy, closeTo(142.203350, .001));
    expect(
      data.all.feature('kenya-part-kenya')!.path.contains(nairobi),
      isTrue,
    );
    expect(KenyaRegion.all.northRotation(nairobi).abs(), lessThan(.01));
    for (final (lat, lon, id) in [
      (3.5, 36.1, 'kenya-lake-turkana'),
      (-1.0, 33.0, 'kenya-lake-victoria'),
      (0.0, 38.5, 'kenya-equator'),
    ]) {
      expect(
        data.all.hitLayer(
          KenyaRegion.all.project(lat, lon),
          layer: 'water',
          kmPerPixel: .1,
          allowedIds: {id},
        ),
        id,
      );
    }
    expect(data.all.feature('kenya-disputed-ilemi'), isNotNull);
    expect(data.all.feature('kenya-coast')!.waterway!.lines, isNotEmpty);
    expect(data.all.feature('kenya-border')!.waterway!.lines, isNotEmpty);
  });
  testWidgets('Kenya all exercises render at phone size', (tester) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    for (final e in services.content.exercises.where(
      (e) => e.countryId == 'kenya',
    )) {
      await open(tester, services, '/exercises/${e.id}');
      expect(tester.takeException(), isNull, reason: e.id);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -350));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: e.id);
    }
  });
  testWidgets('Kenya all articles, places and open observations render', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    for (final a in services.content.articlesIn('kenya')) {
      await open(tester, services, '/articles/${a.id}');
      expect(tester.takeException(), isNull, reason: a.id);
      if (a.activity.isNotEmpty) {
        await open(tester, services, '/countries/kenya/observe/${a.id}');
        expect(find.byType(TextField), findsNWidgets(3));
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, '保存我的发现'))
              .onPressed,
          isNull,
        );
      }
    }
    for (final p in services.content.placesIn('kenya')) {
      await open(tester, services, '/places/${p.id}');
      expect(tester.takeException(), isNull, reason: p.id);
    }
  });
  testWidgets('Kenya deep link and unknown region fallback', (tester) async {
    viewport(tester, const Size(1194, 834));
    final services = await createServices(tester);
    await open(tester, services, _mapRoute);
    expect(
      tester.widget<KenyaLearningMap>(find.byType(KenyaLearningMap)).selection,
      'kenya-mount-kenya',
    );
    await open(tester, services, '/atlas?country=kenya&region=unknown');
    expect(find.text('请选择地图范围'), findsOneWidget);
  });
  testWidgets(
    'Kenya answer and observation persist without inventing progress',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final services = await createServices(tester);
      expect(services.journal.attempts, isEmpty);
      expect(services.journal.notes, isEmpty);
      await open(tester, services, '/articles/kenya-geography');
      final answer = find.widgetWithText(ChoiceChip, '海拔等条件');
      await tester.ensureVisible(answer);
      await settle(tester);
      await tester.tap(answer);
      await settle(tester);
      final confirm = find.widgetWithText(FilledButton, '确认');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await settle(tester);
      expect(services.journal.attempts['kenya-c02']?['answer_id'], 'option-1');
      await open(
        tester,
        services,
        '/countries/kenya/observe/place/kenya-lamu?media=kenya-m06',
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
    'Kenya four task filters and discovery counts reflect real activity',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final services = await createServices(tester);
      await open(tester, services, '/me/countries/kenya');
      expect(find.text('0'), findsNWidgets(3));
      await open(tester, services, '/atlas?country=kenya&place=kenya-lamu');
      expect(
        services.journal.history.where((h) => h['kind'] == 'place'),
        isEmpty,
      );
      await open(tester, services, '/countries/kenya/explore');
      final filter = find.text('写观察');
      await tester.ensureVisible(filter);
      await tester.tap(filter);
      await settle(tester);
      expect(find.text('语言标牌'), findsOneWidget);
      await open(tester, services, '/places/kenya-lamu');
      await open(tester, services, '/me/countries/kenya');
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(2));
    },
  );
  test('rewritten content restarts stale progress without deleting notes or bookmarks', () async {
    final db = AtlasDatabase(NativeDatabase.memory());
    final content = ContentRepository.fromJson(
      jsonDecode(File('assets/atlas/catalog.json').readAsStringSync()),
    );
    final journal = JournalRepository(db);
    await journal.load();
    await journal.recordReading(
      'kenya-nature',
      'kenya-nature-b2',
      .8,
      completed: true,
    );
    await journal.toggle('article', 'kenya-nature', '旧版熊猫');
    await journal.saveNote(
      id: 'kept',
      kind: 'discovery',
      text: '我的旧发现',
      question: '',
      entityId: 'kenya-nature',
      title: '旧版标题快照',
    );
    await journal.reconcileContent(content);
    expect(journal.progress['kenya-nature']?['completed'], 0);
    expect(
      journal.progress['kenya-nature']?['block_id'],
      content.article('kenya-nature')!.blocks.first.id,
    );
    expect(journal.bookmarks, hasLength(1));
    expect(journal.notes.single['title'], '旧版标题快照');
    expect(
      (await db.preferences()).keys.any(
        (key) => key.startsWith('reading-archive-kenya-nature'),
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
            (raw['countries'] as List).firstWhere((c) => c['id'] == 'kenya'),
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
    expect(content.articlesIn('kenya'), hasLength(30));
    expect(content.country('kenya')!.editorial, isNotEmpty);
    content.dispose();
  });
}
