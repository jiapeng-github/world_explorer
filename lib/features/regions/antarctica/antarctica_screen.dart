import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/services.dart';
import '../../../app/atlas_app.dart' show AtlasShell;
import '../../../design/components.dart';
import '../../../domain/atlas_content.dart';
import '../../../data/database/user_repositories.dart';
import 'antarctica_map.dart';
import 'antarctica_diagrams.dart';

const antBase = '/regions/antarctica';
const antNavy = Color(0xff12395b);
const antOrange = Color(0xffff9a3d);
const antIce = Color(0xffe5f2f8);

class AntarcticaScreen extends StatelessWidget {
  const AntarcticaScreen({
    super.key,
    this.page = 'home',
    this.id,
    this.mapView,
  });
  final String page;
  final String? id;
  final String? mapView;
  @override
  Widget build(BuildContext context) {
    final r = context.atlas.content.region('antarctica');
    if (r == null) {
      return const AtlasPage(title: '南极洲', child: Text('专题暂时无法读取，请返回后重试。'));
    }
    if (page == 'map') {
      return AntarcticaMapScreen(placeId: id, initialView: mapView);
    }
    if (page == 'observe') return AntarcticaObservation(id: id!);
    if (page == 'task') return AntarcticaTask(id: id!);
    return ListenableBuilder(
      listenable: context.atlas.journal,
      builder: (context, _) {
        final articles = context.atlas.content.articles
            .where((a) => a.regionId == 'antarctica')
            .toList();
        final titles = {
          'home': '世界大百科',
          'contents': '南极洲',
          'section':
              r.sections.where((s) => s['id'] == id).firstOrNull?['title'] ??
              '南极主题',
          'timeline': '人们怎样认识南极？',
          'explore': '南极探索任务',
          'discoveries': '我的南极发现',
          'journey':
              r.journeys.where((s) => s['id'] == id).firstOrNull?['title'] ??
              '阅读路线',
          'place': context.atlas.content.place(id ?? '')?.name ?? '南极地点',
        };
        Widget body;
        switch (page) {
          case 'home':
            body = home(context, articles);
            break;
          case 'contents':
            body = contents(context, r);
            break;
          case 'section':
            body = section(
              context,
              articles.where((a) => a.sectionId == id).toList(),
            );
            break;
          case 'timeline':
            body = timeline(context);
            break;
          case 'explore':
            body = AntarcticaTasks();
            break;
          case 'discoveries':
            body = discoveries(context, articles);
            break;
          case 'journey':
            body = journey(context, r);
            break;
          case 'place':
            body = place(context);
            break;
          default:
            body = const Text('未找到这一页，请返回目录。');
        }
        final pageView = Theme(
          data: Theme.of(context).copyWith(
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xffdce6ef)),
              ),
            ),
          ),
          child: AtlasPage(
            title: titles[page] ?? '南极洲',
            width: 850,
            appBar: page == 'home'
                ? AppBar(
                    automaticallyImplyLeading: false,
                    title: const Text('世界大百科'),
                    actions: [
                      IconButton(
                        tooltip: '搜索',
                        onPressed: () => context.push('/search?q=南极'),
                        icon: const Icon(Icons.search),
                      ),
                    ],
                  )
                : null,
            padding: page == 'home'
                ? EdgeInsets.zero
                : const EdgeInsets.all(20),
            actions: [
              IconButton(
                tooltip: '南极目录',
                onPressed: () => context.push('$antBase/contents'),
                icon: const Icon(Icons.grid_view_rounded),
              ),
              IconButton(
                tooltip: '搜索',
                onPressed: () => context.push('/search?q=南极'),
                icon: const Icon(Icons.search),
              ),
            ],
            bottom: page == 'place' || MediaQuery.sizeOf(context).width >= 600
                ? null
                : AntarcticaNavigation(mine: page == 'discoveries'),
            child: page == 'place' ? _PlaceVisit(id: id!, child: body) : body,
          ),
        );
        return MediaQuery.sizeOf(context).width >= 600
            ? AtlasShell(
                location: page == 'discoveries' ? '/me' : '/encyclopedia',
                child: pageView,
              )
            : pageView;
      },
    );
  }

  Widget home(BuildContext c, List<AtlasArticle> articles) {
    final pending =
        articles
            .where(
              (a) =>
                  c.atlas.journal.progress.containsKey(a.id) &&
                  c.atlas.journal.progress[a.id]?['completed'] != 1,
            )
            .toList()
          ..sort(
            (a, b) => (c.atlas.journal.progress[b.id]!['updated_at'] as String)
                .compareTo(
                  c.atlas.journal.progress[a.id]!['updated_at'] as String,
                ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            const MediaPhoto(
              'antarctica-m21',
              height: 260,
              width: double.infinity,
            ),
            Positioned(
              left: 22,
              top: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xb312395b), Color(0x0012395b)],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '南极洲',
                      style: TextStyle(
                        fontSize: 42,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'ANTARCTICA · 自然地理专题',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading('一起读懂冰雪大陆'),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (c, b) => Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final f in [
                      (Icons.landscape, '大陆', '冰下有陆地'),
                      (Icons.location_on, '南极点', '地球最南端'),
                      (Icons.waves, '南大洋', '环绕大陆'),
                    ])
                      SizedBox(
                        width: MediaQuery.textScalerOf(c).scale(16) > 22
                            ? b.maxWidth
                            : (b.maxWidth - 12) / 3,
                        child: fact(f.$1, f.$2, f.$3),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              photoGrid(c, [
                ('冰从哪里来？', 'antarctica-m21', '$antBase/sections/ice'),
                ('谁住在冰海边？', 'antarctica-m04', '$antBase/sections/ocean'),
              ], overlay: true),
              const SizedBox(height: 16),
              action(
                c,
                pending.isEmpty ? '开始探索' : '继续阅读：${pending.first.title}',
                pending.isEmpty
                    ? '$antBase/contents'
                    : '/articles/${pending.first.id}',
              ),
              Center(
                child: TextButton.icon(
                  onPressed: () => c.push('$antBase/map'),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('打开南极地图'),
                ),
              ),
              Wrap(
                spacing: 12,
                children: [
                  TextButton(
                    onPressed: () => c.push('$antBase/explore'),
                    child: const Text('探索任务'),
                  ),
                  TextButton(
                    onPressed: () => c.push('$antBase/timeline'),
                    child: const Text('认识南极的时间线'),
                  ),
                  TextButton(
                    onPressed: () => c.push('/me/regions/antarctica'),
                    child: const Text('我的发现'),
                  ),
                ],
              ),
              SavedButton(kind: 'region', id: 'antarctica', title: '南极洲'),
              TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: c,
                  isScrollControlled: true,
                  builder: (ctx) => SafeArea(
                    child: SizedBox(
                      height: MediaQuery.sizeOf(ctx).height * .8,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          heading('摄影与资料来源'),
                          const Text(
                            '实景图片采用公开许可摄影。地图：SCAR Antarctic Digital Database, 2026 · CC BY 4.0。图解为原创原理示意。',
                          ),
                          for (final m in c.atlas.content.media.values.where(
                            (m) => m.id.startsWith('antarctica-'),
                          ))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: SelectableText(
                                '${m.caption}\n${m.credit} · ${m.license}\n${m.sourceUrl}\n${m.licenseUrl}',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                child: const Text('摄影与资料来源'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget contents(BuildContext c, AtlasRegion r) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading('发现八个主题'),
      const Text('从一块冰，走进一个世界。'),
      const SizedBox(height: 18),
      const AntCollage(),
      const SizedBox(height: 18),
      photoGrid(c, [
        for (final s in r.sections)
          (
            s['title'] as String,
            sectionMedia(s['id']),
            '$antBase/sections/${s['id']}',
          ),
      ], captions: true),
      const SizedBox(height: 20),
      action(c, '打开南极地图', '$antBase/map'),
    ],
  );
  Widget section(BuildContext c, List<AtlasArticle> list) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (list.isNotEmpty)
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: MediaPhoto(
            list.first.mediaId,
            height: 240,
            width: double.infinity,
          ),
        ),
      const SizedBox(height: 20),
      for (final a in list) articleTile(c, a),
      if (id == 'science') const AntDiagram('antarctica-team'),
      const SizedBox(height: 16),
      action(c, '在地图上找线索', '$antBase/map'),
    ],
  );
  Widget timeline(BuildContext c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const MediaPhoto('antarctica-m15', height: 200, width: double.infinity),
      const SizedBox(height: 20),
      const Text('从远行，到共同研究。', style: TextStyle(fontSize: 20)),
      for (final row in [
        ('1911', '抵达地理南极点', '阿蒙森远征队抵达地理南极点。'),
        ('1957—1958', '多国协作观测', '国际地球物理年推动多国观测与资料交流。'),
        ('1959', '签署《南极条约》', '1961年生效。'),
        ('1991', '签署环保议定书', '1998年生效。'),
      ])
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(label: Text(row.$1)),
                Text(
                  row.$2,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(row.$3),
              ],
            ),
          ),
        ),
      const Text('原创资料摘记 · 这里的故事，也有科学家、医生和后勤人员。'),
      action(c, '阅读历史与资料来源', '/articles/antarctica-treaty-history'),
    ],
  );
  Widget journey(BuildContext c, AtlasRegion r) {
    final j = r.journeys.where((j) => j['id'] == id).firstOrNull;
    if (j == null) return const Text('未找到阅读路线。');
    final ids = List<String>.from(j['articleIds']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(j['title']),
        const Text('三站阅读 · 随时可以跳读'),
        const SizedBox(height: 20),
        for (var i = 0; i < ids.length; i++)
          articleTile(
            c,
            c.atlas.content.article(ids[i])!,
            prefix: '0${i + 1}  ',
            progress: true,
          ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text('阅读顺序，不是旅行路线。'),
        ),
        action(
          c,
          ids.any((x) => c.atlas.journal.progress.containsKey(x))
              ? '继续这条路线'
              : '开始第一站',
          '/articles/${ids.firstWhere((x) => c.atlas.journal.progress[x]?['completed'] != 1, orElse: () => ids.first)}',
        ),
      ],
    );
  }

  Widget discoveries(BuildContext c, List<AtlasArticle> articles) {
    final journal = c.atlas.journal;
    final notes = journal.notes
        .where((n) => (n['entity_id'] as String).startsWith('antarctica-'))
        .toList();
    final read = articles
        .where((a) => journal.progress.containsKey(a.id))
        .length;
    final visits = journal.history
        .where(
          (h) =>
              h['kind'] == 'place' &&
              (h['entity_id'] as String).startsWith('antarctica-'),
        )
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MediaPhoto('antarctica-m15', height: 200, width: double.infinity),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            fact(Icons.menu_book, '$read', '读过文章'),
            fact(Icons.place, '$visits', '看过地点'),
            fact(Icons.edit_note, '${notes.length}', '观察记录'),
          ],
        ),
        const SizedBox(height: 30),
        if (notes.isEmpty) ...[
          const Center(
            child: Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: antOrange,
            ),
          ),
          heading('你的第一条发现，从这里开始'),
          photoGrid(c, [
            ('冰雪的秘密', 'antarctica-m02', '$antBase/sections/ice'),
            ('南大洋生命', 'antarctica-m05', '$antBase/sections/ocean'),
          ]),
        ],
        for (final n in notes)
          Card(
            child: ListTile(
              title: Text(n['title']),
              subtitle: Text(
                n['text'],
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => c.push('$antBase/observe/${n['entity_id']}'),
            ),
          ),
        const SizedBox(height: 20),
        action(c, '选择一个问题', '$antBase/explore'),
        TextButton(
          onPressed: () => c.push('/me/notes'),
          child: const Text('查看全部笔记'),
        ),
      ],
    );
  }

  Widget place(BuildContext c) {
    final p = c.atlas.content.place(id ?? '');
    if (p == null) return const Text('未找到地点。');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(p.name),
        Text(p.region),
        const SizedBox(height: 16),
        if (p.mediaIds.isNotEmpty)
          MediaPhoto(p.mediaIds.first, height: 260, width: double.infinity),
        if (p.mediaIds.isNotEmpty)
          Text(
            c.atlas.content.media[p.mediaIds.first]?.caption ?? '',
            style: const TextStyle(fontSize: 12, color: Color(0xff53677d)),
          ),
        const SizedBox(height: 14),
        AntLocator(p),
        const SizedBox(height: 14),
        Text(p.description, style: const TextStyle(fontSize: 18, height: 1.7)),
        const SizedBox(height: 16),
        const Text('地图标记表示代表位置'),
        const SizedBox(height: 16),
        action(c, '在地图上找它', '$antBase/map?place=${p.id}'),
        const SizedBox(height: 12),
        action(c, '记下我的发现', '$antBase/observe/${p.id}'),
        const SizedBox(height: 12),
        SavedButton(kind: 'place', id: p.id, title: p.name),
        for (final a in p.articleIds)
          if (c.atlas.content.article(a) != null)
            articleTile(c, c.atlas.content.article(a)!),
      ],
    );
  }
}

Widget heading(String s) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: Text(
    s,
    style: const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: antNavy,
    ),
  ),
);
Widget fact(IconData icon, String title, String subtitle) => Container(
  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
  decoration: BoxDecoration(
    color: antIce,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Row(
    children: [
      Icon(
        icon,
        color: icon == Icons.location_on ? antOrange : const Color(0xff1285b7),
        size: 22,
      ),
      const SizedBox(width: 5),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(subtitle, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    ],
  ),
);
Widget action(BuildContext c, String text, String route) => SizedBox(
  width: double.infinity,
  child: FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: antOrange,
      foregroundColor: antNavy,
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 15),
    ),
    onPressed: () => c.push(route),
    child: Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
  ),
);
String sectionMedia(String id) =>
    'antarctica-m${({'location': 15, 'ice': 2, 'light': 8, 'ocean': 5, 'animals': 4, 'science': 7, 'station': 6, 'care': 16}[id] ?? 15).toString().padLeft(2, '0')}';
Widget photoGrid(
  BuildContext c,
  List<(String, String, String)> rows, {
  bool captions = false,
  bool overlay = false,
}) => LayoutBuilder(
  builder: (c, b) {
    final one = b.maxWidth < 340 || MediaQuery.textScalerOf(c).scale(16) > 22;
    return Wrap(
      spacing: 12,
      runSpacing: 14,
      children: [
        for (final row in rows)
          SizedBox(
            width: one ? b.maxWidth : (b.maxWidth - 12) / 2,
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => c.push(row.$3),
                child: overlay
                    ? Stack(
                        children: [
                          MediaPhoto(
                            row.$2,
                            height: 150,
                            width: double.infinity,
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    antNavy.withValues(alpha: .85),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            right: 8,
                            bottom: 12,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    row.$1,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const CircleAvatar(
                                  radius: 13,
                                  backgroundColor: antOrange,
                                  child: Icon(
                                    Icons.chevron_right,
                                    size: 22,
                                    color: antNavy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MediaPhoto(
                            row.$2,
                            height: 130,
                            width: double.infinity,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.$1,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (captions)
                                  const Text(
                                    '3篇文章',
                                    style: TextStyle(fontSize: 13),
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
Widget articleTile(
  BuildContext c,
  AtlasArticle a, {
  String prefix = '',
  bool progress = false,
}) => Card(
  clipBehavior: Clip.antiAlias,
  child: InkWell(
    onTap: () => c.push('/articles/${a.id}'),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: MediaPhoto(a.mediaId, width: 92, height: 92),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$prefix${a.title}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  progress
                      ? (c.atlas.journal.progress[a.id]?['completed'] == 1
                            ? '已读'
                            : c.atlas.journal.progress.containsKey(a.id)
                            ? '继续阅读'
                            : '未读')
                      : a.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  ),
);

class AntCollage extends StatelessWidget {
  const AntCollage({super.key});
  @override
  Widget build(BuildContext c) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: const Row(
      children: [
        Expanded(
          child: MediaPhoto(
            'antarctica-m02',
            height: 130,
            width: double.infinity,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: MediaPhoto(
            'antarctica-m04',
            height: 130,
            width: double.infinity,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: MediaPhoto(
            'antarctica-m07',
            height: 130,
            width: double.infinity,
          ),
        ),
      ],
    ),
  );
}

class AntarcticaNavigation extends StatelessWidget {
  const AntarcticaNavigation({super.key, this.mine = false});
  final bool mine;
  @override
  Widget build(BuildContext c) => NavigationBar(
    backgroundColor: Colors.white,
    indicatorColor: antNavy,
    selectedIndex: mine ? 3 : 2,
    onDestinationSelected: (i) =>
        c.go(['/discover', '/atlas', '/encyclopedia', '/me'][i]),
    destinations: const [
      NavigationDestination(icon: Icon(Icons.explore_outlined), label: '发现'),
      NavigationDestination(icon: Icon(Icons.map_outlined), label: '地图'),
      NavigationDestination(
        icon: Icon(Icons.menu_book),
        selectedIcon: Icon(Icons.menu_book, color: Colors.white),
        label: '百科',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person_outline, color: Colors.white),
        label: '我的',
      ),
    ],
  );
}

class AntarcticaTasks extends StatefulWidget {
  const AntarcticaTasks({super.key});
  @override
  State<AntarcticaTasks> createState() => _AntarcticaTasksState();
}

class _AntarcticaTasksState extends State<AntarcticaTasks> {
  String filter = '全部';
  @override
  Widget build(BuildContext c) {
    final r = c.atlas.content.region('antarctica')!;
    final tasks = c.atlas.content.exercises
        .where((e) => e.regionId == 'antarctica')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AntCollage(),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          children: [
            for (final f in ['全部', '找地图', '看关系', '写观察'])
              ChoiceChip(
                label: Text(f),
                selected: filter == f,
                onSelected: (_) => setState(() => filter = f),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (filter != '写观察')
          for (final t in tasks.where(
            (e) =>
                filter == '全部' ||
                (filter == '找地图' ? e.mapScope.isNotEmpty : e.mapScope.isEmpty),
          ))
            Card(
              child: ListTile(
                title: Text(t.question),
                subtitle: Text(
                  c.atlas.journal.attempts.containsKey(t.id)
                      ? '继续查看解释'
                      : t.mapScope.isNotEmpty
                      ? '地图定位'
                      : '阅读与理解',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => c.push('$antBase/tasks/${t.id}'),
              ),
            ),
        if (filter == '全部' || filter == '写观察')
          for (final o in r.observations)
            Card(
              child: ListTile(
                title: Text(o['prompt']),
                subtitle: const Text('开放观察'),
                onTap: () => c.push('$antBase/observe/${o['articleId']}'),
              ),
            ),
        const Text('随时跳过，也能继续阅读。'),
      ],
    );
  }
}

class AntarcticaTask extends StatefulWidget {
  const AntarcticaTask({super.key, required this.id});
  final String id;
  @override
  State<AntarcticaTask> createState() => _AntarcticaTaskState();
}

class _AntarcticaTaskState extends State<AntarcticaTask> {
  String? selected, pickedName;
  bool initialized = false, submitted = false, busy = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      selected = context.atlas.journal.attempts[widget.id]?['answer_id'];
      submitted = selected != null;
      selected ??=
          context.atlas.preferences.values['antarctica-selection-${widget.id}']
              as String?;
      pickedName =
          context.atlas.preferences.values['antarctica-picked-${widget.id}']
              as String?;
    }
  }

  @override
  Widget build(BuildContext c) {
    final e = c.atlas.content.exercise(widget.id);
    if (e == null) {
      return const AtlasPage(title: '探索任务', child: Text('没有找到这道题。'));
    }
    return AtlasPage(
      title: '南极探索任务',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading(e.question),
          if (e.mapScope.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.map_outlined),
                label: Text(pickedName == null ? '在地图上选择地点' : '已选：$pickedName'),
                onPressed: submitted
                    ? null
                    : () async {
                        final content = c.atlas.content;
                        final prefs = c.atlas.preferences;
                        final p = await Navigator.of(c).push<AtlasPlace>(
                          MaterialPageRoute(
                            builder: (ctx) => AntarcticaMapScreen(
                              onPicked: (p) => Navigator.of(ctx).pop(p),
                            ),
                          ),
                        );
                        if (p != null && mounted) {
                          final correct = content.article(e.articleId)?.answer;
                          setState(() {
                            pickedName = p.name;
                            selected = p.id == correct
                                ? e.answerId
                                : 'map-${p.id}';
                            unawaited(
                              prefs.set(
                                'antarctica-selection-${widget.id}',
                                selected,
                              ),
                            );
                            unawaited(
                              prefs.set(
                                'antarctica-picked-${widget.id}',
                                pickedName,
                              ),
                            );
                          });
                        }
                      },
              ),
            ),
          ],
          if (e.mapScope.isEmpty && e.id != 'antarctica-P02')
            MediaPhoto(e.mediaId, height: 180, width: double.infinity),
          const SizedBox(height: 20),
          if (e.id == 'antarctica-P01') const AntDiagram('antarctica-snow'),
          if (e.id == 'antarctica-P03')
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '呼吸资料卡｜鲸是哺乳动物，用肺呼吸，需要到水面与空气交换气体。鱼通常通过鳃从水中获取氧气。\n来源：Australian Antarctic Program · Antarctic animals',
                ),
              ),
            ),
          if (e.id == 'antarctica-P04')
            const Row(
              children: [
                Expanded(child: MediaPhoto('antarctica-m04', height: 130)),
                SizedBox(width: 8),
                Expanded(child: MediaPhoto('antarctica-m18', height: 130)),
              ],
            ),
          if (e.id == 'antarctica-P04') const Text('左：阿德利企鹅　右：帽带企鹅'),
          if (e.id == 'antarctica-P05')
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '比较资料前，先检查：同一地点、相近季节、明确日期、可比较的测量方法。仅凭两张漂亮照片不能判断冰区变化。',
                ),
              ),
            ),
          if (e.id == 'antarctica-P06')
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '时间线资料｜1959：签署《南极条约》；1961：条约生效；1991：签署环境保护议定书；1998：议定书生效。\n来源：南极条约秘书处',
                ),
              ),
            ),
          if (e.mapScope.isEmpty)
            RadioGroup<String>(
              groupValue: selected,
              onChanged: (v) {
                if (!submitted) {
                  setState(() => selected = v);
                  unawaited(
                    c.atlas.preferences.set(
                      'antarctica-selection-${widget.id}',
                      v,
                    ),
                  );
                }
              },
              child: Column(
                children: [
                  for (final o in e.options)
                    Card(
                      color: antIce,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xffdce6ef)),
                      ),
                      child: RadioListTile<String>(
                        value: o['id'],
                        enabled: !submitted,
                        title: e.id == 'antarctica-P02'
                            ? Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      o['text'],
                                      style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: AntIceSample(o['text']),
                                  ),
                                ],
                              )
                            : Text(o['text']),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: selected == null || submitted || busy
                ? null
                : () async {
                    setState(() => busy = true);
                    await atlasAction(c, () async {
                      await c.atlas.journal.answer(
                        e.id,
                        selected!,
                        selected == e.answerId,
                      );
                      if (mounted) setState(() => submitted = true);
                    });
                    if (mounted) setState(() => busy = false);
                  },
            child: Text(busy ? '正在保存…' : '确认选择'),
          ),
          if (submitted) ...[
            heading(selected == e.answerId ? '你找到线索了' : '再看看线索'),
            Text(
              e.explanation,
              style: const TextStyle(fontSize: 18, height: 1.6),
            ),
            TextButton(
              onPressed: () => setState(() {
                submitted = false;
                selected = null;
              }),
              child: const Text('再试一次'),
            ),
          ],
          TextButton(
            onPressed: () => c.push(
              '/articles/${e.articleId}?block=${e.evidenceBlockIds.first}',
            ),
            child: const Text('回到正文找证据'),
          ),
        ],
      ),
    );
  }
}

class AntarcticaObservation extends StatefulWidget {
  const AntarcticaObservation({super.key, required this.id});
  final String id;
  @override
  State<AntarcticaObservation> createState() => _AntarcticaObservationState();
}

class _AntarcticaObservationState extends State<AntarcticaObservation> {
  final fields = List.generate(3, (_) => TextEditingController());
  Timer? timer;
  PreferencesRepository? draftStore;
  bool initialized = false, busy = false;
  String get draft => 'antarctica-draft-${widget.id}';
  String get noteId => 'antarctica-note-${widget.id}';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    draftStore = context.atlas.preferences;
    final j = context.atlas.journal.notes
        .where((n) => n['id'] == noteId)
        .firstOrNull;
    final saved = context.atlas.preferences.values[draft];
    final old =
        context.atlas.preferences.values['region.antarctica.note.${widget.id}'];
    if (saved is List && saved.length == 3) {
      for (var i = 0; i < 3; i++) {
        fields[i].text = saved[i] as String;
      }
    } else if (j != null) {
      final split = (j['text'] as String).split('\n我想到：');
      fields[0].text = split.first.replaceFirst('我看见：', '');
      fields[1].text = split.length > 1 ? split[1] : '';
      fields[2].text = j['question'];
    } else if (old is String) {
      fields[0].text = old;
    }
    for (final f in fields) {
      f.addListener(change);
    }
  }

  void change() {
    setState(() {});
    final values = fields.map((f) => f.text).toList();
    unawaited(draftStore!.set(draft, values).catchError((Object _) {}));
  }

  @override
  void dispose() {
    timer?.cancel();
    for (final f in fields) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    setState(() => busy = true);
    final services = context.atlas;
    final values = fields.map((f) => f.text.trim()).toList();
    var saved = false;
    await atlasAction(context, () async {
      final a = services.content.article(widget.id);
      final p = services.content.place(widget.id);
      await services.journal.saveNote(
        id: noteId,
        kind: p == null ? 'article' : 'place',
        text: '我看见：${values[0]}\n我想到：${values[1]}',
        question: values[2],
        entityId: widget.id,
        title: a?.title ?? p?.name ?? '南极观察',
      );
      await services.preferences.set(draft, values);
      saved = true;
    }, success: '观察已保存，可在“我的南极发现”中查看');
    if (mounted) {
      setState(() => busy = false);
      if (saved) context.pushReplacement('/me/regions/antarctica');
    }
  }

  @override
  Widget build(BuildContext c) {
    final a = c.atlas.content.article(widget.id);
    final p = c.atlas.content.place(widget.id);
    final media = a?.mediaId ?? p?.mediaIds.firstOrNull ?? 'antarctica-m16';
    return AtlasPage(
      title: '记下发现',
      liftBottomForKeyboard: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading('我看见了什么？'),
          if (a?.activity['prompt'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                a!.activity['prompt'],
                style: const TextStyle(
                  color: antNavy,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          MediaPhoto(media, height: 220, width: double.infinity),
          TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: c,
              builder: (_) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '${c.atlas.content.media[media]?.caption ?? ''}\n${c.atlas.content.media[media]?.credit ?? ''}\n${c.atlas.content.media[media]?.license ?? ''}\n${c.atlas.content.media[media]?.sourceUrl ?? ''}',
                  ),
                ),
              ),
            ),
            child: const Text('查看图片说明与来源'),
          ),
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TextField(
                controller: fields[i],
                minLines: 3,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: ['我看见…', '我想到…', '我还想知道…'][i],
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          const Text('至少写下一项，就能保存。'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy || fields.every((f) => f.text.trim().isEmpty)
                  ? null
                  : save,
              child: Text(busy ? '正在保存…' : '保存观察'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceVisit extends StatefulWidget {
  const _PlaceVisit({required this.id, required this.child});
  final String id;
  final Widget child;
  @override
  State<_PlaceVisit> createState() => _PlaceVisitState();
}

class _PlaceVisitState extends State<_PlaceVisit> {
  bool recorded = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (recorded) return;
    recorded = true;
    final services = context.atlas;
    final p = services.content.place(widget.id);
    if (p != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(services.journal.visit('place', p.id, p.name));
      });
    }
  }

  @override
  Widget build(BuildContext c) => widget.child;
}
