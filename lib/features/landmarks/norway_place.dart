import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../design/photo_points.dart';
import '../../domain/atlas_content.dart';
import '../../map_engine/norway_map_data.dart';

class NorwayPlace extends StatefulWidget {
  const NorwayPlace(this.place, {super.key});
  final AtlasPlace place;
  @override
  State<NorwayPlace> createState() => _NorwayPlaceState();
}

class _NorwayPlaceState extends State<NorwayPlace> {
  int index = 0;
  int? selected;
  @override
  Widget build(BuildContext context) {
    final p = widget.place, media = p.mediaIds[index];
    final points = p.hotspots.where((h) => h['mediaId'] == media).toList();
    final region = norwayRegionFor(p.id) ?? NorwayRegion.mainland;
    return AtlasPage(
      title: '挪威 · 地点',
      width: 820,
      padding: const EdgeInsets.all(18),
      actions: [SavedButton(kind: 'place', id: p.id, title: p.name)],
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push(
                  '/atlas?country=norway&region=${region.key}&place=${p.id}',
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text('在地图上找它'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AtlasPalette.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => context.push(
                  '/countries/norway/observe/place/${p.id}?media=$media',
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('记下我的发现'),
              ),
            ],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            p.name,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(p.summary, style: const TextStyle(fontSize: 17, height: 1.65)),
          const SizedBox(height: 18),
          if (points.isEmpty)
            MediaPhoto(
              media,
              width: double.infinity,
              height: 250,
              radius: 16,
              showCredit: true,
            )
          else
            PhotoPoints(
              key: ValueKey(media),
              mediaId: media,
              points: points,
              selected: selected,
              onSelect: (i) => setState(() => selected = i),
            ),
          if (selected != null && points.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '${points[selected!]['label']}：${points[selected!]['explanation']}',
                style: const TextStyle(fontSize: 16, height: 1.65),
              ),
            ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, box) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (i, id) in p.mediaIds.indexed)
                  SizedBox(
                    width: MediaQuery.textScalerOf(context).scale(1) > 1.3
                        ? box.maxWidth
                        : (box.maxWidth - 10) / 2,
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: i == index
                              ? AtlasPalette.orange
                              : AtlasPalette.line,
                          width: i == index ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => setState(() {
                          index = i;
                          selected = null;
                        }),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MediaPhoto(id, height: 95, width: double.infinity),
                            Padding(
                              padding: const EdgeInsets.all(9),
                              child: Text(
                                '素材 ${i + 1} · ${i == index ? '正在观察' : '点击查看'}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AtlasPalette.sea,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '地点代表位置 · ${p.region}\n${p.latitude.toStringAsFixed(2)}°N，${p.longitude.toStringAsFixed(2)}°E\n点位不是完整范围、摄影坐标或导航入口。',
              style: const TextStyle(fontSize: 14, height: 1.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            p.description,
            style: const TextStyle(fontSize: 16, height: 1.7),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => context.push('/credits?entity=${p.id}'),
                icon: const Icon(Icons.info_outline),
                label: const Text('素材来源与许可'),
              ),
              TextButton.icon(
                onPressed: () => context.push('/places/${p.id}/gallery'),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('查看完整图片'),
              ),
            ],
          ),
          for (final id in p.articleIds)
            TextButton.icon(
              onPressed: () => context.push('/articles/$id'),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('继续阅读相关内容'),
            ),
        ],
      ),
    );
  }
}
