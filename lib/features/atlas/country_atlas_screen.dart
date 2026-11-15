import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../domain/atlas_content.dart';
import '../../map_engine/country_learning_map.dart';

class CountryAtlasScreen extends StatefulWidget {
  const CountryAtlasScreen({
    super.key,
    required this.profile,
    this.placeId,
    this.featureId,
    this.layer,
    this.onPlaceSelected,
  });
  final CountryMapProfile profile;
  final String? placeId, featureId, layer;
  final ValueChanged<String>? onPlaceSelected;
  @override
  State<CountryAtlasScreen> createState() => _CountryAtlasScreenState();
}

class _CountryAtlasScreenState extends State<CountryAtlasScreen> {
  final controller = CountryMapController();
  final panel = DraggableScrollableController();
  late String layer;
  String? selected;
  double sheetExtent = .5;
  CountryMapProfile get profile => widget.profile;
  bool get egypt => profile.id == 'egypt';

  @override
  void initState() {
    super.initState();
    selected = widget.placeId ?? widget.featureId ?? profile.defaultPlace;
    layer = _layer(widget.layer);
    if (profile.id == 'zaf') sheetExtent = .34;
  }

  String _layer(String? value) => switch (value) {
    'biomes' || '生态' => profile.biomeAsset == null ? '地形' : '生态',
    '河流' || '水系' || 'rivers' || 'river' || 'water' => '河流',
    '地标' || '地点' || 'places' || 'landmarks' => '地标',
    _ => '地形',
  };

  @override
  void didUpdateWidget(CountryAtlasScreen old) {
    super.didUpdateWidget(old);
    if (old.placeId != widget.placeId || old.featureId != widget.featureId) {
      final next = widget.placeId ?? widget.featureId;
      selected = next;
      if (next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && selected == next) controller.focus(next);
        });
      }
    }
    if (old.layer != widget.layer) layer = _layer(widget.layer);
  }

  @override
  void dispose() {
    panel.dispose();
    super.dispose();
  }

  void _stepPanel() {
    if (!panel.isAttached) return;
    final target = sheetExtent < .45
        ? .5
        : sheetExtent < .8
        ? .85
        : .25;
    if (MediaQuery.disableAnimationsOf(context)) {
      panel.jumpTo(target);
    } else {
      panel.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void choose(String id, {bool focus = false}) {
    widget.onPlaceSelected?.call(id);
    setState(() {
      if (selected == null) sheetExtent = profile.id == 'zaf' ? .34 : .5;
      selected = id;
    });
    if (focus) controller.focus(id);
  }

  Future<void> showList({bool search = false}) async {
    final data = context.atlas.content;
    final places = data.placesIn(profile.id);
    var query = '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: SizedBox(
              height:
                  (MediaQuery.sizeOf(ctx).height -
                      MediaQuery.viewInsetsOf(ctx).bottom) *
                  .72,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
                    child: TextField(
                      autofocus: search,
                      decoration: InputDecoration(
                        labelText: '在${profile.name}找一个发现',
                        hintText: profile.searchPrompt,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) => update(() => query = value.trim()),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                      children: [
                        for (final f in profile.features.where(
                          (f) => '${f.name}${f.description}'.contains(query),
                        ))
                          ListTile(
                            leading: Icon(
                              f.river
                                  ? Icons.water
                                  : f.area
                                  ? Icons.terrain
                                  : Icons.location_city,
                            ),
                            title: Text(f.name),
                            subtitle: Text(
                              f.ecology
                                  ? '生态区 · IBGE 2019'
                                  : f.river
                                  ? '河流 · 在地图上看'
                                  : f.area
                                  ? '自然地理 · 示意标注'
                                  : '城市',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(
                                () => layer = f.ecology
                                    ? '生态'
                                    : f.river
                                    ? '河流'
                                    : '地形',
                              );
                              choose(f.id, focus: true);
                            },
                          ),
                        for (final p in places.where(
                          (p) => _matchesPlace(p, query),
                        ))
                          ListTile(
                            leading: SizedBox(
                              width: 56,
                              height: 48,
                              child: MediaPhoto(
                                p.mediaIds.firstOrNull ?? '',
                                width: 56,
                                height: 48,
                                radius: 8,
                              ),
                            ),
                            title: Text(p.name),
                            subtitle: Text(p.category),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() => layer = '地标');
                              choose(p.id, focus: true);
                            },
                          ),
                        if (!profile.features.any(
                              (f) =>
                                  '${f.name}${f.description}'.contains(query),
                            ) &&
                            !places.any((p) => _matchesPlace(p, query)))
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('还没有找到，试试${profile.searchExample}。'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _matchesPlace(AtlasPlace place, String query) =>
      '${place.name}${place.category}${place.summary}${place.aliases.join()}'
          .contains(query);

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            MediaQuery.sizeOf(context).width >= 1024 &&
            constraints.maxWidth >= 800;
        final data = context.atlas.content;
        final title = profile.id == 'japan'
            ? '日本探索地图'
            : constraints.maxWidth < 380
            ? '${profile.name}地图'
            : '${profile.name}探索地图';
        final inlineFilters =
            egypt && wide && MediaQuery.textScalerOf(context).scale(1) <= 1.15;
        Widget layerChoices() => Wrap(
          spacing: 7,
          runSpacing: 4,
          children: [
            for (final (name, icon) in [
              ('地形', Icons.landscape_outlined),
              ('河流', Icons.waves),
              if (profile.biomeAsset != null) ('生态', Icons.eco_outlined),
              ('地标', Icons.place_outlined),
            ])
              ChoiceChip(
                label: Text(switch (name) {
                  '河流' => profile.waterLabel,
                  '地标' => profile.placesLabel,
                  _ => name,
                }),
                avatar: (egypt || profile.id == 'zaf')
                    ? Icon(icon, size: 16)
                    : null,
                showCheckmark: false,
                selectedColor: AtlasPalette.orange,
                side: (egypt || profile.id == 'zaf')
                    ? BorderSide(
                        color: layer == name
                            ? AtlasPalette.orange
                            : AtlasPalette.line,
                      )
                    : null,
                selected: layer == name,
                onSelected: (_) => setState(() => layer = name),
              ),
          ],
        );
        final header = ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: '返回${profile.name}',
                  onPressed: () =>
                      backOrHome(context, '/countries/${profile.id}'),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontSize: egypt ? (wide ? 24 : 21) : null),
                  ),
                ),
                if (wide)
                  SizedBox(
                    width: inlineFilters ? 244 : 320,
                    child: OutlinedButton.icon(
                      onPressed: () => showList(search: true),
                      icon: const Icon(Icons.search),
                      label: Text(
                        profile.searchPrompt,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                else if (!egypt)
                  IconButton(
                    tooltip: '搜索${profile.name}地图',
                    onPressed: () => showList(search: true),
                    icon: const Icon(Icons.search),
                  ),
                if (inlineFilters) ...[
                  const SizedBox(width: 10),
                  layerChoices(),
                ],
                IconButton(
                  tooltip: '${profile.name}地点列表',
                  onPressed: showList,
                  icon: const Icon(Icons.format_list_bulleted),
                ),
              ],
            ),
          ),
        );
        final phoneSearch = Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showList(search: true),
              icon: const Icon(Icons.search),
              label: Text(profile.searchPrompt),
            ),
          ),
        );
        final filters = Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: layerChoices(),
        );
        Widget map() => CountryLearningMap(
          key: ValueKey('${profile.id}-exploration-map'),
          profile: profile,
          countries: data.countries,
          places: data.places,
          controller: controller,
          selectedId: selected,
          layer: layer,
          onSelect: choose,
          onClear: () => setState(() => selected = null),
        );
        if (wide) {
          return Column(
            children: [
              header,
              if (!inlineFilters) filters,
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: map()),
                    SizedBox(
                      width: 350,
                      child: ColoredBox(
                        color: Colors.white,
                        child: SingleChildScrollView(child: details()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            header,
            if (egypt) phoneSearch,
            filters,
            Expanded(
              child: LayoutBuilder(
                builder: (ctx, box) =>
                    NotificationListener<DraggableScrollableNotification>(
                      onNotification: (n) {
                        if ((sheetExtent - n.extent).abs() > .003) {
                          setState(() => sheetExtent = n.extent);
                        }
                        return false;
                      },
                      child: Stack(
                        children: [
                          Positioned.fill(
                            bottom: selected == null
                                ? 0
                                : box.maxHeight * sheetExtent,
                            child: map(),
                          ),
                          if (selected != null)
                            DraggableScrollableSheet(
                              controller: panel,
                              initialChildSize: profile.id == 'zaf' ? .34 : .5,
                              minChildSize: .25,
                              maxChildSize: .85,
                              snap: true,
                              snapSizes: profile.id == 'zaf'
                                  ? const [.25, .34, .85]
                                  : const [.25, .5, .85],
                              builder: (context, scroll) => Material(
                                color: Colors.white,
                                elevation: (egypt || profile.id == 'zaf')
                                    ? 0
                                    : 4,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                                child: ListView(
                                  controller: scroll,
                                  padding: EdgeInsets.zero,
                                  children: [
                                    Center(
                                      child: Container(
                                        width: 42,
                                        height: 4,
                                        margin: const EdgeInsets.only(top: 10),
                                        decoration: BoxDecoration(
                                          color: AtlasPalette.line,
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      ),
                                    ),
                                    details(phone: true),
                                  ],
                                ),
                              ),
                            ),
                          if (selected == null)
                            Positioned(
                              left: 18,
                              right: 18,
                              bottom: 8,
                              child: PrimaryAction(
                                egypt ? '地点列表' : '从地点列表开始',
                                onPressed: showList,
                                icon: Icons.list_alt,
                              ),
                            ),
                        ],
                      ),
                    ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget details({bool phone = false}) {
    final data = context.atlas.content;
    final p = data.place(selected ?? '');
    final f = profile.features.where((f) => f.id == selected).firstOrNull;
    if (p == null && f == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.travel_explore,
              size: 52,
              color: AtlasPalette.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              '点一个地方，看看它的故事',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text('拖动地图，或者从列表选择城市、河流和风景。'),
            const SizedBox(height: 20),
            PrimaryAction('打开地点列表', onPressed: showList),
            if (egypt)
              for (final place
                  in data
                      .placesIn(profile.id)
                      .where((p) => profile.featuredPlaces.contains(p.id)))
                ContentRow(
                  title: place.name,
                  subtitle: place.category,
                  mediaId: place.mediaIds.firstOrNull ?? '',
                  onTap: () => choose(place.id, focus: true),
                ),
          ],
        ),
      );
    }
    final name = p?.name ?? f!.name;
    final preferred = p?.mediaIds.firstOrNull ?? f?.mediaId ?? '';
    final mediaId = data.media.containsKey(preferred)
        ? preferred
        : data.article(f?.articleId ?? '')?.mediaId ?? '';
    final hasPhoto =
        mediaId.isNotEmpty &&
        data.media.containsKey(mediaId) &&
        (profile.id != 'japan' ||
            p != null ||
            (f?.mediaId.isNotEmpty ?? false));
    final route = p != null ? '/places/${p.id}' : '/articles/${f!.articleId}';
    final available = p != null || data.article(f!.articleId) != null;
    if (phone && profile.id == 'zaf') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasPhoto) ...[
                  MediaPhoto(
                    mediaId,
                    width: 82,
                    height: 82,
                    radius: 12,
                    showCredit: true,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p?.summary ?? f!.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AtlasPalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '收起地点',
                  onPressed: () => setState(() => selected = null),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: available ? () => context.push(route) : null,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(p != null ? '查看地点' : '阅读故事'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AtlasPalette.orange,
                      foregroundColor: AtlasPalette.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: '在地图上定位',
                  onPressed: () => controller.focus(selected!),
                  icon: const Icon(Icons.center_focus_strong),
                ),
                IconButton.filledTonal(
                  tooltip: '地点列表',
                  onPressed: showList,
                  icon: const Icon(Icons.format_list_bulleted),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final region = p == null
        ? (f!.river
              ? '${profile.waterLabel} · 看见水的旅程'
              : '${profile.name} · 自然与城市')
        : '${p.region.isEmpty ? profile.name : p.region} · ${p.category}';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        phone ? 20 : 24,
        phone ? 12 : 22,
        phone ? 20 : 24,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!phone && hasPhoto) ...[
            MediaPhoto(
              mediaId,
              width: double.infinity,
              height: 200,
              radius: 14,
              showCredit: true,
            ),
            const SizedBox(height: 18),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: (phone && egypt)
                      ? Theme.of(context).textTheme.titleLarge
                      : Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              if (phone && egypt)
                IconButton(
                  tooltip: sheetExtent >= .8 ? '折叠地点面板' : '展开地点面板',
                  onPressed: _stepPanel,
                  icon: Icon(
                    sheetExtent >= .8 ? Icons.expand_more : Icons.expand_less,
                  ),
                ),
              IconButton(
                tooltip: '收起地点',
                onPressed: () => setState(() => selected = null),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            region,
            style: const TextStyle(color: AtlasPalette.muted, fontSize: 15),
          ),
          if (egypt) ...[
            const SizedBox(height: 4),
            Text(
              p?.summary ?? f!.description,
              style: phone ? Theme.of(context).textTheme.bodySmall : null,
            ),
          ],
          if (phone && hasPhoto) ...[
            SizedBox(height: egypt ? 8 : 14),
            MediaPhoto(
              mediaId,
              width: double.infinity,
              height: egypt ? 93 : 138,
              radius: 14,
              showCredit: true,
            ),
          ],
          if (!egypt) ...[
            const SizedBox(height: 16),
            Text(
              p?.observation ?? f!.description,
              style: const TextStyle(
                fontSize: 18,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          SizedBox(height: phone && egypt ? 8 : 14),
          PrimaryAction(
            available
                ? (p != null ? (egypt ? '查看地点' : '走进$name') : '读一读它的故事')
                : '即将上线',
            arrow: available,
            onPressed: available ? () => context.push(route) : null,
          ),
          const SizedBox(height: 8),
          if (phone && egypt)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: showList,
                icon: const Icon(Icons.format_list_bulleted),
                label: const Text('地点列表'),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () => controller.focus(selected!),
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('在地图上定位'),
            ),
          if (p != null && !egypt) ...[
            const SizedBox(height: 12),
            Text(
              p.summary,
              style: const TextStyle(color: AtlasPalette.muted, height: 1.6),
            ),
          ],
          if (p?.id == 'nile-delta') ...[
            TextButton.icon(
              icon: const Icon(Icons.water),
              label: const Text('两条入海支流'),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final branch in profile.features.where(
                        (f) => f.id.startsWith('egypt-delta-'),
                      ))
                        ListTile(
                          title: Text(branch.name),
                          subtitle: Text(branch.description),
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() => layer = '河流');
                            choose(branch.id, focus: true);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.satellite_alt_outlined),
              label: const Text('去看卫星图'),
              onPressed: () => context.push('/places/nile-delta/gallery'),
            ),
          ],
          const SizedBox(height: 18),
          const Divider(),
          const EditorialHeading('看看附近的发现'),
          for (final nearby in _nearby(p, f).take(3))
            ContentRow(
              title: nearby.name,
              subtitle: nearby.category,
              mediaId: nearby.mediaIds.firstOrNull ?? '',
              onTap: () {
                setState(() => layer = '地标');
                choose(nearby.id, focus: true);
              },
            ),
          TextButton.icon(
            onPressed: showList,
            icon: const Icon(Icons.list_alt),
            label: Text('全部 ${data.placesIn(profile.id).length} 个地点'),
          ),
          TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (ctx) => SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '地图怎样制作',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '自然底图来自 NASA，陆地和海岸来自 Natural Earth 1:50m。${profile.waterCredit}',
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          '这是自然地理图，不是省级行政图或导航地图。区域标签是示意位置；部分小岛在此比例尺下不可见。放大不会增加原始数据的精度。',
                        ),
                        const SizedBox(height: 14),
                        const SelectableText(
                          'https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-rivers-lake-centerlines/',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            child: const Text('地图来源与图例'),
          ),
        ],
      ),
    );
  }

  List<AtlasPlace> _nearby(AtlasPlace? place, CountryMapFeature? feature) {
    final lat =
        place?.latitude ??
        feature?.latitude ??
        (profile.view.north + profile.view.south) / 2;
    final lon =
        place?.longitude ??
        feature?.longitude ??
        (profile.view.east + profile.view.west) / 2;
    double distance(AtlasPlace p) =>
        (p.latitude - lat) * (p.latitude - lat) +
        (p.longitude - lon) * (p.longitude - lon);
    return context.atlas.content
        .placesIn(profile.id)
        .where((p) => p.id != selected)
        .toList()
      ..sort((a, b) => distance(a).compareTo(distance(b)));
  }
}
