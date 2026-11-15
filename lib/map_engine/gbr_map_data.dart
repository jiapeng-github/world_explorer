import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'usa_map_data.dart' show UsaMapFeature, UsaMapRegionData;

// The geometry parser and hit testing are shared with the existing atlas.
typedef GbrMapFeature = UsaMapFeature;
const gbrPlaceParts = {
  'gbr-thames-london': 'gbr-part-england',
  'gbr-tower-bridge': 'gbr-part-england',
  'gbr-giants-causeway': 'gbr-part-northern-ireland',
  'gbr-belfast': 'gbr-part-northern-ireland',
  'gbr-cardiff': 'gbr-part-wales',
  'gbr-eryri': 'gbr-part-wales',
  'gbr-skomer': 'gbr-part-wales',
  'gbr-edinburgh': 'gbr-part-scotland',
  'gbr-glencoe': 'gbr-part-scotland',
  'gbr-stonehenge': 'gbr-part-england',
  'gbr-shildon': 'gbr-part-england',
  'gbr-jurassic-coast': 'gbr-part-england',
};

enum GbrRegion {
  all('全英', '英国四个组成部分'),
  england('英格兰', '英国的组成部分'),
  scotland('苏格兰', '含设得兰、奥克尼与外赫布里底群岛'),
  wales('威尔士', '英国的组成部分'),
  northernIreland('北爱尔兰', '位于爱尔兰岛东北部');

  const GbrRegion(this.label, this.detail);
  final String label, detail;
  String get key => this == northernIreland ? 'northern-ireland' : name;
  static GbrRegion? parse(String? s) =>
      values.where((r) => r.key == s || r.name == s).firstOrNull;
  ui.Offset project(double latitude, double longitude) =>
      gbrProject(latitude, longitude);
  double northRotation(ui.Offset p) => -math.atan2(p.dx, p.dy + _r0);
}

const _rad = math.pi / 180;
final _n =
    math.log(math.cos(49 * _rad) / math.cos(61 * _rad)) /
    math.log(
      math.tan(math.pi / 4 + 61 * _rad / 2) /
          math.tan(math.pi / 4 + 49 * _rad / 2),
    );
final _f =
    math.cos(49 * _rad) *
    math.pow(math.tan(math.pi / 4 + 49 * _rad / 2), _n) /
    _n;
double _rho(double lat) =>
    6371.0088 * _f / math.pow(math.tan(math.pi / 4 + lat * _rad / 2), _n);
final _r0 = _rho(55);
ui.Offset gbrProject(double latitude, double longitude) {
  final angle = _n * (longitude + 3) * _rad, rho = _rho(latitude);
  return ui.Offset(rho * math.sin(angle), rho * math.cos(angle) - _r0);
}

GbrRegion? gbrRegionFor(String? id) {
  final part = gbrPlaceParts[id] ?? id;
  if (part?.startsWith('gbr-part-') == true) {
    return GbrRegion.parse(part!.substring(9));
  }
  if (id == 'gbr-feature-loch-ness') return GbrRegion.scotland;
  if (id?.startsWith('gbr-') == true) return GbrRegion.all;
  return null;
}

class GbrMapRegionData extends UsaMapRegionData {
  GbrMapRegionData(super.j, {super.relief}) : super.fromJson();
  String? hitLayer(
    ui.Offset point, {
    required String layer,
    required double kmPerPixel,
    Set<String>? allowedIds,
  }) {
    final allowed = features
        .where(
          (f) =>
              (layer == 'islands'
                  ? f.kind == 'island'
                  : f.kind == 'part' || f.isWater) &&
              (allowedIds == null || allowedIds.contains(f.id)),
        )
        .map((f) => f.id)
        .toSet();
    return hit(
      point,
      water: layer == 'water',
      kmPerPixel: kmPerPixel,
      allowedIds: allowed,
    );
  }
}

class GbrMapData {
  GbrMapData(this.regions);
  final Map<GbrRegion, GbrMapRegionData> regions;
  GbrMapRegionData get all => regions[GbrRegion.all]!;
  static Future<GbrMapData>? _cache;
  static Future<GbrMapData> load() => _cache ??= _load();
  static Future<GbrMapData> _load() async {
    try {
      final j = jsonDecode(
        await rootBundle.loadString('assets/atlas/gbr-regions.json'),
      ) as Map<String, dynamic>;
      ui.Image? relief;
      try {
        final bytes = await rootBundle.load('assets/atlas/gbr-relief.jpg');
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        try {
          relief = (await codec.getNextFrame()).image;
        } finally {
          codec.dispose();
        }
      } catch (_) {
        /* Vector map and list stay available. */
      }
      return GbrMapData({
        for (final r in GbrRegion.values)
          r: GbrMapRegionData({
            'bounds': j['bounds'][r.key],
            'reliefBounds': j['reliefBounds'],
            'features': j['features'],
          }, relief: relief),
      });
    } catch (_) {
      _cache = null;
      rethrow;
    }
  }
}
