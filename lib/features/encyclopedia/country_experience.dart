import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../design/photo_points.dart';
import '../../domain/atlas_content.dart';
import '../../map_engine/country_learning_map.dart';
import '../reader/learning_diagrams.dart';
import 'fra_overview.dart';
import 'deu_overview.dart';
import 'kenya_overview.dart';
import 'norway_overview.dart';
import 'norway_experience.dart';
import 'kenya_experience.dart';
import 'deu_experience.dart';
import 'zaf_overview.dart';
import 'aus_overview.dart';
import 'brazil_overview.dart';
import 'japan_overview.dart';

List<Json> editorialList(Json data, String key) =>
    List<Json>.from(data[key] ?? []);

bool _atlasEdition(String? id) =>
    id == 'aus' ||
    id == 'zaf' ||
    id == 'egypt' ||
    id == 'usa' ||
    id == 'gbr' ||
    id == 'norway' ||
    id == 'kenya' ||
    id == 'deu' ||
    id == 'fra' ||
    id == 'brazil' ||
    id == 'japan';

class CountryExperienceScreen extends StatefulWidget {
  const CountryExperienceScreen(this.id, {super.key});
  final String id;
  @override
  State<CountryExperienceScreen> createState() =>
      _CountryExperienceScreenState();
}

class _CountryExperienceScreenState extends State<CountryExperienceScreen> {
  bool expanded = false, visited = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = context.atlas.content.country(widget.id);
    if (!visited && c != null) {
      visited = true;
      atlasAction(
        context,
        () => context.atlas.journal.visit('country', c.id, c.name),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = context.atlas.content, c = content.country(widget.id);
    if (c == null) {
      return const AtlasPage(
        title: '国家百科',
        child: AtlasEmpty(title: '资料暂不可用', message: '返回百科继续探索。'),
      );
    }
    if (c.id == 'aus') return AustraliaOverview(c);
    if (c.id == 'zaf') return SouthAfricaOverview(c);
    if (c.id == 'norway') return NorwayOverview(c);
    if (c.id == 'kenya') return KenyaOverview(c);
    if (c.id == 'deu') return GermanyOverview(c);
    if (c.id == 'fra') return FranceOverview(c);
    if (c.id == 'brazil') return BrazilOverview(c);
    if (c.id == 'japan') return JapanOverview(c);
    final journeys = editorialList(c.editorial, 'journeys');
    final places = content.placesIn(c.id);
    final atlasEdition = _atlasEdition(c.id);
    final featured = List<String>.from(c.editorial['featuredPlaceIds'] ?? [])
        .map(content.place)
        .whereType<AtlasPlace>()
        .toList();
    final questions = List<String>.from(
      c.editorial['questionArticleIds'] ??
          ['${c.id}-geography', '${c.id}-canal-history'],
    ).map(content.article).whereType<AtlasArticle>();
    return ListenableBuilder(
      listenable: context.atlas.journal,
      builder: (context, _) {
        final progress =
            context.atlas.journal.progress.entries
                .where(
                  (entry) =>
                      content.article(entry.key)?.countryId == c.id &&
                      entry.value['completed'] != 1,
                )
                .toList()
              ..sort(
                (a, b) => (b.value['updated_at'] as String).compareTo(
                  a.value['updated_at'] as String,
                ),
              );
        final resume = progress.isEmpty
            ? null
            : content.article(progress.first.key);
        return Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: _CountryBottom(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        context.push('/countries/${c.id}/contents'),
                    child: const Text('浏览全部主题'),
                  ),
                ),
                PrimaryAction(
                  resume == null
                      ? (c.editorial['startLabel'] as String? ?? '从山河开始')
                      : '继续阅读：${resume.title}',
                  orange: true,
                  onPressed: () => context.push(
                    resume == null
                        ? '/countries/${c.id}/journeys/${c.editorial['startJourneyId'] ?? journeys.firstOrNull?['id'] ?? 'mountains'}'
                        : '/articles/${resume.id}',
                  ),
                ),
              ],
            ),
          ),
          body: CustomScrollView(
            key: PageStorageKey('country-${c.id}'),
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: MediaQuery.sizeOf(context).width >= 700
                    ? 220
                    : atlasEdition
                    ? 254
                    : 286,
                backgroundColor: AtlasPalette.navy,
                foregroundColor: Colors.white,
                leading: IconButton(
                  tooltip: '返回',
                  onPressed: () => backOrHome(context, '/encyclopedia'),
                  icon: const Icon(Icons.arrow_back_ios_new),
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
                              Color(0x30061B30),
                              Color(0x10061B30),
                              Color(0xD9061B30),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: atlasEdition ? 33 : 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: const TextStyle(
                                fontSize: 46,
                                height: 1.15,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              c.englishName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                letterSpacing: 2,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              c.editorial['subtitle'] ?? '从高山到大海，发现${c.name}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (atlasEdition)
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 18,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(22),
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
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Padding(
                      padding: atlasEdition
                          ? const EdgeInsets.fromLTRB(15, 2, 15, 32)
                          : const EdgeInsets.fromLTRB(22, 24, 22, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '先认识${c.name}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          SizedBox(height: atlasEdition ? 5 : 8),
                          Text(
                            c.editorial['introduction'] ?? '沿着山川、生活与文明，读懂这片土地。',
                            style: const TextStyle(
                              color: AtlasPalette.muted,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FactStrip(country: c),
                          if (!atlasEdition)
                            ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: const Text('更多国家资料'),
                              children: [
                                Text(
                                  c.intro,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 12),
                                for (final fact in c.facts)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 105,
                                          child: Text(
                                            fact.label,
                                            style: const TextStyle(
                                              color: AtlasPalette.muted,
                                            ),
                                          ),
                                        ),
                                        Expanded(child: Text(fact.value)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          SizedBox(height: atlasEdition ? 16 : 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final single =
                                  MediaQuery.textScalerOf(context).scale(1) >
                                  1.3;
                              return Wrap(
                                spacing: 10,
                                runSpacing: 12,
                                children: [
                                  for (final journey in journeys)
                                    SizedBox(
                                      width: single
                                          ? constraints.maxWidth
                                          : (constraints.maxWidth - 20) / 3,
                                      child: _JourneyTile(
                                        country: c,
                                        journey: journey,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const EditorialHeading('你想先发现什么？'),
                          for (final a in questions)
                            _QuestionLink(
                              title: a.title,
                              icon: atlasEdition && a.sectionId == 'geography'
                                  ? Icons.waves
                                  : Icons.landscape_outlined,
                              onTap: () => context.push('/articles/${a.id}'),
                            ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () =>
                                context.push('/atlas?country=${c.id}'),
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('在地图上看看'),
                          ),
                          EditorialHeading(
                            '你想了解什么？',
                            actionLabel: '完整目录',
                            onAction: () =>
                                context.push('/countries/${c.id}/contents'),
                          ),
                          CountrySectionDirectory(
                            country: c,
                            limit: expanded ? null : 6,
                          ),
                          if (!expanded)
                            Center(
                              child: TextButton(
                                onPressed: () =>
                                    setState(() => expanded = true),
                                child: const Text('查看全部 10 个栏目 ›'),
                              ),
                            ),
                          if (countryMapProfile(c.id) case final profile?) ...[
                            const EditorialHeading('在地图上找找联系'),
                            Semantics(
                              button: true,
                              label: '打开${c.name}探索地图',
                              child: GestureDetector(
                                onTap: () =>
                                    context.push('/atlas?country=${c.id}'),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    height: 200,
                                    child: ExcludeSemantics(
                                      child: IgnorePointer(
                                        child: CountryLearningMap(
                                          profile: profile,
                                          countries: content.countries,
                                          places: places,
                                          layer: '河流',
                                          showControls: false,
                                          showLegend: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (places.isNotEmpty) ...[
                            EditorialHeading(
                              '地标与风景',
                              onAction: () => context.push(
                                '/countries/${c.id}/sections/landmarks',
                              ),
                            ),
                            _PlacesGrid(
                              places: atlasEdition && featured.isNotEmpty
                                  ? featured
                                  : places.take(3).toList(),
                            ),
                          ],
                          EditorialHeading(
                            '从留下的东西，走近过去',
                            actionLabel: '精选线索',
                            onAction: () =>
                                context.push('/countries/${c.id}/timeline'),
                          ),
                          for (final node in editorialList(
                            c.editorial,
                            'timeline',
                          ).take(2))
                            _TimelineCard(node: node),
                          const SizedBox(height: 18),
                          _QuestionLink(
                            title: '像小小地理学家一样找线索',
                            icon: Icons.travel_explore,
                            onTap: () =>
                                context.push('/countries/${c.id}/explore'),
                          ),
                          if (atlasEdition)
                            ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: const Text('更多国家资料'),
                              children: [
                                for (final fact in c.facts)
                                  ListTile(
                                    title: Text(fact.label),
                                    subtitle: Text(fact.value),
                                  ),
                              ],
                            ),
                          _QuestionLink(
                            title: '我的${c.name}发现',
                            icon: Icons.edit_note,
                            onTap: () => context.push('/me/countries/${c.id}'),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                context.push('/credits?entity=${c.id}'),
                            icon: const Icon(Icons.info_outline, size: 18),
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
      },
    );
  }
}

class _FactStrip extends StatelessWidget {
  const _FactStrip({required this.country});
  final AtlasCountry country;
  @override
  Widget build(BuildContext context) {
    final overrides = editorialList(country.editorial, 'factOverrides');
    final facts = country.id == 'zaf'
        ? [
            (Icons.place_outlined, '非洲南部', '位置'),
            (Icons.account_balance_outlined, '三城分工', '首都'),
            (Icons.chat_bubble_outline, '12种', '语言'),
          ]
        : country.id == 'aus'
        ? [
            (Icons.place_outlined, '堪培拉', '首都'),
            (Icons.terrain_outlined, '大洋洲', '位置'),
            (Icons.public, '南半球', '范围'),
          ]
        : country.id == 'fra'
        ? [
            (Icons.place_outlined, '巴黎', '首都'),
            (Icons.terrain_outlined, '欧洲与海外', '范围'),
            (Icons.chat_bubble_outline, '法语', '语言'),
          ]
        : [
            (Icons.place_outlined, country.continent, '位置'),
            (Icons.account_balance_outlined, country.capital, '首都'),
            (
              const {
                    'usa',
                    'gbr',
                    'fra',
                    'norway',
                    'kenya',
                    'deu',
                  }.contains(country.id)
                  ? Icons.map_outlined
                  : Icons.payments_outlined,
              country.facts
                      .where((f) => f.label == '货币')
                      .firstOrNull
                      ?.value
                      .replaceAll(' CNY', '') ??
                  '',
              country.id == 'usa'
                  ? '州'
                  : country.id == 'gbr'
                  ? '组成'
                  : '货币',
            ),
          ];
    if (overrides.isNotEmpty) {
      final values = {
        for (final entry in overrides) entry['label']: entry['value'],
      };
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        decoration: BoxDecoration(
          color: AtlasPalette.canvas,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            for (final (i, f) in facts.indexed) ...[
              if (i > 0)
                Container(height: 29, width: 1, color: AtlasPalette.line),
              Expanded(
                child: Semantics(
                  label: '${f.$3}：${values[f.$3]}',
                  excludeSemantics: true,
                  child: Flex(
                    direction: Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(f.$1, size: 23, color: AtlasPalette.navy),
                      const SizedBox(height: 4),
                      Text(
                        values[f.$3] as String? ?? f.$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        f.$3 == '语言' ? '官方语言' : f.$3,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AtlasPalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: AtlasPalette.canvas,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final f in facts)
            Expanded(
              child: Column(
                children: [
                  Icon(f.$1, color: AtlasPalette.navy),
                  const SizedBox(height: 6),
                  Text(
                    f.$2,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    f.$3,
                    style: const TextStyle(
                      color: AtlasPalette.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _JourneyTile extends StatelessWidget {
  const _JourneyTile({required this.country, required this.journey});
  final AtlasCountry country;
  final Json journey;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AtlasPalette.line),
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () =>
          context.push('/countries/${country.id}/journeys/${journey['id']}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    journey['title'],
                    style: TextStyle(
                      fontSize: _atlasEdition(country.id) ? 14 : 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: _atlasEdition(country.id) ? 14 : 20,
                ),
              ],
            ),
          ),
          MediaPhoto(
            journey['mediaId'] ?? country.mediaId,
            width: double.infinity,
            height: MediaQuery.sizeOf(context).width > 700 ? 170 : 112,
          ),
        ],
      ),
    ),
  );
}

class CountrySectionDirectory extends StatelessWidget {
  const CountrySectionDirectory({super.key, required this.country, this.limit});
  final AtlasCountry country;
  final int? limit;
  @override
  Widget build(BuildContext context) {
    if (country.id == 'norway') {
      return NorwaySectionTiles(country, limit: limit);
    }
    if (country.id == 'kenya') return KenyaSectionTiles(country, limit: limit);
    if (country.id == 'deu') return GermanySectionTiles(country, limit: limit);
    final sections = countrySections.entries
        .where((e) => country.sections[e.key]?.isNotEmpty ?? false)
        .take(limit ?? 10);
    final atlasEdition = _atlasEdition(country.id);
    final metadata = country.editorial['sections'] as Json? ?? {};
    return LayoutBuilder(
      builder: (context, constraints) {
        final single =
            constraints.maxWidth < (atlasEdition ? 315 : 330) ||
            MediaQuery.textScalerOf(context).scale(1) > 1.2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final s in sections)
              SizedBox(
                width: single
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 10) / 2,
                child: country.id == 'brazil'
                    ? BrazilDirectoryCard(
                        title: s.value,
                        mediaId: metadata[s.key]?['mediaId'] ?? country.mediaId,
                        onTap: () =>
                            context.push('/countries/brazil/sections/${s.key}'),
                      )
                    : ({
                        'norway',
                        'kenya',
                        'deu',
                        'fra',
                        'aus',
                        'zaf',
                      }.contains(country.id))
                    ? Material(
                        color: AtlasPalette.canvas,
                        borderRadius: BorderRadius.circular(13),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => context.push(
                            '/countries/${country.id}/sections/${s.key}',
                          ),
                          child: SizedBox(
                            height: 62,
                            child: Stack(
                              children: [
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: 88,
                                  child: MediaPhoto(
                                    metadata[s.key]?['mediaId'] ??
                                        country.mediaId,
                                    width: 88,
                                    height: 62,
                                  ),
                                ),
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AtlasPalette.canvas,
                                          AtlasPalette.canvas.withValues(
                                            alpha: .92,
                                          ),
                                          AtlasPalette.canvas.withValues(
                                            alpha: 0,
                                          ),
                                        ],
                                        stops: const [0, .46, 1],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _sectionIcons[s.key] ?? Icons.public,
                                        size: 23,
                                        color: AtlasPalette.navy,
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Text(
                                          s.value,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AtlasPalette.navy,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: () => context.push(
                          '/countries/${country.id}/sections/${s.key}',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: atlasEdition ? 6 : 12,
                            vertical: atlasEdition ? 6 : 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _sectionIcons[s.key] ?? Icons.public,
                              size: atlasEdition ? 20 : 23,
                            ),
                            SizedBox(width: atlasEdition ? 4 : 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.value,
                                    style: TextStyle(
                                      fontSize: atlasEdition ? 13 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (atlasEdition)
                                    Text(
                                      '${country.sections[s.key]!.length} 篇',
                                      style: const TextStyle(
                                        color: AtlasPalette.muted,
                                        fontSize: 10,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (atlasEdition &&
                                metadata[s.key]?['mediaId'] is String)
                              Padding(
                                padding: const EdgeInsets.only(left: 3),
                                child: MediaPhoto(
                                  metadata[s.key]['mediaId'],
                                  width: 43,
                                  height: 38,
                                  radius: 7,
                                ),
                              ),
                            Icon(
                              Icons.chevron_right,
                              size: atlasEdition ? 13 : 18,
                            ),
                          ],
                        ),
                      ),
              ),
          ],
        );
      },
    );
  }
}

const _sectionIcons = {
  'overview': Icons.flag_outlined,
  'geography': Icons.landscape_outlined,
  'people': Icons.people_outline,
  'daily': Icons.home_outlined,
  'food': Icons.restaurant_outlined,
  'culture': Icons.celebration_outlined,
  'landmarks': Icons.location_city_outlined,
  'nature': Icons.pets_outlined,
  'history': Icons.history_edu_outlined,
  'questions': Icons.help_outline,
};

class CountryContentsScreen extends StatelessWidget {
  const CountryContentsScreen(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) {
    final content = context.atlas.content;
    final c = content.country(id);
    if (c == null) return const AtlasPage(title: '探索目录', child: Text('资料暂不可用'));
    final featured = content.place(
      c.editorial['featuredDirectoryPlaceId'] as String? ?? '',
    );
    final directory = List<String>.from(
      c.editorial['directory']?['mediaIds'] ?? [],
    );
    return AtlasPage(
      title: c.editorial['directoryTitle'] ?? '${c.name} · 探索目录',
      appBar: c.id == 'brazil'
          ? const BrazilBrandBar()
          : c.id == 'zaf'
          ? const SouthAfricaBrandBar()
          : c.id == 'norway'
          ? const NorwayBrandBar()
          : c.id == 'kenya'
          ? const KenyaBrandBar()
          : c.id == 'deu'
          ? const GermanyBrandBar()
          : c.id == 'aus'
          ? const AustraliaBrandBar()
          : c.id == 'fra'
          ? const FranceBrandBar()
          : null,
      width: 1000,
      padding: _atlasEdition(c.id)
          ? const EdgeInsets.fromLTRB(15, 12, 15, 24)
          : const EdgeInsets.fromLTRB(22, 16, 22, 28),
      actions: _atlasEdition(c.id)
          ? [SavedButton(kind: 'country', id: c.id, title: c.name)]
          : const [],
      bottom: _CountryBottom(
        child: PrimaryAction(
          '打开${c.name}地图',
          icon: _atlasEdition(c.id) ? Icons.map_outlined : null,
          arrow: !_atlasEdition(c.id),
          onPressed: () => context.push('/atlas?country=$id'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (c.id == 'norway' ||
              c.id == 'kenya' ||
              c.id == 'deu' ||
              c.id == 'fra' ||
              c.id == 'zaf' ||
              c.id == 'aus' ||
              c.id == 'brazil')
            Text(
              '${c.name} · 探索目录',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
          Text(
            _atlasEdition(c.id) ? '带着问题去探索' : '把好奇心带到每一站',
            style:
                (c.id == 'norway' ||
                    c.id == 'kenya' ||
                    c.id == 'deu' ||
                    c.id == 'fra' ||
                    c.id == 'brazil' ||
                    c.id == 'zaf' ||
                    c.id == 'aus')
                ? const TextStyle(fontSize: 17, color: AtlasPalette.muted)
                : Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          if (directory.length == 3)
            _DirectoryMosaic(directory)
          else
            Row(
              children: [
                for (final item in editorialList(c.editorial, 'journeys'))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: MediaPhoto(
                        item['mediaId'],
                        width: double.infinity,
                        height: 130,
                        radius: 12,
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          CountrySectionDirectory(country: c),
          const SizedBox(height: 26),
          if (featured != null)
            _EditorialCover(
              mediaId: featured.mediaIds.first,
              title: c.editorial['featuredDirectoryTitle'] ?? '下一站，去三角洲',
              height: 205,
              onTap: () => context.push(
                '/atlas?country=$id&layer=water&place=${featured.id}',
              ),
            )
          else if (id != 'fra' &&
              id != 'brazil' &&
              id != 'zaf' &&
              id != 'norway' &&
              id != 'kenya' &&
              id != 'deu' &&
              content.placesIn(id).isNotEmpty)
            _PlacesGrid(
              places: context.atlas.content.placesIn(id).take(3).toList(),
            ),
          const SizedBox(height: 18),
          _QuestionLink(
            title: '我的${c.name}发现',
            icon: Icons.edit_note,
            onTap: () => context.push('/me/countries/$id'),
          ),
        ],
      ),
    );
  }
}

class _DirectoryMosaic extends StatelessWidget {
  const _DirectoryMosaic(this.mediaIds);
  final List<String> mediaIds;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final column = constraints.maxWidth / 3;
        const slant = 27.0;
        final height = constraints.maxWidth > 600 ? 160.0 : 102.0;
        return SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (final (i, id) in mediaIds.indexed)
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: i == 0 ? 0 : column * i - slant / 2,
                  width: column + (i == 1 ? slant : slant / 2),
                  child: ClipPath(
                    clipper: _MosaicClipper(i, slant),
                    child: MediaPhoto(
                      id,
                      height: height,
                      width: double.infinity,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _MosaicClipper extends CustomClipper<Path> {
  const _MosaicClipper(this.index, this.slant);
  final int index;
  final double slant;
  @override
  Path getClip(Size size) => Path()
    ..moveTo(index == 0 ? 0 : slant + 2, 0)
    ..lineTo(size.width, 0)
    ..lineTo(index == 2 ? size.width : size.width - slant, size.height)
    ..lineTo(index == 0 ? 0 : 2, size.height)
    ..close();
  @override
  bool shouldReclip(_MosaicClipper old) =>
      index != old.index || slant != old.slant;
}

class _EditorialCover extends StatelessWidget {
  const _EditorialCover({
    required this.mediaId,
    required this.title,
    required this.height,
    this.onTap,
  });
  final String mediaId, title;
  final double height;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    borderRadius: BorderRadius.circular(15),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MediaPhoto(mediaId, width: double.infinity, height: height),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCA071D30)],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 23,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class EditorialSectionScreen extends StatelessWidget {
  const EditorialSectionScreen({
    super.key,
    required this.countryId,
    required this.sectionId,
  });
  final String countryId, sectionId;
  @override
  Widget build(BuildContext context) {
    if (countryId == 'norway' && sectionId == 'daily') {
      return const NorwayDaily();
    }
    if (countryId == 'kenya' && sectionId == 'daily') return const KenyaDaily();
    if (countryId == 'deu' && sectionId == 'daily') return const GermanyDaily();
    final content = context.atlas.content, c = content.country(countryId)!;
    final section =
        (c.editorial['sections'] as Json? ?? {})[sectionId] as Json? ?? {};
    final articles = (c.sections[sectionId] ?? [])
        .map(content.article)
        .whereType<AtlasArticle>()
        .toList();
    final primary = content.article(
      section['primaryArticleId'] as String? ?? '',
    );
    final related = content.article(
      section['relatedArticleId'] as String? ?? '',
    );
    final dailyEdition = _atlasEdition(c.id) && sectionId == 'daily';
    final primaryMap = content.place(
      section['primaryMapPlaceId'] as String? ?? '',
    );
    return AtlasPage(
      title: '${c.name} · ${countrySections[sectionId] ?? '探索'}',
      darkBar: dailyEdition && c.id != 'zaf',
      appBar: c.id == 'zaf' ? const SouthAfricaBrandBar() : null,
      width: 1000,
      bottom: primary == null && primaryMap == null
          ? null
          : _CountryBottom(
              child: PrimaryAction(
                section['primaryLabel'] ?? '开始阅读',
                orange: true,
                onPressed: () => context.push(
                  primaryMap != null
                      ? '/atlas?country=$countryId&layer=places&place=${primaryMap.id}'
                      : '/articles/${primary!.id}',
                ),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccentTitle(
            section['title'] ?? countrySections[sectionId] ?? '继续探索',
            accent: dailyEdition,
          ),
          const SizedBox(height: 12),
          Text(
            section['summary'] ?? '',
            style: const TextStyle(color: AtlasPalette.muted, fontSize: 18),
          ),
          const SizedBox(height: 18),
          MediaPhoto(
            section['mediaId'] ?? articles.firstOrNull?.mediaId ?? c.mediaId,
            width: double.infinity,
            height: 240,
            radius: 16,
            showCredit: true,
          ),
          const SizedBox(height: 22),
          if (sectionId == 'overview') ...[
            _FactStrip(country: c),
            const SizedBox(height: 16),
          ],
          if (primaryMap != null)
            _AccentTitle(c.id == 'zaf' ? '从身边的小事出发' : '先跟着一段通勤走'),
          for (final (i, article) in articles.indexed)
            if (primaryMap != null && i < 3)
              _QuestionLink(
                title: c.id != 'usa'
                    ? article.title
                    : ['纽约地铁', '社区市场', '在街区散步'][i],
                icon: [
                  Icons.train_outlined,
                  Icons.storefront_outlined,
                  Icons.directions_walk,
                ][i],
                onTap: () => context.push('/articles/${article.id}'),
                mediaId: article.mediaId,
              )
            else
              _ArticleRow(article: article),
          if (related != null) ...[
            const EditorialHeading('下一站 · 一起看看餐桌'),
            _ArticleRow(article: related),
          ],
          if (sectionId == 'landmarks') ...[
            const EditorialHeading('从这些地方出发'),
            _PlacesGrid(places: content.placesIn(countryId)),
          ],
          if (sectionId == 'history')
            _QuestionLink(
              title: '沿着精选线索认识历史',
              icon: Icons.timeline,
              onTap: () => context.push('/countries/$countryId/timeline'),
            ),
          if (sectionId == 'questions')
            _QuestionLink(
              title: '打开我的观察任务',
              icon: Icons.travel_explore,
              onTap: () => context.push('/countries/$countryId/explore'),
            ),
          if (sectionId == 'daily' && primary == null && primaryMap == null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: PrimaryAction(
                '记录我家的一个习惯',
                onPressed: () => context.push(
                  '/me/notes/new?entity=$countryId&kind=country',
                ),
              ),
            ),
          if (articles.isEmpty)
            const AtlasEmpty(title: '这一组内容还在准备', message: '可以返回目录选择已有的文章。'),
        ],
      ),
    );
  }
}

class CountryJourneyScreen extends StatelessWidget {
  const CountryJourneyScreen({
    super.key,
    required this.countryId,
    required this.journeyId,
  });
  final String countryId, journeyId;
  @override
  Widget build(BuildContext context) {
    final content = context.atlas.content, c = content.country(countryId);
    final journey = c == null
        ? null
        : editorialList(
            c.editorial,
            'journeys',
          ).where((j) => j['id'] == journeyId).firstOrNull;
    if (journey == null) {
      return const AtlasPage(
        title: '探索主线',
        child: AtlasEmpty(title: '这条主线暂不可用', message: '返回国家目录选择文章。'),
      );
    }
    final articles = List<String>.from(journey['articleIds'] ?? [])
        .map(content.article)
        .whereType<AtlasArticle>()
        .toList();
    if (_atlasEdition(c!.id)) {
      final stops = List<String>.from(journey['stopTitles'] ?? []);
      final journal = context.atlas.journal;
      return ListenableBuilder(
        listenable: journal,
        builder: (context, _) {
          final next = articles
              .where((a) => journal.progress[a.id]?['completed'] != 1)
              .firstOrNull;
          final hasProgress = articles.any(
            (a) => journal.progress.containsKey(a.id),
          );
          return AtlasPage(
            title: '${c.name} · 探索路线',
            width: 800,
            darkBar: true,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 25),
            bottom: _CountryBottom(
              child: PrimaryAction(
                next == null
                    ? '记下一个发现'
                    : hasProgress
                    ? '继续这条路线'
                    : '从第一站开始',
                orange: true,
                arrow: false,
                onPressed: () => next != null
                    ? context.push('/articles/${next.id}')
                    : context.push('/countries/$countryId/explore'),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AccentTitle(journey['title']),
                const SizedBox(height: 13),
                _EditorialCover(
                  mediaId: journey['mediaId'],
                  height: 200,
                  title: journey['coverTitle'] ?? journey['title'],
                ),
                const SizedBox(height: 10),
                Text(
                  (c.id == 'norway' ||
                          c.id == 'kenya' ||
                          c.id == 'deu' ||
                          c.id == 'fra' ||
                          c.id == 'aus')
                      ? '三站 · 阅读顺序，不是交通路线'
                      : '${articles.length == 3 ? '三' : articles.length}站 · 可自由选择',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AtlasPalette.muted,
                  ),
                ),
                const SizedBox(height: 12),
                for (final (i, a) in articles.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _JourneyStop(
                      index: i + 1,
                      article: a,
                      title: i < stops.length ? stops[i] : a.title,
                      read: journal.progress[a.id]?['completed'] == 1,
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }
    return AtlasPage(
      title: '${c.name} · ${journey['title']}',
      width: 800,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediaPhoto(
            journey['mediaId'],
            width: double.infinity,
            height: 250,
            radius: 16,
            showCredit: true,
          ),
          const SizedBox(height: 24),
          Text(
            journey['subtitle'] ?? journey['title'],
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          const Text(
            '从感兴趣的一站开始，随时可以换个方向。',
            style: TextStyle(color: AtlasPalette.muted),
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < articles.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 14, top: 20),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AtlasPalette.navy,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Expanded(child: _ArticleRow(article: articles[i])),
              ],
            ),
          const SizedBox(height: 20),
          PrimaryAction(
            '记下一个发现',
            orange: true,
            onPressed: () =>
                context.push('/me/notes/new?entity=$countryId&kind=country'),
          ),
        ],
      ),
    );
  }
}

class _AccentTitle extends StatelessWidget {
  const _AccentTitle(this.title, {this.accent = true});
  final String title;
  final bool accent;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (accent) ...[
        Container(
          width: 6,
          height: 32,
          decoration: BoxDecoration(
            color: AtlasPalette.orange,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 11),
      ],
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.headlineLarge),
      ),
    ],
  );
}

class _JourneyStop extends StatelessWidget {
  const _JourneyStop({
    required this.index,
    required this.article,
    required this.title,
    required this.read,
  });
  final int index;
  final AtlasArticle article;
  final String title;
  final bool read;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
      side: const BorderSide(color: AtlasPalette.line),
    ),
    child: InkWell(
      onTap: () => context.push('/articles/${article.id}'),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AtlasPalette.orangeSoft,
              foregroundColor: AtlasPalette.navy,
              child: Text(
                '$index',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  if (read)
                    const Text(
                      '已读',
                      style: TextStyle(
                        color: AtlasPalette.success,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            MediaPhoto(
              article.mediaId,
              width: MediaQuery.sizeOf(context).width < 360 ? 95 : 135,
              height: 73,
              radius: 9,
            ),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    ),
  );
}

class CountryTimelineScreen extends StatefulWidget {
  const CountryTimelineScreen(this.id, {super.key});
  final String id;
  @override
  State<CountryTimelineScreen> createState() => _CountryTimelineScreenState();
}

class _CountryTimelineScreenState extends State<CountryTimelineScreen> {
  bool dates = false;
  @override
  Widget build(BuildContext context) {
    if (widget.id == 'norway') return const NorwayTimeline();
    if (widget.id == 'kenya') return const KenyaTimeline();
    if (widget.id == 'deu') return const GermanyTimeline();
    final c = context.atlas.content.country(widget.id);
    final atlasEdition = _atlasEdition(c?.id);
    final intro = c?.editorial['timelineIntro'] as Json?;
    final usa =
        c?.id == 'aus' ||
        c?.id == 'zaf' ||
        c?.id == 'usa' ||
        c?.id == 'gbr' ||
        c?.id == 'norway' ||
        c?.id == 'kenya' ||
        c?.id == 'deu' ||
        c?.id == 'fra' ||
        c?.id == 'brazil';
    return AtlasPage(
      title: c?.editorial['timelineTitle'] ?? '${c?.name ?? ''} · 历史故事',
      darkBar: atlasEdition,
      width: 800,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccentTitle(
            usa
                ? '顺着证据看历史'
                : atlasEdition
                ? '从留下的东西走近过去'
                : '从留下的东西\n走近过去',
            accent: atlasEdition,
          ),
          const SizedBox(height: 20),
          if (!usa) ...[
            MediaPhoto(
              editorialList(
                        c?.editorial ?? {},
                        'timeline',
                      ).firstOrNull?['mediaId']
                      as String? ??
                  c?.mediaId ??
                  '',
              width: double.infinity,
              height: 210,
              radius: 16,
              showCredit: true,
            ),
            const SizedBox(height: 16),
          ],
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('看线索')),
              ButtonSegment(value: true, label: Text('看时间')),
            ],
            selected: {dates},
            onSelectionChanged: (s) => setState(() => dates = s.single),
          ),
          if (intro != null)
            Padding(
              padding: const EdgeInsets.only(top: 13),
              child: Material(
                color: AtlasPalette.orangeSoft,
                borderRadius: BorderRadius.circular(13),
                child: ListTile(
                  leading: const Icon(
                    Icons.auto_stories_outlined,
                    color: AtlasPalette.navy,
                  ),
                  title: Text(
                    intro['title'],
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(intro['summary']),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/articles/${intro['articleId']}'),
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text(
              '精选线索 · 这些故事不是完整的历史年表',
              style: TextStyle(color: AtlasPalette.muted),
            ),
          ),
          for (final node in editorialList(c?.editorial ?? {}, 'timeline'))
            _TimelineCard(node: node, expanded: dates),
          ExpansionTile(
            title: const Text('年代怎么看？'),
            children: const [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '公元前的数字越大，年代越早；公元后的数字越大，年代越晚。时间线中的卡片方便阅读，卡片之间的距离不表示相同的时间长度。',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.node, this.expanded = false});
  final Json node;
  final bool expanded;
  @override
  Widget build(BuildContext context) {
    final ids = List<String>.from(node['articleIds'] ?? []);
    final usa =
        (node['id'] as String? ?? '').startsWith('usa-') ||
        (node['id'] as String? ?? '').startsWith('gbr-') ||
        (node['id'] as String? ?? '').startsWith('fra-') ||
        (node['id'] as String? ?? '').startsWith('aus-') ||
        (node['id'] as String? ?? '').startsWith('brazil-') ||
        (node['id'] as String? ?? '').startsWith('deu-');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AtlasPalette.line),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: ids.isEmpty
                  ? null
                  : () => context.push('/articles/${ids.first}'),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AtlasPalette.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!usa) ...[
                      MediaPhoto(
                        node['mediaId'] ?? '',
                        width: 76,
                        height: 76,
                        radius: 10,
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            node['period'] ?? '',
                            style: TextStyle(
                              color: usa
                                  ? const Color(0xffa44c12)
                                  : AtlasPalette.muted,
                              fontSize: usa ? 22 : 14,
                              fontWeight: usa ? FontWeight.w900 : null,
                            ),
                          ),
                          Text(
                            node['title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (usa) ...[
                      const SizedBox(width: 8),
                      MediaPhoto(
                        node['mediaId'] ?? '',
                        width: 97,
                        height: 67,
                        radius: 10,
                      ),
                    ] else
                      const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node['body'] ?? '',
                      style: const TextStyle(fontSize: 17),
                    ),
                    if (ids.isNotEmpty &&
                        (node['id'] as String? ?? '').startsWith(
                          RegExp(r'^(egypt|usa|gbr|fra|aus|deu|brazil)-'),
                        ))
                      TextButton.icon(
                        onPressed: () =>
                            context.push('/credits?entity=${ids.first}'),
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('查看这条线索的来源'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CountryExploreScreen extends StatelessWidget {
  const CountryExploreScreen(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) {
    if (id == 'norway') return const NorwayTasks();
    if (id == 'kenya') return const KenyaTasks();
    if (id == 'deu') return const GermanyTasks();
    final content = context.atlas.content, c = content.country(id);
    final activities = content
        .articlesIn(id)
        .where((a) => a.activity['type'] == 'open');
    final exercises = content.exercises
        .where((e) => e.countryId == id)
        .toList();
    final explore = c?.editorial['explore'] as Json?;
    if (c != null && explore != null) {
      return _CountryTaskDirectory(
        country: c,
        config: explore,
        exercises: exercises,
        activities: activities.toList(),
      );
    }
    return AtlasPage(
      title: '${c?.name ?? ''} · 有趣问题',
      width: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '像小小地理学家\n一样找线索',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 10),
          const Text(
            '看地图 · 看照片 · 说发现',
            style: TextStyle(color: AtlasPalette.muted, fontSize: 19),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              for (final m in activities.take(3).map((a) => a.mediaId))
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: MediaPhoto(
                      m,
                      width: double.infinity,
                      height: 120,
                      radius: 12,
                    ),
                  ),
                ),
            ],
          ),
          const EditorialHeading('把观察变成自己的发现'),
          for (final a in activities)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                borderRadius: BorderRadius.circular(14),
                color: AtlasPalette.canvas,
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(
                    Icons.edit_note,
                    color: AtlasPalette.navy,
                  ),
                  title: Text(
                    a.activity['title'] ?? a.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(a.activity['prompt'] ?? a.question),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/countries/$id/observe/${a.id}'),
                ),
              ),
            ),
          const EditorialHeading('带着问题，再看一次'),
          for (final e in exercises)
            _QuestionLink(
              title: e.question,
              icon: e.type == 'location'
                  ? Icons.map_outlined
                  : e.type == 'observation'
                  ? Icons.image_search
                  : Icons.help_outline,
              onTap: () => context.push('/exercises/${e.id}'),
            ),
        ],
      ),
    );
  }
}

class _CountryTaskDirectory extends StatefulWidget {
  const _CountryTaskDirectory({
    required this.country,
    required this.config,
    required this.exercises,
    required this.activities,
  });
  final AtlasCountry country;
  final Json config;
  final List<AtlasExercise> exercises;
  final List<AtlasArticle> activities;

  @override
  State<_CountryTaskDirectory> createState() => _CountryTaskDirectoryState();
}

class _CountryTaskDirectoryState extends State<_CountryTaskDirectory> {
  String category = '';
  static const groups = {
    'location': ('地图题', Icons.map_outlined),
    'observation': ('观察题', Icons.image_search_outlined),
    'choice': ('选择题', Icons.fact_check_outlined),
  };

  @override
  Widget build(BuildContext context) {
    final country = widget.country;
    final exercises = widget.exercises;
    final activities = widget.activities;
    final images = editorialList(widget.config, 'categories');
    final featured = List<String>.from(widget.config['featuredTaskIds'] ?? []);
    final selectedExercises = category.isEmpty
        ? featured
              .map((id) => exercises.where((e) => e.id == id).firstOrNull)
              .whereType<AtlasExercise>()
        : exercises.where((e) => e.type == category);
    final selectedActivities = category == 'open'
        ? activities
        : category.isEmpty
        ? featured
              .map(
                (id) =>
                    activities.where((a) => a.activity['id'] == id).firstOrNull,
              )
              .whereType<AtlasArticle>()
        : const <AtlasArticle>[];
    return AtlasPage(
      title: '${country.name} · 探索任务',
      width: 850,
      darkBar: true,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      bottom: _CountryBottom(
        child: PrimaryAction(
          '去看看我的发现',
          arrow: false,
          onPressed: () => context.push('/me/countries/${country.id}'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediaPhoto(
            widget.config['mediaId'],
            height: 143,
            width: double.infinity,
            radius: 15,
          ),
          const SizedBox(height: 12),
          Text(
            '像小小地理学家一样观察',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const _OrangeRule(),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final single = MediaQuery.textScalerOf(context).scale(1) > 1.3;
              return Wrap(
                spacing: 7,
                runSpacing: 8,
                children: [
                  for (final item in images.where(
                    (item) => item['id'] != 'open',
                  ))
                    SizedBox(
                      width: single
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 14) / 3,
                      child: _TaskCategory(
                        title: item['title'],
                        mediaId: item['mediaId'],
                        active: category == item['id'],
                        count: exercises
                            .where((e) => e.type == item['id'])
                            .length,
                        icon: groups[item['id']]?.$2 ?? Icons.search,
                        onTap: () => setState(
                          () => category = category == item['id']
                              ? ''
                              : item['id'],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          EditorialHeading(
            category.isEmpty
                ? '先试试这几个任务'
                : groups[category]?.$1 ?? '把观察变成自己的发现',
          ),
          for (final e in selectedExercises)
            _QuestionLink(
              title: e.question,
              icon: groups[e.type]?.$2 ?? Icons.help_outline,
              onTap: () => context.push('/exercises/${e.id}'),
            ),
          for (final a in selectedActivities)
            _QuestionLink(
              title: a.activity['title'] ?? a.title,
              icon: Icons.edit_note,
              onTap: () =>
                  context.push('/countries/${country.id}/observe/${a.id}'),
            ),
          if (category != 'open')
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: AtlasPalette.orangeSoft,
                side: const BorderSide(color: AtlasPalette.orange),
              ),
              onPressed: () => setState(() => category = 'open'),
              icon: const Icon(Icons.edit_outlined),
              label: Text('写下自己的发现 · ${activities.length} 项'),
            ),
        ],
      ),
    );
  }
}

class _OrangeRule extends StatelessWidget {
  const _OrangeRule();
  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 4,
    decoration: BoxDecoration(
      color: AtlasPalette.orange,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

class _TaskCategory extends StatelessWidget {
  const _TaskCategory({
    required this.title,
    required this.mediaId,
    required this.active,
    required this.count,
    required this.icon,
    required this.onTap,
  });
  final String title, mediaId;
  final bool active;
  final int count;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$title，$count 道题',
    selected: active,
    button: true,
    child: Material(
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 134,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MediaPhoto(mediaId, width: double.infinity, height: 134),
              Positioned(
                left: 5,
                right: 5,
                bottom: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 7,
                    horizontal: 3,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? AtlasPalette.orange
                        : Colors.white.withValues(alpha: .94),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
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
    ),
  );
}

class CountryObservationScreen extends StatefulWidget {
  const CountryObservationScreen(this.entityId, {super.key})
    : place = false,
      mediaId = null;
  const CountryObservationScreen.place(this.entityId, {super.key, this.mediaId})
    : place = true;
  final String entityId;
  final bool place;
  final String? mediaId;
  @override
  State<CountryObservationScreen> createState() =>
      _CountryObservationScreenState();
}

class _CountryObservationScreenState extends State<CountryObservationScreen> {
  final seen = TextEditingController(),
      guessed = TextEditingController(),
      question = TextEditingController();
  bool saving = false, initialized = false, saved = false;
  String noteId = '';
  AtlasServices? services;
  Future<void> pendingDraft = Future.value();
  String get draftKey => 'observation-draft-${widget.entityId}';
  bool get hasText =>
      [seen, guessed, question].any((field) => field.text.trim().isNotEmpty);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    services = context.atlas;
    final draft = context.atlas.preferences.values[draftKey] as Json?;
    seen.text = draft?['seen'] ?? '';
    guessed.text = draft?['guessed'] ?? '';
    question.text = draft?['question'] ?? '';
    noteId = draft?['id'] ?? 'note-${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<void> stash() async {
    if (saved || services == null) return;
    final snapshot = !hasText
        ? null
        : {
            'id': noteId,
            'seen': seen.text,
            'guessed': guessed.text,
            'question': question.text,
          };
    pendingDraft = pendingDraft
        .catchError((Object _) {})
        .then((_) => services!.preferences.set(draftKey, snapshot));
    await pendingDraft;
  }

  @override
  void dispose() {
    if (!saved) unawaited(stash().catchError((Object _) {}));
    seen.dispose();
    guessed.dispose();
    question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = context.atlas.content;
    final a = widget.place ? null : content.article(widget.entityId);
    final place = widget.place ? content.place(widget.entityId) : null;
    final countryId = a?.countryId ?? place?.countryId;
    if (countryId == null) {
      return const AtlasPage(title: '记下发现', child: Text('资料暂不可用'));
    }
    final atlasEdition = _atlasEdition(countryId);
    final activity = a?.activity ?? {};
    final title = a?.title ?? place!.name;
    final prompt =
        place?.observation ?? (activity['prompt'] as String? ?? a!.question);
    final materials = List<String>.from(
      place?.mediaIds ?? activity['mediaIds'] ?? [],
    );
    final photo = widget.mediaId != null && materials.contains(widget.mediaId)
        ? widget.mediaId!
        : materials.firstOrNull ?? a?.mediaId ?? '';
    final source = widget.place
        ? '/places/${widget.entityId}'
        : '/articles/${widget.entityId}';
    final diagram = a?.diagram ?? '';
    return PopScope(
      canPop:
          saved ||
          (seen.text.isEmpty && guessed.text.isEmpty && question.text.isEmpty),
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          try {
            await stash();
          } catch (_) {
            if (context.mounted) showMessage(context, '草稿保存失败，请再试一次。');
            return;
          }
          if (context.mounted) {
            setState(() => saved = true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                backOrHome(context, '/countries/$countryId/explore');
              }
            });
          }
        }
      },
      child: AtlasPage(
        title: atlasEdition
            ? '${content.country(countryId)?.name ?? ''} · 记下一个发现'
            : '记下一个发现',
        width: 780,
        darkBar: atlasEdition && countryId != 'zaf',
        appBar: countryId == 'norway'
            ? const NorwayBrandBar()
            : countryId == 'kenya'
            ? const KenyaBrandBar()
            : countryId == 'deu'
            ? const GermanyBrandBar()
            : countryId == 'zaf'
            ? const SouthAfricaBrandBar()
            : null,
        liftBottomForKeyboard: atlasEdition,
        padding: atlasEdition
            ? const EdgeInsets.fromLTRB(16, 14, 16, 22)
            : const EdgeInsets.fromLTRB(22, 16, 22, 28),
        bottom: _CountryBottom(
          child: PrimaryAction(
            saving ? '正在保存…' : '保存我的发现',
            orange: true,
            arrow: !atlasEdition,
            onPressed: saving || (atlasEdition && !hasText)
                ? null
                : () async {
                    if (seen.text.trim().isEmpty &&
                        guessed.text.trim().isEmpty &&
                        question.text.trim().isEmpty) {
                      showMessage(context, '任选一项，写下你自己的想法。');
                      return;
                    }
                    setState(() => saving = true);
                    await atlasAction(context, () async {
                      await stash();
                      await services!.journal.saveNote(
                        id: noteId,
                        kind: 'discovery',
                        text: [
                          if (seen.text.trim().isNotEmpty)
                            '我看见：${seen.text.trim()}',
                          if (guessed.text.trim().isNotEmpty)
                            '我猜想：${guessed.text.trim()}',
                        ].join('\n'),
                        question: question.text.trim(),
                        entityId: widget.entityId,
                        title: title,
                      );
                      if (!context.mounted) return;
                      await services!.preferences.set(draftKey, null);
                      if (!context.mounted) return;
                      setState(() => saved = true);
                      context.pushReplacement('/me/countries/$countryId');
                    });
                    if (mounted) setState(() => saving = false);
                  },
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (atlasEdition) ...[
              if (countryId == 'zaf')
                const Text(
                  '我的观察笔记',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                )
              else
                const _AccentTitle('把线索写下来'),
              const SizedBox(height: 12),
              MediaPhoto(
                photo,
                width: double.infinity,
                height: countryId == 'aus' ? 230 : 148,
                fit: countryId == 'aus' ? BoxFit.contain : BoxFit.cover,
                radius: 14,
                showCredit: true,
              ),
              const SizedBox(height: 6),
              const Text(
                '先看图片，再写下自己的发现。',
                style: TextStyle(color: AtlasPalette.muted, fontSize: 15),
              ),
              ExpansionTile(
                title: Text(activity['title'] ?? title),
                subtitle: const Text('展开观察材料'),
                tilePadding: EdgeInsets.zero,
                children: [
                  Text(prompt),
                  if (materials.isNotEmpty) LessonPhotos(materials),
                  if (diagram.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    LearningDiagram(diagram),
                  ],
                  TextButton.icon(
                    onPressed: () => context.push(source),
                    icon: const Icon(Icons.menu_book),
                    label: Text(widget.place ? '回到地点找线索' : '回到文章找线索'),
                  ),
                ],
              ),
            ] else ...[
              Text(
                activity['title'] ?? title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(prompt),
              const SizedBox(height: 20),
              MediaPhoto(
                photo,
                width: double.infinity,
                height: 220,
                radius: 14,
                showCredit: true,
              ),
              TextButton.icon(
                onPressed: () => context.push(source),
                icon: const Icon(Icons.menu_book),
                label: const Text('回到文章找线索'),
              ),
            ],
            for (final field in [
              (seen, '我看见', '写下能从照片或地图中看见的线索', Icons.visibility_outlined),
              (guessed, '我猜想', '写下你对这些线索的解释', Icons.psychology_outlined),
              (question, '我还想知道', '写下一个想继续寻找答案的问题', Icons.help_outline),
            ])
              Padding(
                padding: EdgeInsets.only(top: atlasEdition ? 10 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (atlasEdition) ...[
                      Row(
                        children: [
                          Icon(field.$4, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              field.$2,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                    ],
                    Semantics(
                      label: atlasEdition ? field.$2 : null,
                      child: TextField(
                        controller: field.$1,
                        minLines: countryId == 'zaf' ? 1 : 2,
                        maxLines: 5,
                        onChanged: (_) {
                          setState(() {});
                          unawaited(
                            stash().catchError((Object _) {
                              if (mounted) {
                                showMessage(this.context, '草稿保存失败，请再试一次。');
                              }
                            }),
                          );
                        },
                        decoration: InputDecoration(
                          labelText: atlasEdition ? null : field.$2,
                          hintText: countryId == 'zaf'
                              ? field.$3
                              : atlasEdition
                              ? null
                              : field.$3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            if (atlasEdition)
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '选一项写就可以',
                      style: TextStyle(color: AtlasPalette.muted),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '草稿会保留',
                      style: TextStyle(color: AtlasPalette.muted),
                    ),
                  ),
                ],
              )
            else
              const Text(
                '任选一项就可以保存。自己的问题，没有唯一答案。',
                style: TextStyle(color: AtlasPalette.muted),
              ),
          ],
        ),
      ),
    );
  }
}

class CountryDiscoveriesScreen extends StatelessWidget {
  const CountryDiscoveriesScreen(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) {
    if (id == 'norway') return const NorwayDiscoveries();
    if (id == 'kenya') return const KenyaDiscoveries();
    if (id == 'deu') return const GermanyDiscoveries();
    final content = context.atlas.content,
        c = content.country(id),
        j = context.atlas.journal;
    final config = c?.editorial['discoveries'] as Json?;
    final related = {
      id,
      ...content.articlesIn(id).map((a) => a.id),
      ...content.placesIn(id).map((p) => p.id),
    };
    return ListenableBuilder(
      listenable: j,
      builder: (context, _) {
        final notes = j.notes
            .where((n) => related.contains(n['entity_id']))
            .toList();
        final read = j.progress.entries
            .where((p) => related.contains(p.key) && p.value['completed'] == 1)
            .length;
        final viewed = j.history
            .where(
              (h) => h['kind'] == 'place' && related.contains(h['entity_id']),
            )
            .map((h) => h['entity_id'])
            .toSet()
            .length;
        return AtlasPage(
          title: '我的${c?.name ?? ''}发现',
          width: 900,
          darkBar: config != null,
          bottom: _CountryBottom(
            child: PrimaryAction(
              '继续探索${c?.name ?? ''}',
              orange: config != null,
              arrow: config == null,
              onPressed: () => context.push('/countries/$id'),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (config != null) ...[
                MediaPhoto(
                  config['mediaId'],
                  height: 143,
                  width: double.infinity,
                  radius: 15,
                ),
                const SizedBox(height: 13),
                Text(
                  '把好奇心留在这一页',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const _OrangeRule(),
                const SizedBox(height: 16),
                _DiscoveryCounts(
                  read: read,
                  viewed: viewed,
                  notes: notes.length,
                ),
              ] else ...[
                const _AccentTitle('把好奇心\n留在这一页', accent: false),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    Chip(label: Text('读过 $read 篇')),
                    Chip(label: Text('看过 $viewed 处')),
                    Chip(label: Text('记下 ${notes.length} 条')),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              if (notes.isEmpty)
                AtlasEmpty(
                  title: '写下你的第一个发现',
                  message: '一个新发现，或者一个还想知道的问题，都值得记下来。',
                  action: config == null ? '去观察' : '从一条观察开始',
                  onAction: () => context.push('/countries/$id/explore'),
                ),
              for (final note in notes)
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    border: Border.all(color: AtlasPalette.line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MediaPhoto(
                        content.article(note['entity_id'])?.mediaId ??
                            content
                                .place(note['entity_id'])
                                ?.mediaIds
                                .firstOrNull ??
                            c?.mediaId ??
                            '',
                        width: double.infinity,
                        height: 180,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note['title'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: AtlasPalette.muted,
                              ),
                            ),
                            if (config != null)
                              if (DateTime.tryParse(
                                    note['updated_at'] as String? ?? '',
                                  )
                                  case final date?)
                                Text(
                                  '${date.year} 年 ${date.month} 月 ${date.day} 日',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AtlasPalette.muted,
                                  ),
                                ),
                            if ((note['text'] as String).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  note['text'],
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            if ((note['question'] as String).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Text(
                                  '我还想知道：${note['question']}',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            Wrap(
                              spacing: 5,
                              children: [
                                if (config != null &&
                                    (note['entity_id'] as String? ?? '')
                                        .isNotEmpty)
                                  TextButton.icon(
                                    onPressed: () {
                                      final entity =
                                          note['entity_id'] as String;
                                      final route =
                                          content.article(entity) != null
                                          ? '/articles/$entity'
                                          : content.place(entity) != null
                                          ? '/places/$entity'
                                          : '/countries/$id';
                                      context.push(route);
                                    },
                                    icon: const Icon(Icons.menu_book_outlined),
                                    label: const Text('回看来源'),
                                  ),
                                TextButton.icon(
                                  onPressed: () => context.push(
                                    '/me/notes/${note['id']}/edit',
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('编辑笔记'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const EditorialHeading('还想继续探索'),
              if (config != null)
                for (final place in List<String>.from(
                  config['recommendedPlaceIds'] ?? [],
                ).map(content.place).whereType<AtlasPlace>())
                  _QuestionLink(
                    title: switch (place.id) {
                      'nile-delta' => '去看三角洲',
                      'egypt-cairo-historic' => '继续认识开罗',
                      'usa-grand-canyon' => '再看大峡谷',
                      'usa-lake-superior' => '去看五大湖',
                      _ => place.name,
                    },
                    icon: place.id == 'nile-delta'
                        ? Icons.waves
                        : Icons.location_city_outlined,
                    onTap: () => context.push('/places/${place.id}'),
                  )
              else
                for (final article
                    in content
                        .articlesIn(id)
                        .where((a) => j.progress[a.id]?['completed'] != 1)
                        .take(2))
                  _ArticleRow(article: article),
            ],
          ),
        );
      },
    );
  }
}

class _DiscoveryCounts extends StatelessWidget {
  const _DiscoveryCounts({
    required this.read,
    required this.viewed,
    required this.notes,
  });
  final int read, viewed, notes;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
    decoration: BoxDecoration(
      color: AtlasPalette.sea,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        for (final (i, stat) in [
          (Icons.menu_book_outlined, '读过', read, '篇'),
          (Icons.image_outlined, '看过', viewed, '处'),
          (Icons.edit_outlined, '记下', notes, '条'),
        ].indexed) ...[
          if (i > 0) Container(width: 1, height: 43, color: AtlasPalette.line),
          Expanded(
            child: Semantics(
              label: '${stat.$2} ${stat.$3} ${stat.$4}',
              excludeSemantics: true,
              child: Column(
                children: [
                  Icon(stat.$1, size: 28, color: AtlasPalette.navy),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${stat.$2} '),
                        TextSpan(
                          text: '${stat.$3}',
                          style: const TextStyle(
                            color: Color(0xFF9A4500),
                            fontSize: 21,
                          ),
                        ),
                        TextSpan(text: ' ${stat.$4}'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AtlasPalette.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({required this.article});
  final AtlasArticle article;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: ContentRow(
      title: article.title,
      subtitle: '${article.summary} · 约 ${article.readingMinutes} 分钟',
      mediaId: article.mediaId,
      outlined: true,
      onTap: () => context.push('/articles/${article.id}'),
    ),
  );
}

class _QuestionLink extends StatelessWidget {
  const _QuestionLink({
    required this.title,
    required this.onTap,
    this.mediaId,
    this.icon = Icons.landscape_outlined,
  });
  final String title;
  final VoidCallback onTap;
  final String? mediaId;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AtlasPalette.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        minVerticalPadding: 14,
        leading: Icon(icon, color: AtlasPalette.navy),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        trailing: mediaId == null || MediaQuery.sizeOf(context).width < 355
            ? const Icon(Icons.chevron_right, size: 20)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MediaPhoto(mediaId!, width: 96, height: 48, radius: 8),
                  const SizedBox(width: 5),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
        onTap: onTap,
      ),
    ),
  );
}

class _CountryBottom extends StatelessWidget {
  const _CountryBottom({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: child,
        ),
      ),
    ),
  );
}

class _PlacesGrid extends StatelessWidget {
  const _PlacesGrid({required this.places});
  final List<AtlasPlace> places;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 800
          ? 3
          : constraints.maxWidth >= 340 &&
                MediaQuery.textScalerOf(context).scale(1) <= 1.2
          ? 2
          : 1;
      final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
      return Wrap(
        spacing: 14,
        runSpacing: 16,
        children: [
          for (final p in places)
            SizedBox(
              width: width,
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AtlasPalette.line),
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.push('/places/${p.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MediaPhoto(
                        p.mediaIds.firstOrNull ?? '',
                        width: width,
                        height: width * .66,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              p.region.isEmpty ? p.category : p.region,
                              style: const TextStyle(
                                color: AtlasPalette.muted,
                                fontSize: 14,
                              ),
                            ),
                          ],
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
  );
}
