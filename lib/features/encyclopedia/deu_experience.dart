import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../domain/atlas_content.dart';
import 'deu_overview.dart';

const _navy = AtlasPalette.navy;

class GermanySectionTiles extends StatelessWidget {
  const GermanySectionTiles(this.country, {super.key, this.limit});
  final AtlasCountry country;
  final int? limit;
  @override
  Widget build(BuildContext context) {
    final sections = (country.editorial['sections'] as Json).entries.take(
      limit ?? 10,
    );
    const icons = [
      Icons.badge_outlined,
      Icons.landscape_outlined,
      Icons.chat_bubble_outline,
      Icons.home_outlined,
      Icons.restaurant_outlined,
      Icons.music_note_outlined,
      Icons.location_city_outlined,
      Icons.forest_outlined,
      Icons.history,
      Icons.help_outline,
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final single =
            box.maxWidth < 315 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (i, entry) in sections.indexed)
              SizedBox(
                width: single ? box.maxWidth : (box.maxWidth - 10) / 2,
                child: Material(
                  borderRadius: BorderRadius.circular(13),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () =>
                        context.push('/countries/deu/sections/${entry.key}'),
                    child: SizedBox(
                      height: 90,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MediaPhoto(
                            entry.value['mediaId'],
                            width: double.infinity,
                            height: 90,
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Color(0xd9102637)],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            right: 8,
                            bottom: 12,
                            child: Row(
                              children: [
                                Icon(icons[i], color: Colors.white, size: 23),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    entry.value['title'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
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
                ),
              ),
          ],
        );
      },
    );
  }
}

class GermanyPhotoRow extends StatelessWidget {
  const GermanyPhotoRow({
    super.key,
    required this.mediaId,
    required this.title,
    required this.body,
    required this.onTap,
    this.period,
  });
  final String mediaId, title, body;
  final VoidCallback onTap;
  final String? period;
  @override
  Widget build(BuildContext context) {
    final vertical =
        MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
        MediaQuery.sizeOf(context).width < 350;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (period != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AtlasPalette.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              period!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        if (period != null) const SizedBox(height: 7),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _navy,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          body,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AtlasPalette.muted,
          ),
        ),
        if (period != null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '查看证据  ›',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xffb75508),
              ),
            ),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: AtlasPalette.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: vertical
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MediaPhoto(
                        mediaId,
                        width: double.infinity,
                        height: 145,
                        radius: 10,
                      ),
                      const SizedBox(height: 9),
                      copy,
                    ],
                  )
                : Row(
                    children: [
                      MediaPhoto(
                        mediaId,
                        width: period == null ? 112 : 136,
                        height: period == null ? 88 : 160,
                        radius: 10,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: copy),
                      if (period == null)
                        const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AtlasPalette.orange,
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class GermanyTimeline extends StatelessWidget {
  const GermanyTimeline({super.key});
  @override
  Widget build(BuildContext context) {
    final timeline =
        context.atlas.content.country('deu')!.editorial['timeline'] as List;
    return AtlasPage(
      title: '德国 · 历史线索',
      appBar: const GermanyBrandBar(),
      padding: const EdgeInsets.all(18),
      width: 820,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '德国 · 历史线索',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          const Text(
            '从印刷的传播，到对迫害与战争的反思，再到开放边界与统一。用证据走近过去。',
            style: TextStyle(
              fontSize: 17,
              height: 1.65,
              color: AtlasPalette.muted,
            ),
          ),
          const SizedBox(height: 20),
          for (final node in timeline)
            GermanyPhotoRow(
              mediaId: node['mediaId'],
              period: node['period'],
              title: node['title'],
              body: node['body'],
              onTap: () => context.push('/articles/${node['articleIds'][0]}'),
            ),
          const Text(
            '精选线索，不是完整年表。卡片间距不代表时间长度。',
            style: TextStyle(color: AtlasPalette.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class GermanyDaily extends StatelessWidget {
  const GermanyDaily({super.key});
  @override
  Widget build(BuildContext context) {
    final content = context.atlas.content;
    return AtlasPage(
      title: '德国 · 日常生活',
      appBar: const GermanyBrandBar(),
      width: 820,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryAction(
            '在地图上找莱比锡',
            icon: Icons.place_outlined,
            onPressed: () =>
                context.push('/atlas?country=deu&place=deu-leipzig'),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '德国 · 日常生活',
            style: TextStyle(color: AtlasPalette.muted, fontSize: 14),
          ),
          const SizedBox(height: 12),
          const MediaPhoto(
            'deu-m10',
            width: double.infinity,
            height: 230,
            radius: 14,
            showCredit: true,
          ),
          const SizedBox(height: 20),
          const Text(
            '城市里的一天',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            '从莱比锡的一处街景出发，观察交通、食品标签与公共空间。',
            style: TextStyle(fontSize: 17, height: 1.6),
          ),
          const SizedBox(height: 18),
          for (final (slug, title, body) in [
            ('tram', '电车怎样换乘', '在共同站点，换到另一条线路。'),
            ('labels', '标签上的信息', '名称、单位与产地，分别回答什么？'),
            ('street', '自行车与步行空间', '从可见设施，思考不同人的需要。'),
          ])
            GermanyPhotoRow(
              mediaId: content.article('deu-$slug')!.mediaId,
              title: title,
              body: body,
              onTap: () => context.push('/articles/deu-$slug'),
            ),
        ],
      ),
    );
  }
}

class GermanyTasks extends StatefulWidget {
  const GermanyTasks({super.key});
  @override
  State<GermanyTasks> createState() => _GermanyTasksState();
}

class _GermanyTasksState extends State<GermanyTasks> {
  String category = '';
  Future<void> openTask(String path, String title, String mediaId) async {
    await context.atlas.preferences.set('deu-last-task', {
      'path': path,
      'title': title,
      'mediaId': mediaId,
    });
    if (!mounted) return;
    await context.push(path);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final content = context.atlas.content;
    final last = context.atlas.preferences.values['deu-last-task'] as Json?;
    final exercises = content.exercises.where((e) => e.countryId == 'deu');
    final activities = content
        .articlesIn('deu')
        .where((a) => a.activity['type'] == 'open');
    return AtlasPage(
      title: '德国 · 探索任务',
      appBar: const GermanyBrandBar(),
      width: 850,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              height: 210,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const MediaPhoto(
                    'deu-m01',
                    height: 210,
                    width: double.infinity,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xc012395b)],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 16,
                    right: 16,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '德国 · 探索任务',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '从地图、照片与证据出发，\n发现自然与人文。',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, box) {
              final columns = MediaQuery.textScalerOf(context).scale(1) > 1.3
                  ? 2
                  : 4;
              return Wrap(
                spacing: 7,
                runSpacing: 8,
                children: [
                  for (final (id, title, icon) in [
                    ('location', '找地图', Icons.map_outlined),
                    ('observation', '看照片', Icons.image_outlined),
                    ('choice', '找证据', Icons.search),
                    ('open', '写观察', Icons.edit_outlined),
                  ])
                    SizedBox(
                      width: (box.maxWidth - (columns - 1) * 7) / columns,
                      child: Material(
                        color: category == id
                            ? AtlasPalette.orangeSoft
                            : AtlasPalette.canvas,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setState(
                            () => category = category == id ? '' : id,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 4,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  icon,
                                  size: 30,
                                  color: id == 'open' || id == 'observation'
                                      ? AtlasPalette.orange
                                      : _navy,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
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
          const SizedBox(height: 22),
          Text(
            category.isEmpty ? '推荐探索' : '选择一个任务',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          if (category.isEmpty) ...[
            if (last != null)
              GermanyPhotoRow(
                mediaId: last['mediaId'],
                title: '继续上次活动',
                body: last['title'],
                onTap: () =>
                    openTask(last['path'], last['title'], last['mediaId']),
              ),
            GermanyPhotoRow(
              mediaId: 'deu-m02',
              title: '找到柏林',
              body: '在地图上定位德国首都。',
              onTap: () => openTask('/exercises/deu-l02', '找到柏林', 'deu-m02'),
            ),
            GermanyPhotoRow(
              mediaId: 'deu-m20',
              title: '看清潮滩纹理',
              body: '在照片中寻找弯曲的潮沟。',
              onTap: () => openTask('/exercises/deu-p05', '看清潮滩纹理', 'deu-m20'),
            ),
            GermanyPhotoRow(
              mediaId: 'deu-m18',
              title: '看见与猜想',
              body: '把直接观察与待验证的解释分开。',
              onTap: () => openTask(
                '/countries/deu/observe/deu-seen-guessed',
                '看见与猜想',
                'deu-m18',
              ),
            ),
          ] else if (category == 'open') ...[
            for (final a in activities)
              GermanyPhotoRow(
                mediaId: a.mediaId,
                title: a.activity['title'],
                body: a.activity['prompt'],
                onTap: () => openTask(
                  '/countries/deu/observe/${a.id}',
                  a.activity['title'],
                  a.mediaId,
                ),
              ),
          ] else ...[
            for (final e in exercises.where((e) => e.type == category))
              GermanyPhotoRow(
                mediaId: content.article(e.articleId)!.mediaId,
                title: e.question,
                body: content.article(e.articleId)!.title,
                onTap: () => openTask(
                  '/exercises/${e.id}',
                  e.question,
                  content.article(e.articleId)!.mediaId,
                ),
              ),
          ],
          TextButton.icon(
            onPressed: () => context.push('/me/countries/deu'),
            icon: const Icon(Icons.auto_stories_outlined),
            label: const Text('去看看我的发现'),
          ),
        ],
      ),
    );
  }
}

class GermanyDiscoveries extends StatelessWidget {
  const GermanyDiscoveries({super.key});
  @override
  Widget build(BuildContext context) {
    final content = context.atlas.content, j = context.atlas.journal;
    final ids = {
      'deu',
      ...content.articlesIn('deu').map((a) => a.id),
      ...content.placesIn('deu').map((p) => p.id),
    };
    return ListenableBuilder(
      listenable: j,
      builder: (context, _) {
        final notes = j.notes
            .where((n) => ids.contains(n['entity_id']))
            .toList();
        final read = j.progress.entries
            .where((e) => ids.contains(e.key) && e.value['completed'] == 1)
            .length;
        final viewed = j.history
            .where((h) => h['kind'] == 'place' && ids.contains(h['entity_id']))
            .map((h) => h['entity_id'])
            .toSet()
            .length;
        return AtlasPage(
          title: '我的德国发现',
          appBar: const GermanyBrandBar(),
          width: 850,
          padding: const EdgeInsets.all(18),
          bottom: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryAction(
                '开始一次探索',
                orange: true,
                onPressed: () => context.push('/countries/deu/explore'),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '我的德国发现',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  for (final (i, (value, label)) in [
                    (read, '读过文章'),
                    (viewed, '看过地点'),
                    (notes.length, '观察记录'),
                  ].indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AtlasPalette.canvas,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$value',
                              style: const TextStyle(
                                color: AtlasPalette.orange,
                                fontSize: 31,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
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
              const SizedBox(height: 18),
              if (notes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: AtlasPalette.canvas,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.edit_note_outlined,
                        size: 66,
                        color: AtlasPalette.muted,
                      ),
                      SizedBox(height: 14),
                      Text(
                        '尚未留下观察记录',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 9),
                      Text(
                        '去看地图、照片和真实的地理现象，\n把你的发现记下来吧。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: AtlasPalette.muted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final note in notes)
                  GermanyPhotoRow(
                    mediaId:
                        content.article(note['entity_id'])?.mediaId ??
                        content
                            .place(note['entity_id'])
                            ?.mediaIds
                            .firstOrNull ??
                        'deu-m01',
                    title: note['title'],
                    body: [
                      note['text'],
                      note['question'],
                    ].whereType<String>().where((s) => s.isNotEmpty).join('\n'),
                    onTap: () => context.push('/me/notes/${note['id']}/edit'),
                  ),
              const SizedBox(height: 22),
              const Text(
                '为你推荐',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              GermanyPhotoRow(
                mediaId: 'deu-m20',
                title: '去看瓦登海',
                body: '观察潮沟、滩面与生命线索。',
                onTap: () => context.push('/places/deu-wadden'),
              ),
              GermanyPhotoRow(
                mediaId: 'deu-m18',
                title: '森林里找线索',
                body: '从树干与倒木，认识森林的联系。',
                onTap: () => context.push('/places/deu-jasmund'),
              ),
            ],
          ),
        );
      },
    );
  }
}
