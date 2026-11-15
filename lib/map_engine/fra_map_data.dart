import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'usa_map_data.dart' show UsaMapFeature, UsaMapRegionData;

typedef FraMapFeature = UsaMapFeature;
const fraPlaceParts = {
  'fra-seine-paris': 'fra-part-metropole',
  'fra-eiffel': 'fra-part-metropole',
  'fra-mont-saint-michel': 'fra-part-metropole',
  'fra-mer-de-glace': 'fra-part-metropole',
  'fra-camargue': 'fra-part-metropole',
  'fra-fournaise': 'fra-part-reunion',
  'fra-corte': 'fra-part-corsica',
  'fra-louvre': 'fra-part-metropole',
  'fra-lyon-market': 'fra-part-metropole',
  'fra-marseille-port': 'fra-part-metropole',
  'fra-loire-amboise': 'fra-part-metropole',
  'fra-strasbourg': 'fra-part-metropole',
};

enum FraRegion {
  metropole('欧洲部分', '欧洲大陆与科西嘉', 3, 46.5),
  guadeloupe('瓜德罗普', '加勒比海 · 多座岛屿', -61.5, 16.2),
  martinique('马提尼克', '加勒比海 · 岛屿', -61, 14.65),
  guiana('法属圭亚那', '南美洲大陆上的地区', -53.2, 4),
  reunion('留尼汪', '印度洋 · 马达加斯加以东', 55.5, -21.1),
  mayotte('马约特', '印度洋 · 法国实际管辖，科摩罗主张主权', 45.15, -12.8);

  const FraRegion(this.label, this.detail, this.lon, this.lat);
  final String label, detail;
  final double lon, lat;
  String get key => name;
  static FraRegion? parse(String? s) =>
      values.where((r) => r.key == s).firstOrNull;
  ui.Offset project(double latitude, double longitude) {
    const rad = math.pi / 180;
    if (this != metropole) {
      return ui.Offset(
        6371.0088 * (longitude - lon) * rad * math.cos(lat * rad),
        6371.0088 * (lat - latitude) * rad,
      );
    }
    final phi = latitude * rad;
    const e = .0818191910428158;
    final l = math.log(
      math.tan(math.pi / 4 + phi / 2) *
          math.pow((1 - e * math.sin(phi)) / (1 + e * math.sin(phi)), e / 2),
    );
    final r = 11754.255426096 * math.exp(-.725607765053267 * l),
        a = .725607765053267 * (longitude - 3) * rad;
    return ui.Offset(700 + r * math.sin(a), r * math.cos(a) - 12655.612049876);
  }

  double northRotation(ui.Offset p) =>
      this == metropole ? -math.atan2(p.dx - 700, p.dy + 12655.612049876) : 0;
}

FraRegion? fraRegionFor(String? id) {
  final part = fraPlaceParts[id] ?? id;
  if (part == 'fra-part-corsica') return FraRegion.metropole;
  if (part?.startsWith('fra-part-') == true) {
    return FraRegion.parse(part!.substring(9));
  }
  if (id?.startsWith('fra-') == true) return FraRegion.metropole;
  return null;
}

class FraMapRegionData extends UsaMapRegionData {
  FraMapRegionData(super.j, {super.relief}) : super.fromJson();
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

class FraMapData {
  FraMapData(this.regions);
  final Map<FraRegion, FraMapRegionData> regions;
  FraMapRegionData get all => regions[FraRegion.metropole]!;
  static Future<FraMapData>? _cache;
  static Future<FraMapData> load() => _cache ??= _load();
  static Future<FraMapData> _load() async {
    try {
      final j = jsonDecode(
        await rootBundle.loadString('assets/atlas/fra-regions.json'),
      ) as Map<String, dynamic>;
      final result = <FraRegion, FraMapRegionData>{};
      for (final r in FraRegion.values) {
        ui.Image? relief;
        try {
          final b = await rootBundle.load(
            'assets/atlas/fra-${r.key}-relief.jpg',
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
        result[r] = FraMapRegionData(
          j['regions'][r.key] as Map<String, dynamic>,
          relief: relief,
        );
      }
      return FraMapData(result);
    } catch (_) {
      _cache = null;
      rethrow;
    }
  }
}
