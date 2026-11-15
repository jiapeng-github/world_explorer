import 'package:flutter/material.dart';

import '../../map_engine/country_learning_map.dart';
import 'country_atlas_screen.dart';

class JapanAtlasScreen extends StatefulWidget {
  const JapanAtlasScreen({super.key, this.placeId, this.featureId, this.layer});
  final String? placeId, featureId, layer;
  @override
  State<JapanAtlasScreen> createState() => _JapanAtlasScreenState();
}

class _JapanAtlasScreenState extends State<JapanAtlasScreen> {
  static int regionOf(String? id) => switch (id) {
    'japan-naha' || 'japan-iriomote' => 1,
    'japan-chichijima' => 2,
    _ => 0,
  };
  late int region = regionOf(widget.placeId ?? widget.featureId);
  late final selections = <String?>[
    region == 0 ? widget.placeId : null,
    region == 1 ? widget.placeId : null,
    region == 2 ? widget.featureId : null,
  ];
  @override
  void didUpdateWidget(JapanAtlasScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placeId != widget.placeId ||
        oldWidget.featureId != widget.featureId) {
      region = regionOf(widget.placeId ?? widget.featureId);
      selections[region] = widget.placeId ?? widget.featureId;
    }
  }

  void select(String id) {
    final next = id.startsWith('japan-river-') ? 0 : regionOf(id);
    // Preserve each region's camera and sheet when switching tabs.
    if (next != region) {
      setState(() {
        region = next;
        selections[next] = id;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Wrap(
                spacing: 6,
                children: [
                  for (final (i, label) in ['主要列岛', '西南岛屿', '小笠原'].indexed)
                    ChoiceChip(
                      label: Text(label),
                      selected: region == i,
                      onSelected: (_) => setState(() => region = i),
                    ),
                ],
              ),
              const Text('各区域独立比例 · 切换后查看比例尺', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
      Expanded(
        child: IndexedStack(
          index: region,
          children: [
            for (final (i, profile) in [
              japanMapProfile,
              japanSouthwestProfile,
              japanOgasawaraProfile,
            ].indexed)
              CountryAtlasScreen(
                key: ValueKey(i),
                profile: profile,
                placeId: selections[i],
                featureId: regionOf(widget.featureId) == i
                    ? widget.featureId
                    : null,
                layer: widget.layer,
                onPlaceSelected: select,
              ),
          ],
        ),
      ),
    ],
  );
}
