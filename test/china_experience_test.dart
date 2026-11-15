import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_explorer/app/atlas_app.dart';
import 'package:world_explorer/app/services.dart';
import 'package:world_explorer/data/content/content_repository.dart';
import 'package:world_explorer/data/database/atlas_database.dart';
import 'package:world_explorer/data/database/user_repositories.dart';
import 'package:world_explorer/map_engine/atlas_map.dart';
import 'package:world_explorer/map_engine/country_learning_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final item in [
      ('NotoSansSC', 'assets/images/NotoSansSC.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      final loader = FontLoader(item.$1)..addFont(rootBundle.load(item.$2));
      await loader.load();
    }
    await AtlasGeometry.load();
    await CountryMapData.load();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (call) async => call.method == 'isLanguageAvailable' ? true : 1,
        );
  });

  Future<AtlasServices> services(WidgetTester tester) async =>
      (await tester.runAsync(
        () => AtlasServices.load(
          database: AtlasDatabase(NativeDatabase.memory()),
          migrate: false,
        ),
      ))!;
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  final routes = {
    'cn01-overview': '/countries/china',
    'cn02-directory': '/countries/china/contents',
    'cn03-map': '/atlas?country=china&place=jiuzhaigou',
    'cn04-journey': '/countries/china/journeys/mountains',
    'cn05-geography': '/articles/china-geography',
    'cn06-landmark': '/places/great-wall',
    'cn07-timeline': '/countries/china/timeline',
    'cn08-culture': '/articles/china-culture',
    'cn09-daily': '/countries/china/sections/daily',
    'cn10-nature': '/articles/china-nature',
    'cn11-explore': '/countries/china/explore',
    'cn12-discoveries': '/me/countries/china',
    'cn13-observation': '/countries/china/observe/china-explore',
    'cn14-map-question': '/exercises/china-location',
  };
  for (final config in [
    (const Size(390, 844), 1.0),
    (const Size(1194, 834), 1.0),
    (const Size(390, 844), 1.5),
  ]) {
    testWidgets(
      'China routes fit ${config.$1.width} at text scale ${config.$2}',
      (tester) async {
        tester.view.physicalSize = config.$1;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = config.$2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final app = await services(tester);
        try {
          for (final route in routes.entries) {
            final boundary = GlobalKey();
            await tester.pumpWidget(
              RepaintBoundary(
                key: boundary,
                child: WorldAtlasApp(
                  key: ValueKey(route.key),
                  services: app,
                  initialLocation: route.value,
                ),
              ),
            );
            await settle(tester);
            expect(
              tester.takeException(),
              isNull,
              reason: '${route.key} first screen',
            );
            // Reach the footer, where long translated labels and adaptive grids
            // are most likely to overflow on a large text scale.
            final scrollable = find.byType(Scrollable).first;
            if (!route.key.contains('map')) {
              await tester.drag(scrollable, const Offset(0, -650));
              await settle(tester);
              expect(
                tester.takeException(),
                isNull,
                reason: '${route.key} scrolled',
              );
            }
            if (const bool.fromEnvironment('CAPTURE_CHINA') && config.$2 == 1) {
              if (!route.key.contains('map')) {
                await tester.drag(scrollable, const Offset(0, 2000));
                await settle(tester);
              }
              await tester.runAsync(() async {
                final image =
                    await (boundary.currentContext!.findRenderObject()
                            as RenderRepaintBoundary)
                        .toImage(pixelRatio: 2);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                image.dispose();
                final file = File(
                  'docs/countries/china/implemented/${config.$1.width.toInt()}/${route.key}.png',
                );
                await file.parent.create(recursive: true);
                await file.writeAsBytes(bytes!.buffer.asUint8List());
              });
            }
          }
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          await tester.runAsync(app.dispose);
        }
      },
    );
  }

  testWidgets('reader sheets remain usable on a short screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final app = await services(tester);
    try {
      await tester.pumpWidget(
        WorldAtlasApp(
          services: app,
          initialLocation: '/articles/china-geography',
        ),
      );
      await settle(tester);
      await tester.tap(find.text('目录'));
      await settle(tester);
      final last = app.content.article('china-geography')!.blocks.last;
      await tester.scrollUntilVisible(
        find.text(last.title).last,
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(last.title).last);
      await settle(tester);
      final term = app.content.article('china-geography')!.term;
      await tester.scrollUntilVisible(
        find.text('认识一个词：$term'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('认识一个词：$term'));
      await settle(tester);
      await tester.scrollUntilVisible(
        find.text('我明白了'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('我明白了'));
      await settle(tester);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester);
      await tester.runAsync(app.dispose);
    }
  });

  testWidgets(
    'open observation saves actual text once and appears in country journal',
    (tester) async {
      final app = await services(tester);
      await tester.pumpWidget(
        WorldAtlasApp(
          services: app,
          initialLocation: '/countries/china/observe/china-explore',
        ),
      );
      await settle(tester);
      expect(app.journal.notes, isEmpty);
      await tester.enterText(find.byType(TextField).at(0), '长城跟着山脊起伏');
      await tester.enterText(find.byType(TextField).at(1), '这样可能看得更远');
      await tester.enterText(find.byType(TextField).at(2), '材料怎样运上山？');
      await tester.tap(find.text('保存我的发现'));
      await settle(tester);
      expect(app.journal.notes, hasLength(1));
      expect(app.journal.notes.single['text'], contains('我猜想：这样可能看得更远'));
      expect(app.journal.notes.single['question'], '材料怎样运上山？');
      expect(find.text('我的中国发现'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(app.dispose);
    },
  );

  testWidgets(
    'an observation draft survives leaving and deleting a saved note can be undone',
    (tester) async {
      final app = await services(tester);
      try {
        await tester.pumpWidget(
          WorldAtlasApp(
            key: const ValueKey('draft-1'),
            services: app,
            initialLocation: '/countries/china/observe/china-explore',
          ),
        );
        await settle(tester);
        await tester.enterText(find.byType(TextField).at(0), '湖水旁边有树林');
        await tester.pumpWidget(const SizedBox.shrink());
        await settle(tester);
        expect(app.journal.notes, isEmpty);
        await tester.pumpWidget(
          WorldAtlasApp(
            key: const ValueKey('draft-2'),
            services: app,
            initialLocation: '/countries/china/observe/china-explore',
          ),
        );
        await settle(tester);
        expect(
          tester
              .widget<TextField>(find.byType(TextField).first)
              .controller!
              .text,
          '湖水旁边有树林',
        );
        await tester.tap(find.text('保存我的发现'));
        await settle(tester);
        final id = app.journal.notes.single['id'];
        await tester.pumpWidget(
          WorldAtlasApp(
            key: const ValueKey('note-delete'),
            services: app,
            initialLocation: '/me/notes/$id/edit',
          ),
        );
        await settle(tester);
        await tester.tap(find.byTooltip('删除笔记'));
        await settle(tester);
        await tester.tap(find.widgetWithText(TextButton, '删除笔记'));
        await settle(tester);
        expect(app.journal.notes, isEmpty);
        await tester.tap(find.text('撤销'));
        await settle(tester);
        expect(app.journal.notes.single['id'], id);
        expect(app.journal.notes.single['text'], contains('湖水旁边有树林'));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await settle(tester);
        await tester.runAsync(app.dispose);
      }
    },
  );

  testWidgets(
    'map question requires selection and evidence opens the correct block',
    (tester) async {
      final app = await services(tester);
      final exercise = app.content.exercise('china-location')!;
      await tester.pumpWidget(
        WorldAtlasApp(
          services: app,
          initialLocation: '/exercises/china-location',
        ),
      );
      await settle(tester);
      expect(find.byType(CountryLearningMap), findsOneWidget);
      final answer = exercise.options.firstWhere(
        (o) => o['id'] == exercise.answerId,
      );
      final tile = find.widgetWithText(RadioListTile<String>, answer['text']);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      await tester.tap(find.text('看看我的想法'));
      await settle(tester);
      expect(app.journal.attempts[exercise.id]?['correct'], 1);
      await tester.ensureVisible(find.text('回读相关内容  →'));
      await tester.tap(find.text('回读相关内容  →'));
      await settle(tester);
      expect(
        find.text(
          app.content
              .article(exercise.articleId)!
              .blocks
              .firstWhere((b) => b.id == exercise.evidenceBlockIds.first)
              .title,
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(app.dispose);
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
      'china-nature',
      'china-nature-b2',
      .8,
      completed: true,
    );
    await journal.toggle('article', 'china-nature', '旧版熊猫');
    await journal.saveNote(
      id: 'kept',
      kind: 'discovery',
      text: '我的旧发现',
      question: '',
      entityId: 'china-nature',
      title: '旧版标题快照',
    );
    await journal.reconcileContent(content);
    expect(journal.progress['china-nature']?['completed'], 0);
    expect(
      journal.progress['china-nature']?['block_id'],
      content.article('china-nature')!.blocks.first.id,
    );
    expect(journal.bookmarks, hasLength(1));
    expect(journal.notes.single['title'], '旧版标题快照');
    expect(
      (await db.preferences()).keys.any(
        (key) => key.startsWith('reading-archive-china-nature'),
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
            (raw['countries'] as List).firstWhere((c) => c['id'] == 'china'),
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
    expect(content.articlesIn('china'), hasLength(30));
    expect(content.country('china')!.editorial, isNotEmpty);
    content.dispose();
  });
}
