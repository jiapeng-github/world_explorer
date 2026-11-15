import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/catalog.dart';
import '../core/palette.dart';

class MapFocus {
  const MapFocus(this.latitude, this.longitude, this.zoom);
  final double latitude, longitude, zoom;
}

class WorldMap extends StatefulWidget {
  const WorldMap({
    super.key,
    required this.countries,
    this.selectedId,
    this.onSelect,
    this.showLabels = true,
    this.height = 340,
    this.markerLabels,
    this.focus,
    this.landmarks = const [],
    this.selectedLandmarkId,
    this.onLandmarkSelect,
    this.showLandmarks = false,
  });
  final List<Country> countries;
  final String? selectedId, selectedLandmarkId;
  final ValueChanged<String>? onSelect, onLandmarkSelect;
  final bool showLabels, showLandmarks;
  final double height;
  final Map<String, String>? markerLabels;
  final MapFocus? focus;
  final List<Landmark> landmarks;
  static Future<void> preload() async {
    await _WorldMapState.loadLand();
  }

  static Offset project(double latitude, double longitude) =>
      Offset((longitude + 180) / 360, (90 - latitude) / 180);
  @override
  State<WorldMap> createState() => _WorldMapState();
}

class _MapGeometry {
  const _MapGeometry(this.land, this.continents, this.rivers, this.lakes);
  final List<List<Offset>> land, rivers, lakes;
  final Map<String, List<List<Offset>>> continents;
}

class _WorldMapState extends State<WorldMap>
    with SingleTickerProviderStateMixin {
  final TransformationController _transform = TransformationController();
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  Matrix4Tween? _tween;
  Size _size = Size.zero;
  late Future<_MapGeometry> _land = loadLand();
  static Future<_MapGeometry>? _cachedLand;
  static Future<_MapGeometry> loadLand() => _cachedLand ??= readLand();
  static List<List<Offset>> _rings(Map<String, dynamic> geometry) {
    final coordinates = geometry['coordinates'] as List;
    final polygons = geometry['type'] == 'Polygon'
        ? [coordinates]
        : coordinates;
    return [
      for (final polygon in polygons)
        [
          for (final point in polygon[0] as List)
            WorldMap.project(
              (point[1] as num).toDouble(),
              (point[0] as num).toDouble(),
            ),
        ],
    ];
  }

  static Future<_MapGeometry> readLand() async {
    final raw = await Future.wait([
      rootBundle.loadString('assets/maps/world-land.geojson'),
      rootBundle.loadString('assets/maps/world-countries.geojson'),
      rootBundle.loadString(
        'assets/maps/world-rivers_lake_centerlines.geojson',
      ),
      rootBundle.loadString('assets/maps/world-lakes.geojson'),
    ]);
    final land = <List<Offset>>[];
    for (final feature in jsonDecode(raw[0])['features'] as List) {
      land.addAll(_rings(feature['geometry']));
    }
    final continents = <String, List<List<Offset>>>{};
    for (final feature in jsonDecode(raw[1])['features'] as List) {
      final name = feature['properties']['continent'] as String;
      (continents[name] ??= []).addAll(_rings(feature['geometry']));
    }
    final rivers = <List<Offset>>[];
    for (final f in jsonDecode(raw[2])['features'] as List) {
      final g = f['geometry'];
      final lines = g['type'] == 'LineString'
          ? [g['coordinates']]
          : g['coordinates'] as List;
      for (final line in lines) {
        rivers.add([
          for (final p in line)
            WorldMap.project(
              (p[1] as num).toDouble(),
              (p[0] as num).toDouble(),
            ),
        ]);
      }
    }
    final lakes = <List<Offset>>[];
    for (final f in jsonDecode(raw[3])['features'] as List) {
      lakes.addAll(_rings(f['geometry']));
    }
    return _MapGeometry(land, continents, rivers, lakes);
  }

  @override
  void initState() {
    super.initState();
    _animation.addListener(() {
      if (_tween != null) {
        _transform.value = _tween!.transform(
          Curves.easeInOutCubic.transform(_animation.value),
        );
      }
    });
  }

  @override
  void didUpdateWidget(WorldMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focus != widget.focus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _goTo(widget.focus);
      });
    }
  }

  Rect get _mapRect => Rect.fromLTWH(
    0,
    (_size.height - _size.width / 2) / 2,
    _size.width,
    _size.width / 2,
  );
  Offset _position(double lat, double lon) {
    final p = WorldMap.project(lat, lon);
    return Offset(p.dx * _mapRect.width, _mapRect.top + p.dy * _mapRect.height);
  }

  Offset _screen(Offset point) =>
      MatrixUtils.transformPoint(_transform.value, point);
  void _animate(Matrix4 to) {
    _animation.stop();
    _tween = Matrix4Tween(begin: _transform.value.clone(), end: to);
    _animation.forward(from: 0);
  }

  void _goTo(MapFocus? focus) {
    if (_size.isEmpty) return;
    if (focus == null || focus.zoom <= 1) {
      _animate(Matrix4.identity());
      return;
    }
    final p = _position(focus.latitude, focus.longitude);
    final z = focus.zoom.clamp(1.0, 12.0);
    final x = (_size.width / 2 - p.dx * z).clamp(_size.width * (1 - z), 0.0);
    final y = (_size.height / 2 - p.dy * z).clamp(_size.height * (1 - z), 0.0);
    _animate(
      Matrix4.identity()
        ..setEntry(0, 0, z)
        ..setEntry(1, 1, z)
        ..setEntry(2, 2, z)
        ..setEntry(0, 3, x)
        ..setEntry(1, 3, y),
    );
  }

  void _zoom(double factor) {
    final old = _transform.value.getMaxScaleOnAxis();
    final z = (old * factor).clamp(1.0, 12.0);
    final center = _transform.toScene(
      Offset(_size.width / 2, _size.height / 2),
    );
    _animate(
      Matrix4.identity()
        ..setEntry(0, 0, z)
        ..setEntry(1, 1, z)
        ..setEntry(2, 2, z)
        ..setEntry(
          0,
          3,
          (_size.width / 2 - center.dx * z).clamp(_size.width * (1 - z), 0.0),
        )
        ..setEntry(
          1,
          3,
          (_size.height / 2 - center.dy * z).clamp(_size.height * (1 - z), 0.0),
        ),
    );
  }

  @override
  void dispose() {
    _animation.dispose();
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    height: widget.height,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFFC5DFDF)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10173F3D),
          blurRadius: 25,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: FutureBuilder<_MapGeometry>(
      future: _land,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ColoredBox(
            color: AtlasColors.mint,
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  _cachedLand = null;
                  setState(() => _land = loadLand());
                },
                icon: const Icon(Icons.refresh),
                label: const Text('重新加载地图'),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const ColoredBox(
            color: AtlasColors.mint,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return LayoutBuilder(
          builder: (context, c) {
            final nextSize = Size(c.maxWidth, c.maxHeight);
            if (_size != nextSize) {
              _size = nextSize;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _goTo(widget.focus);
              });
            }
            return Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFD8ECE9),
                          Color(0xFFABD2DB),
                          Color(0xFFD5E7E4),
                        ],
                      ),
                    ),
                  ),
                ),
                InteractiveViewer(
                  transformationController: _transform,
                  minScale: 1,
                  maxScale: 12,
                  onInteractionStart: (_) => _animation.stop(),
                  child: SizedBox(
                    width: _size.width,
                    height: _size.height,
                    child: CustomPaint(
                      painter: _LandPainter(
                        snapshot.data!,
                        _mapRect,
                        _transform,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _transform,
                    builder: (context, _) => Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        if (widget.showLabels &&
                            _transform.value.getMaxScaleOnAxis() < 1.8)
                          ..._labels(),
                        if (!widget.showLandmarks)
                          for (var i = 0; i < widget.countries.length; i++)
                            _countryMarker(widget.countries[i], i),
                        if (widget.showLandmarks) ..._landmarkMarkers(),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .92),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.explore_outlined,
                            size: 17,
                            color: AtlasColors.forest,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            widget.showLandmarks ? '地标观察地图' : '我的世界图集',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 16,
                  right: 18,
                  child: IgnorePointer(
                    child: Column(
                      children: [
                        Text(
                          'N',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AtlasColors.forest,
                          ),
                        ),
                        Icon(
                          Icons.navigation,
                          size: 22,
                          color: AtlasColors.forest,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 38,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .96),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Color(0x16173F3D), blurRadius: 15),
                      ],
                    ),
                    child: Column(
                      children: [
                        IconButton(
                          key: const ValueKey('map-zoom-in'),
                          tooltip: '放大地图',
                          onPressed: () => _zoom(1.5),
                          icon: const Icon(Icons.add),
                        ),
                        IconButton(
                          tooltip: '缩小地图',
                          onPressed: () => _zoom(1 / 1.5),
                          icon: const Icon(Icons.remove),
                        ),
                        IconButton(
                          key: const ValueKey('map-reset'),
                          tooltip: '还原地图',
                          onPressed: () => _goTo(null),
                          icon: const Icon(Icons.public),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 14,
                  right: 14,
                  child: IgnorePointer(
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '拖动探索 · 滚轮 / 双指缩放',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF3B686D),
                            ),
                          ),
                        ),
                        Text(
                          'Natural Earth · 1:110m',
                          style: TextStyle(
                            fontSize: 9,
                            color: const Color(0xFF3B686D)
                                .withValues(alpha: .8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
  );
  List<Widget> _labels() {
    const labels = [
      ('北美洲', 42.0, -112.0),
      ('南美洲', -25.0, -66.0),
      ('欧洲', 55.0, 12.0),
      ('非洲', 1.0, 15.0),
      ('亚洲', 51.0, 83.0),
      ('大洋洲', -29.0, 137.0),
      ('太 平 洋', 0.0, -135.0),
      ('大 西 洋', 15.0, -35.0),
      ('印 度 洋', -20.0, 80.0),
    ];
    return [
      for (final (name, lat, lon) in labels)
        Positioned(
          left: _screen(_position(lat, lon)).dx - 32,
          top: _screen(_position(lat, lon)).dy - 10,
          child: IgnorePointer(
            child: Text(
              name,
              style: TextStyle(
                fontSize: name.contains(' ') ? 10 : 12,
                fontWeight: name.contains(' ')
                    ? FontWeight.w400
                    : FontWeight.w700,
                color: name.contains(' ')
                    ? const Color(0xFF4F8894)
                    : const Color(0xFF71846B),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _countryMarker(Country country, int index) {
    final p = _screen(_position(country.latitude, country.longitude));
    final selected = widget.selectedId == country.id;
    final label =
        widget.markerLabels?[country.id] ??
        (widget.showLabels ? country.name : String.fromCharCode(65 + index));
    final width = widget.showLabels ? 94.0 : 48.0;
    if (p.dx < -width ||
        p.dx > _size.width + width ||
        p.dy < -50 ||
        p.dy > _size.height + 50) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: p.dx - width / 2,
      top: p.dy - 60,
      child: Semantics(
        label: widget.showLabels ? '探索${country.name}' : '位置 $label',
        button: true,
        selected: selected,
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('map-marker-${country.id}'),
                onTap: widget.onSelect == null
                    ? null
                    : () => widget.onSelect!(country.id),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: width,
                  height: 46,
                  decoration: BoxDecoration(
                    color: selected ? AtlasColors.forest : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? AtlasColors.sand
                          : const Color(0xFFD7E6DF),
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x25173F3D),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.showLabels ? '${country.flagEmoji} $label' : label,
                      style: TextStyle(
                        fontSize: widget.showLabels ? 13 : 17,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : AtlasColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 2,
              height: 10,
              color: selected ? AtlasColors.forest : Colors.white,
            ),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AtlasColors.forest,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _landmarkMarkers() {
    final result = <Widget>[];
    final placed = <Rect>[];
    for (var i = 0; i < widget.landmarks.length; i++) {
      final l = widget.landmarks[i];
      final anchor = _screen(_position(l.latitude, l.longitude));
      if (anchor.dx < 0 ||
          anchor.dx > _size.width ||
          anchor.dy < 0 ||
          anchor.dy > _size.height) {
        continue;
      }
      final left = (anchor.dx + (i.isEven ? 14 : -158))
          .clamp(6.0, math.max(6.0, _size.width - 150.0))
          .toDouble();
      var top = (anchor.dy - 19).clamp(62.0, _size.height - 78);
      var rect = Rect.fromLTWH(left, top, 144, 38);
      for (
        var attempt = 0;
        attempt < 6 && placed.any((r) => r.inflate(4).overlaps(rect));
        attempt++
      ) {
        top = (top + 44).clamp(62.0, _size.height - 78);
        rect = Rect.fromLTWH(left, top, 144, 38);
      }
      placed.add(rect);
      result.add(
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _LeaderPainter(anchor, rect.center)),
          ),
        ),
      );
      result.add(
        Positioned(
          left: rect.left,
          top: rect.top,
          child: Material(
            color: widget.selectedLandmarkId == l.id
                ? AtlasColors.forest
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 3,
            child: InkWell(
              key: ValueKey('landmark-marker-${l.id}'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => widget.onLandmarkSelect?.call(l.id),
              child: SizedBox(
                width: 144,
                height: 38,
                child: Center(
                  child: Text(
                    '${i + 1}  ${l.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.selectedLandmarkId == l.id
                          ? Colors.white
                          : AtlasColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return result;
  }
}

class _LeaderPainter extends CustomPainter {
  const _LeaderPainter(this.from, this.to);
  final Offset from, to;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = AtlasColors.forest.withValues(alpha: .5)
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(from, 4, Paint()..color = AtlasColors.forest);
    canvas.drawCircle(from, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_LeaderPainter old) => from != old.from || to != old.to;
}

class _LandPainter extends CustomPainter {
  _LandPainter(this.geometry, this.rect, this.transform)
    : super(repaint: transform);
  final TransformationController transform;
  final _MapGeometry geometry;
  final Rect rect;
  Path _path(List<List<Offset>> rings) {
    final path = Path();
    for (final ring in rings) {
      if (ring.isEmpty) continue;
      path.moveTo(
        rect.left + ring.first.dx * rect.width,
        rect.top + ring.first.dy * rect.height,
      );
      for (final p in ring.skip(1)) {
        path.lineTo(
          rect.left + p.dx * rect.width,
          rect.top + p.dy * rect.height,
        );
      }
      path.close();
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final zoom = transform.value.getMaxScaleOnAxis();
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .34)
      ..strokeWidth = .6 / zoom;
    for (var x = 0; x <= 12; x++) {
      final dx = rect.left + rect.width * x / 12;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), grid);
    }
    for (var y = 0; y <= 6; y++) {
      final dy = rect.top + rect.height * y / 6;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), grid);
    }
    final coast = _path(geometry.land);
    canvas.drawPath(
      coast,
      Paint()
        ..color = const Color(0xFF91BDC2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 / zoom
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      coast,
      Paint()
        ..color = const Color(0xFFC2DAD5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 / zoom,
    );
    canvas.drawPath(coast, Paint()..color = const Color(0xFFF1EBD4));
    const colors = {
      'Africa': Color(0xFFE5D7B1),
      'Asia': Color(0xFFD6DFC0),
      'Europe': Color(0xFFE3E6CD),
      'North America': Color(0xFFDCE2C5),
      'South America': Color(0xFFCBDDB9),
      'Oceania': Color(0xFFE6DCB9),
      'Antarctica': Color(0xFFF3F6ED),
    };
    for (final e in geometry.continents.entries) {
      canvas.drawPath(
        _path(e.value),
        Paint()..color = colors[e.key] ?? const Color(0xFFE5DFC8),
      );
    }
    canvas.drawPath(
      coast,
      Paint()
        ..color = const Color(0xFFF7F8E9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8 / zoom,
    );
    canvas.drawPath(
      _path(geometry.lakes),
      Paint()..color = const Color(0xFF91BEC8),
    );
    final riverPaint = Paint()
      ..color = const Color(0xFF70A7B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .85 / math.sqrt(zoom)
      ..strokeCap = StrokeCap.round;
    for (final river in geometry.rivers) {
      if (river.isEmpty) continue;
      final path = Path()
        ..moveTo(
          rect.left + river.first.dx * rect.width,
          rect.top + river.first.dy * rect.height,
        );
      for (final p in river.skip(1)) {
        path.lineTo(
          rect.left + p.dx * rect.width,
          rect.top + p.dy * rect.height,
        );
      }
      canvas.drawPath(path, riverPaint);
    }
    final eq = rect.top + rect.height / 2;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(
        Offset(x, eq),
        Offset(x + 5, eq),
        Paint()
          ..color = const Color(0xFFB48E62).withValues(alpha: .45)
          ..strokeWidth = .8 / zoom,
      );
    }
  }

  @override
  bool shouldRepaint(_LandPainter old) =>
      old.geometry != geometry || old.rect != rect;
}
