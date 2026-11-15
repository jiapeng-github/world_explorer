import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/atlas_theme.dart';
import '../domain/atlas_content.dart';

const worldSize = Size(1800, 900);
Offset project(double lat, double lon) =>
    Offset((lon + 180) * 5, (90 - lat) * 5);

class CountryShape {
  CountryShape(this.id, this.path) : bounds = path.getBounds();
  final String id;
  final Path path;
  final Rect bounds;
  bool contains(Offset p) => bounds.contains(p) && path.contains(p);
}

class AtlasGeometry {
  AtlasGeometry(
    this.countries,
    this.rivers,
    this.lakes,
    this.relief, {
    this.detail = const [],
  }) {
    for (final c in countries) {
      land.addPath(c.path, Offset.zero);
    }
    for (final c in detail) {
      detailLand.addPath(c.path, Offset.zero);
    }
  }
  final List<CountryShape> countries;
  final List<CountryShape> detail;
  final Path land = Path(), detailLand = Path();
  final Path rivers, lakes;
  final ui.Image? relief;
  static Future<AtlasGeometry>? _cache;
  static Future<AtlasGeometry> load() => _cache ??= _read();
  static Path path(Json geometry, {bool line = false}) {
    final type = geometry['type'];
    final coords = geometry['coordinates'] as List;
    final polygons = type == 'MultiPolygon'
        ? coords
        : type == 'Polygon'
        ? [coords]
        : type == 'MultiLineString'
        ? [coords]
        : [
            [coords],
          ];
    final path = Path()..fillType = PathFillType.evenOdd;
    for (final polygon in polygons) {
      for (final ring in polygon as List) {
        Offset? last;
        for (final coordinate in ring as List) {
          final point = project(
            (coordinate[1] as num).toDouble(),
            (coordinate[0] as num).toDouble(),
          );
          if (last == null ||
              (last.dx - point.dx).abs() > worldSize.width / 2) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
          last = point;
        }
        if (!line) path.close();
      }
    }
    return path;
  }

  static Future<AtlasGeometry> _read() async {
    final data = await Future.wait(
      [
        'assets/atlas/countries.geojson',
        'assets/maps/world-rivers_lake_centerlines.geojson',
        'assets/maps/world-lakes.geojson',
        'assets/atlas/countries-detail.geojson',
      ].map(rootBundle.loadString),
    );
    final countries = <CountryShape>[];
    for (final f in jsonDecode(data[0])['features'] as List) {
      countries.add(CountryShape(f['properties']['id'], path(f['geometry'])));
    }
    final rivers = Path(), lakes = Path();
    for (final f in jsonDecode(data[1])['features'] as List) {
      rivers.addPath(path(f['geometry'], line: true), Offset.zero);
    }
    for (final f in jsonDecode(data[2])['features'] as List) {
      lakes.addPath(path(f['geometry']), Offset.zero);
    }
    ui.Image? relief;
    try {
      final bytes = await rootBundle.load('assets/atlas/earth-relief.jpg');
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(),
        targetWidth: 3600,
      );
      relief = (await codec.getNextFrame()).image;
      codec.dispose();
    } catch (_) {
      /* Vector geography remains usable offline. */
    }
    final detail = <CountryShape>[
      for (final f in jsonDecode(data[3])['features'] as List)
        CountryShape(f['properties']['id'], path(f['geometry'])),
    ];
    return AtlasGeometry(countries, rivers, lakes, relief, detail: detail);
  }
}

class AtlasMapController {
  _AtlasMapState? _state;
  void focus(double lat, double lon, {double zoom = 3.6}) =>
      _state?.focus(lat, lon, zoom);
  void zoom(double factor) => _state?.zoom(factor);
  void reset() => _state?.reset();
}

class AtlasMap extends StatefulWidget {
  const AtlasMap({
    super.key,
    required this.countries,
    this.places = const [],
    this.selectedId,
    this.onCountry,
    this.onPlace,
    this.onOcean,
    this.layer = '国家',
    this.controller,
    this.initialCountry,
    this.showControls = true,
    this.related = const [],
    this.candidateIds = const [],
  });
  final List<AtlasCountry> countries;
  final List<AtlasPlace> places;
  final String? selectedId;
  final AtlasCountry? initialCountry;
  final ValueChanged<String>? onCountry, onPlace;
  final VoidCallback? onOcean;
  final String layer;
  final AtlasMapController? controller;
  final bool showControls;
  final List<AtlasCountry> related;
  final List<String> candidateIds;
  @override
  State<AtlasMap> createState() => _AtlasMapState();
}

class _AtlasMapState extends State<AtlasMap> {
  final transform = TransformationController();
  late final Future<AtlasGeometry> geometry = AtlasGeometry.load();
  Size viewport = Size.zero;
  bool initialized = false;
  double scale = 1;
  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    transform.addListener(_changed);
  }

  @override
  void didUpdateWidget(AtlasMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
  }

  void _changed() {
    if (mounted) setState(() => scale = transform.value.entry(0, 0).abs());
  }

  double get minimumScale => math.min(
    viewport.width / worldSize.width,
    viewport.height / worldSize.height,
  );
  void reset() => focus(12, 5, 1);
  void focus(double lat, double lon, double zoom) {
    if (viewport == Size.zero) return;
    final point = project(lat, lon),
        s = (minimumScale * zoom).clamp(minimumScale, 12.0);
    final x = worldSize.width * s <= viewport.width
        ? (viewport.width - worldSize.width * s) / 2
        : (viewport.width / 2 - point.dx * s).clamp(
            math.min(0.0, viewport.width - worldSize.width * s),
            0.0,
          );
    final y = worldSize.height * s <= viewport.height
        ? (viewport.height - worldSize.height * s) / 2
        : (viewport.height / 2 - point.dy * s).clamp(
            math.min(0.0, viewport.height - worldSize.height * s),
            0.0,
          );
    transform.value = Matrix4.identity()
      ..translateByDouble(x.toDouble(), y.toDouble(), 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  void zoom(double factor) {
    final current = transform.toScene(
      Offset(viewport.width / 2, viewport.height / 2),
    );
    focus(
      90 - current.dy / 5,
      current.dx / 5 - 180,
      scale * factor / minimumScale,
    );
  }

  void _hit(Offset point, AtlasGeometry data) {
    if ((widget.selectedId == 'china' || scale > 1.5) &&
        (widget.candidateIds.isEmpty ||
            widget.candidateIds.contains('china')) &&
        (project(25.7433333333, 123.4733333333) - point).distance * scale <
            16) {
      widget.onCountry?.call('china');
      return;
    }
    if (widget.candidateIds.isNotEmpty) {
      final candidates =
          widget.countries
              .where((c) => widget.candidateIds.contains(c.id))
              .toList()
            ..sort(
              (a, b) => (project(a.latitude, a.longitude) - point)
                  .distanceSquared
                  .compareTo(
                    (project(b.latitude, b.longitude) - point).distanceSquared,
                  ),
            );
      final nearest = candidates.firstOrNull;
      if (nearest != null &&
          (project(nearest.latitude, nearest.longitude) - point).distance *
                  scale <
              22) {
        widget.onCountry?.call(nearest.id);
        return;
      }
    }
    if (widget.layer == '地标' || widget.selectedId != null) {
      for (final p in widget.places.reversed) {
        if (widget.layer != '地标' && p.countryId != widget.selectedId) continue;
        if ((project(p.latitude, p.longitude) - point).distance * scale < 24) {
          widget.onPlace?.call(p.id);
          return;
        }
      }
    }
    final shapes = scale >= 1 && data.detail.isNotEmpty
        ? data.detail
        : data.countries;
    final shape = shapes.reversed.where((s) => s.contains(point)).firstOrNull;
    if (shape != null &&
        (widget.candidateIds.isEmpty ||
            widget.candidateIds.contains(shape.id))) {
      widget.onCountry?.call(shape.id);
    } else {
      widget.onOcean?.call();
    }
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    transform.removeListener(_changed);
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final next = Size(constraints.maxWidth, constraints.maxHeight);
      if (next != viewport) {
        viewport = next;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!initialized) {
            initialized = true;
            final c = widget.initialCountry;
            final cover = math.max(
              viewport.width / worldSize.width,
              viewport.height / worldSize.height,
            );
            c == null
                ? reset()
                : focus(
                    c.latitude - 8,
                    c.longitude - 5,
                    2.6 * cover / minimumScale,
                  );
          } else {
            zoom(1);
          }
        });
      }
      return FutureBuilder<AtlasGeometry>(
        future: geometry,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('地图暂时无法载入，请从百科目录选择国家。'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: AtlasPalette.sea,
                  child: InteractiveViewer(
                    transformationController: transform,
                    constrained: false,
                    minScale: minimumScale,
                    maxScale: 12,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    onInteractionEnd: (_) => zoom(1),
                    child: GestureDetector(
                      onTapUp: (d) => _hit(d.localPosition, data),
                      child: RepaintBoundary(
                        child: CustomPaint(
                          size: worldSize,
                          painter: AtlasPainter(
                            data: data,
                            scale: scale,
                            countries: widget.countries,
                            places: widget.places,
                            selectedId: widget.selectedId,
                            layer: widget.layer,
                            related: widget.related,
                            candidateIds: widget.candidateIds,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 8,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    color: Colors.white.withValues(alpha: .87),
                    child: Text(
                      viewport.width < 240
                          ? 'Natural Earth · NASA'
                          : 'Natural Earth · NASA  |  北 ↑',
                      style: TextStyle(
                        fontSize: viewport.width < 240 ? 8 : 10,
                        color: AtlasPalette.navy,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.showControls)
                Positioned(
                  right: 14,
                  bottom: 36,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 2,
                    child: Column(
                      children: [
                        IconButton(
                          tooltip: '放大地图',
                          onPressed: () => zoom(1.5),
                          icon: const Icon(Icons.add),
                        ),
                        IconButton(
                          tooltip: '缩小地图',
                          onPressed: () => zoom(1 / 1.5),
                          icon: const Icon(Icons.remove),
                        ),
                        IconButton(
                          tooltip: '查看全世界',
                          onPressed: reset,
                          icon: const Icon(Icons.public),
                        ),
                      ],
                    ),
                  ),
                ),
              if (widget.showControls &&
                  viewport.width >= 540 &&
                  viewport.height >= 440)
                Positioned(
                  left: 14,
                  bottom: 44,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final item in [
                            ('国家边界', const Color(0xFF8D9CAD)),
                            ('河流', const Color(0xFF208DC5)),
                            ('湖泊', const Color(0xFF6DB2D9)),
                          ])
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 24,
                                    height: item.$1 == '湖泊' ? 10 : 2,
                                    color: item.$2,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    item.$1,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AtlasPalette.navy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    },
  );
}

class AtlasPainter extends CustomPainter {
  AtlasPainter({
    required this.data,
    required this.scale,
    required this.countries,
    required this.places,
    required this.selectedId,
    required this.layer,
    required this.related,
    this.candidateIds = const [],
  });
  final AtlasGeometry data;
  final double scale;
  final List<AtlasCountry> countries, related;
  final List<AtlasPlace> places;
  final String? selectedId;
  final String layer;
  final List<String> candidateIds;
  final List<Rect> _labelBounds = [];
  @override
  void paint(Canvas canvas, Size size) {
    _labelBounds.clear();
    final detailed = scale >= 1 && data.detail.isNotEmpty;
    final shapes = detailed ? data.detail : data.countries;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF85C5E6),
    );
    if (data.relief != null) {
      canvas.save();
      canvas.clipPath(detailed ? data.detailLand : data.land);
      canvas.drawImageRect(
        data.relief!,
        Rect.fromLTWH(
          0,
          0,
          data.relief!.width.toDouble(),
          data.relief!.height.toDouble(),
        ),
        Offset.zero & size,
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: .23),
      );
      canvas.restore();
    }
    for (final c in shapes) {
      if (data.relief == null) {
        canvas.drawPath(c.path, Paint()..color = AtlasPalette.land);
      }
      canvas.drawPath(
        c.path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7 / scale
          ..color = Colors.white.withValues(alpha: .8),
      );
    }
    canvas.drawPath(data.lakes, Paint()..color = const Color(0xFF6DB2D9));
    canvas.drawPath(
      data.rivers,
      Paint()
        ..color = const Color(0xFF208DC5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (layer == '自然' ? 1.4 : .85) / scale,
    );
    final selected = shapes.where((c) => c.id == selectedId).firstOrNull;
    if (selected != null) {
      canvas.drawPath(
        selected.path,
        Paint()..color = AtlasPalette.orange.withValues(alpha: .58),
      );
      canvas.drawPath(
        selected.path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 / scale
          ..color = AtlasPalette.navy,
      );
    }
    if (related.length > 1) {
      final path = Path();
      for (var i = 0; i < related.length; i++) {
        final p = project(related[i].latitude, related[i].longitude);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = AtlasPalette.navy.withValues(alpha: .6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 / scale,
      );
    }
    for (final label in const [
      ('非洲', 4.0, 16.0),
      ('欧洲', 53.0, 20.0),
      ('亚洲', 48.0, 90.0),
      ('北美洲', 44.0, -106.0),
      ('南美洲', -18.0, -60.0),
      ('大洋洲', -26.0, 135.0),
      ('南极洲', -78.0, 30.0),
    ]) {
      _label(
        canvas,
        label.$1,
        project(label.$2, label.$3),
        19,
        AtlasPalette.navy,
      );
    }
    for (final label in const [
      ('大西洋', 2.0, -30.0),
      ('印度洋', -17.0, 77.0),
      ('太平洋', 0.0, -145.0),
      ('地中海', 35.0, 17.0),
    ]) {
      _label(canvas, label.$1, project(label.$2, label.$3), 13, Colors.white);
    }
    if (layer == '地标' || selectedId != null) {
      for (final p in places) {
        if (layer != '地标' && p.countryId != selectedId) continue;
        if (scale < .8 && p.countryId != selectedId) continue;
        final point = project(p.latitude, p.longitude);
        canvas.drawCircle(
          point,
          6 / scale,
          Paint()..color = AtlasPalette.orange,
        );
        canvas.drawCircle(
          point,
          6 / scale,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 / scale
            ..color = Colors.white,
        );
        _labelBounds.add(Rect.fromCircle(center: point, radius: 8 / scale));
      }
    }
    final labels = countries.where(
      (c) => candidateIds.isNotEmpty
          ? candidateIds.contains(c.id)
          : c.id == selectedId ||
                related.any((r) => r.id == c.id) ||
                (scale > 1.5 && c.hasArticles),
    );
    for (final c in labels) {
      final point = project(c.latitude, c.longitude);
      _label(
        canvas,
        candidateIds.isEmpty ? c.name : '${candidateIds.indexOf(c.id) + 1}',
        point,
        c.id == selectedId ? 18 : 13,
        AtlasPalette.navy,
        halo: true,
        avoidCollisions: true,
      );
    }
    // Taiwan is already part of the China polygon. The small island uses an
    // unlabelled minimum-size symbol because the overview geometry omits it.
    if ((selectedId == 'china' || scale > 1.5) && candidateIds.isEmpty) {
      canvas.drawCircle(
        project(25.7433333333, 123.4733333333),
        2 / scale,
        Paint()
          ..color = selectedId == 'china'
              ? AtlasPalette.orange
              : AtlasPalette.land,
      );
    }
    final visibleCounts = <String, int>{};
    if (layer == '地标' || selectedId != null) {
      for (final p in places) {
        if (layer != '地标' && p.countryId != selectedId) continue;
        if (scale < .8 && p.countryId != selectedId) continue;
        if (scale <= 1.5 && p.countryId != selectedId) continue;
        // At overview scale, keep representative labels; all markers remain tappable.
        if (scale < 5 && (visibleCounts[p.countryId] ?? 0) >= 3) continue;
        if (_label(
          canvas,
          p.name,
          project(p.latitude, p.longitude) + Offset(0, -16 / scale),
          12,
          AtlasPalette.navy,
          halo: true,
          avoidCollisions: true,
        )) {
          visibleCounts.update(p.countryId, (n) => n + 1, ifAbsent: () => 1);
        }
      }
    }
  }

  bool _label(
    Canvas canvas,
    String text,
    Offset point,
    double fontSize,
    Color color, {
    bool halo = false,
    bool avoidCollisions = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: fontSize / scale,
          fontWeight: FontWeight.w700,
          color: color,
          shadows: [
            Shadow(
              color: Colors.white.withValues(alpha: .8),
              blurRadius: 2 / scale,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final preferred = Rect.fromCenter(
      center: point,
      width: painter.width + 8 / scale,
      height: painter.height + 3 / scale,
    );
    final rect = avoidCollisions
        ? findAtlasLabelRect(preferred, _labelBounds, scale)
        : preferred;
    if (rect == null) {
      painter.dispose();
      return false;
    }
    if ((rect.center - point).distance > 4 / scale) {
      canvas.drawLine(
        point,
        rect.center,
        Paint()
          ..color = AtlasPalette.navy.withValues(alpha: .5)
          ..strokeWidth = 1 / scale,
      );
    }
    _labelBounds.add(rect);
    if (halo) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(5 / scale)),
        Paint()..color = Colors.white.withValues(alpha: .9),
      );
    }
    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
    painter.dispose();
    return true;
  }

  @override
  bool shouldRepaint(AtlasPainter old) =>
      old.scale != scale ||
      old.selectedId != selectedId ||
      old.layer != layer ||
      old.data != data ||
      old.related != related ||
      old.candidateIds != candidateIds;
}

/// Find a nearby label position without covering either text or place markers.
Rect? findAtlasLabelRect(Rect preferred, List<Rect> occupied, double scale) {
  final horizontal = preferred.width / 2 + 12 / scale;
  for (final offset in [
    Offset.zero,
    Offset(-horizontal, 0),
    Offset(horizontal, 0),
    Offset(0, -26 / scale),
    Offset(0, 26 / scale),
  ]) {
    final candidate = preferred.shift(offset);
    if (!occupied.any((r) => r.overlaps(candidate.inflate(2 / scale)))) {
      return candidate;
    }
  }
  return null;
}
