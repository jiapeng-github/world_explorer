import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../domain/atlas_content.dart';
import '../../map_engine/atlas_map.dart';

class TopicsScreen extends StatelessWidget {
  const TopicsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AtlasPage(
    title: '跨国专题',
    width: 760,
    padding: EdgeInsets.zero,
    child: TopicCards(),
  );
}

class TopicCards extends StatefulWidget {
  const TopicCards({super.key});
  @override
  State<TopicCards> createState() => _TopicCardsState();
}

class _TopicCardsState extends State<TopicCards> {
  String category = '全部';
  @override
  Widget build(BuildContext context) {
    final items = context.atlas.content.topics
        .where((t) => category == '全部' || t.category == category)
        .toList();
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (category == '全部' || category == '自然')
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push('/regions/antarctica'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MediaPhoto(
                          'antarctica-m21',
                          height: 180,
                          width: double.infinity,
                        ),
                        const ListTile(
                          title: Text('南极洲 · 自然地理专题'),
                          subtitle: Text('一起读懂冰雪大陆'),
                          trailing: Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
                  ),
                ),
              Text(
                '沿着好奇心看世界',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                '一个问题，连接不同的地方',
                style: TextStyle(color: AtlasPalette.muted, fontSize: 16),
              ),
              const SizedBox(height: 10),
              FilterStrip(
                values: const ['全部', '自然', '人文', '生活'],
                selected: category,
                onSelected: (v) => setState(() => category = v),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 600;
                  final firstWidth = wide && items.length > 1
                      ? (constraints.maxWidth - 12) * .58
                      : constraints.maxWidth;
                  final smallWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (var index = 0; index < items.length; index++)
                        SizedBox(
                          width: index == 0
                              ? firstWidth
                              : index == 1
                              ? wide
                                    ? constraints.maxWidth - firstWidth - 12
                                    : constraints.maxWidth
                              : smallWidth,
                          height:
                              (index == 0
                                  ? wide
                                        ? 238.0
                                        : 210.0
                                  : index == 1
                                  ? wide
                                        ? 238.0
                                        : 160.0
                                  : 170.0) *
                              math.max(1, textScale),
                          child: _TopicPhotoCard(
                            items[index],
                            compact: index > 1,
                            featured: index == 0,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicPhotoCard extends StatelessWidget {
  const _TopicPhotoCard(
    this.topic, {
    required this.compact,
    required this.featured,
  });
  final AtlasTopic topic;
  final bool compact, featured;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${topic.title}，${topic.question}',
    child: Material(
      color: AtlasPalette.navy,
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/topics/${topic.id}'),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MediaPhoto(topic.mediaId),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, .35, 1],
                  colors: [
                    Colors.transparent,
                    Color(0x170B263E),
                    Color(0xDC071B2C),
                  ],
                ),
              ),
            ),
            Positioned(
              left: compact ? 12 : 16,
              right: compact ? 12 : 52,
              bottom: compact ? 12 : 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TopicBadge(topic.category),
                  const SizedBox(height: 5),
                  Text(
                    topic.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact
                          ? 19
                          : featured
                          ? 28
                          : 25,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    topic.question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 13 : 15,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (!compact)
              const Positioned(
                right: 14,
                bottom: 18,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AtlasPalette.orange,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AtlasPalette.navy,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _TopicBadge extends StatelessWidget {
  const _TopicBadge(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: AtlasPalette.orange,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: AtlasPalette.navy,
      ),
    ),
  );
}

class TopicScreen extends StatelessWidget {
  const TopicScreen(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) {
    final t = context.atlas.content.topic(id);
    if (t == null) {
      return const AtlasPage(
        title: '专题',
        child: AtlasEmpty(title: '这个专题暂时不可用', message: '回到专题目录继续发现。'),
      );
    }
    final articles = t.articleIds
        .map(context.atlas.content.article)
        .whereType<AtlasArticle>()
        .toList();
    final countryMap = <String, AtlasCountry>{
      for (final country
          in articles
              .map((a) => context.atlas.content.country(a.countryId))
              .whereType<AtlasCountry>())
        country.id: country,
    };
    final countries = countryMap.values.toList();
    final cover = context.atlas.content.media[t.mediaId];
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 270 * math.max(1, textScale),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MediaPhoto(t.mediaId),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x260B263E), Color(0xBB0B263E)],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 8,
                        right: 8,
                        child: SafeArea(
                          bottom: false,
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: '返回',
                                onPressed: () => backOrHome(context, '/topics'),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: '图片来源',
                                onPressed: cover == null
                                    ? null
                                    : () => showMediaCredit(context, cover),
                                icon: const Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              SavedButton(
                                kind: 'topic',
                                id: id,
                                title: t.title,
                                light: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 22,
                        right: 22,
                        bottom: 34,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _TopicBadge('跨国专题'),
                            const SizedBox(height: 8),
                            Text(
                              t.title,
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                            Text(
                              t.question,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (countries.isNotEmpty) _TopicConnections(countries),
                        const SizedBox(height: 6),
                        Text(
                          t.description,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AtlasPalette.muted,
                          ),
                        ),
                        const EditorialHeading('从这里开始'),
                        for (var i = 0; i < articles.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _TopicArticleRow(
                              article: articles[i],
                              countryName:
                                  countryMap[articles[i].countryId]?.name ?? '',
                              index: i,
                            ),
                          ),
                        if (articles.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          PrimaryAction(
                            '阅读第一站',
                            onPressed: () =>
                                context.push('/articles/${articles.first.id}'),
                          ),
                        ],
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
}

class _TopicArticleRow extends StatelessWidget {
  const _TopicArticleRow({
    required this.article,
    required this.countryName,
    required this.index,
  });
  final AtlasArticle article;
  final String countryName;
  final int index;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: context.atlas.journal,
    builder: (context, _) {
      final completed =
          context.atlas.journal.progress[article.id]?['completed'] == 1;
      return Material(
        color: completed ? AtlasPalette.orangeSoft : Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AtlasPalette.line),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/articles/${article.id}'),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                MediaPhoto(article.mediaId, width: 76, height: 66, radius: 10),
                const SizedBox(width: 10),
                Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFFCE6419),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$countryName · ${completed ? '已读过' : '可以离线阅读'}',
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AtlasPalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: completed ? AtlasPalette.orange : AtlasPalette.navy,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _TopicConnections extends StatelessWidget {
  const _TopicConnections(this.countries);
  final List<AtlasCountry> countries;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 170,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final transform = _ConnectionTransform(size);
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: FutureBuilder<AtlasGeometry>(
                    future: AtlasGeometry.load(),
                    builder: (context, snapshot) => CustomPaint(
                      painter: _ConnectionPainter(snapshot.data, countries),
                    ),
                  ),
                ),
                for (final country in countries)
                  Positioned(
                    left: (transform.point(country).dx - 30).clamp(
                      0,
                      size.width - 60,
                    ),
                    top: (transform.point(country).dy - 24).clamp(
                      6,
                      size.height - 76,
                    ),
                    child: Semantics(
                      button: true,
                      label: '探索${country.name}',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.push('/countries/${country.id}'),
                        child: SizedBox(
                          width: 60,
                          child: Column(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: AtlasPalette.orange,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: MediaPhoto(country.mediaId),
                                ),
                              ),
                              const SizedBox(height: 3),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .94),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  child: Text(
                                    country.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const Positioned(
                  right: 4,
                  bottom: 0,
                  child: Text(
                    'Natural Earth',
                    style: TextStyle(fontSize: 10, color: AtlasPalette.muted),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      const Text(
        '连接共同的知识主题',
        style: TextStyle(fontSize: 11, color: AtlasPalette.muted),
      ),
    ],
  );
}

class _ConnectionTransform {
  _ConnectionTransform(Size size)
    : scale = math.min(
        size.width / worldSize.width,
        size.height / worldSize.height,
      ),
      offset = Offset(
        (size.width -
                worldSize.width *
                    math.min(
                      size.width / worldSize.width,
                      size.height / worldSize.height,
                    )) /
            2,
        (size.height -
                worldSize.height *
                    math.min(
                      size.width / worldSize.width,
                      size.height / worldSize.height,
                    )) /
            2,
      );
  final double scale;
  final Offset offset;
  Offset point(AtlasCountry country) =>
      project(country.latitude, country.longitude) * scale + offset;
}

class _ConnectionPainter extends CustomPainter {
  _ConnectionPainter(this.geometry, this.countries);
  final AtlasGeometry? geometry;
  final List<AtlasCountry> countries;
  @override
  void paint(Canvas canvas, Size size) {
    final transform = _ConnectionTransform(size);
    final data = geometry;
    if (data != null) {
      canvas.save();
      canvas.translate(transform.offset.dx, transform.offset.dy);
      canvas.scale(transform.scale);
      final land = Paint()..color = const Color(0xFFE0EBF2);
      for (final shape in data.countries) {
        canvas.drawPath(shape.path, land);
      }
      canvas.restore();
    }
    final sorted = [...countries]
      ..sort((a, b) => a.longitude.compareTo(b.longitude));
    final stroke = Paint()
      ..color = AtlasPalette.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (var i = 1; i < sorted.length; i++) {
      final a = transform.point(sorted[i - 1]), b = transform.point(sorted[i]);
      final line = Path()..moveTo(a.dx, a.dy);
      line.quadraticBezierTo(
        (a.dx + b.dx) / 2,
        math.min(a.dy, b.dy) - 18,
        b.dx,
        b.dy,
      );
      canvas.drawPath(line, stroke);
    }
  }

  @override
  bool shouldRepaint(_ConnectionPainter oldDelegate) =>
      oldDelegate.geometry != geometry || oldDelegate.countries != countries;
}
