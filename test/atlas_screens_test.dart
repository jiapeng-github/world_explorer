import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_explorer/app/atlas_app.dart';
import 'package:world_explorer/app/services.dart';
import 'package:world_explorer/data/database/atlas_database.dart';
import 'package:world_explorer/data/content/content_repository.dart';
import 'package:world_explorer/data/speech/narration_player.dart';
import 'package:world_explorer/data/speech/speech_repository.dart';
import 'package:world_explorer/map_engine/atlas_map.dart';
import 'package:world_explorer/map_engine/country_learning_map.dart';
import 'package:world_explorer/main.dart';

class _TestNarrationPlayer implements NarrationPlayer {
  @override
  Stream<void> get completed => const Stream.empty();
  @override
  Future<void> prepare(String asset, double speed) async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('NotoSansSC')
      ..addFont(rootBundle.load('assets/images/NotoSansSC.ttf'));
    await font.load();
    await AtlasGeometry.load();
    await CountryMapData.load(egyptMapProfile);
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (call) async => call.method == 'isLanguageAvailable' ? true : 1,
        );
  });
  const routes = {
    's00-welcome': '/welcome',
    's01-discover': '/discover',
    's02-map': '/atlas',
    's03-catalog': '/encyclopedia',
    's04-country': '/countries/egypt',
    's05-section': '/countries/egypt/sections/geography',
    's06-reader': '/articles/egypt-nature',
    's07-place': '/places/giza',
    's08-gallery': '/places/giza/gallery',
    's09-topics': '/topics',
    's10-topic': '/topics/rivers',
    's11-search': '/search',
    's12-results': '/search?q=尼罗河',
    's13-exercise': '/exercises/egypt-water',
    's14-feedback': '/exercises/egypt-water',
    's15-journal': '/me',
    's16-bookmarks': '/me/bookmarks',
    's17-history': '/me/history',
    's18-notes': '/me/notes',
    's19-editor': '/me/notes/new?entity=egypt-nature',
    's20-reading-settings': '/settings/reading',
    's21-parent-gate': '/parent-gate',
    's22-parent': '/parent',
    's23-packs': '/packs',
    's24-pack': '/packs/egypt',
    's25-backup': '/parent/backup',
    's26-credits': '/credits?entity=egypt',
    's27-rest': '/rest',
  };
  for (final size in [
    const Size(390, 844),
    const Size(1024, 768),
    const Size(320, 740),
  ]) {
    testWidgets('all atlas routes render at ${size.width.toInt()} pixels', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      if (size.width == 320) {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      }
      for (final entry in routes.entries) {
        final db = AtlasDatabase(NativeDatabase.memory());
        final services = await tester.runAsync(
          () => AtlasServices.load(
            database: db,
            speech: entry.key == 's06-reader'
                ? SpeechRepository(createPlayer: _TestNarrationPlayer.new)
                : null,
            migrate: false,
          ),
        );
        final capture = GlobalKey();
        try {
          await tester.pumpWidget(
            RepaintBoundary(
              key: capture,
              child: WorldAtlasApp(
                key: ValueKey(entry.key),
                services: services!,
                initialLocation: entry.value,
              ),
            ),
          );
          await tester.pump();
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await tester.pumpAndSettle();
          if (entry.key == 's06-reader') {
            await tester.runAsync(
              () => services.speech.play(
                services.content.article('egypt-nature')!,
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text('自然讲解 · 第 1 段'), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.runAsync(services.speech.pause);
            await tester.pumpAndSettle();
            expect(find.text('继续听'), findsOneWidget);
            expect(find.text('自然讲解 · 已暂停 · 第 1 段'), findsOneWidget);
          }
          if (entry.key == 's14-feedback') {
            final exercise = services.content.exercise('egypt-water')!;
            final answer =
                exercise.options.firstWhere(
                      (o) => o['id'] == exercise.answerId,
                    )['text']
                    as String;
            await tester.ensureVisible(find.text(answer));
            await tester.tap(find.text(answer));
            await tester.pumpAndSettle();
            await tester.tap(find.text('确认'));
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 100)),
            );
            await tester.pumpAndSettle();
            expect(find.text('你找到了关键线索！'), findsOneWidget);
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} at $size',
          );
          if (size.width != 320 &&
              const bool.fromEnvironment('CAPTURE_SCREENS')) {
            final boundary =
                capture.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 2);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              final file = File(
                'docs/redesign/implemented/${size.width.toInt()}/${entry.key}.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
            });
          }
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          await tester.runAsync(services!.dispose);
        }
      }
    });
  }
  testWidgets('search opens a real article and bookmarks persist', (
    tester,
  ) async {
    final services = await tester.runAsync(
      () => AtlasServices.load(
        database: AtlasDatabase(NativeDatabase.memory()),
        content: null,
        migrate: false,
      ),
    );
    await tester.pumpWidget(
      WorldAtlasApp(services: services!, initialLocation: '/search?q=尼罗河'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('尼罗河为什么重要？').first);
    await tester.pumpAndSettle();
    expect(find.text('词语解释'), findsNothing);
    await tester.tap(find.text('收藏').first);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(services.journal.saved('article', 'egypt-nature'), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(services.dispose);
  });

  testWidgets('bootstrap retains a deep link while local data is loading', (
    tester,
  ) async {
    final services = await tester.runAsync(
      () => AtlasServices.load(
        database: AtlasDatabase(NativeDatabase.memory()),
        migrate: false,
      ),
    );
    tester.platformDispatcher.defaultRouteNameTestValue = '/countries/egypt';
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    final ready = Completer<AtlasServices>();
    await tester.pumpWidget(AtlasBootstrap(loadServices: () => ready.future));
    await tester.pump();
    expect(find.text('正在打开世界图鉴…'), findsOneWidget);
    ready.complete(services!);
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('先认识埃及'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(services.dispose);
  });

  testWidgets('world map zoom uses its two dimensional scale below one', (
    tester,
  ) async {
    final content = await tester.runAsync(ContentRepository.load);
    final controller = AtlasMapController();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: AtlasMap(
              countries: content!.countries,
              controller: controller,
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    AtlasPainter painter() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<AtlasPainter>()
        .single;
    expect(painter().scale, closeTo(400 / 1800, .00001));
    controller.zoom(1.5);
    await tester.pumpAndSettle();
    expect(painter().scale, closeTo(600 / 1800, .00001));
    await tester.pumpWidget(const SizedBox.shrink());
    content.dispose();
  });
}
