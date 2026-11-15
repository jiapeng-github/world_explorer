import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_explorer/data/content/content_repository.dart';
import 'package:world_explorer/map_engine/atlas_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  setUpAll(() async {
    content = ContentRepository.fromJson(
      jsonDecode(File('assets/atlas/catalog.json').readAsStringSync()),
    );
    await (FontLoader(
      'NotoSansSC',
    )..addFont(rootBundle.load('assets/images/NotoSansSC.ttf'))).load();
  });
  test(
    'both map resolutions group Taiwan into China without a separate entity',
    () {
      for (final file in ['countries.geojson', 'countries-detail.geojson']) {
        final features =
            jsonDecode(
                  File('assets/atlas/$file').readAsStringSync(),
                )['features']
                as List;
        expect(features.any((f) => f['properties']['id'] == 'twn'), false);
        final china = features.singleWhere(
          (f) => f['properties']['id'] == 'china',
        );
        final path = AtlasGeometry.path(china['geometry']);
        expect(path.contains(project(23.7, 121)), true, reason: file);
        expect(path.contains(project(39.9, 116.4)), true, reason: file);
        expect(
          File('assets/atlas/$file').readAsStringSync(),
          isNot(contains('中华民国')),
        );
      }
      expect(content.countries.any((c) => c.id == 'twn'), false);
      expect(content.country('twn')?.id, 'china');
      for (final term in ['台湾', 'Taiwan', '钓鱼岛']) {
        final hits = content.search(term);
        expect(hits, isNotEmpty);
        expect(hits.any((h) => h.countryId == 'china'), true);
        expect(
          hits.any((h) => h.route == '/countries/twn' || h.title == '中华民国'),
          false,
        );
      }
    },
  );
  testWidgets('Taiwan and Diaoyu taps select China on the world map', (
    t,
  ) async {
    t.view.physicalSize = const Size(1194, 834);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.runAsync(AtlasGeometry.load);
    final key = GlobalKey();
    String? picked;
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'NotoSansSC'),
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: AtlasMap(
              countries: content.countries,
              selectedId: 'china',
              initialCountry: content.country('china'),
              onCountry: (id) => picked = id,
            ),
          ),
        ),
      ),
    );
    await t.pump();
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await t.pumpAndSettle();
    final viewer = t.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    for (final p in [
      project(23.7, 121),
      project(25.7433333333, 123.4733333333),
    ]) {
      final local = MatrixUtils.transformPoint(
        viewer.transformationController!.value,
        p,
      );
      await t.tapAt(t.getTopLeft(find.byType(InteractiveViewer)) + local);
      await t.pump();
      expect(picked, 'china');
      picked = null;
    }
    expect(t.takeException(), isNull);
    if (const bool.fromEnvironment('CAPTURE_CHINA_IDENTITY')) {
      await t.runAsync(() async {
        final im =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
        final f = File('docs/regions/china-map-fix/world-map.png');
        await f.parent.create(recursive: true);
        await f.writeAsBytes(bytes!.buffer.asUint8List());
        im.dispose();
      });
    }
    await t.pumpWidget(const SizedBox());
  });
}
