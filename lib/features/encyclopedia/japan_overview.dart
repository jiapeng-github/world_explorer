import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../domain/atlas_content.dart';

/// Japan's photo-led entry point. Only links to records present in the catalog.
class JapanOverview extends StatelessWidget {
  const JapanOverview(this.country, {super.key});
  final AtlasCountry country;
  @override
  Widget build(BuildContext context) {
    final content = context.atlas.content;
    final routes = [
      ('岛屿与山海', 'mount-fuji', 'islands'),
      ('城市的一天', 'japan-photo-tokyo', 'daily'),
      ('物件里的时间', 'japan-photo-himeji', 'objects'),
    ];
    return Scaffold(
      backgroundColor: AtlasPalette.canvas,
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回百科',
          onPressed: () => backOrHome(context, '/encyclopedia'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('世界大百科'),
        actions: [
          IconButton(
            tooltip: '日本探索目录',
            onPressed: () => context.push('/countries/japan/contents'),
            icon: const Icon(Icons.menu),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 270,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MediaPhoto(
                        country.mediaId,
                        width: double.infinity,
                        height: 270,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xb012395b)],
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 20,
                        right: 20,
                        bottom: 28,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '日本',
                              style: TextStyle(
                                fontSize: 48,
                                height: 1.1,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'JAPAN',
                              style: TextStyle(
                                fontSize: 23,
                                letterSpacing: 2,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '从岛屿读懂山海与生活',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
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
                          id: country.id,
                          title: country.name,
                          light: true,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                          '先认识日本',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '从亚洲东部的岛屿出发，认识山海、城市与不同地方的人们。',
                          style: TextStyle(fontSize: 16, height: 1.65),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AtlasPalette.canvas,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final (icon, value, label) in [
                                (Icons.place_outlined, '东京', '首都'),
                                (Icons.public, '东亚', '所在地区'),
                                (Icons.chat_bubble_outline, '日语', '主要语言'),
                              ])
                                Expanded(
                                  child: Column(
                                    children: [
                                      Icon(icon, color: AtlasPalette.orange),
                                      const SizedBox(height: 6),
                                      Text(
                                        value,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
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
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '选择一个探索主题',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final (title, media, section) in routes)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: Material(
                              color: AtlasPalette.canvas,
                              borderRadius: BorderRadius.circular(14),
                              child: ListTile(
                                leading: MediaPhoto(
                                  media,
                                  width: 76,
                                  height: 60,
                                  radius: 10,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                subtitle: Text(
                                  section == 'islands'
                                      ? '位置 · 火山 · 森林'
                                      : section == 'daily'
                                      ? '换乘 · 标签 · 河岸'
                                      : '陶器 · 版画 · 铁路',
                                ),
                                title: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: AtlasPalette.orange,
                                ),
                                onTap: () => context.push(
                                  '/countries/japan/journeys/$section',
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 5),
                        if (content.article('japan-questions')
                            case final article?)
                          OutlinedButton.icon(
                            onPressed: () =>
                                context.push('/articles/${article.id}'),
                            icon: const Icon(Icons.help_outline),
                            label: Text(article.title),
                          ),
                        const SizedBox(height: 10),
                        ListenableBuilder(
                          listenable: context.atlas.journal,
                          builder: (context, _) {
                            final unfinished =
                                context.atlas.journal.progress.entries
                                    .where(
                                      (e) =>
                                          content.article(e.key)?.countryId ==
                                              'japan' &&
                                          e.value['completed'] != 1,
                                    )
                                    .toList()
                                  ..sort(
                                    (a, b) => (b.value['updated_at'] as String)
                                        .compareTo(
                                          a.value['updated_at'] as String,
                                        ),
                                  );
                            final articleId = unfinished.isEmpty
                                ? 'japan-find-map'
                                : unfinished.first.key;
                            return FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AtlasPalette.orange,
                                foregroundColor: AtlasPalette.navy,
                                minimumSize: const Size.fromHeight(56),
                              ),
                              onPressed: () =>
                                  context.push('/articles/$articleId'),
                              icon: const Icon(Icons.play_circle_fill),
                              label: Text(
                                unfinished.isEmpty ? '从岛屿开始' : '继续上次阅读',
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/atlas?country=japan'),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('打开日本地图'),
                        ),
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  context.push('/countries/japan/contents'),
                              child: const Text('全部栏目'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.push('/me/countries/japan'),
                              child: const Text('我的日本发现'),
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
  }
}
