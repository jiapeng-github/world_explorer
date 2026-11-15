import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/atlas_theme.dart';
import '../domain/atlas_content.dart';
import 'norway_map_data.dart';

class NorwayMapController {
  final _views = <NorwayRegion, _Camera>{};
  _NorwayLearningMapState? _map;
  void reset() {
    _views.remove(_map?.widget.region);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final map = _map;
      if (map != null && map.mounted) {
        map._set(map._fit(map.widget.data.bounds));
      }
    });
  }

  void focus(String id) => _map?._focus(id);
}

class _Camera {
  const _Camera(this.center, this.scale);
  final Offset center;
  final double scale;
  Offset pointAt(Offset pixel, Size size) =>
      center + (pixel - size.center(Offset.zero)) / scale;
  Offset pixelAt(Offset point, Size size) =>
      size.center(Offset.zero) + (point - center) * scale;
}

class NorwayLearningMap extends StatefulWidget {
  const NorwayLearningMap({
    super.key,
    required this.region,
    required this.data,
    required this.places,
    required this.controller,
    this.layer = 'terrain',
    this.legendTop = 8,
    this.selection,
    this.onSelect,
    this.onClear,
    this.candidates,
  });

  final NorwayRegion region;
  final NorwayMapRegionData data;
  final List<AtlasPlace> places;
  final NorwayMapController controller;
  final String layer;
  final double legendTop;
  final String? selection;
  final ValueChanged<String>? onSelect;
  final VoidCallback? onClear;
  final List<String>? candidates;

  @override
  State<NorwayLearningMap> createState() => _NorwayLearningMapState();
}

class _NorwayLearningMapState extends State<NorwayLearningMap> {
  Size viewport = Size.zero;
  late _Camera camera;
  Offset? gesturePoint;
  double gestureScale = 1;
  Set<String>? get allowed => widget.candidates?.toSet();

  bool _isAllowed(String id) => widget.candidates?.contains(id) ?? true;

  List<AtlasPlace> get visiblePlaces => [
    for (final place in widget.places)
      if ((norwayRegionFor(place.id) == widget.region) &&
          _isAllowed(place.id) &&
          (widget.candidates != null ||
              widget.layer == 'places' ||
              widget.selection == place.id ||
              widget.region != NorwayRegion.mainland ||
              _featured.contains(place.id)))
        place,
  ];

  static const _featured = {
    'norway-oslo',
    'norway-bryggen',
    'norway-tromso',
    'norway-geiranger',
  };

  Offset _point(AtlasPlace p) => widget.region.project(p.latitude, p.longitude);

  @override
  void initState() {
    super.initState();
    widget.controller._map = this;
  }

  @override
  void didUpdateWidget(NorwayLearningMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller._map == this) oldWidget.controller._map = null;
      widget.controller._map = this;
    }
    if (oldWidget.region != widget.region) {
      if (!viewport.isEmpty) camera = _initial();
    }
  }

  @override
  void dispose() {
    if (widget.controller._map == this) widget.controller._map = null;
    super.dispose();
  }

  _Camera _initial() {
    final saved = widget.controller._views[widget.region];
    if (saved != null) return saved;
    final focus = widget.selection;
    if (focus != null &&
        widget.candidates == null &&
        !(widget.region == NorwayRegion.mainland &&
            norwayPlaceParts.containsKey(focus))) {
      return _cameraFor(focus) ?? _fit(widget.data.bounds);
    }
    if (widget.candidates != null &&
        visiblePlaces.length >= 2 &&
        widget.candidates!.every((id) => norwayPlaceParts.containsKey(id))) {
      final points = visiblePlaces.map(_point);
      final first = points.first;
      final box = points
          .skip(1)
          .fold(
            Rect.fromPoints(first, first),
            (bounds, p) => bounds.expandToInclude(Rect.fromPoints(p, p)),
          );
      return _fit(box.inflate(math.max(70, box.longestSide * .20)));
    }
    return _fit(widget.data.bounds);
  }

  _Camera _fit(Rect box) {
    final horizontal =
        math.max(1, viewport.width - 80) / math.max(1, box.width);
    final vertical =
        math.max(1, viewport.height - 56) / math.max(1, box.height);
    return _Camera(box.center, math.min(horizontal, vertical).clamp(.015, 20));
  }

  _Camera? _cameraFor(String id) {
    final place = widget.places.where((p) => p.id == id).firstOrNull;
    if (place != null && (norwayRegionFor(id) == widget.region)) {
      // Deep links still show their regional context.
      final overview = _fit(widget.data.bounds);
      final scale = widget.region == NorwayRegion.mainland
          ? overview.scale * 1.28
          : overview.scale * 1.1;
      return _Camera(_point(place), math.max(.08, scale));
    }
    final bounds = widget.data.boundsFor(id);
    return bounds == null
        ? null
        : _fit(bounds.inflate(math.max(32, bounds.longestSide * .15)));
  }

  void _set(_Camera value) {
    final bounded = widget.data.reliefBounds.inflate(120);
    final center = Offset(
      value.center.dx.clamp(bounded.left, bounded.right),
      value.center.dy.clamp(bounded.top, bounded.bottom),
    );
    final next = _Camera(center, value.scale.clamp(.015, 20));
    widget.controller._views[widget.region] = next;
    setState(() => camera = next);
  }

  void _focus(String id) {
    if (viewport.isEmpty) return;
    final next = _cameraFor(id);
    if (next != null) _set(next);
  }

  void _zoom(double amount) =>
      _set(_Camera(camera.center, camera.scale * amount));

  void _choose(Offset pixel, List<_PlaceMarker> markers) {
    if (widget.onSelect == null) return;
    final ordered = markers.toList()
      ..sort(
        (a, b) => (a.position - pixel).distanceSquared.compareTo(
          (b.position - pixel).distanceSquared,
        ),
      );
    if (ordered.isNotEmpty && (ordered.first.position - pixel).distance <= 22) {
      final options = ordered.first.places;
      if (options.length == 1) {
        widget.onSelect!(options.single.id);
      } else {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (ctx) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final p in options)
                  ListTile(
                    title: Text(p.name),
                    subtitle: Text(p.region),
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onSelect?.call(p.id);
                    },
                  ),
              ],
            ),
          ),
        );
      }
      return;
    }
    final id = widget.data.hitLayer(
      camera.pointAt(pixel, viewport),
      layer: widget.layer,
      kmPerPixel: 1 / camera.scale,
      allowedIds: allowed,
    );
    if (id == null) {
      widget.onClear?.call();
    } else {
      widget.onSelect!(id);
    }
  }

  List<_PlaceMarker> _markers() {
    final markers = <_PlaceMarker>[];
    for (final place in visiblePlaces) {
      final position = camera.pixelAt(_point(place), viewport);
      final cluster = widget.candidates != null || place.id == widget.selection
          ? null
          : markers
                .where(
                  (m) =>
                      m.places.first.id != widget.selection &&
                      (m.position - position).distance < 24,
                )
                .firstOrNull;
      if (cluster == null) {
        markers.add(_PlaceMarker(position, [place]));
      } else {
        cluster.places.add(place);
      }
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, limits) {
      final next = limits.biggest;
      if (next.isEmpty) return const SizedBox.shrink();
      if (viewport.isEmpty) {
        viewport = next;
        camera = _initial();
      } else if (viewport != next) {
        final ratio = math.min(
          next.width / viewport.width,
          next.height / viewport.height,
        );
        viewport = next;
        camera = _Camera(camera.center, camera.scale * ratio);
      }
      final markers = _markers();
      final textDirection = Directionality.of(context);
      final showLegend = widget.candidates == null && next.height >= 164;
      final scaleKm = _roundedScale(76 / camera.scale);
      return Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            label: '挪威地图，${widget.region.label}',
            hint: '可拖动、双指缩放，也可以使用搜索和地点列表',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (event) => _choose(event.localPosition, markers),
              onScaleStart: (event) {
                gestureScale = camera.scale;
                gesturePoint = camera.pointAt(event.localFocalPoint, viewport);
              },
              onScaleUpdate: (event) {
                final scale = (gestureScale * event.scale).clamp(.015, 20.0);
                final center =
                    gesturePoint! -
                    (event.localFocalPoint - viewport.center(Offset.zero)) /
                        scale;
                _set(_Camera(center, scale));
              },
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _NorwayMapPainter(
                    region: widget.region,
                    camera: camera,
                    data: widget.data,
                    layer: widget.layer,
                    selected: widget.selection,
                    markers: markers,
                    candidates: widget.candidates,
                    direction: textDirection,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          if (showLegend)
            Positioned(
              left: 8,
              top: widget.legendTop,
              child: _MapPlate(
                child: Text(
                  switch (widget.layer) {
                    'coast' => '━ 海岸   ┄ 北极圈',
                    'places' => '● 地点   ● 聚合点',
                    'islands' => '岛屿范围 · 地理概念',
                    _ => '┄ 北极圈   ● 地点',
                  },
                  style: const TextStyle(
                    fontSize: 11,
                    color: AtlasPalette.navy,
                  ),
                ),
              ),
            ),
          if (showLegend)
            Positioned(
              top: 8,
              right: 8,
              child: Semantics(
                label: '视图中心的北向',
                child: _MapPlate(
                  child: Column(
                    children: [
                      const Text(
                        '北',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Transform.rotate(
                        angle: widget.region.northRotation(camera.center),
                        child: const Icon(
                          Icons.navigation,
                          size: 18,
                          color: AtlasPalette.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (showLegend)
            Positioned(
              left: 8,
              bottom: 8,
              child: _MapPlate(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$scaleKm 公里', style: const TextStyle(fontSize: 10)),
                    SizedBox(
                      width: scaleKm * camera.scale,
                      child: const Divider(
                        height: 3,
                        thickness: 2,
                        color: AtlasPalette.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Material(
              color: Colors.white,
              elevation: 1,
              borderRadius: BorderRadius.circular(11),
              child: Flex(
                direction: next.height < 240 ? Axis.horizontal : Axis.vertical,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: '放大地图',
                    onPressed: () => _zoom(1.45),
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    tooltip: '缩小地图',
                    onPressed: () => _zoom(1 / 1.45),
                    icon: const Icon(Icons.remove),
                  ),
                  IconButton(
                    tooltip: '显示本区域全图',
                    onPressed: () => _set(_fit(widget.data.bounds)),
                    icon: const Icon(Icons.zoom_out_map),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

int _roundedScale(double value) {
  if (value < 2) return math.max(1, value.floor());
  final power = math.pow(10, (math.log(value) / math.ln10).floor()).toInt();
  return power *
      (value >= 5 * power
          ? 5
          : value >= 2 * power
          ? 2
          : 1);
}

class _MapPlate extends StatelessWidget {
  const _MapPlate({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .95),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: child,
    ),
  );
}

class _PlaceMarker {
  const _PlaceMarker(this.position, this.places);
  final Offset position;
  final List<AtlasPlace> places;
}

class _NorwayMapPainter extends CustomPainter {
  const _NorwayMapPainter({
    required this.region,
    required this.camera,
    required this.data,
    required this.layer,
    required this.selected,
    required this.markers,
    required this.candidates,
    required this.direction,
  });
  final NorwayRegion region;
  final _Camera camera;
  final NorwayMapRegionData data;
  final String layer;
  final String? selected;
  final List<_PlaceMarker> markers;
  final List<String>? candidates;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final clip = Offset.zero & size;
    final view = Rect.fromPoints(
      camera.pointAt(clip.topLeft, size),
      camera.pointAt(clip.bottomRight, size),
    );
    canvas.drawRect(clip, Paint()..color = const Color(0xffa7d5ec));
    canvas.save();
    canvas.clipRect(clip);
    final origin = camera.pixelAt(Offset.zero, size);
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(camera.scale);
    final visible = data.features
        .where(
          (f) =>
              f.bounds.inflate(2).overlaps(view) &&
              (f.kind != 'terrain' ||
                  (candidates?.contains(f.id) ?? false) ||
                  f.id == selected) &&
              (layer != 'islands' ||
                  (f.kind != 'part' && f.id != 'norway-context-irl')),
        )
        .toList();
    final relief = data.relief;
    if (relief != null) {
      final original =
          Offset.zero & Size(relief.width.toDouble(), relief.height.toDouble());
      final raster = Paint()..filterQuality = FilterQuality.medium;
      final land = Path();
      for (final state in visible.where(
        (f) => !f.isWater && f.kind != 'context' && f.waterway == null,
      )) {
        land.addPath(state.path, Offset.zero);
      }
      canvas.save();
      canvas.clipPath(land);
      canvas.drawImageRect(
        relief,
        original,
        data.reliefBounds,
        raster..colorFilter = null,
      );
      canvas.restore();
    }
    for (final f in visible.where((f) => !f.isWater && f.waterway == null)) {
      final picked = f.id == selected,
          candidate = candidates?.contains(f.id) ?? false;
      canvas.drawPath(
        f.path,
        Paint()
          ..color = picked
              ? const Color(0xfff4a632).withValues(alpha: .48)
              : candidate
              ? const Color(0xfff9d68b).withValues(alpha: .43)
              : f.kind == 'context'
              ? const Color(0xffd8dfe5)
              : const Color(0xfff0e2b7)
                    .withValues(alpha: relief == null ? 1 : .07),
      );
      canvas.drawPath(
        f.path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth =
              (picked
                  ? 2.4
                  : candidate
                  ? 1.6
                  : .78) /
              camera.scale
          ..color = picked
              ? const Color(0xffac4c11)
              : const Color(0xff536767).withValues(alpha: .66),
      );
    }
    for (final f in visible.where((f) => f.kind == 'lake')) {
      final picked = f.id == selected;
      canvas.drawPath(
        f.path,
        Paint()
          ..color = picked ? const Color(0xff4b9fca) : const Color(0xff8cc4e5),
      );
      canvas.drawPath(
        f.path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (picked ? 2 : .7) / camera.scale
          ..color = const Color(0xff477f9d),
      );
    }
    for (final f in visible.where((f) => f.waterway != null)) {
      final picked = f.id == selected;
      if (layer != 'coast' &&
          f.kind != 'reference' &&
          !(candidates?.contains(f.id) ?? false) &&
          !picked) {
        continue;
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (picked ? 3 : 1.8) / camera.scale
        ..color = f.kind == 'reference'
            ? AtlasPalette.orange
            : const Color(0xff566c7b);
      if (f.kind == 'reference' || f.kind == 'border') {
        for (final metric in f.path.computeMetrics()) {
          for (double d = 0; d < metric.length; d += 13 / camera.scale) {
            canvas.drawPath(
              metric.extractPath(
                d,
                math.min(d + 7 / camera.scale, metric.length),
              ),
              paint,
            );
          }
        }
      } else {
        canvas.drawPath(f.path, paint);
      }
    }
    for (final f in visible.where((f) => f.kind == 'disputed')) {
      canvas.save();
      canvas.clipPath(f.path);
      canvas.drawPath(f.path, Paint()..color = const Color(0xffead9bb));
      for (
        double x = f.bounds.left - f.bounds.height;
        x < f.bounds.right;
        x += 10 / camera.scale
      ) {
        canvas.drawLine(
          Offset(x, f.bounds.bottom),
          Offset(x + f.bounds.height, f.bounds.top),
          Paint()
            ..color = const Color(0xff9f7f5d)
            ..strokeWidth = 1 / camera.scale,
        );
      }
      canvas.restore();
      for (final metric in f.path.computeMetrics()) {
        for (double d = 0; d < metric.length; d += 11 / camera.scale) {
          canvas.drawPath(
            metric.extractPath(
              d,
              math.min(d + 6 / camera.scale, metric.length),
            ),
            Paint()
              ..style = PaintingStyle.stroke
              ..color = const Color(0xff8c6039)
              ..strokeWidth = 1.7 / camera.scale,
          );
        }
      }
    }
    canvas.restore();

    final occupied = <Rect>[];
    final labelsClip = clip.deflate(9);
    for (final marker in markers) {
      if (!clip.contains(marker.position)) continue;
      final place = marker.places.first;
      final candidate = candidates?.indexOf(place.id) ?? -1;
      final label = candidate >= 0
          ? '${candidate + 1}'
          : marker.places.length > 1
          ? '${marker.places.length}'
          : '';
      final picked = marker.places.any((p) => p.id == selected);
      final point = marker.position;
      final radius = label.isNotEmpty || picked ? 11.0 : 6.0;
      _dot(
        canvas,
        point,
        radius,
        picked ? const Color(0xffca571f) : AtlasPalette.navy,
        label,
      );
      occupied.add(Rect.fromCircle(center: point, radius: radius + 3));
    }
    final chosenPlace = markers
        .where(
          (marker) =>
              marker.places.length == 1 && marker.places.single.id == selected,
        )
        .firstOrNull;
    if (chosenPlace != null && candidates == null) {
      _label(
        canvas,
        chosenPlace.places.single.name.split(' · ').first,
        chosenPlace.position + const Offset(16, -14),
        labelsClip,
        occupied,
        color: const Color(0xff953c12),
        font: 12,
      );
    }
    for (final f in visible) {
      final candidate = candidates?.indexOf(f.id) ?? -1;
      final point = camera.pixelAt(f.anchor, size);
      if (!labelsClip.contains(point)) continue;
      if (candidate >= 0) {
        _dot(
          canvas,
          point,
          11,
          f.id == selected ? const Color(0xffca571f) : AtlasPalette.navy,
          '${candidate + 1}',
        );
        continue;
      }
      if (candidates != null) continue;
      if (f.waterway != null && f.kind != 'reference' && f.id != selected) {
        continue;
      }
      if (f.kind == 'reference') {
        _label(
          canvas,
          '北极圈 · 约66.56°N',
          camera.pixelAt(region.project(66.56, 7), size) +
              const Offset(-25, -22),
          labelsClip,
          occupied,
          color: AtlasPalette.orange,
          font: 11,
        );
        continue;
      }
      if (f.isWater) {
        if (layer != 'coast' ||
            (f.kind == 'lake' && camera.scale < .22 && f.id != selected)) {
          continue;
        }
      } else if (f.bounds.shortestSide * camera.scale < 43 &&
          f.id != selected) {
        continue;
      }
      _label(
        canvas,
        f.name,
        point,
        labelsClip,
        occupied,
        color: f.isWater ? const Color(0xff084e77) : const Color(0xff234b4b),
        center: true,
        font: 11,
      );
    }
    if (candidates == null) {
      for (final marker in markers.where(
        (m) => m.places.length == 1 && m != chosenPlace,
      )) {
        final p = marker.places.first;
        if (!labelsClip.contains(marker.position)) continue;
        _label(
          canvas,
          p.name.split(' · ').first,
          marker.position + const Offset(17, -24),
          labelsClip,
          occupied,
          color: AtlasPalette.navy,
          font: 11,
        );
      }
      if (region == NorwayRegion.mainland) {
        for (final (text, latitude, longitude) in const [('挪威海', 65.5, 3.0)]) {
          _label(
            canvas,
            text,
            camera.pixelAt(region.project(latitude, longitude), size),
            labelsClip,
            occupied,
            color: const Color(0xff31657a),
            center: true,
            font: 12,
          );
        }
      }
    }
  }

  void _dot(Canvas canvas, Offset p, double radius, Color color, String text) {
    canvas.drawCircle(p, radius + 1.5, Paint()..color = Colors.white);
    canvas.drawCircle(p, radius, Paint()..color = color);
    if (text.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          fontFamily: 'NotoSansSC',
        ),
      ),
      textDirection: direction,
    )..layout();
    painter.paint(canvas, p - Offset(painter.width / 2, painter.height / 2));
    painter.dispose();
  }

  void _label(
    Canvas canvas,
    String text,
    Offset anchor,
    Rect clip,
    List<Rect> used, {
    required Color color,
    bool center = false,
    double font = 11,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: font,
          fontWeight: FontWeight.w700,
          fontFamily: 'NotoSansSC',
          shadows: const [Shadow(blurRadius: 3, color: Colors.white)],
        ),
      ),
      textDirection: direction,
      maxLines: 1,
    )..layout();
    final point = center
        ? anchor - Offset(painter.width / 2, painter.height / 2)
        : anchor;
    for (final offset
        in center
            ? const [Offset.zero]
            : [
                Offset.zero,
                const Offset(0, 27),
                Offset(-painter.width - 34, 0),
                Offset(-painter.width - 34, 27),
              ]) {
      final position = point + offset;
      final box = (position & painter.size).inflate(2);
      if (clip.contains(box.topLeft) &&
          clip.contains(box.bottomRight) &&
          !used.any((other) => other.overlaps(box))) {
        painter.paint(canvas, position);
        used.add(box);
        break;
      }
    }
    painter.dispose();
  }

  @override
  bool shouldRepaint(_NorwayMapPainter oldDelegate) => true;
}
