import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../domain/atlas_content.dart';
import '../../map_engine/gbr_learning_map.dart';
import '../../map_engine/gbr_map_data.dart';

class GbrAtlasScreen extends StatefulWidget {
  const GbrAtlasScreen({
    super.key,
    this.region,
    this.layer,
    this.placeId,
    this.featureId,
  });
  final String? region, layer, placeId, featureId;

  @override
  State<GbrAtlasScreen> createState() => _GbrAtlasScreenState();
}

class _RegionState {
  String layer = 'terrain';
  String? selected;
  double extent = .5;
}

class _GbrAtlasScreenState extends State<GbrAtlasScreen> {
  final controller = GbrMapController();
  final sheet = DraggableScrollableController();
  final views = {for (final region in GbrRegion.values) region: _RegionState()};
  Future<GbrMapData> future = GbrMapData.load();
  late GbrRegion region;
  _RegionState get view => views[region]!;

  @override
  void initState() {
    super.initState();
    _restoreLink();
  }

  @override
  void didUpdateWidget(GbrAtlasScreen oldWidget) {
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
        GbrRegion.parse(widget.region) ??
        gbrRegionFor(requested) ??
        GbrRegion.all;
    view.selected = requested;
    view.layer = switch (widget.layer) {
      'water' || 'river' || 'rivers' || '水系' || '河流' => 'water',
      'places' || 'landmarks' || '地点' || '地标' => 'places',
      'terrain' || '地形' => 'terrain',
      'islands' => 'islands',
      _ =>
        widget.placeId != null
            ? 'places'
            : requested?.startsWith('gbr-feature-') == true
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

  void _region(GbrRegion next) {
    if (next == region) return;
    setState(() => region = next);
  }

  void _choose(String id, {bool focus = false}) {
    if (gbrRegionFor(id) == null) return;
    setState(() {
      if (region != GbrRegion.all && gbrRegionFor(id) != region) {
        region = GbrRegion.all;
      }
      if (view.selected == null) view.extent = .5;
      view.selected = id;
      if (focus) {
        view.layer = id.startsWith('gbr-island-')
            ? 'islands'
            : id.startsWith('gbr-feature-')
            ? 'water'
            : gbrPlaceParts.containsKey(id)
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
    final places = context.atlas.content.placesIn('gbr');
    return SafeArea(
      bottom: false,
      child: FutureBuilder<GbrMapData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('地图暂时无法打开，可以先从地点列表继续探索。'),
                OutlinedButton(
                  onPressed: () => setState(() => future = GbrMapData.load()),
                  child: const Text('重新载入地图'),
                ),
                for (final p in places)
                  ListTile(
                    title: Text(p.name),
                    subtitle: Text(p.region),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/places/${p.id}'),
                  ),
              ],
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
              const group = false;
              final hasSelection = place != null || feature != null || group;
              final map = GbrLearningMap(
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
                label: const Text('找地区、河流或地点'),
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
                      '英国探索地图',
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

  Widget _insets(GbrMapData data) => ColoredBox(
    color: const Color(0xffedf3f7),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            for (final r in GbrRegion.values)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: ChoiceChip(
                  label: Text(r.label),
                  selected: r == region,
                  onSelected: (_) => _region(r),
                ),
              ),
            ActionChip(
              label: Text(view.layer == 'islands' ? '返回组成部分' : '认识岛屿'),
              onPressed: () => setState(() {
                view.layer = view.layer == 'islands' ? 'terrain' : 'islands';
                view.selected = null;
              }),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _details(
    GbrMapData data,
    List<AtlasPlace> places,
    AtlasPlace? place,
    GbrMapFeature? feature,
    bool group, {
    required bool compact,
  }) {
    final selected = view.selected;
    final water = group || feature?.isWater == true;
    final name = place?.name ?? feature?.name ?? region.label;
    final location =
        place?.region ??
        (water
            ? '英国 · 水系'
            : feature?.kind == 'context'
            ? '邻近地区 · 不属于英国四组成部分'
            : feature?.kind == 'island'
            ? '岛屿 · 地理概念'
            : feature != null
            ? '英国的组成部分'
            : region.detail);
    final image =
        place?.mediaIds.firstOrNull ??
        (selected == 'gbr-feature-thames' ? 'gbr-m02' : null);
    final description =
        place?.description ??
        (water
            ? _waterDescription(selected!)
            : feature?.kind == 'island'
            ? (selected == 'gbr-island-great-britain'
                  ? '大不列颠岛包含英格兰、苏格兰和威尔士的主要陆地。英国还包括北爱尔兰和许多周边岛屿。'
                  : '这座岛上有爱尔兰和英国的北爱尔兰。岛屿的范围和国家的范围不同。')
            : feature?.kind == 'context'
            ? '爱尔兰是独立国家，北爱尔兰是英国的组成部分。地图上用不同范围表示。'
            : feature != null
            ? '点亮的范围为这个组成部分。下方列出已经收录的地点。'
            : '点选组成部分、河流或地点，也可以切到岛屿视图比较国家与岛的范围。');
    final waterArticle = selected == 'gbr-feature-loch-ness'
        ? 'gbr-glencoe-valley'
        : 'gbr-thames-city';
    final related = places
        .where((p) => gbrPlaceParts[p.id] == selected)
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
        if (place?.id == 'gbr-thames-london')
          OutlinedButton.icon(
            icon: const Icon(Icons.water),
            label: const Text('沿泰晤士河看'),
            onPressed: () => _choose('gbr-feature-thames', focus: true),
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
              '这里暂未收录独立地点，仍可比较地图范围。',
              style: TextStyle(color: AtlasPalette.muted),
            ),
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
    'gbr-feature-thames' => '泰晤士河穿过伦敦，向东通往北海。伦敦河段受潮汐影响，图上的河线是简化的地理范围。',
    'gbr-feature-severn' => '塞文河从威尔士山地流向英格兰，河口通向布里斯托尔海峡。河流与组成部分边界并不总重合。',
    _ => '尼斯湖位于苏格兰高地。湖面狭长，地图用实际湖岸形状表示，不以一个圆点代替湖泊。',
  };
  void _sources() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        children: [
          Text('地图范围与来源', style: Theme.of(ctx).textTheme.titleLarge),
          const Text(
            '英国四组成部分及周围地区。爱尔兰为独立国家；马恩岛等王室属地不计入四部分。全英范围含苏格兰北部群岛。区域切换共用同一LCC投影。',
          ),
          const ListTile(
            title: Text('Natural Earth · 1:10m'),
            subtitle: Text('Map Units 边界、河流与湖泊 · Public domain'),
          ),
          const ListTile(
            title: Text('NASA · Blue Marble'),
            subtitle: Text('投影重采样的地形影像 · 制作记录见内容包'),
          ),
          const Text('全国图形经过制图简化；用于地理学习。比例尺为地图中心附近的近似尺度。'),
        ],
      ),
    ),
  );

  Future<void> _showList(
    GbrMapData data,
    List<AtlasPlace> places, {
    bool search = false,
  }) async {
    final items = [
      const _SearchItem("gbr", "英国", "国家 · 四个组成部分", [
        "UK",
        "United Kingdom",
        "联合王国",
      ], Icons.public),
      for (final p in places)
        _SearchItem(p.id, p.name, '地点 · ${p.region}', [
          ...p.aliases,
          p.region,
          p.category,
        ], Icons.place_outlined),
      for (final f in data.all.features)
        if (f.kind != 'context' || f.id == 'gbr-context-irl')
          _SearchItem(
            f.id,
            f.name,
            f.kind == 'part'
                ? '英国 · 组成部分'
                : f.kind == 'island'
                ? '地理 · 岛屿'
                : f.kind == 'context'
                ? '独立国家 · 英国邻国'
                : '水系 · ${f.kind == 'river' ? '河流' : '湖泊'}',
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
                          labelText: '找地区、河流或地点',
                          hintText: '北爱尔兰、Cardiff、泰晤士河',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) =>
                            update(() => query = value.trim()),
                      ),
                    ),
                    Expanded(
                      child: hits.isEmpty
                          ? const Center(child: Text('没有找到。试试地区、英文别名或地点名。'))
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
    if (mounted && id != null) {
      if (id == 'gbr') {
        setState(() {
          region = GbrRegion.all;
          view.selected = null;
        });
        controller.reset();
      } else {
        _choose(id, focus: true);
      }
    }
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
    if (key.isEmpty) return gbrPlaceParts.containsKey(id) ? 1 : 0;
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
