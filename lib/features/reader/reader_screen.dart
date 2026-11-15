import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../domain/atlas_content.dart';
import 'learning_diagrams.dart';
import 'kenya_evidence_card.dart';
import 'norway_evidence_card.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen(this.id, {super.key, this.block});
  final String id;
  final String? block;
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final scroll = ScrollController();
  final keys = <String, GlobalKey>{};
  Timer? debounce;
  AtlasServices? services;
  AtlasArticle? article;
  late final TapGestureRecognizer termTap = TapGestureRecognizer()
    ..onTap = glossary;
  bool initialized = false;
  double fraction = 0;
  String activeBlock = '';
  String? highlightedBlock;
  @override
  void initState() {
    super.initState();
    scroll.addListener(track);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    services = context.atlas;
    article = services!.content.article(widget.id);
    final a = article;
    if (a == null) return;
    for (final b in a.blocks) {
      keys[b.id] = GlobalKey();
    }
    final saved = services!.journal.progress[a.id];
    final requestedBlock = widget.block ?? saved?['block_id'];
    activeBlock = a.blocks.any((b) => b.id == requestedBlock)
        ? requestedBlock as String
        : a.blocks.first.id;
    if (widget.block == activeBlock) highlightedBlock = activeBlock;
    fraction = (saved?['fraction'] as num?)?.toDouble() ?? 0;
    atlasAction(
      context,
      () => services!.journal.visit('article', a.id, a.title),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (widget.block != null || saved != null)) {
        goTo(activeBlock, animate: false);
      }
    });
  }

  void track() {
    if (!scroll.hasClients || article == null) return;
    fraction = scroll.position.maxScrollExtent <= 0
        ? 1
        : (scroll.offset / scroll.position.maxScrollExtent).clamp(0, 1);
    var nearest = double.infinity;
    for (final entry in keys.entries) {
      final render = entry.value.currentContext?.findRenderObject();
      if (render is RenderBox) {
        final y = render.localToGlobal(Offset.zero).dy;
        final distance = (y - 160).abs();
        if (distance < nearest) {
          nearest = distance;
          activeBlock = entry.key;
        }
      }
    }
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 450), () => persist());
  }

  Future<void> persist({bool? completed}) async {
    if (article == null) return;
    try {
      await services!.journal.recordReading(
        article!.id,
        activeBlock,
        fraction,
        completed: completed,
      );
    } catch (_) {
      if (mounted) showMessage(context, '阅读位置暂时没有保存成功，请稍后重试。');
    }
  }

  void goTo(String id, {bool animate = true}) {
    final target = keys[id]?.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: animate ? const Duration(milliseconds: 280) : Duration.zero,
        alignment: .08,
      );
    }
  }

  void contents() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('这篇文章', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                for (var i = 0; i < article!.blocks.length; i++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AtlasPalette.orangeSoft,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: AtlasPalette.navy,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    title: Text(article!.blocks[i].title),
                    onTap: () {
                      Navigator.pop(ctx);
                      goTo(article!.blocks[i].id);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void glossary({String? term, String? definition}) {
    final a = article;
    if (a == null || (term ?? a.term).isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        term ?? a.term,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭词语解释',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  definition ?? a.definition,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                MediaPhoto(
                  a.mediaId,
                  width: double.infinity,
                  height: 170,
                  radius: 14,
                  showCredit: true,
                ),
                const SizedBox(height: 20),
                PrimaryAction(
                  '我明白了',
                  arrow: false,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    debounce?.cancel();
    unawaited(persist());
    unawaited(services?.speech.pause() ?? Future.value());
    scroll.dispose();
    termTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = article;
    if (a == null) {
      return const AtlasPage(
        title: '阅读',
        child: AtlasEmpty(title: '文章暂时不可用', message: '内容可能已经移除，个人笔记仍会保留。'),
      );
    }
    final preferences = services!.preferences, speech = services!.speech;
    final antarctica = a.regionId == 'antarctica';
    final ownerPath = antarctica
        ? '/regions/antarctica'
        : '/countries/${a.countryId}';
    final egypt = a.countryId == 'egypt';
    final usa = a.countryId == 'usa';
    final gbr = a.countryId == 'gbr';
    final fra = a.countryId == 'fra';
    final deu = a.countryId == 'deu';
    final kenya = a.countryId == 'kenya' || a.countryId == 'norway';
    final aus = a.countryId == 'aus';
    final brazil = a.countryId == 'brazil';
    final zaf = a.countryId == 'zaf';
    final atlasEdition =
        antarctica ||
        zaf ||
        egypt ||
        usa ||
        gbr ||
        fra ||
        deu ||
        kenya ||
        brazil ||
        aus;
    final readTheNile = egypt && a.diagram == 'nile-flow';
    final readTheCanyon = usa && a.diagram == 'usa-canyon-erosion';
    final inline =
        ((deu || kenya) && a.diagram.isNotEmpty) ||
        (zaf && a.diagram.isNotEmpty) ||
        (aus && a.diagram.isNotEmpty) ||
        (brazil && a.diagram.isNotEmpty) ||
        (fra && const {'fra-tides', 'fra-glacier'}.contains(a.diagram)) ||
        readTheNile ||
        readTheCanyon ||
        (gbr &&
            const {
              'gbr-column-cooling',
              'gbr-puffin-habitat',
              'gbr-bilingual',
            }.contains(a.diagram));
    final exercise = services!.content.exercise(a.exerciseId);
    final darkBar =
        egypt &&
            (a.diagram == 'reef-habitat' || a.diagram == 'papyrus-steps') ||
        usa &&
            (a.diagram == 'usa-jazz-response' ||
                a.diagram == 'usa-geyser-process');
    return ListenableBuilder(
      listenable: Listenable.merge([preferences, speech, services!.journal]),
      builder: (context, _) {
        final active = speech.article?.id == a.id;
        final background = preferences.readingBackground == 'warm'
            ? const Color(0xFFFFF8E9)
            : preferences.readingBackground == 'green'
            ? const Color(0xFFF0F7F0)
            : Colors.white;
        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: darkBar ? AtlasPalette.navy : background,
            foregroundColor: darkBar ? Colors.white : null,
            leading: IconButton(
              tooltip: '返回',
              onPressed: () => backOrHome(context, ownerPath),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: darkBar ? Colors.white : null,
              ),
            ),
            title: Text(
              a.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                color: darkBar ? Colors.white : null,
              ),
            ),
            centerTitle: true,
            actions: [
              if (atlasEdition)
                SavedButton(
                  kind: 'article',
                  id: a.id,
                  title: a.title,
                  light: darkBar,
                ),
              PopupMenuButton<String>(
                tooltip: '阅读选项',
                iconColor: darkBar ? Colors.white : null,
                onSelected: (v) => context.push(
                  v == 'settings'
                      ? '/settings/reading'
                      : '/credits?entity=${a.id}',
                ),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'settings', child: Text('阅读设置')),
                  PopupMenuItem(value: 'sources', child: Text('资料来源')),
                ],
              ),
            ],
          ),
          body: Row(
            children: [
              if (MediaQuery.sizeOf(context).width >= 1024)
                SizedBox(
                  width: 235,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 24, 12, 24),
                    children: [
                      const Text(
                        '这篇文章',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 21,
                        ),
                      ),
                      const SizedBox(height: 18),
                      for (var i = 0; i < a.blocks.length; i++)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          title: Text(
                            '${i + 1}. ${a.blocks[i].title}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          onTap: () => goTo(a.blocks[i].id),
                        ),
                      TextButton.icon(
                        onPressed: () => context.push('$ownerPath/contents'),
                        icon: const Icon(Icons.grid_view_outlined),
                        label: const Text('国家目录'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scroll,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: atlasEdition ? 720 : 780,
                      ),
                      child: Padding(
                        padding: atlasEdition
                            ? const EdgeInsets.fromLTRB(16, 8, 16, 30)
                            : const EdgeInsets.fromLTRB(22, 8, 22, 30),
                        child: MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(
                              MediaQuery.textScalerOf(context).scale(1) *
                                  preferences.textScale,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: Theme.of(context).textTheme.headlineLarge
                                    ?.copyWith(
                                      fontSize:
                                          usa &&
                                              MediaQuery.sizeOf(context).width <
                                                  600
                                          ? 29
                                          : null,
                                    ),
                              ),
                              SizedBox(height: readTheNile ? 4 : 10),
                              if (usa ||
                                  gbr ||
                                  fra ||
                                  deu ||
                                  kenya ||
                                  aus ||
                                  antarctica)
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: readTheCanyon
                                      ? AtlasPalette.orangeSoft
                                      : AtlasPalette.canvas,
                                  avatar: Icon(
                                    readTheCanyon
                                        ? Icons.image_search
                                        : Icons.menu_book_outlined,
                                    size: 17,
                                  ),
                                  label: Text(
                                    '${readTheCanyon
                                        ? '读图'
                                        : a.diagram == 'usa-jazz-response'
                                        ? '新奥尔良'
                                        : '阅读'} · 约 ${a.readingMinutes} 分钟',
                                  ),
                                )
                              else if (!readTheNile)
                                Text(
                                  a.summary,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(color: AtlasPalette.muted),
                                ),
                              if (a.revision > 1 && !kenya && !antarctica)
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: readTheNile ? 5 : 12,
                                  ),
                                  child: Text(
                                    '${readTheNile ? '读图' : '阅读'} · 约 ${a.readingMinutes} 分钟',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AtlasPalette.muted,
                                    ),
                                  ),
                                ),
                              SizedBox(height: atlasEdition ? 13 : 20),
                              if (a.diagram == 'terrain')
                                LearningDiagram(a.diagram)
                              else
                                MediaPhoto(
                                  a.mediaId,
                                  alignment: a.id == 'norway-nature'
                                      ? Alignment.topCenter
                                      : a.id == 'kenya-history'
                                      ? Alignment.topCenter
                                      : Alignment.center,
                                  width: double.infinity,
                                  fit:
                                      (kenya &&
                                              services!
                                                      .content
                                                      .media[a.mediaId]
                                                      ?.kind ==
                                                  'diagram') ||
                                          aus &&
                                              (a.mediaId == 'aus-joey' ||
                                                  services!
                                                          .content
                                                          .media[a.mediaId]
                                                          ?.kind ==
                                                      'diagram')
                                      ? BoxFit.contain
                                      : BoxFit.cover,
                                  height:
                                      atlasEdition &&
                                          MediaQuery.sizeOf(context).width < 700
                                      ? (antarctica
                                            ? 200
                                            : readTheNile
                                            ? 162
                                            : 180)
                                      : 240,
                                  radius: 12,
                                  showCredit: true,
                                ),
                              const SizedBox(height: 6),
                              if (a.diagram != 'terrain')
                                Text(
                                  readTheNile
                                      ? '尼罗河弯道 · NASA Landsat 7 · 2000 年'
                                      : services!
                                                .content
                                                .media[a.mediaId]
                                                ?.caption ??
                                            '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AtlasPalette.muted,
                                  ),
                                ),
                              SizedBox(height: readTheNile ? 9 : 20),
                              if (antarctica) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AtlasPalette.sea,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    a.summary,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (a.id == 'antarctica-emperor')
                                  const Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Chip(label: Text('羽毛与保温')),
                                      Chip(label: Text('亲鸟照料幼鸟')),
                                      Chip(label: Text('聚集减少热量流失')),
                                    ],
                                  ),
                              ],
                              if (a.id == 'norway-history') ...[
                                const NorwayEvidenceCard(),
                                const SizedBox(height: 20),
                              ],
                              if (a.id == 'kenya-history') ...[
                                const KenyaEvidenceCard(),
                                const SizedBox(height: 20),
                              ],
                              if (a.diagram == 'reef-habitat') ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AtlasPalette.sea,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '红海 · 水下观察',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AtlasPalette.navy,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              if (a.diagram.isNotEmpty &&
                                  a.diagram != 'terrain') ...[
                                LearningDiagram(a.diagram),
                                SizedBox(height: atlasEdition ? 12 : 18),
                              ],
                              if (inline && exercise != null) ...[
                                _InlineReadingExercise(
                                  exercise,
                                  prompt:
                                      (gbr ||
                                          fra ||
                                          deu ||
                                          kenya ||
                                          brazil ||
                                          zaf ||
                                          aus)
                                      ? exercise.question
                                      : readTheCanyon
                                      ? '找一找河道'
                                      : '哪一边是下游？',
                                  mapPath:
                                      brazil &&
                                          a.diagram == 'brazil-meeting-waters'
                                      ? '/atlas?country=brazil&place=${a.placeId}&layer=water'
                                      : brazil &&
                                            a.diagram == 'brazil-six-biomes'
                                      ? '/atlas?country=brazil&layer=biomes'
                                      : brazil && a.diagram == 'brazil-wetland'
                                      ? '/atlas?country=brazil&feature=brazil-biome-pantanal&layer=biomes'
                                      : (gbr ||
                                            fra ||
                                            deu ||
                                            kenya ||
                                            kenya ||
                                            brazil ||
                                            zaf ||
                                            aus)
                                      ? '/atlas?country=${a.countryId}&place=${a.placeId}'
                                      : readTheCanyon
                                      ? '/atlas?country=usa&region=conus&layer=water&place=usa-grand-canyon'
                                      : '/atlas?country=egypt&layer=water&place=nile-delta',
                                  mapLabel:
                                      (readTheCanyon ||
                                          gbr ||
                                          fra ||
                                          deu ||
                                          kenya ||
                                          brazil ||
                                          zaf ||
                                          aus)
                                      ? '在地图上看看'
                                      : '下一站 · 尼罗河三角洲',
                                  onEvidence: () {
                                    final evidence =
                                        exercise.evidenceBlockIds.firstOrNull;
                                    if (evidence == null) return;
                                    setState(() => highlightedBlock = evidence);
                                    goTo(evidence);
                                  },
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (usa &&
                                  a.diagram == 'usa-geyser-process' &&
                                  exercise != null)
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.search),
                                  label: const Text('找出水和热量'),
                                  onPressed: () =>
                                      context.push('/exercises/${exercise.id}'),
                                ),
                              if (a.diagram == 'reef-habitat')
                                PrimaryAction(
                                  '在照片里找找可能的藏身处',
                                  orange: true,
                                  icon: Icons.image_search,
                                  onPressed: () => context.push(
                                    '$ownerPath/observe/${a.id}',
                                  ),
                                ),
                              if (atlasEdition && a.term.isNotEmpty)
                                TextButton.icon(
                                  onPressed: glossary,
                                  icon: const Icon(Icons.lightbulb_outline),
                                  label: Text('认识一个词：${a.term}'),
                                ),
                              if (a.placeId.isNotEmpty ||
                                  a.mapFeatureId.isNotEmpty)
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.map_outlined),
                                  label: Text(
                                    readTheNile ? '打开埃及地图，找北箭头和尼罗河' : '在地图上看看',
                                  ),
                                  onPressed: () => context.push(
                                    Uri(
                                      path: '/atlas',
                                      queryParameters: {
                                        'country': a.countryId,
                                        if ((atlasEdition &&
                                                a.mapFeatureId.isNotEmpty) ||
                                            (brazil &&
                                                a.placeId ==
                                                    'brazil-manaus-meeting-waters'))
                                          'layer': 'water',
                                        if (a.placeId.isNotEmpty &&
                                            !(usa &&
                                                a.mapFeatureId ==
                                                    'usa-feature-great-lakes'))
                                          'place': a.placeId,
                                        if (a.mapFeatureId.isNotEmpty)
                                          'feature': a.mapFeatureId,
                                      },
                                    ).toString(),
                                  ),
                                ),
                              if (active &&
                                  (speech.playing ||
                                      speech.preparing ||
                                      speech.paused))
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AtlasPalette.navy,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            tooltip:
                                                speech.playing ||
                                                    speech.preparing
                                                ? '暂停讲解'
                                                : '继续讲解',
                                            onPressed: () =>
                                                speech.playing ||
                                                    speech.preparing
                                                ? speech.pause()
                                                : speech.resume(
                                                    rate:
                                                        preferences.speechRate,
                                                  ),
                                            icon: Icon(
                                              speech.playing || speech.preparing
                                                  ? Icons.pause_circle_filled
                                                  : Icons.play_circle_filled,
                                              color: Colors.white,
                                              size: 36,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              speech.preparing
                                                  ? '正在准备语音…'
                                                  : '${speech.modeLabel}${speech.paused ? ' · 已暂停' : ''} · 第 ${speech.blockIndex + 1} 段',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => context.push(
                                              '/settings/reading',
                                            ),
                                            child: const Text(
                                              '语速',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            tooltip: '上一段',
                                            onPressed: speech.blockIndex > 0
                                                ? () => speech.move(-1)
                                                : null,
                                            icon: const Icon(
                                              Icons.skip_previous,
                                              color: Colors.white,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: '下一段',
                                            onPressed:
                                                speech.blockIndex + 1 <
                                                    a.blocks.length
                                                ? () => speech.move(1)
                                                : null,
                                            icon: const Icon(
                                              Icons.skip_next,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              if (active && speech.notice != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    speech.notice!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AtlasPalette.muted,
                                    ),
                                  ),
                                ),
                              if (active && speech.error != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    speech.error!,
                                    style: const TextStyle(
                                      color: AtlasPalette.muted,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              for (var i = 0; i < a.blocks.length; i++)
                                Container(
                                  key: keys[a.blocks[i].id],
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        active &&
                                            speech.playing &&
                                            speech.blockIndex == i
                                        ? const Color(0xFFEAF2F9)
                                        : highlightedBlock == a.blocks[i].id
                                        ? AtlasPalette.orangeSoft
                                        : null,
                                    border: const Border(
                                      top: BorderSide(color: AtlasPalette.line),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.blocks[i].title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      const SizedBox(height: 12),
                                      SelectableText.rich(
                                        _paragraph(a.blocks[i].text, a),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontSize: atlasEdition
                                                  ? 18
                                                  : null,
                                              height: atlasEdition
                                                  ? 1.65
                                                  : null,
                                            ),
                                      ),
                                      if (a.blocks[i].mediaId != null) ...[
                                        const SizedBox(height: 16),
                                        MediaPhoto(
                                          a.blocks[i].mediaId!,
                                          width: double.infinity,
                                          height: 240,
                                          fit: BoxFit.contain,
                                          radius: 12,
                                          showCredit: true,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          services!
                                                  .content
                                                  .media[a.blocks[i].mediaId]
                                                  ?.caption ??
                                              '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AtlasPalette.muted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              if (!atlasEdition && a.term.isNotEmpty)
                                TextButton.icon(
                                  onPressed: glossary,
                                  icon: const Icon(Icons.lightbulb_outline),
                                  label: Text('认识一个词：${a.term}'),
                                ),
                              if (a.glossary.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final word in a.glossary)
                                      ActionChip(
                                        label: Text(word['term'] ?? ''),
                                        avatar: const Icon(
                                          Icons.lightbulb_outline,
                                          size: 18,
                                        ),
                                        onPressed: () => glossary(
                                          term: word['term'],
                                          definition: word['definition'],
                                        ),
                                      ),
                                  ],
                                ),
                              const SizedBox(height: 12),
                              if (a.question.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: AtlasPalette.orangeSoft,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '想一想',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(a.question),
                                      Material(
                                        color: Colors.transparent,
                                        child: ExpansionTile(
                                          tilePadding: EdgeInsets.zero,
                                          title: const Text('看看一条思考线索'),
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              child: Text(a.answer),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 22),
                              PrimaryAction(
                                services!.journal.progress[a
                                            .id]?['completed'] ==
                                        1
                                    ? '已经读过，再探索一点'
                                    : '我读完了',
                                onPressed: () => atlasAction(
                                  context,
                                  () => persist(completed: true),
                                  success: '这次阅读已经记在足迹里',
                                ),
                              ),
                              if (!readTheNile &&
                                  services!.content.exercises.any(
                                    (e) => e.articleId == a.id,
                                  )) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () => context.push(
                                    '/exercises/${services!.content.exercises.firstWhere((e) => e.articleId == a.id).id}',
                                  ),
                                  icon: const Icon(Icons.extension_outlined),
                                  label: const Text('试一个小问题'),
                                ),
                              ],
                              if (a.activity['type'] == 'open') ...[
                                const SizedBox(height: 18),
                                PrimaryAction(
                                  a.activity['title'] ?? '记下一个发现',
                                  orange: true,
                                  icon: Icons.edit_note,
                                  onPressed: () => context.push(
                                    '$ownerPath/observe/${a.id}',
                                  ),
                                ),
                              ],
                              const EditorialHeading('继续发现'),
                              for (final other
                                  in services!.content
                                      .articlesIn(a.countryId)
                                      .where((x) => x.id != a.id)
                                      .take(2))
                                ContentRow(
                                  title: other.title,
                                  subtitle: other.summary,
                                  mediaId: other.mediaId,
                                  onTap: () =>
                                      context.push('/articles/${other.id}'),
                                ),
                              TextButton(
                                onPressed: () =>
                                    context.push('/credits?entity=${a.id}'),
                                child: const Text('查看这篇文章的资料来源'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: background,
                border: const Border(top: BorderSide(color: AtlasPalette.line)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  _tool(Icons.format_list_bulleted, '目录', contents),
                  _tool(
                    active && speech.playing
                        ? Icons.pause_circle_outline
                        : Icons.headphones_outlined,
                    active && (speech.playing || speech.preparing)
                        ? '暂停'
                        : active && speech.paused
                        ? '继续听'
                        : '听讲解',
                    () => active && (speech.playing || speech.preparing)
                        ? speech.pause()
                        : active && speech.paused
                        ? speech.resume(rate: preferences.speechRate)
                        : speech.play(
                            a,
                            start: active
                                ? speech.blockIndex
                                : a.blocks
                                      .indexWhere((b) => b.id == activeBlock)
                                      .clamp(0, a.blocks.length - 1),
                            rate: preferences.speechRate,
                          ),
                  ),
                  _tool(
                    services!.journal.saved('article', a.id)
                        ? Icons.bookmark
                        : Icons.bookmark_outline,
                    services!.journal.saved('article', a.id) ? '已收藏' : '收藏',
                    () => atlasAction(
                      context,
                      () => services!.journal.toggle('article', a.id, a.title),
                    ),
                  ),
                  _tool(
                    Icons.edit_note_rounded,
                    '笔记',
                    () => context.push(
                      '/me/notes/new?entity=${a.id}&kind=article',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  TextSpan _paragraph(String text, AtlasArticle a) {
    if (a.term.isEmpty || !text.contains(a.term)) return TextSpan(text: text);
    final parts = text.split(a.term);
    return TextSpan(
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          TextSpan(text: parts[i]),
          if (i < parts.length - 1)
            TextSpan(
              text: a.term,
              style: const TextStyle(
                color: AtlasPalette.blue,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
              recognizer: termTap,
            ),
        ],
      ],
    );
  }

  Widget _tool(IconData icon, String label, VoidCallback callback) => Expanded(
    child: TextButton(
      onPressed: callback,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    ),
  );
}

class _InlineReadingExercise extends StatefulWidget {
  const _InlineReadingExercise(
    this.exercise, {
    required this.onEvidence,
    required this.prompt,
    required this.mapPath,
    required this.mapLabel,
  });
  final AtlasExercise exercise;
  final VoidCallback onEvidence;
  final String prompt, mapPath, mapLabel;

  @override
  State<_InlineReadingExercise> createState() => _InlineReadingExerciseState();
}

class _InlineReadingExerciseState extends State<_InlineReadingExercise> {
  String? selected;
  bool saved = false, busy = false;
  String? restoredId;
  bool get correct => selected == widget.exercise.answerId;

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    if (e.countryId == 'norway' && restoredId != e.id) {
      restoredId = e.id;
      selected = context.atlas.journal.attempts[e.id]?['answer_id'] as String?;
      saved = selected != null;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 9, 13, 12),
      decoration: BoxDecoration(
        color: AtlasPalette.orangeSoft,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('动手找找', style: Theme.of(context).textTheme.titleLarge),
              Text(
                widget.prompt,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: AtlasPalette.navy),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 5,
            children: [
              for (final option in e.options)
                ChoiceChip(
                  label: Text(option['text']),
                  selected: selected == option['id'],
                  side: const BorderSide(color: AtlasPalette.blue),
                  onSelected: busy || saved
                      ? null
                      : (_) => setState(() => selected = option['id']),
                ),
            ],
          ),
          const SizedBox(height: 5),
          if (!saved)
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(74, 46),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
              ),
              onPressed: selected == null || busy
                  ? null
                  : () async {
                      setState(() => busy = true);
                      await atlasAction(context, () async {
                        await context.atlas.journal.answer(
                          e.id,
                          selected!,
                          correct,
                        );
                        if (mounted) setState(() => saved = true);
                      });
                      if (mounted) setState(() => busy = false);
                    },
              child: Text(busy ? '正在保存…' : '确认'),
            )
          else ...[
            const SizedBox(height: 4),
            Text(correct ? e.explanation : e.hint),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: widget.onEvidence,
                  child: const Text('回到证据'),
                ),
                if (correct)
                  TextButton(
                    onPressed: () => context.push(widget.mapPath),
                    child: Text(widget.mapLabel),
                  )
                else
                  TextButton(
                    onPressed: () => setState(() {
                      selected = null;
                      saved = false;
                    }),
                    child: const Text('再试一次'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
