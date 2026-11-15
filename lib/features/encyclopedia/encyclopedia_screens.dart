import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../domain/atlas_content.dart';
import '../discover/discover_screen.dart' show QuestionTile;
import '../topics/topic_screens.dart';

class EncyclopediaScreen extends StatefulWidget {
  const EncyclopediaScreen({super.key});
  @override
  State<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends State<EncyclopediaScreen> {
  String continent = '全部';
  bool topics = false, sort = false;
  @override
  Widget build(BuildContext context) {
    final countries = context.atlas.content.featured
        .where((c) => (continent == '全部' || c.continent == continent))
        .toList();
    if (sort) countries.sort((a, b) => a.englishName.compareTo(b.englishName));
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            topics ? '跨国专题' : '国家百科',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.push('/search'),
                          tooltip: '搜索国家、地点或问题',
                          icon: const Icon(Icons.search_rounded, size: 30),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('国家')),
                          ButtonSegment(value: true, label: Text('专题')),
                        ],
                        selected: {topics},
                        showSelectedIcon: false,
                        onSelectionChanged: (v) =>
                            setState(() => topics = v.first),
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: AtlasPalette.navy,
                          selectedForegroundColor: Colors.white,
                          backgroundColor: AtlasPalette.canvas,
                          side: BorderSide.none,
                          minimumSize: const Size(150, 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (!topics)
                      Row(
                        children: [
                          Expanded(
                            child: FilterStrip(
                              values: const [
                                '全部',
                                '亚洲',
                                '欧洲',
                                '非洲',
                                '北美洲',
                                '南美洲',
                                '大洋洲',
                              ],
                              selected: continent,
                              onSelected: (v) => setState(() => continent = v),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() => sort = !sort),
                            label: Text(sort ? '英文 A–Z' : '精选顺序'),
                            icon: Icon(
                              Icons.sort_by_alpha,
                              color: sort
                                  ? AtlasPalette.blue
                                  : AtlasPalette.muted,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (topics)
              const SliverToBoxAdapter(child: TopicCards())
            else if (countries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AtlasEmpty(
                  title: '这里的国家内容即将上线',
                  message: '先看看其他大洲，新的国家会陆续加入。',
                  action: '查看全部国家',
                  onAction: () => setState(() => continent = '全部'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = (constraints.crossAxisExtent / 230)
                        .floor()
                        .clamp(2, 5);
                    return SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 14,
                        mainAxisExtent: constraints.crossAxisExtent < 420
                            ? 215
                            : 260,
                      ),
                      itemCount: countries.length,
                      itemBuilder: (context, i) => CountryCard(countries[i]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CountryCard extends StatelessWidget {
  const CountryCard(this.country, {super.key});
  final AtlasCountry country;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
      side: const BorderSide(color: AtlasPalette.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.push('/countries/${country.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: MediaPhoto(
              country.mediaId,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 8, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        country.name,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        country.tagline.isEmpty
                            ? country.continent
                            : country.tagline,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AtlasPalette.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 21),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class CountryScreen extends StatefulWidget {
  const CountryScreen(this.id, {super.key});
  final String id;
  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  bool allSections = false, visited = false, fullIntro = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!visited) {
      visited = true;
      final c = context.atlas.content.country(widget.id);
      if (c != null) {
        atlasAction(
          context,
          () => context.atlas.journal.visit('country', c.id, c.name),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.atlas.content.country(widget.id);
    if (c == null) {
      return const AtlasPage(
        title: '国家百科',
        child: AtlasEmpty(title: '还没有这个国家的资料', message: '回到百科，选择另一个地方。'),
      );
    }
    final content = context.atlas.content,
        places = content.placesIn(c.id),
        articles = content.articlesIn(c.id);
    final sections = countrySections.entries
        .where((s) => s.key != 'overview')
        .toList();
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: PrimaryAction(
                c.hasArticles ? '从国家概览开始' : '在地图上认识${c.name}',
                orange: true,
                onPressed: () => context.push(
                  c.hasArticles
                      ? '/countries/${c.id}/sections/overview'
                      : '/atlas?country=${c.id}',
                ),
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.sizeOf(context).width >= 700 ? 290 : 238,
            pinned: true,
            backgroundColor: AtlasPalette.navy,
            foregroundColor: Colors.white,
            leading: IconButton(
              tooltip: '返回',
              onPressed: () => backOrHome(context, '/encyclopedia'),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            ),
            actions: [
              SavedButton(
                kind: 'country',
                id: c.id,
                title: c.name,
                light: true,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  MediaPhoto(
                    c.mediaId,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x7303162D),
                          Colors.transparent,
                          Color(0x6603162D),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 74,
                    left: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          c.englishName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    bottom: -1,
                    left: 0,
                    right: 0,
                    height: 21,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '先认识这个国家',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          if (c.intro.isNotEmpty)
                            IconButton(
                              tooltip: fullIntro ? '收起完整介绍' : '展开完整介绍',
                              onPressed: () =>
                                  setState(() => fullIntro = !fullIntro),
                              icon: Icon(
                                fullIntro
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        c.intro.isEmpty
                            ? '${c.name}位于${c.continent}。从地图开始，观察它的海岸、邻国和位置。'
                            : fullIntro
                            ? c.intro
                            : '${c.intro.split('。').first}。',
                        style: const TextStyle(
                          color: AtlasPalette.muted,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AtlasPalette.canvas,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Wrap(
                          spacing: 18,
                          runSpacing: 10,
                          children: [
                            if (c.capital.isNotEmpty)
                              _fact(
                                Icons.account_balance_outlined,
                                '首都',
                                c.capital,
                              ),
                            if (c.facts.any((f) => f.label.contains('语言')))
                              _fact(
                                Icons.chat_bubble_outline_rounded,
                                '语言',
                                c.facts
                                    .firstWhere((f) => f.label.contains('语言'))
                                    .value,
                              ),
                            _fact(
                              Icons.location_on_outlined,
                              '位置',
                              c.continent,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (c.takeaways.isNotEmpty) ...[
                        LayoutBuilder(
                          builder: (context, constraints) => Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < c.takeaways.length; i++) ...[
                                if (i > 0) const SizedBox(width: 10),
                                Expanded(child: _takeaway(c, i)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                      ],
                      EditorialHeading('你想了解什么？'),
                      if (c.hasArticles)
                        LayoutBuilder(
                          builder: (context, constraints) => Wrap(
                            spacing: 10,
                            runSpacing: 9,
                            children: [
                              for (final entry
                                  in (allSections
                                      ? countrySections.entries
                                      : sections.take(6)))
                                SizedBox(
                                  width: (constraints.maxWidth - 10) / 2,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: AtlasPalette.line,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                      minimumSize: const Size(0, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => context.push(
                                      '/countries/${c.id}/sections/${entry.key}',
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(sectionIcon(entry.key), size: 23),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            entry.value,
                                            style: const TextStyle(
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          size: 19,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (c.hasArticles && !allSections)
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() => allSections = true),
                            child: const Text('查看全部 10 个栏目  ›'),
                          ),
                        ),
                      if (!c.hasArticles)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AtlasPalette.canvas,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '这里先提供位置与基础资料。深度文章还在编辑中，你可以继续探索已收录的国家。',
                          ),
                        ),
                      if (places.isNotEmpty) ...[
                        const Divider(),
                        EditorialHeading(
                          '地标与风景',
                          onAction: () => context.push(
                            '/countries/${c.id}/sections/landmarks',
                          ),
                        ),
                        SizedBox(
                          height:
                              154 +
                              56 * MediaQuery.textScalerOf(context).scale(1),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: places.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) => SizedBox(
                              width: 230,
                              child: QuestionTile(
                                title: places[i].name,
                                mediaId: places[i].mediaIds.firstOrNull ?? '',
                                route: '/places/${places[i].id}',
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (c.timeline.isNotEmpty) ...[
                        const EditorialHeading('沿着时间认识它'),
                        for (final event in c.timeline)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(
                                    top: 7,
                                    right: 14,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: AtlasPalette.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${event['period']} · ${event['title']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        event['body'],
                                        style: const TextStyle(
                                          color: AtlasPalette.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      if (articles.isNotEmpty) const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/atlas?country=${c.id}'),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('在地图上找到它'),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            context.push('/credits?entity=${c.id}'),
                        icon: const Icon(Icons.info_outline, size: 19),
                        label: const Text('资料来源与图片许可'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _takeaway(AtlasCountry country, int index) {
    const labels = <String, List<(String, String)>>{
      'egypt': [('尼罗河', '向北流入地中海'), ('古老遗迹', '金字塔与历史'), ('多样环境', '河谷、沙漠与海岸')],
      'china': [('辽阔山川', '从地图认识中国'), ('不同生活', '观察地方差异'), ('文化传承', '连接过去与今天')],
      'brazil': [('亚马孙河', '河流与雨林'), ('多彩生活', '语言与文化'), ('认识自然', '寻找生态联系')],
      'japan': [('南北岛屿', '环境各有不同'), ('文字线索', '认识日语书写'), ('富士山', '自然与文化相连')],
      'norway': [('峡湾', '冰川留下的地形'), ('午夜太阳', '高纬夏季的景象'), ('多样文化', '认识不同的生活')],
      'kenya': [('赤道与高山', '海拔也是线索'), ('多样语言', '不同社区的声音'), ('动物的家', '关注整个栖息地')],
    };
    final pair = labels[country.id]?[index] ?? ('发现 ${index + 1}', '点开了解更多');
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (sheetContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pair.$1,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    country.takeaways[index],
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('继续认识这个国家'),
                  ),
                ],
              ),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MediaPhoto(
              index == 0 && country.id == 'egypt'
                  ? 'nile-aswan'
                  : country.mediaId,
              height: 64,
              width: double.infinity,
              radius: 9,
            ),
            const SizedBox(height: 4),
            Text(
              pair.$1,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              pair.$2,
              style: const TextStyle(
                fontSize: 11,
                height: 1.5,
                color: AtlasPalette.muted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fact(IconData icon, String label, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: AtlasPalette.blue, size: 25),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AtlasPalette.muted),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ],
  );
}

class CountrySectionScreen extends StatelessWidget {
  const CountrySectionScreen({
    super.key,
    required this.countryId,
    required this.sectionId,
  });
  final String countryId, sectionId;
  @override
  Widget build(BuildContext context) {
    final c = context.atlas.content.country(countryId);
    if (c == null) {
      return const AtlasPage(
        title: '国家栏目',
        child: AtlasEmpty(title: '资料暂时不可用', message: '可以返回国家百科继续浏览。'),
      );
    }
    final ids = c.sections[sectionId] ?? [];
    final articles = ids
        .map(context.atlas.content.article)
        .whereType<AtlasArticle>()
        .toList();
    return AtlasPage(
      title: '${c.name} · ${countrySections[sectionId] ?? '百科'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediaPhoto(
            c.mediaId,
            width: double.infinity,
            height: 220,
            radius: 16,
            showCredit: true,
          ),
          const SizedBox(height: 22),
          Text(
            countrySections[sectionId] ?? '继续探索',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(c.intro, style: const TextStyle(color: AtlasPalette.muted)),
          const SizedBox(height: 20),
          if (sectionId == 'overview') ...[
            for (final fact in c.facts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 105,
                      child: Text(
                        fact.label,
                        style: const TextStyle(color: AtlasPalette.muted),
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
            const EditorialHeading('从这些文章开始'),
          ],
          for (final a in articles)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ContentRow(
                title: a.title,
                subtitle: a.summary,
                mediaId: a.mediaId,
                outlined: true,
                onTap: () => context.push('/articles/${a.id}'),
              ),
            ),
          if (sectionId == 'landmarks')
            for (final p in context.atlas.content.placesIn(c.id))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ContentRow(
                  title: p.name,
                  subtitle: p.summary,
                  mediaId: p.mediaIds.firstOrNull ?? '',
                  outlined: true,
                  onTap: () => context.push('/places/${p.id}'),
                ),
              ),
          if (articles.isEmpty && sectionId != 'landmarks')
            const AtlasEmpty(title: '这一页正在编辑中', message: '已有的文章仍然可以离线阅读。'),
        ],
      ),
    );
  }
}
