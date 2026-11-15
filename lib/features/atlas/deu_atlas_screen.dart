import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../domain/atlas_content.dart';
import '../../map_engine/deu_learning_map.dart';
import '../../map_engine/deu_map_data.dart';
import '../../map_engine/atlas_map.dart';

class DeuAtlasScreen extends StatefulWidget {
  const DeuAtlasScreen({
    super.key,
    this.region,
    this.layer,
    this.placeId,
    this.featureId,
  });
  final String? region, layer, placeId, featureId;

  @override
  State<DeuAtlasScreen> createState() => _DeuAtlasScreenState();
}

class _RegionState {
  String layer = 'terrain';
  String? selected;
  double extent = .5;
}

class _DeuAtlasScreenState extends State<DeuAtlasScreen> {
  final controller = DeuMapController();
  final sheet = DraggableScrollableController();
  final views = {for (final region in DeuRegion.values) region: _RegionState()};
  Future<DeuMapData> future = DeuMapData.load();
  late DeuRegion region;
  _RegionState get view => views[region]!;

  @override
  void initState() {
    super.initState();
    _restoreLink();
  }

  @override
  void didUpdateWidget(DeuAtlasScreen oldWidget) {
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
        DeuRegion.parse(widget.region) ??
        deuRegionFor(requested) ??
        DeuRegion.all;
    view.selected = requested;
    view.layer = switch (widget.layer) {
      'water' || 'river' || 'rivers' || '水系' || '河流' => 'water',
      'places' || 'landmarks' || '地点' || '地标' => 'places',
      'terrain' || '地形' => 'terrain',
      'islands' => 'islands',
      _ =>
        widget.placeId != null
            ? 'places'
            : requested?.startsWith('deu-feature-') == true
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

  void _region(DeuRegion next) {
    if (next == region) return;
    setState(() => region = next);
  }

  void _choose(String id, {bool focus = false}) {
    if (deuRegionFor(id) == null) return;
    setState(() {
      region = deuRegionFor(id) ?? region;
      if (view.selected == null) view.extent = .5;
      view.selected = id;
      if (focus) {
        view.layer = id.startsWith('deu-island-')
            ? 'islands'
            : id.startsWith('deu-feature-')
            ? 'water'
            : deuPlaceParts.containsKey(id)
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
    final places = context.atlas.content.placesIn('deu');
    if (widget.region != null && DeuRegion.parse(widget.region) == null) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '请选择地图范围',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text('这个地区链接暂时无法识别。'),
            for (final r in DeuRegion.values)
              ListTile(
                title: Text(r.label),
                subtitle: Text(r.detail),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/atlas?country=deu&region=${r.key}'),
              ),
          ],
        ),
      );
    }
    return SafeArea(
      bottom: false,
      child: FutureBuilder<DeuMapData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('地图暂时无法打开，可以先从地点列表继续探索。'),
                OutlinedButton(
                  onPressed: () => setState(() => future = DeuMapData.load()),
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
              final map = DeuLearningMap(
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
                      '德国探索地图',
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
                                        // Drag updates the space reserved for the map on the next deume.
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

  Widget _insets(DeuMapData data) => ColoredBox(
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
                        selectedId: 'deu',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            for (final r in DeuRegion.values)
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
    DeuMapData data,
    List<AtlasPlace> places,
    AtlasPlace? place,
    DeuMapFeature? feature,
    bool group, {
    required bool compact,
  }) {
    final selected = view.selected;
    final water = group || feature?.isWater == true;
    final name = place?.name ?? feature?.name ?? region.label;
    final location = place?.region ?? region.detail;
    final image =
        place?.mediaIds.firstOrNull ??
        (selected == 'deu-feature-rhine' ? 'deu-m01' : null);
    final description =
        place?.description ??
        (water
            ? _waterDescription(selected!)
            : '${region.detail}。地形区域为有来源的概略教学范围，不是行政边界。劳西茨为文化区域示意，不是独立国家或单一州。');
    final waterArticle = selected == 'deu-feature-elbe'
        ? 'deu-hamburg'
        : 'deu-rhine';
    final related = places
        .where((p) => deuPlaceParts[p.id] == selected)
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
        if (place?.id == 'deu-koblenz')
          OutlinedButton.icon(
            icon: const Icon(Icons.water),
            label: const Text('沿莱茵河看'),
            onPressed: () => _choose('deu-feature-rhine', focus: true),
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
    'deu-feature-rhine' => '莱茵河跨越或沿着多个国家的地区延伸，经荷兰河口水系通向北海。国界不会截断河流。',
    'deu-feature-moselle' => '摩泽尔河在科布伦茨汇入莱茵河，河线保留源数据分段。',
    'deu-feature-elbe' => '易北河经过德国，也与捷克相连；汉堡港连接这条水道。',
    _ => '多瑙河从德国向东延伸，流经或沿着多个国家，最终到达黑海。图外河段继续存在。',
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
              '包含德国陆地与岛屿、邻国背景及跨境河流。北部低地与阿尔卑斯为 Natural Earth 自然区域裁切；中部山地与劳西茨为有来源的概略教学范围，不是法定边界。',
            ),
            ListTile(
              title: Text('Natural Earth · 1:10m'),
              subtitle: Text('Map Units 与河流 · Public domain'),
            ),
            ListTile(
              title: Text('NASA · Blue Marble'),
              subtitle: Text('独立投影重采样，地形影像仅作背景'),
            ),
            Text('ETRS89 / LAEA Europe（EPSG:3035）。比例尺为当地近似值；河道保留原始分段，不跨缺口补线。'),
          ],
        ),
      ),
    ),
  );

  Future<void> _showList(
    DeuMapData data,
    List<AtlasPlace> places, {
    bool search = false,
  }) async {
    final items = [
      const _SearchItem("deu", "德国", "欧洲中部", [
        "DE",
        "Germany",
        "Deutschland",
      ], Icons.public),
      for (final p in places)
        _SearchItem(p.id, p.name, '地点 · ${p.region}', [
          ...p.aliases,
          p.region,
          p.category,
        ], Icons.place_outlined),
      for (final f in data.regions.values.expand((r) => r.features))
        if (f.kind != 'context' || f.id == 'deu-context-irl')
          _SearchItem(
            f.id,
            f.name,
            f.kind == 'terrain'
                ? '自然或文化 · 教学区域'
                : f.kind == 'part'
                ? '德国 · 国家范围'
                : f.kind == 'island'
                ? '地理 · 岛屿'
                : f.kind == 'context'
                ? '独立国家 · 德国邻国'
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
                          hintText: '柏林、莱茵河、劳西茨',
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
      if (id == 'deu') {
        setState(() {
          region = DeuRegion.all;
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
    if (key.isEmpty) return deuPlaceParts.containsKey(id) ? 1 : 0;
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
