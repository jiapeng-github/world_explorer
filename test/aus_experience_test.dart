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
import 'package:world_explorer/map_engine/aus_map_profile.dart';

const _mapRoute = '/atlas?country=aus&layer=water&place=aus-great-barrier-reef';
const _routes = {
  'au01-overview': '/countries/aus',
  'au02-contents': '/countries/aus/contents',
  'au04-map-phone': _mapRoute,
  'au05-coral': '/articles/aus-coral',
  'au06-reef': '/places/aus-great-barrier-reef',
  'au07-people': '/countries/aus/sections/people',
  'au08-daily': '/countries/aus/sections/daily',
  'au09-animal': '/articles/aus-kangaroo-pouch',
  'au10-timeline': '/countries/aus/timeline',
  'au11-explore': '/countries/aus/explore',
  'au12-discoveries': '/me/countries/aus',
  'au13-journey': '/countries/aus/journeys/coast-city',
  'au14-observation':
      '/countries/aus/observe/aus-animal-observation?media=aus-joey',
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
    await CountryMapData.load(ausMapProfile);
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
    if (!const bool.fromEnvironment('CAPTURE_AUS')) return;
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('docs/countries/aus/implemented/$fileName.png');
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
      'AUS routes fit ${size.width.toInt()} × ${size.height.toInt()} at ${scale}x',
      (tester) async {
        viewport(tester, size, scale: scale);
        final services = await createServices(tester);
        for (final route in _routes.entries) {
          if (size.width == 1194 && route.value != _mapRoute) continue;
          final boundary = GlobalKey();
          await open(tester, services, route.value, boundary: boundary);
          expect(tester.takeException(), isNull, reason: route.key);
          expect(find.text('没有找到这个页面'), findsNothing, reason: route.key);
          expect(find.text('金字塔留下了哪些线索？'), findsNothing, reason: route.key);
          expect(find.text('暂时没有这个地点的资料'), findsNothing, reason: route.key);
          if (size.width != 320) {
            await capture(
              tester,
              boundary,
              size.width == 1194 ? 'au03-map-tablet' : route.key,
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

  testWidgets('Australia all articles, places and exercises render', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    for (final route in [
      for (final a in services.content.articles.where(
        (a) => a.countryId == 'aus',
      ))
        '/articles/${a.id}',
      for (final p in services.content.placesIn('aus')) '/places/${p.id}',
      for (final e in services.content.exercises.where(
        (e) => e.countryId == 'aus',
      ))
        '/exercises/${e.id}',
    ]) {
      await open(tester, services, route);
      expect(tester.takeException(), isNull, reason: route);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: route);
    }
  });
  testWidgets('Australia coral answer, saved article and observation persist', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final services = await createServices(tester);
    final article = services.content.article('aus-coral')!;
    await open(tester, services, '/articles/${article.id}');
    await tester.tap(find.byTooltip('收藏').first);
    await settle(tester);
    expect(services.journal.saved('article', article.id), isTrue);
    final answer = find.widgetWithText(ChoiceChip, '动物');
    await tester.ensureVisible(answer);
    await settle(tester);
    await tester.tap(answer);
    await settle(tester);
    final confirm = find.widgetWithText(FilledButton, '确认');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await settle(tester);
    expect(
      services.journal.attempts[article.exerciseId]?['answer_id'],
      'option-1',
    );
    await open(
      tester,
      services,
      '/countries/aus/observe/aus-animal-observation?media=aus-joey',
    );
    final field = find.byType(TextField).first;
    await tester.ensureVisible(field);
    await tester.enterText(field, '幼崽的头露在育儿袋外。');
    await settle(tester);
    final save = find.widgetWithText(FilledButton, '保存我的发现');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await settle(tester);
    expect(services.journal.notes.single['text'], contains('幼崽的头露在育儿袋外。'));
    await open(tester, services, '/me/countries/aus');
    expect(tester.takeException(), isNull);
  });
}
