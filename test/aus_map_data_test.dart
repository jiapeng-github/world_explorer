import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_explorer/map_engine/aus_map_profile.dart';
import 'package:world_explorer/map_engine/country_learning_map.dart';
import 'package:world_explorer/map_engine/atlas_map.dart';

void main() {
  test('Australia view includes mainland, capital and Tasmania', () {
    for (final (lat, lon) in [
      (-43.6, 146.8),
      (-35.28, 149.13),
      (-12.4, 130.8),
      (-31.95, 115.86),
    ]) {
      expect(ausMapProfile.bounds.contains(project(lat, lon)), isTrue);
    }
    expect(ausMapProfile.bounds.contains(project(-41, 174)), isFalse);
  });
  test('Murray and Darling preserve real polyline geometry', () {
    final j = jsonDecode(
      File(ausMapProfile.waterAsset).readAsStringSync(),
    ) as Map<String, dynamic>;
    final rivers = CountryMapData.parseRivers(j);
    expect(rivers.map((r) => r.id).toSet(), {'aus-murray', 'aus-darling'});
    for (final r in rivers) {
      expect(r.lines.expand((l) => l).length, greaterThan(30));
      expect(r.bounds.width, greaterThan(0));
    }
    expect(j['sourceArchiveSha256'], matches(RegExp(r'^[a-f0-9]{64}$')));
  });
  test(
    'Reef layer retains sourced linework rather than a fabricated park polygon',
    () {
      final j = jsonDecode(
        File(ausMapProfile.areaAsset!).readAsStringSync(),
      ) as Map<String, dynamic>;
      final f = j['features'].single;
      expect(f['geometry']['type'], 'MultiLineString');
      expect(f['geometry']['coordinates'].length, greaterThan(100));
      expect(j['note'], contains('不是海洋公园边界'));
      final reefs = CountryMapData.parseRivers(j);
      expect(reefs.single.id, 'aus-reef-distribution');
      expect(
        reefs.single.distanceTo(reefs.single.lines.first.first),
        closeTo(0, .00001),
      );
    },
  );
}
