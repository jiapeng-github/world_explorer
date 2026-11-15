import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../domain/atlas_content.dart';

class SouthAfricaBrandBar extends StatelessWidget
    implements PreferredSizeWidget {
  const SouthAfricaBrandBar({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(52);
  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    backgroundColor: Colors.white,
    toolbarHeight: 52,
    titleSpacing: 16,
    title: Row(
      children: [
        InkWell(
          onTap: () => backOrHome(context, '/encyclopedia'),
          child: Image.asset(
            'assets/images/world-atlas-logo.png',
            width: 30,
            height: 34,
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
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AtlasPalette.navy,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    actions: [
      IconButton(
        tooltip: '打开南非地图',
        onPressed: () => context.push('/atlas?country=zaf'),
        icon: const Icon(Icons.map_outlined),
      ),
      IconButton(
        tooltip: '搜索',
        onPressed: () => context.push('/search'),
        icon: const Icon(Icons.search),
      ),
      IconButton(
        tooltip: '南非探索目录',
        onPressed: () => context.push('/countries/zaf/contents'),
        icon: const Icon(Icons.menu),
      ),
    ],
  );
}

class SouthAfricaOverview extends StatelessWidget {
  const SouthAfricaOverview(this.country, {super.key});
  final AtlasCountry country;
  @override
  Widget build(BuildContext context) {
    final c = country;
    final content = context.atlas.content;
    final journeys = (c.editorial['journeys'] as List).cast<Json>();
    return ListenableBuilder(
      listenable: context.atlas.journal,
      builder: (context, _) {
        final pending =
            context.atlas.journal.progress.entries
                .where(
                  (e) =>
                      content.article(e.key)?.countryId == 'zaf' &&
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
            : content.article(pending.first.key);
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: const SouthAfricaBrandBar(),
          body: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 205,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MediaPhoto(
                            c.mediaId,
                            width: double.infinity,
                            height: 205,
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [Colors.transparent, Color(0x600b263e)],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            top: 20,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '南非',
                                  style: TextStyle(
                                    fontSize: 34,
                                    height: 1.1,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Text(
                                  'SOUTH AFRICA',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AtlasPalette.orange,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    c.tagline,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
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
                      offset: const Offset(0, -15),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(22),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              '先认识南非',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              c.intro,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.65,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xffedf3f9),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final (icon, value, label) in [
                                    (Icons.place_outlined, '三城分工', '首都'),
                                    (Icons.terrain_outlined, '非洲南部', '位置'),
                                    (Icons.chat_bubble_outline, '12种', '官方语言'),
                                  ])
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Icon(
                                            icon,
                                            color: AtlasPalette.navy,
                                            size: 25,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            value,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            label,
                                            style: const TextStyle(
                                              color: AtlasPalette.muted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 17),
                            const Text(
                              '选一条路线，开始探索',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
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
                                          color: AtlasPalette.canvas,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: InkWell(
                                            onTap: () => context.push(
                                              '/countries/zaf/journeys/${j['id']}',
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                MediaPhoto(
                                                  j['mediaId'],
                                                  width: double.infinity,
                                                  height: single ? 125 : 90,
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 9,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          j['title'],
                                                          maxLines: 1,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      const Icon(
                                                        Icons.chevron_right,
                                                        size: 14,
                                                        color:
                                                            AtlasPalette.orange,
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
                            ),
                            const SizedBox(height: 12),
                            for (final (id, icon) in [
                              ('zaf-african-penguins', Icons.waves),
                              ('zaf-two-capes', Icons.public),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: Material(
                                  color: const Color(0xffeef4fa),
                                  borderRadius: BorderRadius.circular(12),
                                  child: ListTile(
                                    dense: true,
                                    minTileHeight: 48,
                                    leading: Icon(
                                      icon,
                                      color: AtlasPalette.navy,
                                    ),
                                    title: Text(
                                      content.article(id)!.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                    ),
                                    onTap: () => context.push('/articles/$id'),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xffff9027),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                              ),
                              onPressed: () => context.push(
                                resume == null
                                    ? '/countries/zaf/journeys/coast-life'
                                    : '/articles/${resume.id}',
                              ),
                              icon: const Icon(Icons.play_circle_fill),
                              label: Text(
                                resume == null
                                    ? '从海岸开始'
                                    : '继续阅读：${resume.title}',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () =>
                                  context.push('/credits?entity=zaf'),
                              icon: const Icon(Icons.info_outline, size: 16),
                              label: const Text('资料来源与图片许可'),
                            ),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      context.push('/countries/zaf/contents'),
                                  child: const Text('全部栏目'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      context.push('/countries/zaf/timeline'),
                                  child: const Text('历史线索'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      context.push('/me/countries/zaf'),
                                  child: const Text('我的发现'),
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
