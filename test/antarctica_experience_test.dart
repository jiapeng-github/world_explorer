import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_explorer/app/atlas_app.dart';
import 'package:world_explorer/app/services.dart';
import 'package:world_explorer/data/database/atlas_database.dart';
import 'package:world_explorer/features/regions/antarctica/antarctica_map.dart';

const routes = {
  'an01-home': '/regions/antarctica',
  'an02-contents': '/regions/antarctica/contents',
  'an03-map': '/regions/antarctica/map',
  'an04-selection': '/regions/antarctica/map?place=antarctica-ross-shelf',
  'an05-ice': '/articles/antarctica-ice-shelf',
  'an06-question': '/regions/antarctica/tasks/antarctica-P02',
  'an07-food': '/articles/antarctica-krill-web',
  'an08-penguin': '/articles/antarctica-emperor',
  'an09-science': '/regions/antarctica/sections/science',
  'an10-station': '/places/antarctica-zhongshan',
  'an11-light': '/articles/antarctica-polar-day',
  'an12-timeline': '/regions/antarctica/timeline',
  'an13-tasks': '/regions/antarctica/explore',
  'an14-discoveries': '/me/regions/antarctica',
  'an15-route': '/regions/antarctica/journeys/ice-journey',
  'an16-note': '/regions/antarctica/observe/antarctica-under-ice',
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final pair in [
      ('NotoSansSC', 'assets/images/NotoSansSC.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(pair.$1)..addFont(rootBundle.load(pair.$2))).load();
    }
  });
  for (final size in [
    const Size(390, 844),
    const Size(1194, 834),
    const Size(430, 932),
    const Size(320, 568),
  ]) {
    testWidgets('Antarctica 16 routes ${size.width}', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      if (size.width == 320) {
        t.platformDispatcher.textScaleFactorTestValue = 1.5;
      }
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final s = (await t.runAsync(
        () => AtlasServices.load(
          database: AtlasDatabase(NativeDatabase.memory()),
          migrate: false,
        ),
      ))!;
      debugDisableShadows = false;
      try {
        for (final entry in routes.entries) {
          final key = GlobalKey();
          await t.pumpWidget(
            RepaintBoundary(
              key: key,
              child: WorldAtlasApp(
                key: ValueKey(entry.key),
                services: s,
                initialLocation: entry.value,
              ),
            ),
          );
          await t.pump();
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 500)),
          );
          await t.pumpAndSettle();
          await t.runAsync(() async {
            for (final el in find.byType(Image).evaluate()) {
              await precacheImage((el.widget as Image).image, el);
            }
          });
          await t.pumpAndSettle();
          expect(t.takeException(), isNull, reason: entry.key);
          if (const bool.fromEnvironment('CAPTURE_ANTARCTICA')) {
            await t.runAsync(() async {
              final im =
                  await (key.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage(pixelRatio: 1.5);
              final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
              im.dispose();
              final f = File(
                'docs/regions/antarctica/implemented/${entry.key}-${size.width.toInt()}.png',
              );
              await f.parent.create(recursive: true);
              await f.writeAsBytes(bytes!.buffer.asUint8List());
            });
          }
        }
      } finally {
        debugDisableShadows = true;
      }
      await t.pumpWidget(const SizedBox());
      await t.runAsync(s.dispose);
    });
  }
  test('polar projection handles pole and dateline', () {
    expect(antarcticProject(-90, 0), Offset.zero);
    expect(
      (antarcticProject(-80, 180) - antarcticProject(-80, -180)).distance,
      lessThan(.001),
    );
    expect(antarcticProject(-71, 0).dy, isNegative);
    expect(antarcticProject(-71, 90).dx, isPositive);
  });
  testWidgets(
    'region is searchable without incrementing country count; records survive backup',
    (t) async {
      final s = (await t.runAsync(
        () => AtlasServices.load(
          database: AtlasDatabase(NativeDatabase.memory()),
          migrate: false,
        ),
      ))!;
      expect(s.content.region('antarctica'), isNotNull);
      expect(
        s.content.articles.where((a) => a.regionId == 'antarctica').length,
        24,
      );
      expect(
        s.content.featured.any((c) => c.id == 'antarctica' || c.id == 'ata'),
        false,
      );
      expect(
        s.content.search('南极').any((h) => h.route == '/regions/antarctica'),
        true,
      );
      await t.runAsync(() async {
        await s.journal.toggle('region', 'antarctica', '南极洲');
        await s.journal.saveNote(
          id: 'antarctica-note-test',
          kind: 'article',
          text: '我看见了海冰',
          question: '冰下有什么？',
          entityId: 'antarctica-under-ice',
          title: '观察',
        );
        await s.journal.answer('antarctica-P02', '0', true);
        final b = await s.journal.backup();
        await s.journal.restore(b, replace: true);
        expect(s.journal.saved('region', 'antarctica'), true);
        expect(s.journal.notes.single['text'], '我看见了海冰');
        expect(s.journal.attempts.containsKey('antarctica-P02'), true);
        await s.dispose();
      });
    },
  );
  testWidgets('observation drafts restore and save into discoveries', (
    t,
  ) async {
    final s = (await t.runAsync(
      () => AtlasServices.load(
        database: AtlasDatabase(NativeDatabase.memory()),
        migrate: false,
      ),
    ))!;
    Future<void> open(String key) async {
      await t.pumpWidget(
        WorldAtlasApp(
          key: ValueKey(key),
          services: s,
          initialLocation: '/regions/antarctica/observe/antarctica-O02',
        ),
      );
      await t.pump();
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await t.pumpAndSettle();
    }

    await open('first');
    expect(
      t
          .widget<FilledButton>(find.widgetWithText(FilledButton, '保存观察'))
          .onPressed,
      isNull,
    );
    await t.enterText(find.byType(TextField).first, '冰块之间有深色水面');
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await t.pumpWidget(const SizedBox());
    await t.pump();
    await open('restored');
    expect(
      t.widget<TextField>(find.byType(TextField).first).controller!.text,
      '冰块之间有深色水面',
    );
    final button = find.widgetWithText(FilledButton, '保存观察');
    await t.ensureVisible(button);
    await t.tap(button);
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await t.pumpAndSettle();
    expect(s.journal.notes.single['entity_id'], 'antarctica-under-ice');
    expect(s.journal.notes.single['text'], contains('冰块之间有深色水面'));
    expect(find.text('我的南极发现'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.runAsync(s.dispose);
  });
  testWidgets(
    'ice question requires confirmation and restores submitted answer',
    (t) async {
      final s = (await t.runAsync(
        () => AtlasServices.load(
          database: AtlasDatabase(NativeDatabase.memory()),
          migrate: false,
        ),
      ))!;
      Future<void> open(String key) async {
        await t.pumpWidget(
          WorldAtlasApp(
            key: ValueKey(key),
            services: s,
            initialLocation: '/exercises/antarctica-P02',
          ),
        );
        await t.pump();
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await t.pumpAndSettle();
      }

      await open('first');
      final confirm = find.widgetWithText(FilledButton, '确认选择');
      expect(t.widget<FilledButton>(confirm).onPressed, isNull);
      await t.ensureVisible(find.text('海冰'));
      await t.tap(find.text('海冰'));
      await t.pump();
      expect(s.journal.attempts.containsKey('antarctica-P02'), false);
      await t.ensureVisible(confirm);
      await t.tap(confirm);
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await t.pumpAndSettle();
      expect(s.journal.attempts['antarctica-P02']?['answer_id'], '2');
      await t.pumpWidget(const SizedBox());
      await t.pump();
      await open('restore');
      expect(find.text('你找到线索了'), findsOneWidget);
      expect(t.widget<FilledButton>(confirm).onPressed, isNull);
      await t.pumpWidget(const SizedBox());
      await t.runAsync(s.dispose);
    },
  );
  test('content and GIS assets meet the frozen contract', () async {
    final j = jsonDecode(
      File('assets/atlas/antarctica-region.json').readAsStringSync(),
    );
    expect(j['articles'].length, 24);
    expect(j['places'].length, 12);
    expect(j['exercises'].length, 18);
    expect(j['observations'].length, 6);
    expect(j['journeys'].length, 3);
    final media = {for (final m in j['media']) m['id']: m};
    for (final a in j['articles']) {
      expect(a['blocks'].length, 5);
      final count = RegExp(r'[\u4e00-\u9fff]')
          .allMatches((a['blocks'] as List).map((b) => b['text']).join())
          .length;
      expect(count, inInclusiveRange(450, 650), reason: a['id']);
      expect(a['sourceUrls'], isNotEmpty);
      expect(media.containsKey(a['mediaId']), true);
    }
    for (final m in media.values) {
      expect(File(m['asset']).existsSync(), true);
      expect(m['licenseUrl'], isNotEmpty);
      expect(m['sourceUrl'], startsWith('https://'));
    }
    final gis = jsonDecode(
      File('assets/atlas/antarctica-coast.json').readAsStringSync(),
    );
    expect(gis['crs'], 'EPSG:3031');
    final surfaces = (gis['features'] as List)
        .map((f) => f['attributes']['surface'])
        .toSet();
    expect(surfaces, containsAll(['land', 'ice shelf']));
    expect(gis['features'].length, greaterThan(2000));
  });
}
