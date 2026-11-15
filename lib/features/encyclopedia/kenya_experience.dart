import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../domain/atlas_content.dart';
import 'kenya_overview.dart';

const _navy = AtlasPalette.navy;

class KenyaSectionTiles extends StatelessWidget {
  const KenyaSectionTiles(this.country, {super.key, this.limit});
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
                        context.push('/countries/kenya/sections/${entry.key}'),
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

class KenyaPhotoRow extends StatelessWidget {
  const KenyaPhotoRow({
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

class KenyaTimeline extends StatelessWidget {
  const KenyaTimeline({super.key});
  @override
  Widget build(BuildContext context) {
    final timeline =
        context.atlas.content.country('kenya')!.editorial['timeline'] as List;
    return AtlasPage(
      title: '肯尼亚 · 历史线索',
      appBar: const KenyaBrandBar(),
      padding: const EdgeInsets.all(18),
      width: 820,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '肯尼亚 · 历史线索',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          const Text(
            '认识海岸交流、殖民统治与争取自主的历史，用证据走近过去。',
            style: TextStyle(
              fontSize: 17,
              height: 1.65,
              color: AtlasPalette.muted,
            ),
          ),
          const SizedBox(height: 20),
          for (final node in timeline)
            KenyaPhotoRow(
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

class KenyaDaily extends StatelessWidget {
  const KenyaDaily({super.key});
  @override
  Widget build(BuildContext context) {
    final content = context.atlas.content;
    return AtlasPage(
      title: '肯尼亚 · 日常生活',
      appBar: const KenyaBrandBar(),
      width: 820,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryAction(
            '看看内罗毕在哪里',
            icon: Icons.place_outlined,
            onPressed: () =>
                context.push('/atlas?country=kenya&place=kenya-nairobi-city'),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '肯尼亚 · 日常生活',
            style: TextStyle(color: AtlasPalette.muted, fontSize: 14),
          ),
          const SizedBox(height: 12),
          const MediaPhoto(
            'kenya-m04',
            width: double.infinity,
            height: 230,
            radius: 14,
            showCredit: true,
          ),
          const SizedBox(height: 20),
          const Text(
            '内罗毕的一天',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            '从内罗毕的街景出发，观察交通、食物与城市里的语言。',
            style: TextStyle(fontSize: 17, height: 1.6),
          ),
          const SizedBox(height: 18),
          for (final (slug, title, body) in [
            ('transport', '城市怎样连接？', '在共同站点，换到另一条线路。'),
            ('food', '从玉米到餐桌', '原料怎样经过加工，成为日常食物？'),
            ('people', '一座城市，多种语言', '官方语言与具体生活有什么关系？'),
          ])
            KenyaPhotoRow(
              mediaId: content.article('kenya-$slug')!.mediaId,
              title: title,
              body: body,
              onTap: () => context.push('/articles/kenya-$slug'),
            ),
        ],
      ),
    );
  }
}

class KenyaTasks extends StatefulWidget {
  const KenyaTasks({super.key});
  @override
  State<KenyaTasks> createState() => _KenyaTasksState();
}

class _KenyaTasksState extends State<KenyaTasks> {
  String category = '';
  Future<void> openTask(String path, String title, String mediaId) async {
    await context.atlas.preferences.set('kenya-last-task', {
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
    final last = context.atlas.preferences.values['kenya-last-task'] as Json?;
    final exercises = content.exercises.where((e) => e.countryId == 'kenya');
    final activities = content
        .articlesIn('kenya')
        .where((a) => a.activity['type'] == 'open');
    return AtlasPage(
      title: '肯尼亚 · 探索任务',
      appBar: const KenyaBrandBar(),
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
                  Row(
                    children: [
                      for (final id in ['kenya-m03', 'kenya-m09', 'kenya-m01'])
                        Expanded(
                          child: MediaPhoto(
                            id,
                            height: 210,
                            width: double.infinity,
                          ),
                        ),
                    ],
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
                          '肯尼亚 · 探索任务',
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
              KenyaPhotoRow(
                mediaId: last['mediaId'],
                title: '继续上次活动',
                body: last['title'],
                onTap: () =>
                    openTask(last['path'], last['title'], last['mediaId']),
              ),
            KenyaPhotoRow(
              mediaId: 'kenya-m03',
              title: '找到内罗毕',
              body: '在地图上定位肯尼亚首都。',
              onTap: () =>
                  openTask('/exercises/kenya-l02', '找到内罗毕', 'kenya-m03'),
            ),
            KenyaPhotoRow(
              mediaId: 'kenya-m06',
              title: '观察海岸木门',
              body: '分开记录看见的形状与需要解释的含义。',
              onTap: () => openTask(
                '/countries/kenya/observe/kenya-patterns',
                '观察海岸木门',
                'kenya-m06',
              ),
            ),
            KenyaPhotoRow(
              mediaId: 'kenya-m09',
              title: '看见与猜想',
              body: '把直接观察与待验证的解释分开。',
              onTap: () => openTask(
                '/countries/kenya/observe/kenya-questions',
                '看见与猜想',
                'kenya-m09',
              ),
            ),
          ] else if (category == 'open') ...[
            for (final a in activities)
              KenyaPhotoRow(
                mediaId: a.mediaId,
                title: a.activity['title'],
                body: a.activity['prompt'],
                onTap: () => openTask(
                  '/countries/kenya/observe/${a.id}',
                  a.activity['title'],
                  a.mediaId,
                ),
              ),
          ] else ...[
            for (final e in exercises.where((e) => e.type == category))
              KenyaPhotoRow(
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
            onPressed: () => context.push('/me/countries/kenya'),
            icon: const Icon(Icons.auto_stories_outlined),
            label: const Text('去看看我的发现'),
          ),
        ],
      ),
    );
  }
}

class KenyaDiscoveries extends StatelessWidget {
  const KenyaDiscoveries({super.key});
  @override
  Widget build(BuildContext context) {
    final content = context.atlas.content, j = context.atlas.journal;
    final ids = {
      'kenya',
      ...content.articlesIn('kenya').map((a) => a.id),
      ...content.placesIn('kenya').map((p) => p.id),
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
          title: '我的肯尼亚发现',
          appBar: const KenyaBrandBar(),
          width: 850,
          padding: const EdgeInsets.all(18),
          bottom: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryAction(
                '开始一次探索',
                orange: true,
                onPressed: () => context.push('/countries/kenya/explore'),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '我的肯尼亚发现',
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
                  KenyaPhotoRow(
                    mediaId:
                        content.article(note['entity_id'])?.mediaId ??
                        content
                            .place(note['entity_id'])
                            ?.mediaIds
                            .firstOrNull ??
                        'kenya-m01',
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
              LayoutBuilder(
                builder: (context, box) {
                  final single =
                      MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                      box.maxWidth < 320;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final (id, media, title) in [
                        ('lamu', 'kenya-m05', '走进拉穆古镇'),
                        ('kakamega', 'kenya-m19', '森林里找线索'),
                      ])
                        SizedBox(
                          width: single
                              ? box.maxWidth
                              : (box.maxWidth - 12) / 2,
                          child: Material(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: AtlasPalette.line),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => context.push('/places/kenya-$id'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  MediaPhoto(
                                    media,
                                    height: 122,
                                    width: double.infinity,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      '$title  ›',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
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
            ],
          ),
        );
      },
    );
  }
}
