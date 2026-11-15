import 'package:flutter/material.dart';

import '../core/palette.dart';
import '../core/explorer_store.dart';
import '../models/catalog.dart';
import '../widgets/atlas_widgets.dart';
import '../widgets/world_map.dart';
import 'learning_screens.dart';
import 'country_encyclopedia.dart';
export 'country_encyclopedia.dart'
    show CountryScreen, TopicScreen, LandmarkScreen;

class WorldHome extends StatelessWidget {
  const WorldHome({super.key});
  @override
  Widget build(BuildContext context) {
    final store = ExplorerScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今天，想去哪里？',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '从一条河、一片森林、一个问题开始。',
                    style: TextStyle(color: AtlasColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              tooltip: '搜索国家',
              onPressed: () => openScreen(context, const SearchScreen()),
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const AtlasExplorer(),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => openScreen(context, const MapScreen()),
              icon: const Icon(Icons.open_in_full, size: 18),
              label: const Text('展开地图'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => openScreen(context, const SearchScreen()),
              child: const Text('查看目的地目录 →'),
            ),
          ],
        ),
        SectionHeading(
          '下一站，由好奇心决定',
          subtitle: '第一批目的地 · 内容可离线阅读',
          trailing: AtlasTag(
            '${store.catalog.countries.length} 个国家',
            icon: Icons.public,
          ),
        ),
        LayoutBuilder(
          builder: (context, c) => Wrap(
            spacing: 16,
            runSpacing: 16,
            children: store.catalog.countries
                .map(
                  (country) => SizedBox(
                    width: c.maxWidth > 800
                        ? (c.maxWidth - 32) / 3
                        : c.maxWidth > 540
                        ? (c.maxWidth - 16) / 2
                        : c.maxWidth,
                    child: CountryTile(country: country),
                  ),
                )
                .toList(),
          ),
        ),
        if (store.lastCountryId != null) ...[
          const SizedBox(height: 24),
          AtlasCard(
            color: AtlasColors.mint,
            onTap: () => openScreen(
              context,
              StoryScreen(country: store.catalog.country(store.lastCountryId!)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_stories_outlined,
                  color: AtlasColors.forest,
                  size: 30,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '接着上次的发现',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        store.catalog.country(store.lastCountryId!).story.title,
                        style: const TextStyle(color: AtlasColors.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: AtlasColors.forest),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

void openCountry(BuildContext context, Country country) {
  ExplorerScope.of(context).markVisited(country.id);
  openScreen(context, CountryScreen(country: country));
}

class CountryTile extends StatelessWidget {
  const CountryTile({super.key, required this.country});
  final Country country;
  @override
  Widget build(BuildContext context) {
    final store = ExplorerScope.of(context);
    return AtlasCard(
      onTap: () => openCountry(context, country),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(int.parse('FF${country.color}', radix: 16))
                      .withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    country.flagEmoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  country.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (store.completed.contains(country.id))
                const Icon(Icons.verified, color: AtlasColors.forest),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            country.question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  country.continent,
                  style: const TextStyle(
                    color: AtlasColors.muted,
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                size: 20,
                color: AtlasColors.forest,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MapScreen extends StatelessWidget {
  const MapScreen({super.key, this.initialCountryId, this.initialLandmarkId});
  final String? initialCountryId, initialLandmarkId;
  @override
  Widget build(BuildContext context) => ExplorerPage(
    title: '世界探索图集',
    subtitle: '从一片大陆，到一个真实的地方',
    actions: [
      IconButton(
        tooltip: '搜索国家',
        onPressed: () => openScreen(context, const SearchScreen()),
        icon: const Icon(Icons.search),
      ),
    ],
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        AtlasExplorer(
          initialCountryId: initialCountryId,
          initialLandmarkId: initialLandmarkId,
          expanded: true,
        ),
        const SizedBox(height: 18),
        const Text(
          '底图按大洲配色，颜色不代表地形或气候。使用 Natural Earth 简化地理数据，省略国界；地点为教学参考位置。',
          style: TextStyle(fontSize: 12, height: 1.6, color: AtlasColors.muted),
        ),
      ],
    ),
  );
}

class AtlasExplorer extends StatefulWidget {
  const AtlasExplorer({
    super.key,
    this.initialCountryId,
    this.initialLandmarkId,
    this.expanded = false,
  });
  final String? initialCountryId, initialLandmarkId;
  final bool expanded;
  @override
  State<AtlasExplorer> createState() => _AtlasExplorerState();
}

class _AtlasExplorerState extends State<AtlasExplorer> {
  String selected = 'egypt', region = '世界';
  String? landmarkId;
  bool landmarks = false;
  MapFocus? focus;
  @override
  void initState() {
    super.initState();
    selected = widget.initialCountryId ?? 'egypt';
    landmarkId = widget.initialLandmarkId;
    landmarks = landmarkId != null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initialCountryId != null && focus == null) {
      final c = ExplorerScope.of(context).catalog.country(selected);
      focus = _countryFocus(c);
    }
  }

  MapFocus _countryFocus(Country c) =>
      MapFocus(c.latitude, c.longitude, switch (c.id) {
        'egypt' => 5.0,
        'china' => 2.8,
        _ => 3.0,
      });
  void choose(Country c) => setState(() {
    selected = c.id;
    landmarkId = null;
    focus = _countryFocus(c);
  });
  @override
  Widget build(BuildContext context) {
    final store = ExplorerScope.of(context),
        countries = store.catalog.countries;
    final country = store.catalog.country(selected);
    final visible = countries
        .where((c) => region == '世界' || c.continent == region)
        .toList();
    final place = country.landmarks.firstWhere(
      (l) => l.id == landmarkId,
      orElse: () => country.landmarks.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final r in [
                '世界',
                ...countries.map((c) => c.continent).toSet(),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: ValueKey('map-region-$r'),
                    label: Text(r == '世界' ? '🌐  全世界' : r),
                    selected: region == r,
                    onSelected: (_) => setState(() {
                      region = r;
                      if (r == '世界') {
                        focus = const MapFocus(0, 0, 1);
                      } else {
                        final c = countries.firstWhere((c) => c.continent == r);
                        selected = c.id;
                        landmarkId = null;
                        focus = switch (r) {
                          '亚洲' => const MapFocus(32, 85, 2),
                          '非洲' => const MapFocus(5, 20, 2.1),
                          _ => const MapFocus(-18, -58, 2.2),
                        };
                      }
                    }),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 850;
            final map = Column(
              children: [
                Row(
                  children: [
                    for (final mode in [false, true])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          key: ValueKey(
                            mode
                                ? 'map-layer-landmarks'
                                : 'map-layer-countries',
                          ),
                          avatar: Icon(
                            mode ? Icons.place_outlined : Icons.public,
                            size: 16,
                          ),
                          label: Text(mode ? '地标' : '国家'),
                          selected: landmarks == mode,
                          onSelected: (_) => setState(() {
                            landmarks = mode;
                            landmarkId = null;
                            if (mode) focus = _countryFocus(country);
                          }),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      landmarks
                          ? '${country.name} · 3 处地标'
                          : '${visible.length} 个可读国家',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AtlasColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                WorldMap(
                  countries: visible,
                  selectedId: selected,
                  height: wide ? (widget.expanded ? 500 : 435) : 360,
                  focus: focus,
                  onSelect: (id) => choose(store.catalog.country(id)),
                  landmarks: country.landmarks,
                  showLandmarks: landmarks,
                  selectedLandmarkId: landmarks ? place.id : null,
                  onLandmarkSelect: (id) => setState(() => landmarkId = id),
                ),
              ],
            );
            final detail = AtlasCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!landmarks || place.photoAsset != null)
                    CountryPhotoView(country: country, height: wide ? 170 : 150)
                  else
                    Container(
                      height: 145,
                      width: double.infinity,
                      color: AtlasColors.mint,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.travel_explore,
                            size: 45,
                            color: AtlasColors.forest,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${country.name} · 地标观察',
                            style: const TextStyle(color: AtlasColors.forest),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            AtlasTag(
                              landmarks ? place.category : country.continent,
                            ),
                            if (store.completed.contains(country.id))
                              const AtlasTag('已有印章', icon: Icons.verified),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          landmarks
                              ? place.name
                              : '${country.flagEmoji} ${country.name}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          landmarks ? place.teaser : country.profile.tagline,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: AtlasColors.muted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!landmarks)
                          Wrap(
                            spacing: 14,
                            runSpacing: 8,
                            children: [
                              Text(
                                '首都 · ${country.profile.capital}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const Text(
                                '6 篇百科 · 3 处地标',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          key: const ValueKey('map-open-detail'),
                          onPressed: () => landmarks
                              ? openScreen(
                                  context,
                                  LandmarkScreen(
                                    country: country,
                                    landmark: place,
                                  ),
                                )
                              : openCountry(context, country),
                          icon: Icon(
                            landmarks
                                ? Icons.place_outlined
                                : Icons.menu_book_outlined,
                          ),
                          label: Text(
                            landmarks ? '读懂这处地标' : '打开${country.name}百科',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: map),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: detail,
                        ),
                      ),
                    ],
                  )
                : Column(children: [map, const SizedBox(height: 16), detail]);
          },
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in visible)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ActionChip(
                    key: ValueKey('atlas-country-${c.id}'),
                    avatar: Text(c.flagEmoji),
                    label: Text('${c.name}  ${selected == c.id ? '•' : '→'}'),
                    backgroundColor: selected == c.id
                        ? AtlasColors.mint
                        : Colors.white,
                    onPressed: () => choose(c),
                  ),
                ),
            ],
          ),
        ),
        if (landmarks) ...[
          const SizedBox(height: 18),
          for (var i = 0; i < country.landmarks.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AtlasCard(
                color: place.id == country.landmarks[i].id
                    ? AtlasColors.mint
                    : Colors.white,
                padding: const EdgeInsets.all(16),
                onTap: () =>
                    setState(() => landmarkId = country.landmarks[i].id),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: Colors.white,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: AtlasColors.forest,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        country.landmarks[i].name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: '在地图上定位${country.landmarks[i].name}',
                      onPressed: () => setState(() {
                        landmarkId = country.landmarks[i].id;
                        focus = MapFocus(
                          country.landmarks[i].latitude,
                          country.landmarks[i].longitude,
                          8,
                        );
                      }),
                      icon: const Icon(Icons.my_location, size: 20),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final search = TextEditingController();
  String region = '全部';
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countries = ExplorerScope.of(context).catalog.countries;
    final query = search.text.trim().toLowerCase();
    final results = countries
        .where(
          (c) =>
              (region == '全部' || c.continent == region) &&
              ('${c.name} ${c.englishName} ${c.subtitle} ${c.topics.map((t) => t.body).join(' ')}')
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    return ExplorerPage(
      title: '寻找下一站',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            key: const ValueKey('country-search'),
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '搜索国家、河流、雨林…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: '清空搜索',
                      onPressed: () {
                        search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['全部', ...countries.map((c) => c.continent).toSet()]
                .map(
                  (r) => ChoiceChip(
                    label: Text(r),
                    selected: region == r,
                    onSelected: (_) => setState(() => region = r),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          if (results.isEmpty)
            EmptyState(
              icon: Icons.travel_explore,
              title: '这一站还在准备中',
              message: '目前可以探索中国、埃及和巴西。\n换个词，或先去看看地图。',
              action: OutlinedButton(
                onPressed: () {
                  search.clear();
                  setState(() => region = '全部');
                },
                child: const Text('查看全部目的地'),
              ),
            )
          else
            ...results.map(
              (country) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CountryTile(country: country),
              ),
            ),
        ],
      ),
    );
  }
}

IconData topicIcon(String id) => switch (id) {
  'geography' => Icons.explore_outlined,
  'nature' => Icons.forest_outlined,
  'people' => Icons.people_outline,
  'culture' => Icons.waving_hand_outlined,
  'history' => Icons.account_balance_outlined,
  _ => Icons.extension_outlined,
};
void showCountryFacts(BuildContext context, Country country) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${country.flagEmoji} ${country.name}小名片',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...country.facts.map(
                  (fact) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            fact.label,
                            style: const TextStyle(color: AtlasColors.muted),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            fact.value,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    openScreen(
                      context,
                      MapScreen(initialCountryId: country.id),
                    );
                  },
                  icon: const Icon(Icons.public),
                  label: const Text('在地图上找一找'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
void showSources(BuildContext context, Country country) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('知识从哪里来？'),
    content: SizedBox(
      width: 580,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '百科实景照片标注了摄影署名与许可，故事插画标注为 AI 生成。文字依据下列资料整理。',
              style: TextStyle(color: AtlasColors.muted),
            ),
            const SizedBox(height: 16),
            ...country.sources.map(
              (source) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SelectableText(
                      source.url,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AtlasColors.forest,
                      ),
                    ),
                    Text(
                      '核验：${source.checkedAt}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AtlasColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('知道了'),
      ),
    ],
  ),
);

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final themes = ExplorerScope.of(context).catalog.themes;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('今天，你对什么好奇？', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        const Text(
          '从一个问题，走进更大的世界。',
          style: TextStyle(color: AtlasColors.muted),
        ),
        const SizedBox(height: 24),
        ...themes.map(
          (theme) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: AtlasCard(
              padding: EdgeInsets.zero,
              onTap: () =>
                  openScreen(context, ThemeJourneyScreen(theme: theme)),
              child: LayoutBuilder(
                builder: (context, c) {
                  final image = Illustration(
                    asset: theme.asset,
                    height: c.maxWidth > 700 ? 230 : 190,
                  );
                  final body = Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AtlasTag('主题探索', icon: Icons.route_outlined),
                        const SizedBox(height: 16),
                        Text(
                          theme.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          theme.subtitle,
                          style: const TextStyle(color: AtlasColors.muted),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => openScreen(
                            context,
                            ThemeJourneyScreen(theme: theme),
                          ),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('开始主题旅行'),
                        ),
                      ],
                    ),
                  );
                  return c.maxWidth > 700
                      ? Row(
                          children: [
                            Expanded(child: image),
                            Expanded(child: body),
                          ],
                        )
                      : Column(children: [image, body]);
                },
              ),
            ),
          ),
        ),
        const AtlasCard(
          color: AtlasColors.sand,
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AtlasColors.forest,
                size: 32,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  '不着急知道所有答案。\n把你的问题带在身边，也是一种发现。',
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ThemeJourneyScreen extends StatelessWidget {
  const ThemeJourneyScreen({super.key, required this.theme});
  final JourneyTheme theme;
  @override
  Widget build(BuildContext context) {
    final store = ExplorerScope.of(context);
    final countries = theme.countryIds.map(store.catalog.country).toList();
    return ExplorerPage(
      title: theme.title,
      subtitle: theme.subtitle,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          WorldMap(
            countries: countries,
            onSelect: (id) => openCountry(context, store.catalog.country(id)),
          ),
          const SectionHeading('沿着好奇，认识这些地方'),
          ...countries.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AtlasCard(
                onTap: () => openCountry(context, entry.value),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AtlasColors.mint,
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(color: AtlasColors.forest),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            entry.value.question,
                            style: const TextStyle(color: AtlasColors.muted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
