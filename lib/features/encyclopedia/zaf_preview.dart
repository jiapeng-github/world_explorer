import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../map_engine/atlas_map.dart';

const _penguinSource =
    'https://www.sanparks.org/wp-content/uploads/2024/02/boulders-brochure.pdf';
const _capeSource = 'https://www.sanparks.org/parks/Agulhas';
const _sections = [
  ('国家名片', Icons.flag_outlined, 'coast', 'facts'),
  ('地理与气候', Icons.terrain_outlined, 'coast', 'cape'),
  ('人们与语言', Icons.people_outline, 'city', ''),
  ('日常生活', Icons.home_outlined, 'city', 'daily'),
  ('饮食与物产', Icons.restaurant_outlined, 'city', ''),
  ('艺术与活动', Icons.palette_outlined, 'city', ''),
  ('城市与地标', Icons.location_city, 'coast', 'map'),
  ('动物与生态', Icons.pets_outlined, 'penguins', 'penguins'),
  ('历史故事', Icons.history_edu, 'city', ''),
  ('有趣问题', Icons.help_outline, 'penguins', 'cape'),
];
void _open(BuildContext c, String page) => c.push('/preview/zaf?page=$page');

class SouthAfricaPreview extends StatelessWidget {
  const SouthAfricaPreview({super.key, this.page = 'home'});
  final String page;
  @override
  Widget build(BuildContext context) {
    if (page == 'note') return const _Note();
    if (page == 'map') return const _MapPage();
    if (page == 'penguins' || page == 'cape') {
      return _Reader(cape: page == 'cape');
    }
    return AtlasPage(
      title: '世界大百科',
      width: 780,
      background: AtlasPalette.canvas,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      actions: [
        IconButton(
          tooltip: '南非探索目录',
          onPressed: () => _open(context, 'contents'),
          icon: const Icon(Icons.menu),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (page == 'home') ...[
            _Cover(
              'coast',
              title: '南非',
              subtitle: 'SOUTH AFRICA\n从海岸走向高原',
              height: 265,
            ),
            _panel(
              children: [
                _heading('先认识南非'),
                const Text(
                  '沿着非洲南端的海岸，认识山地、城市与多样生活。',
                  style: TextStyle(fontSize: 17, height: 1.7),
                ),
                const SizedBox(height: 8),
                const Wrap(
                  spacing: 6,
                  children: [
                    Chip(label: Text('非洲南端')),
                    Chip(label: Text('多样地形')),
                    Chip(label: Text('多种语言')),
                  ],
                ),
              ],
            ),
            _heading('走进南非的三条探索路线'),
            LayoutBuilder(
              builder: (ctx, b) {
                final single =
                    MediaQuery.textScalerOf(ctx).scale(1) > 1.2 ||
                    b.maxWidth < 330;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (image, title, target) in [
                      ('penguins', '海岸与生命', 'penguins'),
                      ('coast', '山地与海角', 'cape'),
                      ('city', '城市与生活', 'daily'),
                    ])
                      SizedBox(
                        width: single ? b.maxWidth : (b.maxWidth - 16) / 3,
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            onTap: () => _open(ctx, target),
                            child: Column(
                              children: [
                                _Photo(image, height: 95),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
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
            const SizedBox(height: 12),
            _link(context, '企鹅一定生活在冰雪里吗？', Icons.waves, 'penguins'),
            _link(context, '好望角是非洲最南端吗？', Icons.public, 'cape'),
            PrimaryAction(
              '从海岸开始',
              orange: true,
              onPressed: () => _open(context, 'penguins'),
            ),
            TextButton(
              onPressed: () => _open(context, 'contents'),
              child: const Text('打开全部栏目'),
            ),
          ] else if (page == 'contents') ...[
            _heading('南非 · 探索目录'),
            const Text('带着问题去探索'),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: _Photo('coast', height: 120)),
                SizedBox(width: 4),
                Expanded(child: _Photo('penguins', height: 120)),
                SizedBox(width: 4),
                Expanded(child: _Photo('city', height: 120)),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (ctx, b) {
                final single =
                    b.maxWidth < 330 ||
                    MediaQuery.textScalerOf(ctx).scale(1) > 1.2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final (title, icon, _, target) in _sections)
                      SizedBox(
                        width: single ? b.maxWidth : (b.maxWidth - 10) / 2,
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: target.isEmpty
                                ? null
                                : () => _open(ctx, target),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(
                                    icon,
                                    size: 22,
                                    color: AtlasPalette.navy,
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (target.isEmpty)
                                          const Text(
                                            '即将上线',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AtlasPalette.muted,
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
            ),
            const SizedBox(height: 20),
            PrimaryAction('打开南非地图', onPressed: () => _open(context, 'map')),
          ] else if (page == 'facts') ...[
            _heading('先认识南非'),
            const _Photo('coast', height: 230),
            _panel(
              children: [
                const Text(
                  '南非位于非洲大陆南端。南非是一个国家，“南部非洲”则指更大的区域，两者范围不同。',
                  style: TextStyle(fontSize: 18, height: 1.7),
                ),
                const SizedBox(height: 14),
                const Text(
                  '南非有12种官方语言，包括南非手语。官方语言的数量并不表示每个人都会说全部语言。',
                  style: TextStyle(fontSize: 18, height: 1.7),
                ),
                const SelectableText(
                  '资料：南非政府\nhttps://www.gov.za/about-sa/south-africa-glance',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            _link(context, '到地图上认识国家范围', Icons.map, 'map'),
          ] else ...[
            _heading('南非 · 城市里的一天'),
            const Text('从具体场景认识生活'),
            const SizedBox(height: 10),
            const _Photo('city', height: 230),
            _panel(
              children: [
                const Text(
                  '约翰内斯堡的城市天际线',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text(
                  '照片让我们看见建筑与街道，却不能讲完每位居民的一天。观察时，把看见的设施与对生活的猜想分开。',
                  style: TextStyle(fontSize: 17, height: 1.7),
                ),
              ],
            ),
            for (final (title, body) in [
              ('上学的路', '图中能看到道路，但不能凭照片知道每个孩子怎样上学。'),
              ('市场里的标签', '售卖地点不等于生产地点；判断产地需要看具体标签。'),
              ('公共空间', '哪些空间可以让人共同使用？实际体验还需要听使用者讲述。'),
            ])
              _panel(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(body, style: const TextStyle(fontSize: 16, height: 1.7)),
                ],
              ),
            PrimaryAction(
              '写下一次观察',
              orange: true,
              onPressed: () =>
                  context.push('/preview/zaf?page=note&material=city'),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            '南非内容预览 · 未开放栏目仍在制作',
            style: TextStyle(fontSize: 12, color: AtlasPalette.muted),
          ),
        ],
      ),
    );
  }
}

Widget _heading(String s) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 10),
  child: Text(
    s,
    style: const TextStyle(
      fontSize: 25,
      fontWeight: FontWeight.w800,
      color: AtlasPalette.navy,
    ),
  ),
);
Widget _panel({required List<Widget> children}) => Container(
  margin: const EdgeInsets.symmetric(vertical: 10),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  ),
);
Widget _link(BuildContext c, String title, IconData icon, String page) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xffeaf1f8),
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: Icon(icon, color: AtlasPalette.navy),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(c, page),
        ),
      ),
    );

class _Photo extends StatelessWidget {
  const _Photo(this.id, {required this.height});
  final String id;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Stack(
      children: [
        Image.asset(
          'assets/atlas/zaf-$id.jpg',
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            height: height,
            color: AtlasPalette.sea,
            alignment: Alignment.center,
            child: const Text('照片正在准备'),
          ),
        ),
        Positioned(
          right: 4,
          bottom: 4,
          child: IconButton.filledTonal(
            tooltip: '照片来源',
            icon: const Icon(Icons.info_outline, size: 18),
            onPressed: () => _credits(context, id),
          ),
        ),
      ],
    ),
  );
}

Future<void> _credits(BuildContext c, String id) async {
  try {
    final j = jsonDecode(
      await rootBundle.loadString('assets/atlas/zaf-preview-media.json'),
    ) as Map<String, dynamic>;
    final m = j[id] as Map<String, dynamic>;
    if (!c.mounted) return;
    showModalBottomSheet<void>(
      context: c,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: SelectableText(
            '${m['title']}\n${m['author']}\n${m['license']}\n${m['source']}\n${m['licenseUrl']}\n拍摄日期：${m['date']}\n${m['processing']}',
          ),
        ),
      ),
    );
  } catch (_) {
    if (c.mounted) showMessage(c, '图片资料暂时不可用。');
  }
}

class _Cover extends StatelessWidget {
  const _Cover(
    this.id, {
    required this.title,
    required this.subtitle,
    required this.height,
  });
  final String id, title, subtitle;
  final double height;
  @override
  Widget build(BuildContext c) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Stack(
      children: [
        _Photo(id, height: height),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xd012395b)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 43,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 19, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Reader extends StatefulWidget {
  const _Reader({required this.cape});
  final bool cape;
  @override
  State<_Reader> createState() => _ReaderState();
}

class _ReaderState extends State<_Reader> {
  String? answer;
  bool submitted = false, busy = false;
  @override
  Widget build(BuildContext c) {
    final cape = widget.cape;
    final title = cape ? '好望角是非洲最南端吗？' : '企鹅一定生活在冰雪里吗？';
    final correct = cape ? '厄加勒斯角' : '海里';
    return AtlasPage(
      title: title,
      width: 720,
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: PrimaryAction(
            '记下我的发现',
            orange: true,
            onPressed: () => _open(c, 'note'),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Photo(cape ? 'coast' : 'penguins', height: 250),
          _heading(cape ? '先找到两个不同的海角' : '海边也有企鹅的家'),
          for (final (heading, body)
              in cape
                  ? [
                      (
                        '名称相似，位置不同',
                        '好望角位于开普半岛，是著名海角。非洲大陆最南端则是更东边的厄加勒斯角。找地点时，名称、方位和海岸形状要放在一起核对。',
                      ),
                      (
                        '分界不是海上的彩线',
                        '厄加勒斯角被作为大西洋与印度洋的地理分界地点。真实海水会流动混合，不会永远出现一条两色分界线。照片里的颜色差异不能独自证明海洋边界。',
                      ),
                      (
                        '用地图查证',
                        '在地图上比较两处坐标，越靠南的位置纬度越小。不要因为一个海角更加著名，就把它当成大陆最南端。',
                      ),
                    ]
                  : [
                      (
                        '先看环境',
                        '博尔德斯海岸可以看到非洲企鹅。这里有沙滩、花岗岩和海水，不是冰雪覆盖的南极。企鹅有不同种类，不能把一种企鹅的环境套用到所有企鹅身上。',
                      ),
                      (
                        '海中寻找食物',
                        '非洲企鹅在海里捕食鱼类，也会回到陆地休息和繁殖。照片中的站立姿态只能说明当时看见的动作，觅食习性还需要结合研究资料。',
                      ),
                      (
                        '两个空间连在一起',
                        '海洋提供食物，海岸提供上岸活动的地方。理解动物时，要同时看它使用的不同环境，而不是只记住外表。',
                      ),
                      (
                        '远一点观察',
                        '公开步道能帮助人们观察企鹅，同时减少打扰。我们不提供巢穴位置，也不需要靠近、触摸或追逐动物。照片与资料同样能帮助提出有价值的问题。',
                      ),
                    ])
            _panel(
              children: [
                Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(body, style: const TextStyle(fontSize: 18, height: 1.75)),
              ],
            ),
          if (!cape)
            _panel(
              children: [
                const Text(
                  '生活空间 · 原创关系示意',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Wrap(
                  spacing: 12,
                  children: [
                    Chip(
                      avatar: Icon(Icons.landscape),
                      label: Text('陆地：休息、繁殖'),
                    ),
                    Chip(avatar: Icon(Icons.water), label: Text('海洋：寻找食物')),
                  ],
                ),
                const Text(
                  '这表示生活关系，不是迁移路线或比例地图。',
                  style: TextStyle(fontSize: 13, color: AtlasPalette.muted),
                ),
              ],
            ),
          _heading(cape ? '非洲大陆最南端在哪里？' : '企鹅在哪里寻找鱼类？'),
          Wrap(
            spacing: 10,
            children: [
              for (final option in cape ? ['好望角', '厄加勒斯角'] : ['海里', '沙滩上'])
                ChoiceChip(
                  label: Text(option),
                  selected: answer == option,
                  onSelected: submitted
                      ? null
                      : (_) => setState(() => answer = option),
                ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryAction(
            busy
                ? '正在保存…'
                : submitted
                ? '重新想一想'
                : '确认',
            onPressed: busy || answer == null
                ? null
                : () async {
                    if (submitted) {
                      setState(() {
                        submitted = false;
                        answer = null;
                      });
                      return;
                    }
                    setState(() => busy = true);
                    await atlasAction(c, () async {
                      await c.atlas.preferences.set(
                        'zaf-preview-answer-${cape ? 'cape' : 'penguins'}',
                        {'answer': answer, 'correct': answer == correct},
                      );
                      if (mounted) setState(() => submitted = true);
                    });
                    if (mounted) setState(() => busy = false);
                  },
          ),
          if (submitted)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                answer == correct
                    ? '找到证据了！${cape ? '最南端是厄加勒斯角。' : '企鹅在海里寻找鱼类。'}'
                    : '再读一读上方正文，找到与问题对应的证据。',
              ),
            ),
          TextButton.icon(
            onPressed: () => _open(c, 'map'),
            icon: const Icon(Icons.map_outlined),
            label: const Text('在地图上看看'),
          ),
          SelectableText(
            '资料来源：SANParks\n${cape ? _capeSource : _penguinSource}',
            style: const TextStyle(fontSize: 12, color: AtlasPalette.muted),
          ),
        ],
      ),
    );
  }
}

class _MapPage extends StatefulWidget {
  const _MapPage();
  @override
  State<_MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<_MapPage> {
  String layer = '国家';
  String selected = 'zaf';
  @override
  Widget build(BuildContext c) {
    final content = c.atlas.content;
    return AtlasPage(
      title: '南非探索地图',
      scroll: false,
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final l in ['国家', '地形', '河流'])
                ChoiceChip(
                  label: Text(l),
                  selected: layer == l,
                  onSelected: (_) => setState(() => layer = l),
                ),
            ],
          ),
          Expanded(
            child: AtlasMap(
              countries: content.countries,
              initialCountry: content.country('zaf'),
              selectedId: selected,
              layer: layer,
              onCountry: (id) => setState(() => selected = id),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  content.country(selected)?.name ?? '南非',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '莱索托是独立国家。此页使用现有世界底图；国家专属地形与地点图层仍待接入。',
                  style: TextStyle(fontSize: 14),
                ),
                TextButton(
                  onPressed: () => _open(c, 'cape'),
                  child: const Text('认识好望角与厄加勒斯角'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatefulWidget {
  const _Note();
  @override
  State<_Note> createState() => _NoteState();
}

class _NoteState extends State<_Note> {
  final fields = List.generate(3, (_) => TextEditingController());
  bool ready = false, busy = false;
  late String material;
  Future<void> pending = Future.value();
  String get key => 'zaf-preview-draft-$material';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ready) return;
    material =
        GoRouterState.of(context).uri.queryParameters['material'] == 'city'
        ? 'city'
        : 'penguins';
    final draft = context.atlas.preferences.values[key];
    if (draft is List) {
      for (var i = 0; i < 3 && i < draft.length; i++) {
        fields[i].text = draft[i] as String;
      }
    }
    ready = true;
  }

  void changed() {
    setState(() {});
    final values = fields.map((f) => f.text).toList();
    final prefs = context.atlas.preferences;
    pending = pending
        .catchError((Object _) {})
        .then((_) => prefs.set(key, values));
  }

  @override
  void dispose() {
    for (final f in fields) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => AtlasPage(
    title: '我的观察笔记',
    width: 720,
    liftBottomForKeyboard: true,
    bottom: Padding(
      padding: const EdgeInsets.all(16),
      child: PrimaryAction(
        busy ? '正在保存…' : '保存我的发现',
        orange: true,
        onPressed: busy || fields.every((f) => f.text.trim().isEmpty)
            ? null
            : () async {
                setState(() => busy = true);
                await atlasAction(c, () async {
                  await pending;
                  if (!c.mounted) return;
                  await c.atlas.journal.saveNote(
                    id: 'zaf-preview-$material',
                    kind: 'discovery',
                    text: [
                      if (fields[0].text.trim().isNotEmpty)
                        '我看见：${fields[0].text.trim()}',
                      if (fields[1].text.trim().isNotEmpty)
                        '我猜想：${fields[1].text.trim()}',
                    ].join('\n'),
                    question: fields[2].text,
                    entityId: 'zaf-preview-$material',
                    title: '南非 · ${material == 'city' ? '城市观察' : '企鹅海岸'}',
                  );
                }, success: '发现已保存在本机');
                if (mounted) setState(() => busy = false);
              },
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Photo(material, height: 220),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextField(
              controller: fields[i],
              onChanged: (_) => changed(),
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: ['我看见', '我猜想', '我还想知道'][i],
                hintText: ['描述直接看见的细节', '写一个需要验证的解释', '留下你自己的问题'][i],
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        const Text('草稿自动保存在本机。', style: TextStyle(color: AtlasPalette.muted)),
      ],
    ),
  );
}
