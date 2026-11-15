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
import 'package:world_explorer/domain/atlas_content.dart';
import 'package:world_explorer/map_engine/atlas_map.dart';
import 'package:world_explorer/map_engine/country_learning_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('NotoSansSC')
      ..addFont(rootBundle.load('assets/images/NotoSansSC.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (call) async => call.method == 'isLanguageAvailable' ? true : 1,
        );
  });

  test('China river assets retain detailed source lines and provenance', () {
    final raw = jsonDecode(
      File('assets/atlas/china-rivers.geojson').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(raw['sourceVersion'], isNotEmpty);
    expect(raw['sourceArchiveSha256'], matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(raw['license'], 'Public domain');
    final rivers = CountryMapData.parseRivers(raw);
    expect(rivers.map((r) => r.id).toSet(), {'yangtze', 'yellow-river'});
    for (final river in rivers) {
      expect(river.lines.expand((l) => l).length, greaterThan(1000));
      expect(river.bounds.width, greaterThan(100));
      final vertex = river.lines.firstWhere((line) => line.length > 10)[10];
      expect(river.distanceTo(vertex), closeTo(0, 1e-8));
      expect(river.distanceTo(project(0, 0)), greaterThan(100));
    }
  });

  test('river hit testing does not bridge separate source segments', () {
    final river = CountryWaterway('example', '示意', [
      [const Offset(0, 0), const Offset(10, 0)],
      [const Offset(20, 0), const Offset(30, 0)],
    ]);
    expect(river.distanceTo(const Offset(15, 0)), 5);
    expect(river.distanceTo(const Offset(7, 3)), 3);
  });

  test(
    'nearby landmarks cluster by geographic screen distance and expand on zoom',
    () {
      AtlasPlace place(String id, double latitude, double longitude) =>
          AtlasPlace(
            id: id,
            countryId: 'china',
            name: id,
            category: '地点',
            latitude: latitude,
            longitude: longitude,
            summary: '',
            description: '',
            observation: '',
            mediaIds: const [],
            sourceUrl: '',
          );
      final places = [
        place('beijing-a', 39.9, 116.4),
        place('beijing-b', 40.7, 117.2),
        place('hangzhou', 30.3, 120.2),
      ];
      final clustered = clusterMapPlaces(places, 2);
      expect(clustered.map((c) => c.places.length), [2, 1]);
      expect(clusterMapPlaces(places, 10).length, 3);
      expect(clusterMapPlaces(places, 2, selectedId: 'beijing-a').length, 3);
    },
  );

  testWidgets(
    'river selection follows source geometry and excludes disallowed answers',
    (tester) async {
      final data = await tester.runAsync(CountryMapData.load);
      final controller = CountryMapController();
      final allowed = ValueNotifier<Set<String>>(const {'yangtze'});
      String? chosen;
      var clears = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 500,
              child: ValueListenableBuilder<Set<String>>(
                valueListenable: allowed,
                builder: (context, ids, _) => CountryLearningMap(
                  countries: const [],
                  controller: controller,
                  allowedIds: ids,
                  layer: '河流',
                  showControls: false,
                  onSelect: (id) => chosen = id,
                  onClear: () => clears++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      final yangtze = data!.rivers.firstWhere((r) => r.id == 'yangtze');
      final actualRiverPoint = yangtze.nearestVertex(project(30.5, 112));
      final tapPoint =
          tester.getTopLeft(find.byType(CountryLearningMap)) +
          MatrixUtils.transformPoint(controller.camera!, actualRiverPoint) +
          const Offset(0, 5);
      await tester.tapAt(tapPoint);
      await tester.pumpAndSettle();
      expect(
        chosen,
        'yangtze',
        reason: 'A thin real river can be tapped with screen-space tolerance',
      );
      chosen = null;
      allowed.value = const {'yellow-river'};
      await tester.pumpAndSettle();
      await tester.tapAt(tapPoint);
      await tester.pumpAndSettle();
      expect(chosen, isNull);
      expect(clears, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      allowed.dispose();
    },
  );

  for (final size in [
    const Size(320, 100),
    const Size(390, 330),
    const Size(700, 500),
  ]) {
    testWidgets(
      'full China extent fits a ${size.width} by ${size.height} viewport',
      (tester) async {
        await tester.runAsync(CountryMapData.load);
        final controller = CountryMapController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: CountryLearningMap(
                    countries: const [],
                    controller: controller,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        final mapRect = tester.getRect(find.byType(CountryLearningMap));
        final camera = controller.camera!;
        for (final point in [
          project(55, 72),
          project(3, 138),
          project(25, 122),
          project(18, 109),
        ]) {
          expect(
            (Offset.zero & size).contains(
              MatrixUtils.transformPoint(camera, point),
            ),
            isTrue,
            reason: 'The source range including Taiwan, Hainan and southern sea context must fit',
          );
        }
        for (final tooltip in ['放大中国地图', '缩小中国地图', '显示中国全图']) {
          expect(
            mapRect.contains(tester.getCenter(find.byTooltip(tooltip))),
            isTrue,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'real geographic selection works and layer changes retain camera',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final content = ContentRepository.fromJson(
        jsonDecode(File('assets/atlas/catalog.json').readAsStringSync()),
      );
      final controller = CountryMapController();
      final layer = ValueNotifier('地形');
      String? chosen;
      await tester.runAsync(CountryMapData.load);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 600,
                height: 500,
                child: ValueListenableBuilder<String>(
                  valueListenable: layer,
                  builder: (context, value, _) => CountryLearningMap(
                    countries: content.countries,
                    places: content.places,
                    controller: controller,
                    allowedIds: const {'beijing'},
                    layer: value,
                    showControls: false,
                    onSelect: (id) => chosen = id,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(controller.camera, isNotNull);
      final city = chinaMapFeatures.firstWhere((f) => f.id == 'beijing');
      final offset = MatrixUtils.transformPoint(controller.camera!, city.point);
      final origin = tester.getTopLeft(find.byType(CountryLearningMap));
      await tester.tapAt(origin + offset);
      await tester.pumpAndSettle();
      expect(chosen, 'beijing');
      controller.zoom(1.4);
      await tester.pumpAndSettle();
      final camera = controller.camera!.storage.toList();
      layer.value = '河流';
      await tester.pumpAndSettle();
      expect(controller.camera!.storage.toList(), camera);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      content.dispose();
      layer.dispose();
    },
  );

  for (final size in [
    const Size(390, 844),
    const Size(1024, 768),
    const Size(1194, 834),
    const Size(320, 740),
  ]) {
    testWidgets('China screen sheets and list remain usable at ${size.width}', (
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
      final services = await tester.runAsync(
        () => AtlasServices.load(
          database: AtlasDatabase(NativeDatabase.memory()),
          migrate: false,
        ),
      );
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: WorldAtlasApp(
            services: services!,
            initialLocation: '/atlas?country=china',
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('CAPTURE_CHINA_MAP')) {
        final boundary =
            capture.currentContext!.findRenderObject() as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          await File('/tmp/china-map-${size.width.toInt()}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
        });
      }
      expect(
        find.byType(DraggableScrollableSheet),
        size.width < 1024 ? findsOneWidget : findsNothing,
      );
      final initialHeight = tester
          .getSize(find.byType(CountryLearningMap))
          .height;
      if (size.width == 390) {
        await tester.tap(find.byTooltip('放大中国地图'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('走进九寨沟'));
        await tester.pumpAndSettle();
        final mapController = tester
            .widget<CountryLearningMap>(find.byType(CountryLearningMap))
            .controller!;
        final savedCamera = mapController.camera!.storage.toList();
        await tester.tap(find.text('走进九寨沟'));
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('返回'));
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        expect(
          mapController.camera!.storage.toList(),
          savedCamera,
          reason: 'Opening a place and returning must preserve the map camera',
        );
      }
      if (size.width < 1024) {
        final sheetList = find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.byType(ListView),
        );
        tester
            .state<ScrollableState>(
              find
                  .descendant(of: sheetList, matching: find.byType(Scrollable))
                  .first,
            )
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        await tester.dragFrom(
          tester.getTopLeft(sheetList) + Offset(size.width / 2, 22),
          const Offset(0, -250),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(CountryLearningMap)).height,
          lessThan(initialHeight),
        );
        final mapRect = tester.getRect(find.byType(CountryLearningMap));
        expect(
          mapRect.contains(tester.getCenter(find.byTooltip('显示中国全图'))),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byTooltip('收起地点'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('中国地点列表'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('长江').first);
      await tester.pumpAndSettle();
      expect(find.text('长江'), findsOneWidget);
      expect(
        tester.getSize(find.byType(CountryLearningMap)).height,
        closeTo(initialHeight, 1),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(services.dispose);
    });
  }
}
