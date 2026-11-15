import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../map_engine/usa_learning_map.dart';
import '../../map_engine/usa_map_data.dart';

class UsaExerciseMap extends StatefulWidget {
  const UsaExerciseMap({
    super.key,
    required this.candidates,
    this.selected,
    this.onSelect,
  });
  final List<String> candidates;
  final String? selected;
  final ValueChanged<String>? onSelect;

  @override
  State<UsaExerciseMap> createState() => _UsaExerciseMapState();
}

class _UsaExerciseMapState extends State<UsaExerciseMap> {
  final data = UsaMapData.load();
  final camera = UsaMapController();
  UsaRegion region = UsaRegion.conus;
  bool get hasInsets =>
      widget.candidates.any((id) => usaRegionFor(id) != UsaRegion.conus);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasInsets)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 5),
            child: Wrap(
              spacing: 5,
              children: [
                for (final item in UsaRegion.values)
                  ChoiceChip(
                    label: Text(item.label),
                    selected: item == region,
                    onSelected: (_) => setState(() => region = item),
                    selectedColor: AtlasPalette.orangeSoft,
                  ),
              ],
            ),
          ),
        Expanded(
          child: FutureBuilder<UsaMapData>(
            future: data,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('请用下面的文字选项。'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return UsaLearningMap(
                region: region,
                data: snapshot.data!.regions[region]!,
                places: context.atlas.content.placesIn('usa'),
                controller: camera,
                candidates: widget.candidates,
                selection: widget.selected,
                onSelect: widget.onSelect,
              );
            },
          ),
        ),
      ],
    );
  }
}
