import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../domain/atlas_content.dart';
import '../../map_engine/kenya_learning_map.dart';
import '../../map_engine/kenya_map_data.dart';
import '../../map_engine/atlas_map.dart';

class KenyaAtlasScreen extends StatefulWidget {
  const KenyaAtlasScreen({
    super.key,
    this.region,
    this.layer,
    this.placeId,
    this.featureId,
  });
  final String? region, layer, placeId, featureId;

  @override
  State<KenyaAtlasScreen> createState() => _KenyaAtlasScreenState();
}

class _RegionState {
  String layer = 'terrain';
  String? selected;
  double extent = .5;
}

class _KenyaAtlasScreenState extends State<KenyaAtlasScreen> {
  final controller = KenyaMapController();
  final sheet = DraggableScrollableController();
  final views = {
    for (final region in KenyaRegion.values) region: _RegionState(),
  };
  Future<KenyaMapData> future = KenyaMapData.load();
  late KenyaRegion region;
  _RegionState get view => views[region]!;

  @override
  void initState() {
    super.initState();
    _restoreLink();
  }

  @override
  void didUpdateWidget(KenyaAtlasScreen oldWidget) {
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
        KenyaRegion.parse(widget.region) ??
        kenyaRegionFor(requested) ??
        KenyaRegion.all;
    view.selected = requested;
    view.layer = switch (widget.layer) {
      'water' || 'river' || 'rivers' || '水系' || '河流' => 'water',
      'places' || 'landmarks' || '地点' || '地标' => 'places',
      'terrain' || '地形' => 'terrain',
      'islands' => 'islands',
      _ =>
        widget.placeId != null
            ? 'places'
            : requested?.startsWith('kenya-lake-') == true
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

  void _region(KenyaRegion next) {
    if (next == region) return;
    setState(() => region = next);
  }

  void _choose(String id, {bool focus = false}) {
    if (kenyaRegionFor(id) == null) return;
    setState(() {
      region = kenyaRegionFor(id) ?? region;
      if (view.selected == null) view.extent = .5;
      view.selected = id;
      if (focus) {
        view.layer = id.startsWith('kenya-island-')
            ? 'islands'
            : id.startsWith('kenya-lake-')
            ? 'water'
            : kenyaPlaceParts.containsKey(id)
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
    final places = context.atlas.content.placesIn('kenya');
    if (widget.region != null && KenyaRegion.parse(widget.region) == null) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '请选择地图范围',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text('这个地区链接暂时无法识别。'),
            for (final r in KenyaRegion.values)
              ListTile(
                title: Text(r.label),
                subtitle: Text(r.detail),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/atlas?country=kenya&region=${r.key}'),
              ),
          ],
        ),
      );
    }
    return SafeArea(
      bottom: false,
      child: FutureBuilder<KenyaMapData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('地图暂时无法打开，可以先从地点列表继续探索。'),
                OutlinedButton(
                  onPressed: () => setState(() => future = KenyaMapData.load()),
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
              final map = KenyaLearningMap(
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
                label: const Text('找湖泊、参考线或地点'),
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
                      '肯尼亚探索地图',
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
                                  SizedBox(
                                    width: limits.maxWidth >= 1050 ? 340 : 300,
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
                                  const SizedBox(width: 14),
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
                                        // Drag updates the space reserved for the map on the next kenyame.
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

  Widget _insets(KenyaMapData data) => ColoredBox(
    color: const Color(0xffedf3f7),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            ActionChip(
              label: const Text('世界位置'),
              avatar: const Icon(Icons.public, size: 16),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (ctx) => SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      height: 310,
                      child: AtlasMap(
                        countries: context.atlas.content.countries,
                        selectedId: 'kenya',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            for (final r in KenyaRegion.values)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: ChoiceChip(
                  label: Text(r.label),
                  selected: r == region,
                  onSelected: (_) => _region(r),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _details(
    KenyaMapData data,
    List<AtlasPlace> places,
    AtlasPlace? place,
    KenyaMapFeature? feature,
    bool group, {
    required bool compact,
  }) {
    final selected = view.selected;
    final water = group || feature?.isWater == true;
    final name = place?.name ?? feature?.name ?? region.label;
    final location = place?.region ?? region.detail;
    final image =
        place?.mediaIds.firstOrNull ??
        (selected == 'kenya-lake-turkana'
            ? 'kenya-m15'
            : selected == 'kenya-lake-victoria'
            ? 'kenya-m18'
            : null);
    final description =
        place?.description ??
        (water
            ? _waterDescription(selected!)
            : '${region.detail}。赤道是纬度为零的参考线。北部伊莱米三角地区存在边界争议，以阴影和虚线单独标示。地点是代表位置，不是导航入口。');
    final waterArticle = 'kenya-water';
    final related = places
        .where((p) => kenyaPlaceParts[p.id] == selected)
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
        if (place?.id == 'kenya-turkana')
          OutlinedButton.icon(
            icon: const Icon(Icons.water),
            label: const Text('看看跨境湖面'),
            onPressed: () => _choose('kenya-lake-turkana', focus: true),
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
    'kenya-lake-turkana' => '图尔卡纳湖从肯尼亚北部延伸到埃塞俄比亚。湖面不会在国界处终止。',
    _ => '维多利亚湖由肯尼亚、乌干达和坦桑尼亚共享。基苏木是肯尼亚的湖岸城市之一。',
  };
  void _sources() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '地图范围与来源',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              '包含肯尼亚陆地与岛屿、邻国背景、跨境湖泊与赤道参考线。伊莱米三角地区为争议区域，单独标示；不绘制缺少可靠数据的湖岸或行政区。',
            ),
            ListTile(
              title: Text('Natural Earth · 1:10m'),
              subtitle: Text(
                'Map Units、Lakes、Boundary Lines、Disputed Areas · Public domain',
              ),
            ),
            ListTile(
              title: Text('NASA · Blue Marble'),
              subtitle: Text('独立投影重采样，地形影像仅作背景'),
            ),
            Text('WGS84 / LAEA，中心为北纬0°、东经38°。比例尺为当地近似值；跨境湖面不沿国界截断。'),
          ],
        ),
      ),
    ),
  );

  Future<void> _showList(
    KenyaMapData data,
    List<AtlasPlace> places, {
    bool search = false,
  }) async {
    final items = [
      const _SearchItem("kenya", "肯尼亚", "非洲东部", ["KE", "Kenya"], Icons.public),
      for (final p in places)
        _SearchItem(p.id, p.name, '地点 · ${p.region}', [
          ...p.aliases,
          p.region,
          p.category,
        ], Icons.place_outlined),
      for (final f in data.regions.values.expand((r) => r.features))
        if (f.kind != 'context')
          _SearchItem(
            f.id,
            f.name,
            f.kind == 'reference' || f.kind == 'border' || f.kind == 'coast'
                ? '地图参照线'
                : f.kind == 'disputed'
                ? '争议地区'
                : f.kind == 'part'
                ? '肯尼亚 · 国家范围'
                : f.kind == 'island'
                ? '地理 · 岛屿'
                : f.kind == 'context'
                ? '独立国家 · 肯尼亚邻国'
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
                          labelText: '找湖泊、参考线或地点',
                          hintText: '内罗毕、拉穆、图尔卡纳湖',
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
      if (id == 'kenya') {
        setState(() {
          region = KenyaRegion.all;
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
    if (key.isEmpty) return kenyaPlaceParts.containsKey(id) ? 1 : 0;
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
