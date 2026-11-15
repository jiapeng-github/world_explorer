import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'usa_map_data.dart' show UsaMapFeature, UsaMapRegionData;

typedef DeuMapFeature = UsaMapFeature;
final deuPlaceParts = {
  for (final slug in [
    'berlin',
    'koblenz',
    'cologne',
    'hamburg',
    'leipzig',
    'mainz',
    'dessau',
    'castle',
    'jasmund',
    'wadden',
    'alps',
    'bautzen',
    'munich',
  ])
    'deu-$slug': 'deu-part-germany',
};

enum DeuRegion {
  all('德国全图', '欧洲中部 · 包含北部岛屿');

  const DeuRegion(this.label, this.detail);
  final String label, detail;
  String get key => name;
  static DeuRegion? parse(String? s) => s == 'all' ? all : null;
  ui.Offset project(double latitude, double longitude) =>
      deuProject(latitude, longitude);
  double northRotation(ui.Offset p) {
    final x = (p.dx - 4321) / _d, y = (-p.dy - 3210) * _d;
    final rho = math.sqrt(x * x + y * y);
    if (rho < .000001) return 0;
    final c = 2 * math.asin((rho / (2 * _rq)).clamp(-1.0, 1.0));
    final beta = math.asin(
      math.cos(c) * math.sin(_b0) + y * math.sin(c) * math.cos(_b0) / rho,
    );
    final lon =
        10 +
        math.atan2(
              x * math.sin(c),
              rho * math.cos(_b0) * math.cos(c) -
                  y * math.sin(_b0) * math.sin(c),
            ) *
            180 /
            math.pi;
    var phi = beta;
    for (var i = 0; i < 6; i++) {
      final derivative =
          2 *
          (1 - _e2) *
          math.cos(phi) /
          math.pow(1 - _e2 * math.pow(math.sin(phi), 2), 2);
      phi -= (_q(phi) - _qp * math.sin(beta)) / derivative;
    }
    final n = deuProject(phi * 180 / math.pi + .001, lon) - p;
    return math.atan2(n.dx, -n.dy);
  }
}

// EPSG:3035 / GRS80 ellipsoidal Lambert azimuthal equal area.
// Same parameters as PROJ; output kilometres with screen y south.
const _e2 = .006694380022900787;
final _e = math.sqrt(_e2);
double _q(double p) {
  final s = math.sin(p);
  return (1 - _e2) *
      (s / (1 - _e2 * s * s) -
          math.log((1 - _e * s) / (1 + _e * s)) / (2 * _e));
}

final _qp = _q(math.pi / 2), _b0 = math.asin(_q(52 * math.pi / 180) / _qp);
final _rq = 6378.137 * math.sqrt(_qp / 2);
final _d =
    6378.137 *
    math.cos(52 * math.pi / 180) /
    (math.sqrt(1 - _e2 * math.pow(math.sin(52 * math.pi / 180), 2)) *
        _rq *
        math.cos(_b0));
ui.Offset deuProject(double latitude, double longitude) {
  final b = math.asin(_q(latitude * math.pi / 180) / _qp),
      dl = (longitude - 10) * math.pi / 180;
  final k =
      _rq *
      math.sqrt(
        2 /
            (1 +
                math.sin(_b0) * math.sin(b) +
                math.cos(_b0) * math.cos(b) * math.cos(dl)),
      );
  return ui.Offset(
    4321 + _d * k * math.cos(b) * math.sin(dl),
    -(3210 +
        k /
            _d *
            (math.cos(_b0) * math.sin(b) -
                math.sin(_b0) * math.cos(b) * math.cos(dl))),
  );
}

DeuRegion? deuRegionFor(String? id) =>
    id?.startsWith('deu-') == true ? DeuRegion.all : null;

class DeuMapRegionData extends UsaMapRegionData {
  DeuMapRegionData(super.j, {super.relief}) : super.fromJson();
  String? hitLayer(
    ui.Offset point, {
    required String layer,
    required double kmPerPixel,
    Set<String>? allowedIds,
  }) => hit(
    point,
    water: layer == 'water',
    kmPerPixel: kmPerPixel,
    allowedIds: features
        .where(
          (f) =>
              (f.kind == 'part' || f.kind == 'terrain' || f.isWater) &&
              (allowedIds == null || allowedIds.contains(f.id)),
        )
        .map((f) => f.id)
        .toSet(),
  );
}

class DeuMapData {
  DeuMapData(this.regions);
  final Map<DeuRegion, DeuMapRegionData> regions;
  DeuMapRegionData get all => regions[DeuRegion.all]!;
  static Future<DeuMapData>? _cache;
  static Future<DeuMapData> load() => _cache ??= _load();
  static Future<DeuMapData> _load() async {
    try {
      final j = jsonDecode(
        await rootBundle.loadString('assets/atlas/deu-regions.json'),
      ) as Map<String, dynamic>;
      final result = <DeuRegion, DeuMapRegionData>{};
      for (final r in DeuRegion.values) {
        ui.Image? relief;
        try {
          final b = await rootBundle.load(
            'assets/atlas/deu-${r.key}-relief.jpg',
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
        result[r] = DeuMapRegionData(
          j['regions'][r.key] as Map<String, dynamic>,
          relief: relief,
        );
      }
      return DeuMapData(result);
    } catch (_) {
      _cache = null;
      rethrow;
    }
  }
}
