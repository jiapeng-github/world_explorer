import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../domain/atlas_content.dart';

class KenyaBrandBar extends StatelessWidget implements PreferredSizeWidget {
  const KenyaBrandBar({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(64);
  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    backgroundColor: Colors.white,
    titleSpacing: 16,
    title: Row(
      children: [
        InkWell(
          onTap: () => backOrHome(context, '/encyclopedia'),
          child: Image.asset(
            'assets/images/world-atlas-logo.png',
            width: 36,
            height: 40,
          ),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '世界大百科',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: AtlasPalette.navy,
                ),
              ),
              Text(
                '儿童地理百科',
                style: TextStyle(fontSize: 11, color: AtlasPalette.muted),
              ),
            ],
          ),
        ),
      ],
    ),
    actions: [
      IconButton(
        tooltip: '打开肯尼亚地图',
        onPressed: () => context.push('/atlas?country=kenya'),
        icon: const Icon(Icons.map_outlined),
      ),
      IconButton(
        tooltip: '搜索',
        onPressed: () => context.push('/search'),
        icon: const Icon(Icons.search),
      ),
      IconButton(
        tooltip: '肯尼亚探索目录',
        onPressed: () => context.push('/countries/kenya/contents'),
        icon: const Icon(Icons.menu),
      ),
    ],
  );
}

class KenyaOverview extends StatelessWidget {
  const KenyaOverview(this.country, {super.key});
  final AtlasCountry country;
  @override
  Widget build(BuildContext context) {
    final c = country;
    final journeys = (c.editorial['journeys'] as List).cast<Json>();
    return ListenableBuilder(
      listenable: context.atlas.journal,
      builder: (context, _) {
        final pending =
            context.atlas.journal.progress.entries
                .where(
                  (e) =>
                      context.atlas.content.article(e.key)?.countryId ==
                          'kenya' &&
                      e.value['completed'] != 1,
                )
                .toList()
              ..sort(
                (a, b) => (b.value['updated_at'] as String).compareTo(
                  a.value['updated_at'] as String,
                ),
              );
        final resume = pending.isEmpty
            ? null
            : context.atlas.content.article(pending.first.key);
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: const KenyaBrandBar(),
          body: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 290,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MediaPhoto(
                            c.mediaId,
                            height: 290,
                            width: double.infinity,
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0x660e3048), Colors.transparent],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 22,
                            top: 28,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '肯尼亚',
                                  style: TextStyle(
                                    fontSize: 48,
                                    height: 1.1,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'KENYA',
                                  style: TextStyle(
                                    fontSize: 18,
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 9,
                                  ),
                                  width: 52,
                                  height: 4,
                                  color: AtlasPalette.orange,
                                ),
                                Text(
                                  c.tagline,
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 8,
                            bottom: 20,
                            child: SavedButton(
                              kind: 'country',
                              id: c.id,
                              title: c.name,
                              light: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -12),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 23,
                                  decoration: BoxDecoration(
                                    color: AtlasPalette.orange,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '先认识肯尼亚',
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final (icon, value, label) in [
                                  (Icons.account_balance_outlined, '内罗毕', '首都'),
                                  (Icons.place_outlined, '非洲东部', '位置'),
                                  (
                                    Icons.chat_bubble_outline,
                                    '斯瓦希里语、英语',
                                    '官方语言',
                                  ),
                                ])
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Icon(
                                          icon,
                                          size: 27,
                                          color: AtlasPalette.orange,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          value,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          label,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AtlasPalette.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            LayoutBuilder(
                              builder: (context, limits) {
                                final single =
                                    MediaQuery.textScalerOf(context).scale(1) >
                                    1.3;
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final j in journeys)
                                      SizedBox(
                                        width: single
                                            ? limits.maxWidth
                                            : (limits.maxWidth - 16) / 3,
                                        child: Material(
                                          borderRadius: BorderRadius.circular(
                                            13,
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: InkWell(
                                            onTap: () => context.push(
                                              '/countries/kenya/journeys/${j['id']}',
                                            ),
                                            child: SizedBox(
                                              height: single ? 150 : 152,
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  MediaPhoto(
                                                    j['mediaId'],
                                                    height: 152,
                                                    width: double.infinity,
                                                  ),
                                                  const DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment.center,
                                                        end: Alignment
                                                            .bottomCenter,
                                                        colors: [
                                                          Colors.transparent,
                                                          Color(0xcc102a3a),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left: 8,
                                                    right: 5,
                                                    bottom: 12,
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            j['title'],
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                ),
                                                          ),
                                                        ),
                                                        const Icon(
                                                          Icons.chevron_right,
                                                          color: Colors.white,
                                                          size: 16,
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
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Material(
                              color: const Color(0xffedf3f9),
                              borderRadius: BorderRadius.circular(14),
                              child: Column(
                                children: [
                                  for (final (id, title) in [
                                    ('kenya-geography', '赤道附近为什么有高山？'),
                                    ('kenya-questions', '照片之外，还有哪些问题？'),
                                  ])
                                    ListTile(
                                      dense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                      leading: const Icon(
                                        Icons.help,
                                        color: AtlasPalette.orange,
                                      ),
                                      title: Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.chevron_right,
                                        size: 20,
                                      ),
                                      onTap: () =>
                                          context.push('/articles/$id'),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AtlasPalette.orange,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(54),
                              ),
                              onPressed: () => context.push(
                                resume == null
                                    ? '/countries/kenya/journeys/mountain-water'
                                    : '/articles/${resume.id}',
                              ),
                              icon: const Icon(Icons.arrow_forward),
                              label: Text(
                                resume == null
                                    ? '从肯尼亚山开始'
                                    : '继续阅读：${resume.title}',
                              ),
                            ),
                            Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                for (final (label, path) in [
                                  ('全部栏目', '/countries/kenya/contents'),
                                  ('历史线索', '/countries/kenya/timeline'),
                                  ('我的发现', '/me/countries/kenya'),
                                  ('资料来源', '/credits?entity=kenya'),
                                ])
                                  TextButton(
                                    onPressed: () => context.push(path),
                                    child: Text(label),
                                  ),
                              ],
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
      },
    );
  }
}
