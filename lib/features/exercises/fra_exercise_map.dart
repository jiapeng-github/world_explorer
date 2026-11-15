import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../map_engine/fra_learning_map.dart';
import '../../map_engine/fra_map_data.dart';
import '../../map_engine/fra_world_locator.dart';

class FraExerciseMap extends StatefulWidget {
  const FraExerciseMap({
    super.key,
    required this.candidates,
    this.selected,
    this.onSelect,
  });
  final List<String> candidates;
  final String? selected;
  final ValueChanged<String>? onSelect;
  @override
  State<FraExerciseMap> createState() => _FraExerciseMapState();
}

class _FraExerciseMapState extends State<FraExerciseMap> {
  final data = FraMapData.load();
  final camera = FraMapController();
  FraRegion region = FraRegion.metropole;
  bool get overseas => widget.candidates.contains('fra-part-reunion');
  @override
  void didUpdateWidget(FraExerciseMap old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected && overseas) {
      region = fraRegionFor(widget.selected) ?? region;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candidates.any((id) => id.startsWith('fra-ocean-'))) {
      return FraWorldLocator(
        selected: widget.selected,
        onSelect: widget.onSelect,
        oceanExercise: true,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (overseas)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final r in [
                  FraRegion.metropole,
                  FraRegion.reunion,
                  FraRegion.martinique,
                  FraRegion.guiana,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ChoiceChip(
                      label: Text(r.label),
                      selected: r == region,
                      onSelected: widget.onSelect == null
                          ? null
                          : (_) => setState(() => region = r),
                    ),
                  ),
              ],
            ),
          ),
        if (overseas)
          const Text(
            '先选择地区，再点选真实岛面或大陆区域。每图独立比例。',
            style: TextStyle(fontSize: 12),
          ),
        Expanded(
          child: FutureBuilder<FraMapData>(
            future: data,
            builder: (ctx, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('地图暂时无法打开，请用下面的文字选项。'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return FraLearningMap(
                region: region,
                data: snapshot.data!.regions[region]!,
                places: context.atlas.content.placesIn('fra'),
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
