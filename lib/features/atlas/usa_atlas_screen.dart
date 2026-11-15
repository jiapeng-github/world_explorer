import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../domain/atlas_content.dart';
import '../../map_engine/usa_learning_map.dart';
import '../../map_engine/usa_map_data.dart';

class UsaAtlasScreen extends StatefulWidget {
  const UsaAtlasScreen({
    super.key,
    this.region,
    this.layer,
    this.placeId,
    this.featureId,
  });
  final String? region, layer, placeId, featureId;

  @override
  State<UsaAtlasScreen> createState() => _UsaAtlasScreenState();
}

class _RegionState {
  String layer = 'terrain';
  String? selected;
  double extent = .5;
}

class _UsaAtlasScreenState extends State<UsaAtlasScreen> {
  final controller = UsaMapController();
  final sheet = DraggableScrollableController();
  final views = {for (final region in UsaRegion.values) region: _RegionState()};
  Future<UsaMapData> future = UsaMapData.load();
  late UsaRegion region;
  _RegionState get view => views[region]!;

  @override
  void initState() {
    super.initState();
    _restoreLink();
  }

  @override
  void didUpdateWidget(UsaAtlasScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.region != widget.region ||
        oldWidget.layer != widget.layer ||
        oldWidget.placeId != widget.placeId ||
        oldWidget.featureId != widget.featureId) {
      _restoreLink();
      _focusAfterBuild(view.selected);
    }
  }

  void _restoreLink() {
    final requested = widget.placeId ?? widget.featureId;
    region =
        usaRegionFor(requested) ??
        UsaRegion.parse(widget.region) ??
        UsaRegion.conus;
    view.selected = requested;
    view.layer = switch (widget.layer) {
      'water' || 'river' || 'rivers' || '水系' || '河流' => 'water',
      'places' || 'landmarks' || '地点' || '地标' => 'places',
      'terrain' || '地形' => 'terrain',
      _ =>
        widget.placeId != null
            ? 'places'
            : requested?.startsWith('usa-feature-') == true
            ? 'water'
            : 'terrain',
    };
  }

  void _focusAfterBuild(String? id) {
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && view.selected == id) controller.focus(id);
    });
  }

  void _region(UsaRegion next) {
    if (next == region) return;
    setState(() => region = next);
  }

  void _choose(String id, {bool focus = false}) {
    final next = usaRegionFor(id);
    if (next == null) return;
    setState(() {
      region = next;
      if (view.selected == null) view.extent = .5;
      view.selected = id;
      if (focus) {
        view.layer = id.startsWith('usa-feature-')
            ? 'water'
            : usaPlaceStates.containsKey(id)
            ? 'places'
            : 'terrain';
      }
    });
    if (focus) _focusAfterBuild(id);
  }

  void _stepSheet() {
    if (!sheet.isAttached) return;
    final target = view.extent < .43
        ? .5
        : view.extent < .8
        ? .85
        : .25;
    if (MediaQuery.disableAnimationsOf(context)) {
      sheet.jumpTo(target);
    } else {
      sheet.animateTo(
        target,
        duration: const Duration(milliseconds: 210),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    sheet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final places = context.atlas.content.placesIn('usa');
    return SafeArea(
      bottom: false,
      child: FutureBuilder<UsaMapData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AtlasEmpty(
              title: '暂时无法打开美国地图',
              message: '请重新载入离线地图。',
              action: '重新载入地图',
              onAction: () => setState(() => future = UsaMapData.load()),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final mapData = data.regions[region]!;
          return LayoutBuilder(
            builder: (context, limits) {
              final wide =
                  limits.maxWidth >= 750 &&
                  MediaQuery.textScalerOf(context).scale(1) < 1.35;
              final selected = view.selected;
              final place = places.where((p) => p.id == selected).firstOrNull;
              final feature = mapData.features
                  .where((f) => f.id == selected)
                  .firstOrNull;
              final group = selected == usaGreatLakes;
              final hasSelection = place != null || feature != null || group;
              final map = UsaLearningMap(
                region: region,
                data: mapData,
                places: places,
                controller: controller,
                layer: view.layer,
                selection: selected,
                legendTop: wide ? 57 : 8,
                onSelect: _choose,
                onClear: () => setState(() => view.selected = null),
              );
              final search = OutlinedButton.icon(
                onPressed: () => _showList(data, places, search: true),
                icon: const Icon(Icons.search, size: 20),
                label: const Text('找州、河流或地点'),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  backgroundColor: const Color(0xffeef3f9),
                  side: const BorderSide(color: AtlasPalette.line),
                  minimumSize: const Size.fromHeight(42),
                ),
              );
              final tools = _layers();
              final details = _details(
                data,
                places,
                place,
                feature,
                group,
                compact: !wide,
              );
              final header = Row(
                children: [
                  IconButton(
                    onPressed: () => backOrHome(context, '/atlas'),
                    tooltip: '返回世界地图',
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      '美国探索地图',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (wide)
                    SizedBox(
                      width: math.min(360, limits.maxWidth * .35),
                      child: search,
                    )
                  else
                    IconButton(
                      tooltip: '地点列表',
                      icon: const Icon(Icons.list_alt_outlined),
                      onPressed: () => _showList(data, places),
                    ),
                ],
              );
              final insets = _insets(data);
              return ColoredBox(
                color: const Color(0xfff4f7fb),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 14 : 6,
                        6,
                        wide ? 16 : 8,
                        4,
                      ),
                      child: header,
                    ),
                    if (!wide)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 5),
                        child: search,
                      ),
                    if (!wide)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 5),
                        child: tools,
                      ),
                    Expanded(
                      child: wide
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(8, 4, 12, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(17),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: Column(
                                              children: [
                                                Expanded(child: map),
                                                insets,
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            left: 12,
                                            right: 64,
                                            child: Align(
                                              alignment: Alignment.topLeft,
                                              child: ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                      maxWidth: 326,
                                                    ),
                                                child: tools,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  SizedBox(
                                    width: limits.maxWidth >= 1050 ? 310 : 264,
                                    child: Card(
                                      margin: EdgeInsets.zero,
                                      color: Colors.white,
                                      child: ListView(
                                        key: ValueKey(selected),
                                        padding: const EdgeInsets.all(14),
                                        children: [details],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, body) => Stack(
                                children: [
                                  Positioned.fill(
                                    bottom: hasSelection
                                        ? body.maxHeight *
                                              view.extent.clamp(.25, .50)
                                        : 0,
                                    child: Column(
                                      children: [
                                        Expanded(child: map),
                                        insets,
                                      ],
                                    ),
                                  ),
                                  if (hasSelection)
                                    NotificationListener<
                                      DraggableScrollableNotification
                                    >(
                                      onNotification: (event) {
                                        final active = region;
                                        // Drag updates the space reserved for the map on the next frame.
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (mounted &&
                                                  region == active &&
                                                  view.selected == selected &&
                                                  (view.extent - event.extent)
                                                          .abs() >
                                                      .001) {
                                                setState(
                                                  () => view.extent =
                                                      event.extent,
                                                );
                                              }
                                            });
                                        return false;
                                      },
                                      child: DraggableScrollableSheet(
                                        key: ValueKey(region),
                                        controller: sheet,
                                        minChildSize: .25,
                                        initialChildSize: view.extent.clamp(
                                          .25,
                                          .85,
                                        ),
                                        maxChildSize: .85,
                                        snap: true,
                                        snapSizes: const [.5],
                                        builder: (context, scrolling) => Material(
                                          elevation: 0,
                                          color: Colors.white,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(20),
                                              ),
                                          child: ListView(
                                            controller: scrolling,
                                            padding: const EdgeInsets.fromLTRB(
                                              15,
                                              0,
                                              15,
                                              12,
                                            ),
                                            children: [
                                              Center(
                                                child: Semantics(
                                                  button: true,
                                                  label: '调整地点面板高度',
                                                  child: InkWell(
                                                    onTap: _stepSheet,
                                                    child: SizedBox(
                                                      width: 68,
                                                      height: 29,
                                                      child: Center(
                                                        child: Container(
                                                          width: 35,
                                                          height: 4,
                                                          decoration: BoxDecoration(
                                                            color: AtlasPalette
                                                                .muted,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              details,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _layers() => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AtlasPalette.line),
    ),
    child: Row(
      children: [
        for (final (id, text, icon) in const [
          ('terrain', '地形', Icons.terrain_outlined),
          ('water', '水系', Icons.water),
          ('places', '地点', Icons.place_outlined),
        ])
          Expanded(
            child: Semantics(
              selected: id == view.layer,
              button: true,
              child: Material(
                color: id == view.layer
                    ? AtlasPalette.orange
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                child: InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: () => setState(() => view.layer = id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 15, color: AtlasPalette.navy),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            text,
                            style: const TextStyle(
                              color: AtlasPalette.navy,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _insets(UsaMapData data) => ColoredBox(
    color: const Color(0xffa7d5ec),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(9, 4, 9, 7),
      child: region != UsaRegion.conus
          ? Row(
              children: [
                TextButton.icon(
                  onPressed: () => _region(UsaRegion.conus),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('返回全美概览'),
                ),
                Expanded(child: Text(region.label, textAlign: TextAlign.end)),
              ],
            )
          : Row(
              children: [
                for (final next in [UsaRegion.ak, UsaRegion.hi]) ...[
                  Expanded(
                    child: _RegionInset(
                      region: next,
                      data: data.regions[next]!,
                      onTap: () => _region(next),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                const Flexible(
                  child: Text(
                    '插图不按\n同一比例',
                    style: TextStyle(fontSize: 11, color: AtlasPalette.navy),
                  ),
                ),
              ],
            ),
    ),
  );

  Widget _details(
    UsaMapData data,
    List<AtlasPlace> places,
    AtlasPlace? place,
    UsaMapFeature? feature,
    bool group, {
    required bool compact,
  }) {
    final selected = view.selected;
    final water = group || feature?.isWater == true;
    final name = place?.name ?? feature?.name ?? (group ? '五大湖' : region.label);
    final location =
        place?.region ??
        (water
            ? '北美洲 · 水系'
            : feature?.kind == 'district'
            ? '联邦特区 · 美国东部'
            : feature?.id == 'usa-state-53'
            ? '州 · 美国西北部'
            : feature != null
            ? '州 · ${region.label}'
            : region.detail);
    final image =
        place?.mediaIds.firstOrNull ??
        (water
            ? switch (selected) {
                'usa-feature-colorado-river' => 'usa-m04',
                'usa-feature-mississippi-river' => 'usa-m36',
                _ => 'usa-m27',
              }
            : null);
    final description =
        place?.description ??
        (water
            ? _waterDescription(selected!)
            : feature != null
            ? '点亮的范围使用人口普查局制图边界。缩放地图，可以看清附近的州界和已收录的地点。'
            : '点选地图上的州、河流或地点。阿拉斯加和夏威夷有各自的地图和比例。');
    final waterArticle = switch (selected) {
      'usa-feature-colorado-river' => 'usa-grand-canyon-geology',
      'usa-feature-mississippi-river' => 'usa-two-waters',
      _ => 'usa-great-lakes',
    };
    final related = places
        .where((p) => usaPlaceStates[p.id] == selected)
        .toList();
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: compact ? 21 : 26,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          location,
          style: const TextStyle(
            color: AtlasPalette.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compact) ...[heading, const SizedBox(height: 7)],
        if (image != null) ...[
          MediaPhoto(
            image,
            width: double.infinity,
            height: compact ? 81 : 172,
            radius: 12,
          ),
          const SizedBox(height: 9),
        ],
        if (!compact) ...[heading, const SizedBox(height: 12)],
        if (place != null)
          PrimaryAction(
            '查看地点',
            onPressed: () => context.push('/places/${place.id}'),
          )
        else if (water)
          PrimaryAction(
            '读一读水系故事',
            onPressed: () => context.push('/articles/$waterArticle'),
          )
        else
          PrimaryAction('地点列表', onPressed: () => _showList(data, places)),
        const SizedBox(height: 10),
        if (place?.id == 'usa-grand-canyon')
          OutlinedButton.icon(
            icon: const Icon(Icons.water),
            label: const Text('沿科罗拉多河看'),
            onPressed: () => _choose('usa-feature-colorado-river', focus: true),
          ),
        if (place != null || water)
          OutlinedButton.icon(
            icon: const Icon(Icons.list_alt_outlined),
            label: const Text('地点列表'),
            onPressed: () => _showList(data, places),
          ),
        const SizedBox(height: 6),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
        for (final p in related)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.place_outlined),
            title: Text(p.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _choose(p.id, focus: true),
          ),
        if (feature != null && !water && related.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              '这个州的地点仍在整理中。',
              style: TextStyle(color: AtlasPalette.muted),
            ),
          ),
        if (group)
          for (final lake in data.regions[UsaRegion.conus]!.lakes)
            TextButton(
              onPressed: () => _choose(lake.id, focus: true),
              child: Text(lake.name),
            ),
        TextButton.icon(
          onPressed: _sources,
          icon: const Icon(Icons.info_outline, size: 16),
          label: const Text('地图范围与来源'),
        ),
      ],
    );
  }

  String _waterDescription(String id) => switch (id) {
    'usa-feature-colorado-river' =>
      '从落基山地一带流向西南，穿过大峡谷并进入墨西哥。蓝线使用 Natural Earth 的各段河道。',
    'usa-feature-mississippi-river' => '从美国北部流向墨西哥湾。对照新奥尔良河岸照片，看弯曲的河道怎样贴近城市。',
    'usa-feature-lake-michigan' => '密歇根湖全在美国境内，经麦基诺水道与休伦湖相连。',
    usaGreatLakes => '五个相连的大型淡水湖分布在美国和加拿大之间。密歇根湖全在美国境内，另外四个湖跨越美加国界。',
    _ => '这是五大湖之一，湖面跨越美国和加拿大。放大地图能看清湖岸轮廓。',
  };

  void _sources() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
        children: [
          Text('地图范围与来源', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            '相连 48 州、阿拉斯加、夏威夷共 50 州，另显示华盛顿特区。州界、河道和湖岸按制图比例简化。插图分别计算比例。',
          ),
          ListTile(
            title: const Text('美国人口普查局 · 2025 年制图边界'),
            subtitle: const Text('census.gov · 州和联邦特区'),
          ),
          ListTile(
            title: const Text('Natural Earth · 1:10m 水文'),
            subtitle: const Text('naturalearthdata.com · 科罗拉多河、密西西比河、五大湖'),
          ),
          ListTile(
            title: const Text('NASA · Blue Marble'),
            subtitle: const Text('science.nasa.gov · 区域地形底图'),
          ),
        ],
      ),
    ),
  );

  Future<void> _showList(
    UsaMapData data,
    List<AtlasPlace> places, {
    bool search = false,
  }) async {
    final items = [
      for (final p in places)
        _SearchItem(p.id, p.name, '地点 · ${p.region}', [
          ...p.aliases,
          p.region,
          p.category,
        ], Icons.place_outlined),
      const _SearchItem(usaGreatLakes, '五大湖', '水系 · 美加湖区', [
        'Great Lakes',
      ], Icons.water),
      for (final features in data.regions.values)
        for (final f in features.features)
          _SearchItem(
            f.id,
            f.name,
            f.id == 'usa-state-53'
                ? '州 · 美国西北部'
                : f.kind == 'district'
                ? '联邦特区 · 美国东部'
                : f.kind == 'state'
                ? '州 · ${usaRegionFor(f.id)!.label}'
                : f.kind == 'river'
                ? '河流 · 相连 48 州'
                : '湖泊 · 五大湖',
            [f.english, f.code, ...f.aliases],
            f.isWater ? Icons.water : Icons.map_outlined,
          ),
    ];
    var query = '';
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) {
          final hits =
              items
                  .map((item) => (item, item.rank(query)))
                  .where((entry) => entry.$2 >= 0)
                  .toList()
                ..sort((a, b) {
                  final order = b.$2.compareTo(a.$2);
                  return order == 0 ? a.$1.name.compareTo(b.$1.name) : order;
                });
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: SizedBox(
                height:
                    (MediaQuery.sizeOf(ctx).height -
                        MediaQuery.viewInsetsOf(ctx).bottom) *
                    .68,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: TextField(
                        autofocus: search,
                        decoration: const InputDecoration(
                          labelText: '找州、河流或地点',
                          hintText: '华盛顿、CO、科罗拉多河',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) =>
                            update(() => query = value.trim()),
                      ),
                    ),
                    Expanded(
                      child: hits.isEmpty
                          ? const Center(child: Text('没有找到。试试州名、缩写或地点名。'))
                          : ListView.builder(
                              itemCount: hits.length,
                              itemBuilder: (ctx, index) {
                                final item = hits[index].$1;
                                return ListTile(
                                  leading: Icon(item.icon),
                                  title: Text(item.name),
                                  subtitle: Text(item.category),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => Navigator.pop(ctx, item.id),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (mounted && id != null) _choose(id, focus: true);
  }
}

class _SearchItem {
  const _SearchItem(this.id, this.name, this.category, this.aliases, this.icon);
  final String id, name, category;
  final List<String> aliases;
  final IconData icon;

  int rank(String query) {
    String normalize(String value) =>
        value.toLowerCase().replaceAll(RegExp(r'[\s.,·]'), '');
    final key = normalize(query);
    if (key.isEmpty) return usaPlaceStates.containsKey(id) ? 1 : 0;
    final words = [
      name,
      ...aliases,
    ].where((word) => word.isNotEmpty).map(normalize);
    if (normalize(name) == key) return 4;
    if (words.contains(key)) return 3;
    if (words.any((word) => word.startsWith(key))) return 2;
    if (words.any((word) => word.contains(key))) return 1;
    return -1;
  }
}

class _RegionInset extends StatelessWidget {
  const _RegionInset({
    required this.region,
    required this.data,
    required this.onTap,
  });
  final UsaRegion region;
  final UsaMapRegionData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '查看${region.label}地图',
    button: true,
    child: Material(
      color: const Color(0xffa7d5ec),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(9),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).width >= 860 ? 88 : 53,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _InsetPainter(data)),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .94),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    region.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _InsetPainter extends CustomPainter {
  const _InsetPainter(this.data);
  final UsaMapRegionData data;
  ui.Image? get relief => data.relief;

  @override
  void paint(Canvas canvas, Size size) {
    final box = data.bounds;
    final scale = math.min(
      (size.width - 10) / box.width,
      (size.height - 5) / box.height,
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(
      size.width / 2 - box.center.dx * scale,
      size.height / 2 - box.center.dy * scale,
    );
    canvas.scale(scale);
    if (relief case final img?) {
      canvas.drawImageRect(
        img,
        Offset.zero & Size(img.width.toDouble(), img.height.toDouble()),
        data.reliefBounds,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    for (final f in data.features) {
      canvas.drawPath(
        f.path,
        Paint()
          ..color = const Color(0xff667f51)
              .withValues(alpha: relief == null ? 1 : .30),
      );
      canvas.drawPath(
        f.path,
        Paint()
          ..color = const Color(0xff526f51)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7 / scale,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InsetPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.relief != relief;
}
