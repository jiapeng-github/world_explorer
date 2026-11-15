import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../map_engine/norway_learning_map.dart';
import '../../map_engine/norway_map_data.dart';

class NorwayExerciseMap extends StatefulWidget {
  const NorwayExerciseMap({
    super.key,
    required this.candidates,
    this.selected,
    this.onSelect,
  });
  final List<String> candidates;
  final String? selected;
  final ValueChanged<String>? onSelect;
  @override
  State<NorwayExerciseMap> createState() => _NorwayExerciseMapState();
}

class _NorwayExerciseMapState extends State<NorwayExerciseMap> {
  final data = NorwayMapData.load();
  final camera = NorwayMapController();
  NorwayRegion region = NorwayRegion.mainland;
  @override
  void initState() {
    super.initState();
    region = norwayRegionFor(widget.selected) ?? NorwayRegion.mainland;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<NorwayMapData>(
    future: data,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Center(child: Text('地图暂时无法打开，请使用下面的文字选项。'));
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final multiple = widget.candidates.any(
        (id) => id == 'norway-part-svalbard',
      );
      return Column(
        children: [
          if (multiple)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final r in NorwayRegion.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        label: Text(r.label),
                        selected: r == region,
                        onSelected: (_) => setState(() => region = r),
                      ),
                    ),
                ],
              ),
            ),
          if (multiple)
            const Text(
              '分图比例尺不同 · 切换查看后，点选岛屿范围并确认',
              style: TextStyle(fontSize: 11),
            ),
          Expanded(
            child: NorwayLearningMap(
              region: region,
              data: snapshot.data!.regions[region]!,
              places: context.atlas.content.placesIn('norway'),
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
