import 'package:flutter/material.dart';

import '../core/explorer_store.dart';
import '../core/narration.dart';
import '../core/palette.dart';
import '../models/catalog.dart';
import '../widgets/atlas_widgets.dart';
import '../widgets/world_map.dart';
import 'learning_screens.dart';
import 'world_screens.dart' show MapScreen, topicIcon, showSources;

class CountryPhotoView extends StatelessWidget {
  const CountryPhotoView({
    super.key,
    required this.country,
    this.height = 300,
    this.overlay,
  });
  final Country country;
  final double height;
  final Widget? overlay;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(26),
    child: SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            country.profile.photo.asset,
            fit: BoxFit.cover,
            semanticLabel: country.profile.photo.caption,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: AtlasColors.sand,
              child: Center(
                child: Icon(
                  Icons.landscape,
                  size: 70,
                  color: AtlasColors.forest,
                ),
              ),
            ),
          ),
          if (overlay != null)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00152C27), Color(0xCF152C27)],
                ),
              ),
            ),
          ?overlay,
          if (overlay == null)
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xB8173F3D),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  country.profile.photo.caption,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ),
          Positioned(
            top: 12,
            right: 12,
            child: Tooltip(
              message: '照片来源与许可',
              child: Material(
                color: Colors.white.withValues(alpha: .9),
                borderRadius: BorderRadius.circular(30),
                child: InkWell(
                  onTap: () => showPhotoCredit(context, country.profile.photo),
                  borderRadius: BorderRadius.circular(30),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_camera_outlined, size: 14),
                        SizedBox(width: 5),
                        Text('实景 · 署名', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void showPhotoCredit(BuildContext context, CountryPhoto photo) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(photo.caption),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('摄影 / 编辑：${photo.credit}'),
              const SizedBox(height: 12),
              Text(photo.license),
              SelectableText(photo.licenseUrl),
              const SizedBox(height: 12),
              SelectableText(photo.sourceUrl),
              const SizedBox(height: 12),
              const Text(
                '图片已缩放，界面按比例裁切显示。照片仍遵循原许可。',
                style: TextStyle(fontSize: 13, color: AtlasColors.muted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );

class CountryScreen extends StatefulWidget {
  const CountryScreen({super.key, required this.country});
  final Country country;
  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  int section = 0;
  final scroll = ScrollController();
  final sectionAnchor = GlobalKey();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final country = widget.country;
    final store = ExplorerScope.of(context);
    final read = country.topics
        .where((t) => store.readTopics.contains('${country.id}/${t.id}'))
        .length;
    return ExplorerPage(
      title: '${country.name} · 国家百科',
      subtitle: '${country.continent} / ${country.englishName}',
      actions: [
        IconButton(
          tooltip: store.favorites.contains(country.id) ? '取消收藏' : '收藏国家',
          onPressed: () => store.toggleFavorite(country.id),
          icon: Icon(
            store.favorites.contains(country.id)
                ? Icons.bookmark
                : Icons.bookmark_border,
          ),
        ),
      ],
      child: ListView(
        controller: scroll,
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
        ),
        children: [
          CountryPhotoView(
            country: country,
            height: MediaQuery.sizeOf(context).width < 600 ? 310 : 365,
            overlay: Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${country.flagEmoji}  ${country.englishName.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    country.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    country.profile.tagline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    country.profile.photo.caption,
                    style: const TextStyle(
                      color: Color(0xFFDDE9DC),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            key: sectionAnchor,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      key: ValueKey('country-tab-$i'),
                      label: Text(
                        ['国家概览', '百科阅读 · $read/6', '地标与风景', '历史时间线'][i],
                      ),
                      selected: section == i,
                      onSelected: (_) => setState(() => section = i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (section == 0) ...[
            _Introduction(country: country),
            const SectionHeading('一眼认识这个国家', subtitle: '从位置、语言和生活线索开始'),
            LayoutBuilder(
              builder: (context, c) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final fact in country.facts)
                    SizedBox(
                      width:
                          (c.maxWidth - (c.maxWidth > 800 ? 36 : 12)) /
                          (c.maxWidth > 800 ? 4 : 2),
                      child: AtlasCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fact.label,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AtlasColors.muted,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              fact.value,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SectionHeading('先带走三个发现'),
            AtlasCard(
              color: AtlasColors.mint,
              child: Column(
                children: [
                  for (var i = 0; i < country.profile.takeaways.length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: i == 2 ? 0 : 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.white,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AtlasColors.forest,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              country.profile.takeaways[i],
                              style: const TextStyle(height: 1.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SectionHeading(
              '不止认识名字，更要读懂一个地方',
              subtitle: '六篇分节介绍 · 词语解释 · 思考小问题',
            ),
            _ChapterGrid(country: country),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  key: const ValueKey('start-country-story'),
                  onPressed: () =>
                      openScreen(context, StoryScreen(country: country)),
                  icon: const Icon(Icons.auto_stories_outlined),
                  label: const Text('读故事，做探索任务'),
                ),
                OutlinedButton.icon(
                  onPressed: () => openScreen(
                    context,
                    MapScreen(initialCountryId: country.id),
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('在地图中探索'),
                ),
              ],
            ),
          ],
          if (section == 1) ...[
            Text(
              '从一个问题开始，把世界看得更仔细。',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              '每篇有三个小节。读完可以留下阅读足迹，稍后继续。',
              style: TextStyle(color: AtlasColors.muted),
            ),
            const SizedBox(height: 20),
            _ChapterGrid(country: country),
          ],
          if (section == 2) ...[
            const Text(
              '让风景与地图上的位置连起来。',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              '每一站都有介绍、观察问题和地图位置。',
              style: TextStyle(color: AtlasColors.muted),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < country.landmarks.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: LandmarkCard(
                  country: country,
                  landmark: country.landmarks[i],
                  index: i,
                ),
              ),
          ],
          if (section == 3) ...[
            const Text(
              '把不同年代，放回时间里',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              '几个观察窗口，帮助理解过去与今天的联系。',
              style: TextStyle(color: AtlasColors.muted),
            ),
            const SizedBox(height: 24),
            for (final event in country.profile.timeline)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AtlasColors.forest,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Container(width: 2, color: AtlasColors.line),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: AtlasCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AtlasTag(event.period, color: AtlasColors.sand),
                              const SizedBox(height: 12),
                              Text(
                                event.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                event.body,
                                style: const TextStyle(height: 1.8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => showSources(context, country),
            icon: const Icon(Icons.fact_check_outlined, size: 18),
            label: Text('参考资料 · ${country.sources.length} 项来源'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Introduction extends StatelessWidget {
  const _Introduction({required this.country});
  final Country country;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '你好，${country.name}',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      Text(
        country.profile.localName,
        style: const TextStyle(color: AtlasColors.muted, fontSize: 14),
      ),
      const SizedBox(height: 14),
      Text(country.profile.intro, style: Theme.of(context).textTheme.bodyLarge),
    ],
  );
}

class _ChapterGrid extends StatelessWidget {
  const _ChapterGrid({required this.country});
  final Country country;
  @override
  Widget build(BuildContext context) {
    final store = ExplorerScope.of(context);
    return LayoutBuilder(
      builder: (context, c) => Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (var i = 0; i < country.topics.length; i++)
            SizedBox(
              width: c.maxWidth > 800
                  ? (c.maxWidth - 28) / 3
                  : c.maxWidth > 550
                  ? (c.maxWidth - 14) / 2
                  : c.maxWidth,
              child: AtlasCard(
                key: ValueKey('chapter-${country.topics[i].id}'),
                onTap: () => openScreen(
                  context,
                  TopicScreen(country: country, topic: country.topics[i]),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: i.isEven
                                ? AtlasColors.mint
                                : AtlasColors.sand.withValues(alpha: .5),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            topicIcon(country.topics[i].id),
                            color: AtlasColors.forest,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '0${i + 1}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AtlasColors.line,
                          ),
                        ),
                        if (store.readTopics.contains(
                          '${country.id}/${country.topics[i].id}',
                        ))
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.check_circle,
                              size: 19,
                              color: AtlasColors.forest,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      country.topics[i].title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      country.topics[i].summary,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AtlasColors.muted,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          '3 个小节 · 约 2 分钟',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AtlasColors.muted,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: AtlasColors.forest,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TopicScreen extends StatefulWidget {
  const TopicScreen({super.key, required this.country, required this.topic});
  final Country country;
  final CountryTopic topic;
  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  final narration = Narration();
  final anchors = List.generate(3, (_) => GlobalKey());
  final scroll = ScrollController();
  @override
  void dispose() {
    narration.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.country,
        t = widget.topic,
        store = ExplorerScope.of(context);
    final read = store.readTopics.contains('${c.id}/${t.id}');
    final next = (c.topics.indexOf(t) + 1) % c.topics.length;
    return ExplorerPage(
      title: '${c.name} · ${t.title}',
      actions: [
        IconButton(
          tooltip: '知识来源',
          onPressed: () => showSources(context, c),
          icon: const Icon(Icons.fact_check_outlined),
        ),
      ],
      child: ListView(
        controller: scroll,
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 20 : 32,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AtlasTag(t.title, icon: topicIcon(t.id)),
                      const AtlasTag('3 个小节 · 约 2 分钟', color: AtlasColors.sand),
                      if (read) const AtlasTag('已读过', icon: Icons.check),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    t.summary,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 20),
                  ListenableBuilder(
                    listenable: narration,
                    builder: (context, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: !store.voiceEnabled
                              ? null
                              : () => narration.speaking
                                    ? narration.stop()
                                    : narration.speak(
                                        '${t.summary}。${t.body}',
                                        rate: store.speechRate,
                                      ),
                          icon: Icon(
                            narration.speaking
                                ? Icons.stop_circle_outlined
                                : Icons.volume_up_outlined,
                          ),
                          label: Text(
                            !store.voiceEnabled
                                ? '朗读已关闭'
                                : narration.speaking
                                ? '停止朗读'
                                : '听这篇百科',
                          ),
                        ),
                        if (narration.error != null)
                          Text(
                            narration.error!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AtlasColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AtlasCard(
                    color: AtlasColors.mint,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '这一篇，我们会发现',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        for (var i = 0; i < t.sections.length; i++)
                          TextButton(
                            onPressed: () {
                              final target = anchors[i].currentContext;
                              if (target != null) {
                                Scrollable.ensureVisible(
                                  target,
                                  duration: const Duration(milliseconds: 400),
                                  alignment: .05,
                                );
                              }
                            },
                            child: Text('${i + 1}. ${t.sections[i].title}'),
                          ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < t.sections.length; i++)
                    Padding(
                      key: anchors[i],
                      padding: const EdgeInsets.only(top: 34),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '0${i + 1}   ${t.sections[i].title}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            t.sections[i].body,
                            style: const TextStyle(
                              fontSize: 19,
                              height: 1.95,
                              color: AtlasColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 30),
                  AtlasCard(
                    color: AtlasColors.sand.withValues(alpha: .45),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '词语小卡 · ${t.term}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(t.definition, style: const TextStyle(height: 1.8)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AtlasCard(
                    padding: EdgeInsets.zero,
                    child: ExpansionTile(
                      key: const ValueKey('topic-question'),
                      tilePadding: const EdgeInsets.all(20),
                      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      title: Text(
                        '想一想\n${t.question}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.7,
                        ),
                      ),
                      subtitle: const Text(
                        '先说说你的想法，再展开看看',
                        style: TextStyle(
                          fontSize: 12,
                          color: AtlasColors.muted,
                        ),
                      ),
                      children: [
                        Text(t.answer, style: const TextStyle(height: 1.8)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        key: const ValueKey('mark-topic-read'),
                        onPressed: () async {
                          await store.markTopicRead(c.id, t.id);
                          if (context.mounted) {
                            showNotice(context, '这篇百科已记入阅读足迹');
                          }
                        },
                        icon: Icon(read ? Icons.check_circle : Icons.done),
                        label: Text(read ? '已留下阅读足迹' : '读完了，留下足迹'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          narration.stop();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => TopicScreen(
                                country: c,
                                topic: c.topics[next],
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: Text('下一篇 · ${c.topics[next].title}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LandmarkCard extends StatelessWidget {
  const LandmarkCard({
    super.key,
    required this.country,
    required this.landmark,
    required this.index,
  });
  final Country country;
  final Landmark landmark;
  final int index;
  @override
  Widget build(BuildContext context) => AtlasCard(
    onTap: () => openScreen(
      context,
      LandmarkScreen(country: country, landmark: landmark),
    ),
    padding: const EdgeInsets.all(20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 60,
          decoration: BoxDecoration(
            color: AtlasColors.mint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '0${index + 1}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AtlasColors.forest,
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                landmark.category,
                style: const TextStyle(fontSize: 12, color: AtlasColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                landmark.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                landmark.teaser,
                style: const TextStyle(height: 1.7, fontSize: 15),
              ),
              const SizedBox(height: 12),
              const Text(
                '认识这处地标 →',
                style: TextStyle(
                  color: AtlasColors.forest,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class LandmarkScreen extends StatelessWidget {
  const LandmarkScreen({
    super.key,
    required this.country,
    required this.landmark,
  });
  final Country country;
  final Landmark landmark;
  @override
  Widget build(BuildContext context) => ExplorerPage(
    title: landmark.name,
    subtitle: '${country.name} · ${landmark.category}',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (landmark.photoAsset != null)
          CountryPhotoView(country: country, height: 300),
        const SizedBox(height: 20),
        Text(
          landmark.teaser,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        Text(
          landmark.description,
          style: const TextStyle(fontSize: 19, height: 1.9),
        ),
        const SectionHeading('它在这里', subtitle: '参考点帮助找位置；自然区域的范围比圆点更大'),
        WorldMap(
          countries: [country],
          height: 330,
          focus: MapFocus(landmark.latitude, landmark.longitude, 4),
          landmarks: [landmark],
          showLandmarks: true,
          selectedLandmarkId: landmark.id,
        ),
        const SizedBox(height: 20),
        AtlasCard(
          color: AtlasColors.mint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '小小观察员',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(landmark.observation, style: const TextStyle(height: 1.8)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => openScreen(
            context,
            MapScreen(
              initialCountryId: country.id,
              initialLandmarkId: landmark.id,
            ),
          ),
          icon: const Icon(Icons.explore_outlined),
          label: const Text('回到地图，看看附近的地标'),
        ),
        const SizedBox(height: 20),
        SelectableText(
          '资料来源：${landmark.sourceUrl}',
          style: const TextStyle(fontSize: 12, color: AtlasColors.muted),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}
