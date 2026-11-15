import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../map_engine/gbr_learning_map.dart';
import '../../map_engine/gbr_map_data.dart';

class GbrExerciseMap extends StatefulWidget {
  const GbrExerciseMap({
    super.key,
    required this.candidates,
    this.selected,
    this.onSelect,
  });
  final List<String> candidates;
  final String? selected;
  final ValueChanged<String>? onSelect;

  @override
  State<GbrExerciseMap> createState() => _GbrExerciseMapState();
}

class _GbrExerciseMapState extends State<GbrExerciseMap> {
  final data = GbrMapData.load();
  final camera = GbrMapController();
  GbrRegion region = GbrRegion.all;
  bool get hasInsets => false;

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
                for (final item in GbrRegion.values)
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
          child: FutureBuilder<GbrMapData>(
            future: data,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('请用下面的文字选项。'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return GbrLearningMap(
                region: region,
                data: snapshot.data!.regions[region]!,
                places: context.atlas.content.placesIn('gbr'),
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
