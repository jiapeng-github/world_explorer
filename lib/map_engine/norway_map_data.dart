import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'usa_map_data.dart' show UsaMapFeature, UsaMapRegionData;

typedef NorwayMapFeature = UsaMapFeature;
final norwayPlaceParts = {
  for (final slug in [
    'geiranger',
    'bryggen',
    'oslo',
    'naeroyfjord',
    'urnes',
    'lofoten-reine',
    'tromso',
    'alta',
    'karasjok',
    'eidsvoll',
    'jostedalsbreen',
  ])
    'norway-$slug': 'norway-part-mainland',
  'norway-longyearbyen': 'norway-part-svalbard',
};

enum NorwayRegion {
  mainland('本土', '本土与近岸岛屿', 65, 15),
  svalbard('斯瓦尔巴', '北方群岛 · 含熊岛', 78, 20),
  janMayen('扬马延', '北方岛屿', 71, -8);

  const NorwayRegion(this.label, this.detail, this.lat0, this.lon0);
  final String label, detail;
  final double lat0, lon0;
  String get key => this == janMayen ? 'jan-mayen' : name;
  static NorwayRegion? parse(String? value) =>
      values.where((r) => r.key == value).firstOrNull;
  _Laea get _projection => _projections[this]!;
  ui.Offset project(double latitude, double longitude) =>
      _projection.project(latitude, longitude);
  double northRotation(ui.Offset p) => _projection.northRotation(p);
}

final _projections = {
  for (final r in NorwayRegion.values) r: _Laea(r.lat0, r.lon0),
};

// WGS84 ellipsoidal LAEA; checked against PROJ for all three regions.
const _e2 = .0066943799901413165;
final _e = math.sqrt(_e2);
double _q(double p) {
  final s = math.sin(p);
  return (1 - _e2) *
      (s / (1 - _e2 * s * s) -
          math.log((1 - _e * s) / (1 + _e * s)) / (2 * _e));
}

final _qp = _q(math.pi / 2), _rq = 6378.137 * math.sqrt(_qp / 2);

class _Laea {
  _Laea(this.lat0, this.lon0);
  final double lat0, lon0;
  late final phi0 = lat0 * math.pi / 180;
  late final b0 = math.asin(_q(phi0) / _qp);
  late final d =
      6378.137 *
      math.cos(phi0) /
      (math.sqrt(1 - _e2 * math.pow(math.sin(phi0), 2)) * _rq * math.cos(b0));
  ui.Offset project(double lat, double lon) {
    final b = math.asin(_q(lat * math.pi / 180) / _qp),
        dl = (lon - lon0) * math.pi / 180;
    final k =
        _rq *
        math.sqrt(
          2 /
              (1 +
                  math.sin(b0) * math.sin(b) +
                  math.cos(b0) * math.cos(b) * math.cos(dl)),
        );
    return ui.Offset(
      d * k * math.cos(b) * math.sin(dl),
      -k /
          d *
          (math.cos(b0) * math.sin(b) -
              math.sin(b0) * math.cos(b) * math.cos(dl)),
    );
  }

  double northRotation(ui.Offset p) {
    final x = p.dx / d, y = -p.dy * d, rho = math.sqrt(x * x + y * y);
    if (rho < .000001) return 0;
    final c = 2 * math.asin((rho / (2 * _rq)).clamp(-1.0, 1.0));
    final beta = math.asin(
      math.cos(c) * math.sin(b0) + y * math.sin(c) * math.cos(b0) / rho,
    );
    final lon =
        lon0 +
        math.atan2(
              x * math.sin(c),
              rho * math.cos(b0) * math.cos(c) - y * math.sin(b0) * math.sin(c),
            ) *
            180 /
            math.pi;
    var phi = beta;
    for (var i = 0; i < 8; i++) {
      final derivative =
          2 *
          (1 - _e2) *
          math.cos(phi) /
          math.pow(1 - _e2 * math.pow(math.sin(phi), 2), 2);
      phi -= (_q(phi) - _qp * math.sin(beta)) / derivative;
    }
    final n = project(phi * 180 / math.pi + .001, lon) - p;
    return math.atan2(n.dx, -n.dy);
  }
}

NorwayRegion? norwayRegionFor(String? id) {
  if (id == null) return null;
  if (id == 'norway-part-svalbard' ||
      id == 'norway-longyearbyen' ||
      id == 'norway-coast-svalbard') {
    return NorwayRegion.svalbard;
  }
  if (id == 'norway-part-jan-mayen' || id == 'norway-coast-jan-mayen') {
    return NorwayRegion.janMayen;
  }
  if (norwayPlaceParts.containsKey(id) ||
      [
        'norway',
        'norway-part-mainland',
        'norway-border',
        'norway-coast',
        'norway-arctic-circle',
      ].contains(id)) {
    return NorwayRegion.mainland;
  }
  return null;
}

class NorwayMapRegionData extends UsaMapRegionData {
  NorwayMapRegionData(super.j, {super.relief}) : super.fromJson();
  String? hitLayer(
    ui.Offset point, {
    required String layer,
    required double kmPerPixel,
    Set<String>? allowedIds,
  }) {
    bool allowed(NorwayMapFeature f) => allowedIds?.contains(f.id) ?? true;
    String? best;
    var distance = kmPerPixel * 12;
    for (final f in features.where((f) => f.waterway != null && allowed(f))) {
      if (allowedIds == null && f.kind != 'reference' && layer != 'coast') {
        continue;
      }
      final d = f.waterway!.distanceTo(point);
      if (d < distance) {
        best = f.id;
        distance = d;
      }
    }
    if (best != null) return best;
    return hit(
      point,
      water: false,
      kmPerPixel: kmPerPixel,
      allowedIds: features
          .where((f) => f.kind == 'part' && allowed(f))
          .map((f) => f.id)
          .toSet(),
    );
  }
}

class NorwayMapData {
  NorwayMapData(this.regions);
  final Map<NorwayRegion, NorwayMapRegionData> regions;
  NorwayMapRegionData get all => regions[NorwayRegion.mainland]!;
  static Future<NorwayMapData>? _cache;
  static Future<NorwayMapData> load() => _cache ??= _load();
  static Future<NorwayMapData> _load() async {
    try {
      final j = jsonDecode(
        await rootBundle.loadString('assets/atlas/norway-regions.json'),
      ) as Map<String, dynamic>;
      final result = <NorwayRegion, NorwayMapRegionData>{};
      for (final r in NorwayRegion.values) {
        ui.Image? relief;
        try {
          if (r == NorwayRegion.janMayen) {
            // Global raster resolution is insufficient for this small island.
            // Keep its verified vector coastline instead of magnified pixels.
            throw StateError('Vector-only region');
          }
          final b = await rootBundle.load(
            'assets/atlas/norway-${r.key}-relief.jpg',
          );
          final c = await ui.instantiateImageCodec(b.buffer.asUint8List());
          try {
            relief = (await c.getNextFrame()).image;
          } finally {
            c.dispose();
          }
        } catch (_) {
          /* Vector map remains usable. */
        }
        result[r] = NorwayMapRegionData(
          j['regions'][r.key] as Map<String, dynamic>,
          relief: relief,
        );
      }
      return NorwayMapData(result);
    } catch (_) {
      _cache = null;
      rethrow;
    }
  }
}
