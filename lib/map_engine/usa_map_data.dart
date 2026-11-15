import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'country_learning_map.dart' show CountryWaterway;

enum UsaRegion {
  conus('相连 48 州', '含华盛顿特区'),
  ak('阿拉斯加', '独立比例'),
  hi('夏威夷', '独立比例');

  const UsaRegion(this.label, this.detail);
  final String label, detail;

  static UsaRegion? parse(String? value) =>
      values.where((region) => region.name == value).firstOrNull;

  double get centralMeridian => switch (this) {
    conus => -96,
    ak => -154,
    hi => -157.5,
  };

  // The normalized longitude delta keeps Aleutian positions adjacent at ±180°.
  ui.Offset project(double latitude, double longitude) {
    final delta = ((longitude - centralMeridian + 180) % 360 - 180) * _radians;
    if (this == hi) {
      return ui.Offset(
        _radius * delta * math.cos(20.5 * _radians),
        _radius * (20.5 - latitude) * _radians,
      );
    }
    final a = _albers!;
    final angle = a.n * delta;
    final distance = a.rho(latitude);
    return ui.Offset(
      distance * math.sin(angle),
      distance * math.cos(angle) - a.r0,
    );
  }

  double northRotation(ui.Offset point) {
    final a = _albers;
    return a == null ? 0 : -math.atan2(point.dx, point.dy + a.r0);
  }

  _Albers? get _albers => switch (this) {
    conus => _conus,
    ak => _alaska,
    hi => null,
  };
}

const _radians = math.pi / 180;
const _radius = 6378.137;
final _conus = _Albers(23, 29.5, 45.5);
final _alaska = _Albers(50, 55, 65);

class _Albers {
  _Albers(double origin, double parallel1, double parallel2) {
    final phi1 = parallel1 * _radians, phi2 = parallel2 * _radians;
    final m1 = _mSquared(phi1), m2 = _mSquared(phi2);
    final q1 = _q(math.sin(phi1)), q2 = _q(math.sin(phi2));
    n = (m1 - m2) / (q2 - q1);
    c = m1 + n * q1;
    r0 = rho(origin);
  }

  static const _eSquared = .0066943800229;
  static final _e = math.sqrt(_eSquared);
  late final double n, c, r0;

  static double _mSquared(double phi) {
    final sine = math.sin(phi), cosine = math.cos(phi);
    return cosine * cosine / (1 - _eSquared * sine * sine);
  }

  static double _q(double s) =>
      (1 - _eSquared) *
      (s / (1 - _eSquared * s * s) -
          math.log((1 - _e * s) / (1 + _e * s)) / (2 * _e));

  double rho(double latitude) =>
      _radius * math.sqrt(c - n * _q(math.sin(latitude * _radians))) / n;
}

const usaGreatLakes = 'usa-feature-great-lakes';

/// Locations are observation anchors. These assignments also drive state cards.
const usaPlaceStates = {
  'usa-grand-canyon': 'usa-state-04',
  'usa-yellowstone-old-faithful': 'usa-state-56',
  'usa-lake-superior': 'usa-state-55',
  'usa-mississippi-river': 'usa-state-22',
  'usa-new-york-harbor': 'usa-state-36',
  'usa-washington-dc': 'usa-district-11',
  'usa-independence-hall': 'usa-state-42',
  'usa-selma-bridge': 'usa-state-01',
  'usa-san-francisco-golden-gate': 'usa-state-06',
  'usa-denali': 'usa-state-02',
  'usa-hawaii-volcanoes': 'usa-state-15',
  'usa-everglades': 'usa-state-12',
};

UsaRegion? usaRegionFor(String? id) {
  final key = usaPlaceStates[id] ?? id;
  if (key == 'usa-state-02') return UsaRegion.ak;
  if (key == 'usa-state-15') return UsaRegion.hi;
  if (key == 'usa-district-11' ||
      key == usaGreatLakes ||
      const {
        'usa-feature-colorado-river',
        'usa-feature-mississippi-river',
        'usa-feature-lake-superior',
        'usa-feature-lake-michigan',
        'usa-feature-lake-huron',
        'usa-feature-lake-erie',
        'usa-feature-lake-ontario',
      }.contains(key) ||
      key != null &&
          key.startsWith('usa-state-') &&
          _conusFips.contains(key.substring('usa-state-'.length))) {
    return UsaRegion.conus;
  }
  return null;
}

const _conusFips = {
  '01',
  '04',
  '05',
  '06',
  '08',
  '09',
  '10',
  '12',
  '13',
  '16',
  '17',
  '18',
  '19',
  '20',
  '21',
  '22',
  '23',
  '24',
  '25',
  '26',
  '27',
  '28',
  '29',
  '30',
  '31',
  '32',
  '33',
  '34',
  '35',
  '36',
  '37',
  '38',
  '39',
  '40',
  '41',
  '42',
  '44',
  '45',
  '46',
  '47',
  '48',
  '49',
  '50',
  '51',
  '53',
  '54',
  '55',
  '56',
};

class UsaMapFeature {
  UsaMapFeature._(Map<String, dynamic> p, this.path, this.anchor, this.waterway)
    : id = p['id'] as String,
      name = p['name'] as String,
      kind = p['kind'] as String,
      code = p['code'] as String? ?? '',
      english = p['english'] as String? ?? '',
      aliases = List<String>.from(p['aliases'] ?? const []);
  final String id, name, kind, code, english;
  final List<String> aliases;
  final ui.Path path;
  final ui.Offset anchor;
  final CountryWaterway? waterway;
  late final ui.Rect bounds = path.getBounds();

  bool get isWater => kind == 'lake' || kind == 'river';

  factory UsaMapFeature.fromJson(Map<String, dynamic> json) {
    final p = json['properties'] as Map<String, dynamic>;
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;
    if (geometry['type'] == 'MultiLineString') {
      final river = CountryWaterway(p['id'], p['name'], [
        for (final line in coordinates)
          [for (final xy in line as List) _point(xy)],
      ]);
      return UsaMapFeature._(
        p,
        river.path,
        river.nearestVertex(river.bounds.center),
        river,
      );
    }
    final path = ui.Path()..fillType = ui.PathFillType.evenOdd;
    var largest = -1.0;
    var anchor = ui.Offset.zero;
    for (final polygon in coordinates.cast<List>()) {
      final outline = polygon.first as List;
      final points = outline.map(_point).toList();
      final box = _bounds(points);
      final area = box.width * box.height;
      if (area > largest) {
        largest = area;
        final outer = ui.Path()..addPolygon(points, true);
        anchor = outer.contains(box.center)
            ? box.center
            : points[points.length ~/ 2];
      }
      path.addPolygon(points, true);
      for (final hole in polygon.skip(1).cast<List>()) {
        path.addPolygon(hole.map(_point).toList(), true);
      }
    }
    return UsaMapFeature._(p, path, anchor, null);
  }
}

ui.Offset _point(Object? raw) {
  final xy = (raw as List).cast<num>();
  return ui.Offset(xy[0].toDouble(), xy[1].toDouble());
}

ui.Rect _bounds(Iterable<ui.Offset> points) {
  final first = points.first;
  return points
      .skip(1)
      .fold(
        ui.Rect.fromPoints(first, first),
        (box, point) => box.expandToInclude(ui.Rect.fromPoints(point, point)),
      );
}

ui.Rect _rect(List raw) => ui.Rect.fromLTRB(
  (raw[0] as num).toDouble(),
  (raw[1] as num).toDouble(),
  (raw[2] as num).toDouble(),
  (raw[3] as num).toDouble(),
);

class UsaMapRegionData {
  UsaMapRegionData.fromJson(Map<String, dynamic> j, {this.relief})
    : bounds = _rect(j['bounds']),
      reliefBounds = _rect(j['reliefBounds']),
      features = [
        for (final item in j['features'] as List) UsaMapFeature.fromJson(item),
      ];
  final ui.Rect bounds, reliefBounds;
  final ui.Image? relief;
  final List<UsaMapFeature> features;
  Iterable<UsaMapFeature> get lakes => features.where((f) => f.kind == 'lake');
  late final Map<String, UsaMapFeature> _byId = {
    for (final f in features) f.id: f,
  };
  UsaMapFeature? feature(String id) => _byId[id];

  ui.Rect? boundsFor(String id) {
    if (id == usaGreatLakes && lakes.isNotEmpty) {
      return lakes
          .skip(1)
          .fold<ui.Rect>(
            lakes.first.bounds,
            (box, f) => box.expandToInclude(f.bounds),
          );
    }
    return feature(id)?.bounds;
  }

  /// Lakes and rivers have priority over the state surface in the water layer.
  String? hit(
    ui.Offset point, {
    required bool water,
    required double kmPerPixel,
    Set<String>? allowedIds,
  }) {
    bool allowed(UsaMapFeature f) => allowedIds?.contains(f.id) ?? true;
    if (water) {
      for (final f in lakes.where(allowed)) {
        if (f.bounds.contains(point) && f.path.contains(point)) return f.id;
      }
      String? nearest;
      var threshold = kmPerPixel * 14;
      for (final f in features.where((f) => f.kind == 'river' && allowed(f))) {
        if (!f.bounds.inflate(threshold).contains(point)) continue;
        final distance = f.waterway!.distanceTo(point);
        if (distance < threshold) {
          threshold = distance;
          nearest = f.id;
        }
      }
      if (nearest != null) return nearest;
    }
    for (final f in features.where((f) => !f.isWater && allowed(f))) {
      if (f.bounds.contains(point) && f.path.contains(point)) return f.id;
    }
    return null;
  }
}

class UsaMapData {
  UsaMapData(this.regions);
  final Map<UsaRegion, UsaMapRegionData> regions;
  static Future<UsaMapData>? _cache;

  static Future<UsaMapData> load() => _cache ??= _load();

  static Future<UsaMapData> _load() async {
    try {
      final j = jsonDecode(
        await rootBundle.loadString('assets/atlas/usa-regions.json'),
      ) as Map;
      final images = await Future.wait(UsaRegion.values.map(_loadRelief));
      return UsaMapData({
        for (final (i, region) in UsaRegion.values.indexed)
          region: UsaMapRegionData.fromJson(
            j['regions'][region.name],
            relief: images[i],
          ),
      });
    } catch (_) {
      _cache = null;
      rethrow;
    }
  }

  static Future<ui.Image?> _loadRelief(UsaRegion region) async {
    try {
      final bytes = await rootBundle.load(
        'assets/atlas/usa-relief-${region.name}.jpg',
      );
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      try {
        return (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
    } catch (_) {
      return null; // The projected vector map remains usable.
    }
  }
}
