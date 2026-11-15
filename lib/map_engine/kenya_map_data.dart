import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'usa_map_data.dart' show UsaMapFeature, UsaMapRegionData;

typedef KenyaMapFeature = UsaMapFeature;
final kenyaPlaceParts = {
  for (final slug in [
    'mount-kenya',
    'nairobi-city',
    'lamu',
    'mombasa-port',
    'amboseli',
    'nakuru',
    'naivasha',
    'turkana',
    'kisumu',
    'kakamega',
    'watamu',
    'national-museum',
  ])
    'kenya-$slug': 'kenya-part-kenya',
};

enum KenyaRegion {
  all('肯尼亚全图', '非洲东部 · 赤道与印度洋');

  const KenyaRegion(this.label, this.detail);
  final String label, detail;
  String get key => name;
  static KenyaRegion? parse(String? s) => s == 'all' ? all : null;
  ui.Offset project(double latitude, double longitude) =>
      kenyaProject(latitude, longitude);
  double northRotation(ui.Offset p) {
    final x = p.dx / _d, y = -p.dy * _d;
    final rho = math.sqrt(x * x + y * y);
    if (rho < .000001) return 0;
    final c = 2 * math.asin((rho / (2 * _rq)).clamp(-1.0, 1.0));
    final beta = math.asin(
      math.cos(c) * math.sin(_b0) + y * math.sin(c) * math.cos(_b0) / rho,
    );
    final lon =
        38 +
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
    final n = kenyaProject(phi * 180 / math.pi + .001, lon) - p;
    return math.atan2(n.dx, -n.dy);
  }
}

// WGS84 ellipsoidal LAEA centered on 0N, 38E.
// Same parameters as PROJ; output kilometres with screen y south.
const _e2 = .0066943799901413165;
final _e = math.sqrt(_e2);
double _q(double p) {
  final s = math.sin(p);
  return (1 - _e2) *
      (s / (1 - _e2 * s * s) -
          math.log((1 - _e * s) / (1 + _e * s)) / (2 * _e));
}

final _qp = _q(math.pi / 2), _b0 = 0.0;
final _rq = 6378.137 * math.sqrt(_qp / 2);
final _d = 6378.137 / _rq;
ui.Offset kenyaProject(double latitude, double longitude) {
  final b = math.asin(_q(latitude * math.pi / 180) / _qp),
      dl = (longitude - 38) * math.pi / 180;
  final k =
      _rq *
      math.sqrt(
        2 /
            (1 +
                math.sin(_b0) * math.sin(b) +
                math.cos(_b0) * math.cos(b) * math.cos(dl)),
      );
  return ui.Offset(_d * k * math.cos(b) * math.sin(dl), -k * math.sin(b) / _d);
}

KenyaRegion? kenyaRegionFor(String? id) =>
    id?.startsWith('kenya-') == true ? KenyaRegion.all : null;

class KenyaMapRegionData extends UsaMapRegionData {
  KenyaMapRegionData(super.j, {super.relief}) : super.fromJson();
  String? hitLayer(
    ui.Offset point, {
    required String layer,
    required double kmPerPixel,
    Set<String>? allowedIds,
  }) {
    bool allowed(UsaMapFeature f) => allowedIds?.contains(f.id) ?? true;
    String? nearest;
    var threshold = kmPerPixel * 12;
    for (final f in features.where((f) => f.waterway != null && allowed(f))) {
      if (allowedIds == null && f.kind != 'reference') continue;
      final d = f.waterway!.distanceTo(point);
      if (d < threshold) {
        nearest = f.id;
        threshold = d;
      }
    }
    if (nearest != null) return nearest;
    for (final f in features.where((f) => f.kind == 'disputed' && allowed(f))) {
      if (f.path.contains(point)) return f.id;
    }
    return hit(
      point,
      water: layer == 'water',
      kmPerPixel: kmPerPixel,
      allowedIds: features
          .where((f) => f.waterway == null && f.kind != 'context' && allowed(f))
          .map((f) => f.id)
          .toSet(),
    );
  }
}

class KenyaMapData {
  KenyaMapData(this.regions);
  final Map<KenyaRegion, KenyaMapRegionData> regions;
  KenyaMapRegionData get all => regions[KenyaRegion.all]!;
  static Future<KenyaMapData>? _cache;
  static Future<KenyaMapData> load() => _cache ??= _load();
  static Future<KenyaMapData> _load() async {
    try {
      final j = jsonDecode(
        await rootBundle.loadString('assets/atlas/kenya-regions.json'),
      ) as Map<String, dynamic>;
      final result = <KenyaRegion, KenyaMapRegionData>{};
      for (final r in KenyaRegion.values) {
        ui.Image? relief;
        try {
          final b = await rootBundle.load(
            'assets/atlas/kenya-${r.key}-relief.jpg',
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
        result[r] = KenyaMapRegionData(
          j['regions'][r.key] as Map<String, dynamic>,
          relief: relief,
        );
      }
      return KenyaMapData(result);
    } catch (_) {
      _cache = null;
      rethrow;
    }
  }
}
