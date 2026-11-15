import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/atlas_theme.dart';
import '../domain/atlas_content.dart';
import 'atlas_map.dart';
import 'country_map_profile.dart';

export 'country_map_profile.dart';

class CountryWaterway {
  CountryWaterway(this.id, this.name, this.lines, {this.canal = false})
    : path = Path(),
      bounds = Rect.zero {
    for (final line in lines) {
      if (line.isEmpty) continue;
      path.moveTo(line.first.dx, line.first.dy);
      for (final point in line.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
    }
    bounds = path.getBounds();
  }
  final String id, name;
  final bool canal;
  final List<List<Offset>> lines;
  final Path path;
  Rect bounds;

  /// Distance to the real polyline, in projected world coordinates.
  double distanceTo(Offset point) {
    var nearest = double.infinity;
    for (final line in lines) {
      for (var i = 1; i < line.length; i++) {
        final a = line[i - 1], b = line[i], delta = b - a;
        final length2 = delta.dx * delta.dx + delta.dy * delta.dy;
        final t = length2 == 0
            ? 0.0
            : (((point.dx - a.dx) * delta.dx + (point.dy - a.dy) * delta.dy) /
                      length2)
                  .clamp(0.0, 1.0);
        nearest = math.min(nearest, (point - (a + delta * t)).distance);
      }
    }
    return nearest;
  }

  Offset nearestVertex(Offset target) {
    var result = lines.first.first, distance = double.infinity;
    for (final point in lines.expand((line) => line)) {
      final next = (target - point).distanceSquared;
      if (next < distance) {
        distance = next;
        result = point;
      }
    }
    return result;
  }
}

class CountryMapData {
  CountryMapData(
    this.base,
    this.rivers, {
    this.relief,
    this.areas = const {},
    this.biomes = const {},
  });
  final AtlasGeometry base;
  final List<CountryWaterway> rivers;
  final ui.Image? relief;
  final Map<String, CountryWaterway> areas;
  final Map<String, CountryShape> biomes;
  static final _cache = <String, Future<CountryMapData>>{};
  static Future<CountryMapData> load([
    CountryMapProfile profile = chinaMapProfile,
  ]) => _cache.putIfAbsent(profile.id, () => _load(profile));
  static Future<CountryMapData> _load(CountryMapProfile profile) async {
    var base = await AtlasGeometry.load();
    if (profile.detailAsset case final asset?) {
      final regional = jsonDecode(await rootBundle.loadString(asset)) as Json;
      final shapes = <String, CountryShape>{
        for (final f in regional['features'] as List)
          f['properties']['id']: CountryShape(
            f['properties']['id'],
            AtlasGeometry.path(f['geometry']),
          ),
      };
      // Replace only this profile's regional shapes, leaving the shared world
      // geometry/cache untouched. Source interior rings remain intact.
      base = AtlasGeometry(
        [for (final c in base.countries) shapes[c.id] ?? c],
        base.rivers,
        base.lakes,
        base.relief,
        detail: [for (final c in base.detail) shapes[c.id] ?? c],
      );
    }
    final j =
        jsonDecode(await rootBundle.loadString(profile.waterAsset)) as Json;
    ui.Image? relief;
    if (profile.relief case final raster?) {
      try {
        final bytes = await rootBundle.load(raster.asset);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        try {
          relief = (await codec.getNextFrame()).image;
        } finally {
          codec.dispose();
        }
      } catch (_) {
        // A missing raster must not disable the offline vector map.
      }
    }
    final areas = <String, CountryWaterway>{};
    if (profile.areaAsset case final asset?) {
      final json = jsonDecode(await rootBundle.loadString(asset)) as Json;
      for (final reef in parseRivers(json)) {
        areas[reef.id] = reef;
      }
    }
    final biomes = <String, CountryShape>{};
    if (profile.biomeAsset case final asset?) {
      final json = jsonDecode(await rootBundle.loadString(asset)) as Json;
      for (final f in json['features'] as List) {
        final id = f['properties']['id'] as String;
        biomes[id] = CountryShape(id, AtlasGeometry.path(f['geometry']));
      }
    }
    return CountryMapData(
      base,
      parseRivers(j),
      relief: relief,
      areas: areas,
      biomes: biomes,
    );
  }

  static List<CountryWaterway> parseRivers(Json json) => [
    for (final f in json['features'] as List)
      CountryWaterway(f['properties']['id'], f['properties']['name'], [
        for (final line in f['geometry']['coordinates'] as List)
          [
            for (final p in line as List)
              project((p[1] as num).toDouble(), (p[0] as num).toDouble()),
          ],
      ], canal: f['properties']['kind'] == 'canal'),
  ];
}

/// Camera is owned by the caller, so layers/detail sheets do not reset it.
class CountryMapController {
  _CountryLearningMapState? _state;
  Matrix4? _savedTransform;
  Size? _savedViewport;
  void reset() => _state?._fitInitial();
  void zoom(double factor) => _state?._zoom(factor);
  void focus(String id) => _state?._focus(id);
  Matrix4? get camera => _savedTransform?.clone();
}

class MapPlaceCluster {
  MapPlaceCluster(this.places);
  final List<AtlasPlace> places;
  Offset get point =>
      places.fold<Offset>(
        Offset.zero,
        (sum, p) => sum + project(p.latitude, p.longitude),
      ) /
      places.length.toDouble();
}

/// Clusters use map coordinates and screen distance, never screenshot positions.
List<MapPlaceCluster> clusterMapPlaces(
  List<AtlasPlace> places,
  double scale, {
  String? selectedId,
}) {
  final clusters = <MapPlaceCluster>[];
  for (final p in places) {
    final point = project(p.latitude, p.longitude);
    final nearby = p.id == selectedId
        ? null
        : clusters
              .where(
                (c) =>
                    !c.places.any((other) => other.id == selectedId) &&
                    c.places.every(
                      (other) =>
                          (project(other.latitude, other.longitude) - point)
                                  .distance *
                              scale <
                          30,
                    ),
              )
              .firstOrNull;
    if (nearby == null) {
      clusters.add(MapPlaceCluster([p]));
    } else {
      nearby.places.add(p);
    }
  }
  return clusters;
}

class CountryLearningMap extends StatefulWidget {
  const CountryLearningMap({
    super.key,
    required this.countries,
    this.profile = chinaMapProfile,
    this.places = const [],
    this.layer = '地形',
    this.selectedId,
    this.onSelect,
    this.onClear,
    this.allowedIds,
    this.controller,
    this.showControls = true,
    this.showLegend = true,
    this.fitCandidates = false,
  });
  final List<AtlasCountry> countries;
  final CountryMapProfile profile;
  final List<AtlasPlace> places;
  final String layer;
  final String? selectedId;
  final ValueChanged<String>? onSelect;
  final VoidCallback? onClear;
  final Set<String>? allowedIds;
  final CountryMapController? controller;
  final bool showControls, showLegend, fitCandidates;

  @override
  State<CountryLearningMap> createState() => _CountryLearningMapState();
}

class _CountryLearningMapState extends State<CountryLearningMap> {
  final transform = TransformationController();
  late Future<CountryMapData> future = CountryMapData.load(widget.profile);
  CountryMapData? data;
  Size viewport = Size.zero;
  bool initialized = false;
  double scale = 1;
  CountryMapProfile get profile => widget.profile;
  List<AtlasPlace> get places =>
      widget.places.where((p) => p.countryId == profile.id).toList();

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    transform.addListener(_changed);
  }

  @override
  void didUpdateWidget(CountryLearningMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
    if (oldWidget.profile != profile) {
      future = CountryMapData.load(profile);
      data = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitInitial();
      });
    }
  }

  void _changed() {
    widget.controller?._savedTransform = transform.value.clone();
    widget.controller?._savedViewport = viewport;
    if (mounted) setState(() => scale = transform.value.entry(0, 0).abs());
  }

  double get minimumScale => math.min(
    viewport.width / worldSize.width,
    viewport.height / worldSize.height,
  );
  void _fitInitial() {
    if (widget.fitCandidates && widget.allowedIds != null) {
      final points = [
        for (final p in places.where((p) => _allowed(p.id)))
          project(p.latitude, p.longitude),
        for (final f in profile.features.where((f) => _allowed(f.id))) f.point,
      ];
      if (points.length >= 2) {
        final bounds = points
            .skip(1)
            .fold(
              Rect.fromPoints(points.first, points.first),
              (bounds, point) =>
                  bounds.expandToInclude(Rect.fromPoints(point, point)),
            );
        _fit(bounds.inflate(math.max(.27, bounds.longestSide * .20)));
        return;
      }
    }
    _fit(profile.bounds);
  }

  void _fit(Rect bounds) {
    if (viewport.isEmpty) return;
    final egypt = profile.id == 'egypt';
    final heightInset = egypt
        ? (viewport.height < 320 ? 26 : 44)
        : (viewport.height < 180 ? 24 : 82);
    final s = math
        .min(
          (viewport.width - (egypt ? 32 : 48)).clamp(1, double.infinity) /
              bounds.width,
          (viewport.height - heightInset).clamp(1, double.infinity) /
              bounds.height,
        )
        .clamp(minimumScale, profile.maxScale);
    _camera(bounds.center, s);
  }

  void _camera(Offset center, double nextScale) {
    final s = nextScale.clamp(minimumScale, profile.maxScale);
    transform.value = Matrix4.identity()
      ..translateByDouble(
        viewport.width / 2 - center.dx * s,
        viewport.height / 2 - center.dy * s,
        0,
        1,
      )
      ..scaleByDouble(s, s, 1, 1);
  }

  void _zoom(double factor) =>
      _camera(transform.toScene(viewport.center(Offset.zero)), scale * factor);
  void _focus(String id) {
    final biome = data?.biomes[id];
    if (biome != null) {
      _fit(biome.bounds.inflate(3));
      return;
    }
    final view = profile.focusViews[id];
    if (view != null) {
      _fit(
        Rect.fromPoints(
          project(view.north, view.west),
          project(view.south, view.east),
        ),
      );
      return;
    }
    final river = data?.rivers.where((r) => r.id == id).firstOrNull;
    if (river != null) {
      final window = river.bounds.intersect(profile.bounds.inflate(8));
      _fit(
        profile.id == 'egypt' && !window.isEmpty
            ? window.inflate(3)
            : river.bounds.inflate(24),
      );
      return;
    }
    final place = places.where((p) => p.id == id).firstOrNull;
    final feature = profile.features.where((p) => p.id == id).firstOrNull;
    if (place == null && feature == null) return;
    final point = place != null
        ? project(place.latitude, place.longitude)
        : feature!.point;
    _camera(
      point,
      math.max(scale, math.min(viewport.width, viewport.height) / 170),
    );
  }

  bool _allowed(String id) => widget.allowedIds?.contains(id) ?? true;
  bool _showPlace(AtlasPlace p) =>
      _allowed(p.id) &&
      (widget.layer != '生态' || widget.selectedId == p.id) &&
      (widget.allowedIds != null ||
          widget.layer == '地标' ||
          widget.selectedId == p.id ||
          profile.featuredPlaces.contains(p.id));

  List<String> _hits(Offset point) {
    final ranked = <(String, double)>[];
    for (final cluster in clusterMapPlaces(
      places.where(_showPlace).toList(),
      scale,
      selectedId: widget.selectedId,
    ).where((c) => c.places.length > 1)) {
      final distance = (point - cluster.point).distance * scale;
      if (distance <= 24) {
        ranked.addAll(cluster.places.map((p) => (p.id, distance)));
      }
    }
    for (final p in places.where(_showPlace)) {
      final d = (point - project(p.latitude, p.longitude)).distance * scale;
      if (d <= 24) ranked.add((p.id, d));
    }
    for (final f in profile.features.where(
      (f) => _allowed(f.id) && f.ecology == (widget.layer == '生态'),
    )) {
      if (f.river) continue;
      final d = (point - f.point).distance * scale;
      if (d <= 24) ranked.add((f.id, d));
    }
    if (widget.layer == '河流' || widget.allowedIds != null) {
      for (final river in data?.rivers ?? <CountryWaterway>[]) {
        if (!_allowed(river.id)) continue;
        final d = river.distanceTo(point) * scale;
        if (d <= 16) ranked.add((river.id, d));
      }
    }
    for (final area
        in data?.areas.entries ?? <MapEntry<String, CountryWaterway>>[]) {
      if (_allowed(area.key) && area.value.distanceTo(point) * scale <= 12) {
        ranked.add((area.key, 0));
      }
    }
    ranked.sort((a, b) => a.$2.compareTo(b.$2));
    if (widget.layer == '生态' && ranked.isEmpty) {
      for (final biome in data?.biomes.values ?? <CountryShape>[]) {
        if (_allowed(biome.id) && biome.contains(point)) {
          ranked.add((biome.id, 0));
        }
      }
    }
    return ranked.map((r) => r.$1).toSet().toList();
  }

  Widget _japanScaleBar() {
    // Equirectangular projection: five world units per longitude degree.
    // Horizontal distance is local to the current viewport centre latitude.
    final centre = transform.toScene(
      Offset(viewport.width / 2, viewport.height / 2),
    );
    final latitude = (90 - centre.dy / 5).clamp(-85.0, 85.0);
    final kmPerPixel =
        111.195 * math.cos(latitude * math.pi / 180) / (5 * scale);
    final target = kmPerPixel * 85;
    final magnitude = math
        .pow(10, (math.log(target) / math.ln10).floor())
        .toDouble();
    final distance = [
      5.0,
      2.0,
      1.0,
    ].map((v) => v * magnitude).firstWhere((v) => v <= target);
    return Semantics(
      label: '地图中心纬度附近，横向约${distance.toStringAsFixed(distance < 1 ? 1 : 0)}公里',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '约 ${distance.toStringAsFixed(distance < 1 ? 1 : 0)} 公里',
              style: const TextStyle(fontSize: 10, color: AtlasPalette.navy),
            ),
            Container(
              width: distance / kmPerPixel,
              height: 5,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(width: 2),
                  right: BorderSide(width: 2),
                  bottom: BorderSide(width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _name(String id) =>
      places.where((p) => p.id == id).firstOrNull?.name ??
      profile.features.where((p) => p.id == id).firstOrNull?.name ??
      id;
  void _select(Offset point) {
    final hits = _hits(point);
    if (hits.isEmpty) {
      widget.onClear?.call();
    } else if (hits.length == 1) {
      widget.onSelect?.call(hits.single);
    } else {
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  '这里有几个发现，选一个看看',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              for (final id in hits)
                ListTile(
                  title: Text(_name(id)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onSelect?.call(id);
                  },
                ),
            ],
          ),
        ),
      );
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
        final old = viewport;
        final center = old.isEmpty
            ? profile.bounds.center
            : transform.toScene(old.center(Offset.zero));
        viewport = next;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!initialized) {
            initialized = true;
            final saved = widget.controller?._savedTransform;
            final previousSize = widget.controller?._savedViewport;
            if (saved != null && previousSize != null) {
              transform.value = saved;
              final savedCenter = transform.toScene(
                previousSize.center(Offset.zero),
              );
              _camera(savedCenter, saved.entry(0, 0).abs());
            } else {
              _fitInitial();
              final selected = widget.selectedId;
              if (selected != null &&
                  profile.focusViews.containsKey(selected)) {
                _focus(selected);
              }
            }
          } else {
            _camera(center, scale);
          }
        });
      }
      return FutureBuilder<CountryMapData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('地图暂时无法显示，可以使用地点列表。', textAlign: TextAlign.center),
                  TextButton(
                    onPressed: () {
                      CountryMapData._cache.remove(profile.id);
                      setState(() => future = CountryMapData.load(profile));
                    },
                    child: const Text('重新载入地图'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          data = snapshot.data;
          final visible = Rect.fromPoints(
            transform.toScene(Offset.zero),
            transform.toScene(Offset(viewport.width, viewport.height)),
          );
          return Stack(
            children: [
              Positioned.fill(
                child: ClipRect(
                  child: ColoredBox(
                    color: AtlasPalette.sea,
                    child: InteractiveViewer(
                      transformationController: transform,
                      constrained: false,
                      minScale: minimumScale,
                      maxScale: profile.maxScale,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      child: GestureDetector(
                        onTapUp:
                            widget.onSelect == null && widget.onClear == null
                            ? null
                            : (d) => _select(d.localPosition),
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: worldSize,
                            painter: CountryMapPainter(
                              data: data!,
                              profile: profile,
                              scale: scale,
                              visible: visible,
                              places: places.where(_showPlace).toList(),
                              selectedId: widget.selectedId,
                              layer: widget.layer,
                              allowedIds: widget.allowedIds,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.showLegend &&
                  viewport.width >= 280 &&
                  viewport.height >= 150)
                Positioned(
                  left: 10,
                  top: 10,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: widget.layer == '生态'
                          ? const Text(
                              '生态区 · IBGE 2019　北 ↑',
                              style: TextStyle(fontSize: 12),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 22,
                                  height: 3,
                                  color: const Color(0xFF177FBD),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  '河流',
                                  style: TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 12),
                                if (profile.id == 'egypt')
                                  const Text(
                                    '┄',
                                    style: TextStyle(
                                      color: AtlasPalette.blue,
                                      fontSize: 16,
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.circle,
                                    size: 9,
                                    color: AtlasPalette.orange,
                                  ),
                                const SizedBox(width: 6),
                                Text(
                                  profile.id == 'egypt' ? '运河' : '发现点',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (profile.id != 'egypt') ...[
                                  const SizedBox(width: 12),
                                  const Text(
                                    '北 ↑',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
                ),
              if (profile.id == 'egypt' &&
                  widget.showLegend &&
                  viewport.height >= 150)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Semantics(
                    label: '地图朝北',
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 3, 8, 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '北',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Icon(
                              Icons.navigation,
                              size: 21,
                              color: AtlasPalette.navy,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (profile.id == 'aus' &&
                  widget.showLegend &&
                  viewport.height >= 225)
                Positioned(
                  left: 10,
                  top: 54,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: Colors.white.withValues(alpha: .94),
                      child: const Text(
                        '绿色：礁体分布 · 非公园边界',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xff087d76),
                        ),
                      ),
                    ),
                  ),
                ),
              if (viewport.height >= 225)
                Positioned(
                  left: 8,
                  bottom: 5,
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.white.withValues(alpha: .9),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      child: Text(
                        widget.layer == '生态'
                            ? 'IBGE 2019 · 生态区 ≠ 现存植被覆盖'
                            : 'Natural Earth · NASA  |  自然地理图',
                        style: TextStyle(
                          fontSize: 10,
                          color: AtlasPalette.navy,
                        ),
                      ),
                    ),
                  ),
                ),
              if (profile.id == 'japan' &&
                  widget.showLegend &&
                  viewport.height >= 150)
                Positioned(
                  left: 8,
                  bottom: viewport.height >= 225 ? 32 : 6,
                  child: IgnorePointer(child: _japanScaleBar()),
                ),
              if (widget.showControls)
                Positioned(
                  right: 10,
                  bottom: viewport.height < 225 ? 6 : 27,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    elevation: (profile.id == 'egypt' || profile.id == 'zaf')
                        ? 0
                        : 2,
                    child: Flex(
                      direction: viewport.height < 225
                          ? Axis.horizontal
                          : Axis.vertical,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: '放大${profile.name}地图',
                          onPressed: () => _zoom(1.4),
                          icon: const Icon(Icons.add),
                        ),
                        IconButton(
                          tooltip: '缩小${profile.name}地图',
                          onPressed: () => _zoom(1 / 1.4),
                          icon: const Icon(Icons.remove),
                        ),
                        IconButton(
                          tooltip: '显示${profile.name}全图',
                          onPressed: _fitInitial,
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
    },
  );
}

class CountryMapPainter extends CustomPainter {
  CountryMapPainter({
    required this.data,
    required this.profile,
    required this.scale,
    required this.visible,
    required this.places,
    required this.layer,
    this.selectedId,
    this.allowedIds,
  });
  final CountryMapData data;
  final CountryMapProfile profile;
  final double scale;
  final Rect visible;
  final List<AtlasPlace> places;
  final String layer;
  final String? selectedId;
  final Set<String>? allowedIds;
  final List<Rect> _labels = [];

  @override
  void paint(Canvas canvas, Size size) {
    _labels.clear();
    final base = data.base;
    final egypt = profile.id == 'egypt';
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = egypt ? const Color(0xFF428FA6) : const Color(0xFF8DC9E7),
    );
    final land = base.detail.isNotEmpty ? base.detailLand : base.land;
    canvas.drawPath(land, Paint()..color = AtlasPalette.land);
    if (base.relief != null || data.relief != null) {
      canvas.save();
      canvas.clipPath(land);
      if (base.relief case final image?) {
        _drawRaster(canvas, image, Offset.zero & size);
      }
      if (data.relief case final image?) {
        _drawRaster(canvas, image, profile.relief!.bounds);
      }
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = egypt
              ? const Color(0x19FFE2A1)
              : Colors.white.withValues(alpha: .12),
      );
      canvas.restore();
    }
    canvas.drawPath(base.lakes, Paint()..color = const Color(0xFF57AAD3));
    if (layer == '生态') {
      for (final feature in profile.features.where((f) => f.ecology)) {
        final shape = data.biomes[feature.id];
        if (shape == null) continue;
        canvas.drawPath(shape.path, Paint()..color = feature.color);
        canvas.drawPath(
          shape.path,
          Paint()
            ..color = feature.id == selectedId
                ? AtlasPalette.orange
                : Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = (feature.id == selectedId ? 3 : .9) / scale,
        );
      }
    }
    if (profile.id == 'zaf') {
      for (final shape in base.detail) {
        if (!shape.bounds.overlaps(visible)) continue;
        canvas.drawPath(
          shape.path,
          Paint()
            ..color = shape.id == 'zaf'
                ? const Color(0x26FFC86D)
                : const Color(0x688D9E9A),
        );
        canvas.drawPath(
          shape.path,
          Paint()
            ..color = Colors.white.withValues(alpha: .95)
            ..style = PaintingStyle.stroke
            ..strokeWidth = (shape.id == 'zaf' ? 1.8 : 1.1) / scale,
        );
      }
      // Country identity labels have priority over river/place labels. These
      // anchors are labels only, never substitute country geometry.
      for (final (name, lat, lon) in const [
        ('南非', -30.2, 24.2),
        ('莱索托', -29.6, 28.3),
        ('纳米比亚', -24.0, 17.5),
        ('博茨瓦纳', -23.0, 24.0),
        ('津巴布韦', -20.5, 29.0),
        ('莫桑比克', -24.5, 33.0),
      ]) {
        final p = project(lat, lon);
        if (visible.contains(p)) _label(canvas, name, p, selected: false);
      }
    }

    for (final area in data.areas.entries) {
      final color = area.key == selectedId
          ? AtlasPalette.orange
          : const Color(0xff087d76);

      canvas.drawPath(
        area.value.path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 / scale,
      );
    }
    // No country fill covers the relief, and no invented province boundaries.
    for (final river in data.rivers) {
      final selected = river.id == selectedId;
      final line = river.canal ? _dashed(river.path) : river.path;
      canvas.drawPath(
        line,
        Paint()
          ..color = Colors.white.withValues(alpha: .8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (selected ? 6 : 3.5) / scale
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = selected ? AtlasPalette.orange : const Color(0xFF177FBD)
          ..style = PaintingStyle.stroke
          ..strokeWidth =
              (selected
                  ? 3.5
                  : layer == '河流'
                  ? 2.4
                  : 1.5) /
              scale
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final currentPlace = places.where((p) => p.id == selectedId).firstOrNull;
    if (egypt && currentPlace != null) {
      final point = project(currentPlace.latitude, currentPlace.longitude);
      if (visible.inflate(24 / scale).contains(point)) {
        _egyptPin(canvas, point);
        _label(
          canvas,
          _placeLabel(currentPlace),
          point + Offset(0, -34 / scale),
          selected: true,
        );
      }
    }
    int featureOrder(CountryMapFeature f) {
      if (f.id == selectedId) return 0;
      if (egypt && !f.area && !f.river) return 1;
      if (egypt && (f.id == 'egypt-mediterranean' || f.id == 'egypt-red-sea')) {
        return 2;
      }
      return 3;
    }

    final features =
        profile.features
            .where(
              (f) =>
                  (allowedIds == null || allowedIds!.contains(f.id)) &&
                  f.ecology == (layer == '生态'),
            )
            .toList()
          ..sort((a, b) => featureOrder(a).compareTo(featureOrder(b)));
    for (final f in features) {
      // These locations belong to the country fill, not the teaching labels.
      if (f.id == 'china-taiwan') continue;
      if (f.id == 'china-diaoyu') {
        canvas.drawCircle(
          f.point,
          2 / scale,
          Paint()..color = AtlasPalette.orange,
        );
        continue;
      }
      final river = data.rivers.where((r) => r.id == f.id).firstOrNull;
      final point = river?.nearestVertex(f.point) ?? f.point;
      if (!visible.inflate(20 / scale).contains(point)) continue;
      final selected = f.id == selectedId;
      if (egypt && !selected && scale < 17 && f.id.startsWith('egypt-delta-')) {
        continue;
      }
      if (!f.area && !f.river) {
        _point(canvas, point, selected, muted: egypt && !selected);
      }
      if (selected && f.area) _point(canvas, point, true);
      final offset = switch (f.id) {
        'egypt-cairo' || 'egypt-aswan' || 'egypt-luxor' => const Offset(32, -2),
        'egypt-lake-nasser' => const Offset(-43, 0),
        'egypt-nile' => const Offset(-24, -8),
        _ => Offset(0, f.river || f.area ? 0 : -18),
      };
      _label(
        canvas,
        f.name,
        point + offset / scale,
        selected: selected,
        bold: f.area,
        ocean:
            f.id.contains('sea') ||
            f.id.contains('ocean') ||
            f.id == 'egypt-mediterranean',
      );
    }
    final sorted = [...places]
      ..sort(
        (a, b) =>
            (a.id == selectedId ? 0 : 1).compareTo(b.id == selectedId ? 0 : 1),
      );
    for (final cluster in clusterMapPlaces(
      sorted,
      scale,
      selectedId: selectedId,
    )) {
      final point = cluster.point;
      if (!visible.inflate(24 / scale).contains(point)) continue;
      if (cluster.places.length > 1) {
        _cluster(canvas, point, cluster.places.length);
        continue;
      }
      final p = cluster.places.single;
      final selected = p.id == selectedId;
      if (egypt && selected) continue;
      _point(canvas, point, selected, muted: egypt);
      _label(
        canvas,
        egypt ? _placeLabel(p) : p.name,
        point +
            (egypt && p.id == 'giza'
                    ? const Offset(-27, 0)
                    : const Offset(0, -18)) /
                scale,
        selected: selected,
      );
    }
  }

  String _placeLabel(AtlasPlace place) => switch (place.id) {
    'giza' => '吉萨',
    'nile-delta' => '三角洲',
    _ => place.name,
  };

  void _egyptPin(Canvas canvas, Offset p) {
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.scale(1 / scale);
    final drop = Path()
      ..moveTo(0, 4)
      ..cubicTo(-7, -4, -11, -8, -11, -15)
      ..arcToPoint(const Offset(11, -15), radius: const Radius.circular(11))
      ..cubicTo(11, -8, 7, -4, 0, 4)
      ..close();
    canvas.drawPath(drop, Paint()..color = AtlasPalette.orange);
    canvas.drawCircle(const Offset(0, -15), 4.7, Paint()..color = Colors.white);
    canvas.restore();
  }

  void _drawRaster(Canvas canvas, ui.Image image, Rect rect) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  Path _dashed(Path line) {
    final dashed = Path();
    final dash = 5 / scale, gap = 4 / scale;
    for (final segment in line.computeMetrics()) {
      for (double start = 0; start < segment.length; start += dash + gap) {
        dashed.addPath(
          segment.extractPath(start, math.min(start + dash, segment.length)),
          Offset.zero,
        );
      }
    }
    return dashed;
  }

  void _cluster(Canvas canvas, Offset point, int count) {
    canvas.drawCircle(point, 14 / scale, Paint()..color = AtlasPalette.navy);
    canvas.drawCircle(
      point,
      14 / scale,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 / scale,
    );
    final text = TextPainter(
      text: TextSpan(
        text: '$count',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'NotoSansSC',
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(point.dx, point.dy);
    canvas.scale(1 / scale);
    text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
    canvas.restore();
    text.dispose();
    _labels.add(Rect.fromCircle(center: point, radius: 17 / scale));
  }

  void _point(
    Canvas canvas,
    Offset point,
    bool selected, {
    bool muted = false,
  }) {
    if (selected) {
      canvas.drawCircle(
        point,
        13 / scale,
        Paint()..color = AtlasPalette.orange.withValues(alpha: .24),
      );
    }
    canvas.drawCircle(
      point,
      (selected ? 8 : 5) / scale,
      Paint()..color = muted ? AtlasPalette.blue : AtlasPalette.orange,
    );
    canvas.drawCircle(
      point,
      (selected ? 8 : 5) / scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 / scale
        ..color = Colors.white,
    );
  }

  void _label(
    Canvas canvas,
    String label,
    Offset point, {
    bool selected = false,
    bool bold = false,
    bool ocean = false,
  }) {
    final seaLabel = ocean && profile.id == 'egypt' && !selected;
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: (selected
              ? 15
              : bold
              ? 14
              : 12),
          color: selected || seaLabel
              ? Colors.white
              : ocean
              ? const Color(0xFF174A70)
              : AtlasPalette.ink,
          fontWeight: FontWeight.w700,
          shadows: seaLabel
              ? [Shadow(color: AtlasPalette.navy, blurRadius: 2)]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromCenter(
      center: point,
      width: (text.width + 14) / scale,
      height: (text.height + 6) / scale,
    );
    if (!selected && _labels.any((r) => r.overlaps(rect.inflate(3 / scale)))) {
      text.dispose();
      return;
    }
    _labels.add(rect);
    if (!seaLabel) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(6 / scale)),
        Paint()
          ..color = selected
              ? AtlasPalette.navy
              : Colors.white.withValues(alpha: .92),
      );
    }
    // Lay out at readable pixel size: subpixel font metrics collapse at local zoom.
    canvas.save();
    canvas.translate(point.dx, point.dy);
    canvas.scale(1 / scale);
    text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
    canvas.restore();
    text.dispose();
  }

  @override
  bool shouldRepaint(CountryMapPainter oldDelegate) =>
      oldDelegate.scale != scale ||
      oldDelegate.visible != visible ||
      oldDelegate.layer != layer ||
      oldDelegate.selectedId != selectedId ||
      oldDelegate.places != places ||
      oldDelegate.allowedIds != allowedIds ||
      oldDelegate.profile != profile ||
      oldDelegate.data != data;
}
