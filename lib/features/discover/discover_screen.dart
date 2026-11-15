import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.title = '世界大百科'});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 12, 14, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
        IconButton.filledTonal(
          onPressed: () => context.push('/search'),
          tooltip: '搜索国家、地点或问题',
          icon: const Icon(Icons.search_rounded, size: 30),
        ),
      ],
    ),
  );
}

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.white,
    child: SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, viewport) {
          if (viewport.maxWidth < 820) {
            return ListView(
              children: [
                const BrandHeader(),
                const SizedBox(height: 410, child: _DiscoveryHero()),
                Transform.translate(
                  offset: const Offset(0, -12),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 26),
                      child: _DiscoveryContent(),
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              const BrandHeader(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, available) {
                    // Fill a tablet's remaining viewport, but allow scrolling in
                    // short split-screen windows or with enlarged text.
                    final textScale =
                        MediaQuery.textScalerOf(context).scale(18) / 18;
                    final minimumHeight =
                        530 + (textScale - 1).clamp(0, 3) * 220;
                    final contentHeight = (available.maxHeight - 32)
                        .clamp(minimumHeight, double.infinity)
                        .toDouble();
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: SizedBox(
                        height: contentHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 6,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: const _DiscoveryHero(tablet: true),
                              ),
                            ),
                            const SizedBox(width: 24),
                            const Expanded(
                              flex: 5,
                              child: _DiscoveryContent(tablet: true),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _DiscoveryHero extends StatelessWidget {
  const _DiscoveryHero({this.tablet = false});
  final bool tablet;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const MediaPhoto('nile-aswan', alignment: Alignment(-.75, .65)),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xDDFFFFFF),
              Color(0x00FFFFFF),
              Color(0x00000000),
              Color(0xAA071D2F),
            ],
            stops: [0, .13, .38, .52, 1],
          ),
        ),
      ),
      Positioned(
        top: 12,
        left: 22,
        right: 22,
        child: Text(
          '世界这么大，\n今天去哪儿？',
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontSize: tablet ? 43 : 34),
        ),
      ),
      Positioned(
        bottom: 30,
        left: 22,
        right: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: AtlasPalette.orange, size: 22),
                SizedBox(width: 6),
                Text(
                  '今日目的地 · 埃及',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              '沿着尼罗河，发现埃及',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 190,
              child: PrimaryAction(
                '开始探索',
                onPressed: () => context.push('/countries/egypt'),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _DiscoveryContent extends StatelessWidget {
  const _DiscoveryContent({this.tablet = false});
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final questions = Row(
      crossAxisAlignment: tablet
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      children: [
        Expanded(
          child: QuestionTile(
            title: '雨林里住着谁？',
            mediaId: 'tree-frog',
            route: '/topics/nature',
            expandImage: tablet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: QuestionTile(
            title: '世界各地怎么上学？',
            mediaId: 'school',
            route: '/topics/daily',
            expandImage: tablet,
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ContinueReading(topSpacing: tablet ? 0 : 14),
        EditorialHeading(
          '从一个问题出发',
          actionLabel: '查看更多',
          onAction: () => context.push('/topics'),
        ),
        if (tablet) Expanded(child: questions) else questions,
        const SizedBox(height: 22),
        ContentRow(
          title: '把世界铺在眼前',
          subtitle: '从地图上的一个地方开始',
          leading: const Icon(Icons.public, size: 36, color: AtlasPalette.blue),
          outlined: true,
          onTap: () => context.go('/atlas'),
        ),
      ],
    );
  }
}

class ContinueReading extends StatelessWidget {
  const ContinueReading({super.key, this.topSpacing = 14});
  final double topSpacing;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: context.atlas.journal,
    builder: (context, _) {
      final journal = context.atlas.journal;
      final progress = journal.progress.values
          .where(
            (p) =>
                p['completed'] != 1 &&
                context.atlas.content.article(p['article_id']) != null,
          )
          .firstOrNull;
      final article =
          context.atlas.content.article(
            progress?['article_id'] ?? 'china-history',
          ) ??
          context.atlas.content.articles.first;
      return Container(
        margin: EdgeInsets.only(top: topSpacing),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AtlasPalette.canvas,
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => context.push('/articles/${article.id}'),
          child: Row(
            children: [
              MediaPhoto(article.mediaId, width: 98, height: 88, radius: 12),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress == null ? '从一个问题开始' : '继续阅读',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AtlasPalette.muted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      article.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 10),
                      ExcludeSemantics(
                        child: LinearProgressIndicator(
                          value: (progress['fraction'] as num).toDouble(),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(8),
                          color: AtlasPalette.blue,
                          backgroundColor: AtlasPalette.line,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '已读 ${((progress['fraction'] as num).clamp(0, 1) * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AtlasPalette.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 22),
            ],
          ),
        ),
      );
    },
  );
}

class QuestionTile extends StatelessWidget {
  const QuestionTile({
    super.key,
    required this.title,
    required this.mediaId,
    required this.route,
    this.expandImage = false,
  });
  final String title, mediaId, route;
  final bool expandImage;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AtlasPalette.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.push(route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (expandImage)
            Expanded(
              child: MediaPhoto(
                mediaId,
                width: double.infinity,
                height: double.infinity,
              ),
            )
          else
            AspectRatio(
              aspectRatio: 1.55,
              child: MediaPhoto(
                mediaId,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 9, 6, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title == '世界各地怎么上学？' ? '世界各地\n怎么上学？' : title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 19),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final selected = <String>{};
  bool saving = false;
  Future<void> finish() async {
    setState(() => saving = true);
    await atlasAction(context, () async {
      await context.atlas.preferences.onboard(selected.toList());
      if (mounted) context.go('/discover');
    });
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    const interests = [
      ('动物', 'elephant'),
      ('山川', 'mount-fuji'),
      ('城市', 'florence'),
      ('历史', 'egypt-giza'),
      ('生活', 'school'),
      ('文化', 'china-wall'),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: finish,
          tooltip: '进入发现',
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : finish,
            child: const Text('跳过'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            children: [
              Text(
                '你对什么最好奇？',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                '选几个喜欢的，也可以直接出发',
                style: TextStyle(color: AtlasPalette.muted, fontSize: 17),
              ),
              const SizedBox(height: 22),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: interests.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.03,
                ),
                itemBuilder: (context, index) {
                  final item = interests[index],
                      active = selected.contains(interests[index].$1);
                  return Semantics(
                    button: true,
                    selected: active,
                    label: item.$1,
                    child: InkWell(
                      onTap: () => setState(() {
                        active
                            ? selected.remove(item.$1)
                            : selected.add(item.$1);
                      }),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: active
                                ? AtlasPalette.navy
                                : AtlasPalette.line,
                            width: active ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: MediaPhoto(
                                    item.$2,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    item.$1,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                              ],
                            ),
                            if (active)
                              const Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  radius: 17,
                                  backgroundColor: AtlasPalette.orange,
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              PrimaryAction(
                saving ? '正在保存…' : '开始探索世界',
                onPressed: saving ? null : finish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
