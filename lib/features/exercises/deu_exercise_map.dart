import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../domain/atlas_content.dart';
import '../../map_engine/deu_learning_map.dart';
import '../../map_engine/deu_map_data.dart';

class DeuExerciseMap extends StatefulWidget {
  const DeuExerciseMap({
    super.key,
    required this.candidates,
    this.selected,
    this.onSelect,
  });
  final List<String> candidates;
  final String? selected;
  final ValueChanged<String>? onSelect;
  @override
  State<DeuExerciseMap> createState() => _DeuExerciseMapState();
}

class _DeuExerciseMapState extends State<DeuExerciseMap> {
  final data = DeuMapData.load();
  final camera = DeuMapController();
  @override
  Widget build(BuildContext context) => FutureBuilder<DeuMapData>(
    future: data,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Center(child: Text('地图暂时无法打开，请使用下面的文字选项。'));
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return Column(
        children: [
          if (widget.candidates.any((s) => s.startsWith('deu-terrain-')))
            const Padding(
              padding: EdgeInsets.all(6),
              child: Text('概略教学区域 · 非行政或法定边界', style: TextStyle(fontSize: 12)),
            ),
          Expanded(
            child: DeuLearningMap(
              region: DeuRegion.all,
              data: snapshot.data!.all,
              places: [
                ...context.atlas.content.placesIn('deu'),
                AtlasPlace.fromJson({
                  'id': 'deu-munich',
                  'countryId': 'deu',
                  'name': '慕尼黑',
                  'category': '城市',
                  'latitude': 48.137,
                  'longitude': 11.576,
                  'summary': '定位练习参考点',
                  'description': '',
                  'observation': '',
                  'mediaIds': <String>[],
                  'sourceUrl': 'https://www.muenchen.de/',
                }),
              ],
              controller: camera,
              candidates: widget.candidates,
              selection: widget.selected,
              onSelect: widget.onSelect,
            ),
          ),
        ],
      );
    },
  );
}
