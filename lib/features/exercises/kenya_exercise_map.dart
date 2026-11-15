import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../map_engine/kenya_learning_map.dart';
import '../../map_engine/kenya_map_data.dart';

class KenyaExerciseMap extends StatefulWidget {
  const KenyaExerciseMap({
    super.key,
    required this.candidates,
    this.selected,
    this.onSelect,
  });
  final List<String> candidates;
  final String? selected;
  final ValueChanged<String>? onSelect;
  @override
  State<KenyaExerciseMap> createState() => _KenyaExerciseMapState();
}

class _KenyaExerciseMapState extends State<KenyaExerciseMap> {
  final data = KenyaMapData.load();
  final camera = KenyaMapController();
  @override
  Widget build(BuildContext context) => FutureBuilder<KenyaMapData>(
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
          if (widget.candidates.any((s) => s.startsWith('kenya-terrain-')))
            const Padding(
              padding: EdgeInsets.all(6),
              child: Text('概略教学区域 · 非行政或法定边界', style: TextStyle(fontSize: 12)),
            ),
          Expanded(
            child: KenyaLearningMap(
              region: KenyaRegion.all,
              data: snapshot.data!.all,
              places: context.atlas.content.placesIn('kenya'),
              layer: widget.candidates.any((id) => id.startsWith('kenya-lake-'))
                  ? 'water'
                  : 'terrain',
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
