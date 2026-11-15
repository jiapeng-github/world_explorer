import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:world_explorer/app/atlas_app.dart';
import 'package:world_explorer/app/services.dart';
import 'package:world_explorer/data/database/atlas_database.dart';
import 'package:world_explorer/features/reader/learning_diagrams.dart';
import 'package:world_explorer/map_engine/atlas_map.dart';
import 'package:world_explorer/map_engine/country_learning_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'NotoSansSC',
    )..addFont(rootBundle.load('assets/images/NotoSansSC.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await AtlasGeometry.load();
    await CountryMapData.load(chinaMapProfile);
    await CountryMapData.load(egyptMapProfile);
    PackageInfo.setMockInitialValues(
      appName: '世界大百科',
      packageName: 'com.example.world_explorer',
      version: '0.8.0',
      buildNumber: '8',
      buildSignature: '',
    );
  });
  Future<AtlasServices> setup(
    WidgetTester t, {
    Size size = const Size(1280, 800),
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final s = (await t.runAsync(
      () => AtlasServices.load(
        database: AtlasDatabase(NativeDatabase.memory()),
        migrate: false,
      ),
    ))!;
    addTearDown(() async {
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      await t.runAsync(s.dispose);
    });
    return s;
  }

  Future<void> open(
    WidgetTester t,
    AtlasServices s,
    String route, {
    GlobalKey? capture,
  }) async {
    final app = WorldAtlasApp(
      key: ValueKey(route),
      services: s,
      initialLocation: route,
    );
    await t.pumpWidget(
      capture == null ? app : RepaintBoundary(key: capture, child: app),
    );
    await t.pump();
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull, reason: route);
  }

  Future<void> screenshot(WidgetTester t, GlobalKey key, String name) async {
    if (!const bool.fromEnvironment('CAPTURE_REVIEW')) return;
    await t.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('docs/review/verified/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  test('map labels avoid nearby markers and already placed country labels', () {
    final occupied = <Rect>[
      const Rect.fromLTWH(100, 100, 16, 16),
      const Rect.fromLTWH(80, 130, 60, 24),
    ];
    final label = findAtlasLabelRect(
      const Rect.fromLTWH(75, 100, 70, 20),
      occupied,
      1,
    );
    expect(label, isNotNull);
    expect(occupied.any((r) => r.overlaps(label!)), isFalse);
    occupied.add(label!);
    final next = findAtlasLabelRect(
      const Rect.fromLTWH(75, 100, 70, 20),
      occupied,
      1,
    );
    expect(next, isNotNull);
    expect(occupied.any((r) => r.overlaps(next!)), isFalse);
    expect(
      findAtlasLabelRect(const Rect.fromLTWH(75, 100, 70, 20), [
        const Rect.fromLTWH(-1000, -1000, 2000, 2000),
      ], 1),
      isNull,
    );
  });
  testWidgets(
    'credits builds only visible sources and shows installed version',
    (t) async {
      final s = await setup(t);
      await open(t, s, '/credits');
      expect(find.byType(SelectableText).evaluate().length, lessThan(20));
      await t.scrollUntilVisible(
        find.text('开源软件许可'),
        650,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 200,
      );
      await t.tap(find.text('开源软件许可'));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pumpAndSettle();
      expect(find.text('0.8.0+8'), findsOneWidget);
    },
  );
  testWidgets(
    'note save stays above safe area and keyboard and persists text',
    (t) async {
      final s = await setup(t);
      await open(t, s, '/me/notes/new');
      expect(find.text('保存笔记').hitTestable(), findsOneWidget);
      await t.enterText(find.byType(TextField).first, '我发现尼罗河流向北方。');
      t.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(t.view.resetViewInsets);
      await t.pumpAndSettle();
      expect(t.getRect(find.text('保存笔记')).bottom, lessThan(500));
      await t.tap(find.text('保存笔记'));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)),
      );
      await t.pumpAndSettle();
      expect(s.journal.notes.any((n) => n['text'] == '我发现尼罗河流向北方。'), isTrue);
    },
  );
  testWidgets('search tablet focus and accessible name', (t) async {
    final s = await setup(t);
    await open(t, s, '/search');
    expect(t.widget<TextField>(find.byType(TextField)).autofocus, isFalse);
    expect(
      t.widget<TextField>(find.byType(TextField)).decoration!.labelText,
      '搜索',
    );
  });
  testWidgets(
    'reader retains article title on resumed block and contains Nile diagram',
    (t) async {
      final s = await setup(t);
      final a = s.content.article('egypt-geography')!;
      await open(t, s, '/articles/${a.id}?block=${a.blocks.last.id}');
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text(a.title)),
        findsOneWidget,
      );
      expect(find.byType(LearningDiagram), findsWidgets);
    },
  );
  testWidgets(
    'country routes have first viewport titles and seven direct map entries',
    (t) async {
      final s = await setup(t);
      for (final id in ['china', 'egypt', 'usa', 'gbr']) {
        final key = GlobalKey();
        await open(t, s, '/countries/$id', capture: key);
        for (final j in s.content.country(id)!.editorial['journeys'] as List) {
          expect(
            find.text(j['title']).hitTestable(),
            findsOneWidget,
            reason: '$id ${j['title']}',
          );
        }
        await screenshot(t, key, id);
      }
      for (final id in [
        'brazil',
        'kenya',
        'norway',
        'aus',
        'fra',
        'deu',
        'zaf',
      ]) {
        await open(t, s, '/countries/$id');
        expect(
          find.byTooltip('打开${s.content.country(id)!.name}地图').hitTestable(),
          findsOneWidget,
        );
      }
    },
  );
  testWidgets(
    'pack header avoids recursive detail action and exposes explore',
    (t) async {
      final s = await setup(t);
      await open(t, s, '/packs/china');
      expect(find.text('查看'), findsNothing);
      expect(find.text('开始探索中国').hitTestable(), findsOneWidget);
    },
  );
  testWidgets('review viewport captures and scrolling endpoints', (t) async {
    final s = await setup(t);
    for (final (name, route) in [
      ('discover', '/discover'),
      ('catalog', '/encyclopedia'),
      ('journal', '/me'),
      ('parent', '/parent'),
      ('notes', '/me/notes/new'),
      ('antarctica', '/regions/antarctica'),
      ('antarctica-contents', '/regions/antarctica/contents'),
      ('antarctica-tasks', '/regions/antarctica/explore'),
    ]) {
      final key = GlobalKey();
      await open(t, s, route, capture: key);
      await screenshot(t, key, name);
      if (route.startsWith('/regions/')) {
        expect(find.byType(AtlasShell), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      }
      if (name == 'notes') continue;
      final scroller = find.byType(Scrollable).first;
      for (var i = 0; i < 8; i++) {
        await t.drag(scroller, const Offset(0, -600));
        await t.pumpAndSettle();
      }
      expect(t.takeException(), isNull, reason: name);
      await screenshot(t, key, '$name-bottom');
    }
  });
  testWidgets('reading sliders speak actual values and presets change rate', (
    t,
  ) async {
    final s = await setup(t);
    final semantics = t.ensureSemantics();
    await open(t, s, '/settings/reading');
    final sliders = find.byType(Slider);
    expect(t.getSemantics(sliders.at(0)).toStringDeep(), contains('字号 100%'));
    expect(t.getSemantics(sliders.at(1)).toStringDeep(), contains('语速 标准'));
    final fast = find.widgetWithText(TextButton, '较快');
    await t.ensureVisible(fast);
    await t.tap(fast);
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await t.pumpAndSettle();
    expect(s.preferences.speechRate, .6);
    semantics.dispose();
  });
  testWidgets(
    'resume progress has readable quantity without raw progress semantics',
    (t) async {
      final s = await setup(t);
      final a = s.content.article('egypt-geography')!;
      await t.runAsync(
        () => s.journal.recordReading(a.id, a.blocks.first.id, .35),
      );
      final semantics = t.ensureSemantics();
      await open(t, s, '/discover');
      expect(find.text('已读 35%'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^35[,，]')), findsNothing);
      semantics.dispose();
    },
  );
}
