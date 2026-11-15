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
import 'package:world_explorer/features/reader/zaf_diagrams.dart';

const _mapRoute = '/atlas?country=zaf&layer=terrain';
const _routes = {
  'za01-overview': '/countries/zaf',
  'za02-contents': '/countries/zaf/contents',
  'za04-map-phone': _mapRoute,
  'za05-penguins': '/articles/zaf-african-penguins',
  'za06-boulders': '/places/zaf-boulders',
  'za07-timeline': '/countries/zaf/timeline',
  'za08-languages': '/articles/zaf-languages',
  'za09-daily': '/countries/zaf/sections/daily',
  'za15-country-card': '/countries/zaf/sections/overview',
  'za10-mountains': '/articles/zaf-coast-plateau',
  'za11-explore': '/countries/zaf/explore',
  'za12-discoveries': '/me/countries/zaf',
  'za13-journey': '/countries/zaf/journeys/mountains-grassland',
  'za14-observation':
      '/countries/zaf/observe/place/zaf-boulders?media=zaf-penguins',
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
    await CountryMapData.load(southAfricaMapProfile);
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
    if (!const bool.fromEnvironment('CAPTURE_ZAF')) return;
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('docs/countries/zaf/implemented/$fileName.png');
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
      'ZAF routes fit ${size.width.toInt()} × ${size.height.toInt()} at ${scale}x',
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
              size.width == 1194 ? 'za03-map-tablet' : route.key,
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

  test('South Africa national geometry preserves independent neighbours and rivers', () async {
    final data = await CountryMapData.load(southAfricaMapProfile);
    final land = data.base.detail.singleWhere((s) => s.id == 'zaf');
    expect(land.contains(project(-29.12, 26.21)), isTrue);
    expect(
      land.contains(project(-29.6, 28.3)),
      isFalse,
      reason: 'Lesotho is independent',
    );
    expect(
      land.contains(project(-26.5, 31.5)),
      isFalse,
      reason: 'Eswatini is independent',
    );
    expect(data.rivers.map((r) => r.id).toSet(), {'zaf-orange', 'zaf-limpopo'});
    expect(data.relief, isNotNull);
    for (final river in data.rivers) {
      expect(river.distanceTo(river.lines.first.first), lessThan(.001));
    }
  });
  testWidgets('Every South Africa article and exercise renders', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    final articles = services.content.articles.where(
      (a) => a.countryId == 'zaf',
    );
    expect(articles.length, 30);
    for (final a in articles) {
      await open(tester, services, '/articles/${a.id}');
      expect(tester.takeException(), isNull, reason: a.id);
    }
    final exercises = services.content.exercises.where(
      (e) => e.countryId == 'zaf',
    );
    expect(exercises.length, 24);
    for (final e in exercises) {
      await open(tester, services, '/exercises/${e.id}');
      expect(tester.takeException(), isNull, reason: e.id);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -450));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: '${e.id} after scroll');
    }
  });
  testWidgets('South Africa answer and observation persist across navigation', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    await open(tester, services, '/articles/zaf-african-penguins');
    final answer = find.widgetWithText(ChoiceChip, '黑白羽毛与周围岩石');
    await tester.ensureVisible(answer);
    await settle(tester);
    await tester.tap(answer);
    await settle(tester);
    final confirm = find.widgetWithText(FilledButton, '确认');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await settle(tester);
    expect(services.journal.attempts['zaf-p05']?['answer_id'], 'option-1');
    await open(
      tester,
      services,
      '/countries/zaf/observe/place/zaf-boulders?media=zaf-penguins',
    );
    final save = find.widgetWithText(FilledButton, '保存我的发现');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.ensureVisible(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, '企鹅站在岩石旁。');
    await settle(tester);
    await open(tester, services, '/countries/zaf');
    await open(
      tester,
      services,
      '/countries/zaf/observe/place/zaf-boulders?media=zaf-penguins',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '企鹅站在岩石旁。',
      reason: 'Unsaved draft restores',
    );
    await tester.ensureVisible(save);
    await tester.tap(save);
    await settle(tester);
    expect(services.journal.notes.single['text'], contains('企鹅站在岩石旁。'));
    await open(tester, services, '/countries/zaf');
    await open(
      tester,
      services,
      '/countries/zaf/observe/place/zaf-boulders?media=zaf-penguins',
    );
    expect(services.journal.notes.single['text'], contains('企鹅站在岩石旁。'));
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
      reason: 'Saved notes are in discoveries; a new observation starts empty.',
    );
  });
  testWidgets('South Africa map selects a real place and opens its detail', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    await open(
      tester,
      services,
      '/atlas?country=zaf&place=zaf-agulhas&layer=terrain',
    );
    final map = tester.widget<CountryLearningMap>(
      find.byType(CountryLearningMap),
    );
    expect(map.profile.id, 'zaf');
    expect(map.selectedId, 'zaf-agulhas');
    final view = find.widgetWithText(FilledButton, '查看地点');
    await tester.ensureVisible(view);
    await tester.tap(view);
    await settle(tester);
    expect(find.text('厄加勒斯角'), findsWidgets);
    expect(find.byType(CountryLearningMap), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('All authored diagrams support large text and interaction', (
    tester,
  ) async {
    viewport(tester, const Size(320, 568), scale: 1.5);
    for (final kind in [
      'coast-plateau',
      'two-capes',
      'penguin-home',
      'food-web',
      'wetland',
      'transfer',
      'languages',
      'market',
      'recipe',
      'patterns',
      'history',
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ZafDiagram('zaf-$kind', key: ValueKey(kind)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final chip = find.byType(ChoiceChip).last;
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: kind);
    }
  });
}
