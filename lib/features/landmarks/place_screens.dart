import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../design/photo_points.dart';
import '../../domain/atlas_content.dart';
import '../../map_engine/atlas_map.dart';
import 'norway_place.dart';

class PlaceScreen extends StatefulWidget {
  const PlaceScreen(this.id, {super.key});
  final String id;
  @override
  State<PlaceScreen> createState() => _PlaceScreenState();
}

class _PlaceScreenState extends State<PlaceScreen> {
  bool visited = false, fullDescription = false;
  String? observedPhoto;
  AtlasServices? services;
  String get narrationId => 'place:${widget.id}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    services = context.atlas;
    if (!visited) {
      visited = true;
      final p = services!.content.place(widget.id);
      if (p != null) {
        atlasAction(
          context,
          () => services!.journal.visit('place', p.id, p.name),
        );
      }
    }
  }

  @override
  void dispose() {
    final speech = services?.speech;
    if (speech?.article?.id == narrationId) unawaited(speech!.pause());
    super.dispose();
  }

  AtlasArticle narration(AtlasPlace p) => AtlasArticle(
    id: narrationId,
    countryId: p.countryId,
    sectionId: 'landmarks',
    title: p.name,
    summary: p.summary,
    mediaId: p.mediaIds.firstOrNull ?? '',
    blocks: [
      ArticleBlock(id: '$narrationId-intro', title: p.name, text: p.summary),
      ArticleBlock(
        id: '$narrationId-story',
        title: '认识这个地方',
        text: p.description,
      ),
      ArticleBlock(
        id: '$narrationId-observe',
        title: '仔细看一看',
        text: p.observation,
      ),
    ],
    term: '',
    definition: '',
    question: '',
    answer: '',
    sourceUrls: [p.sourceUrl],
  );

  void writeObservation(AtlasPlace place) {
    if (!const {'egypt', 'usa', 'aus'}.contains(place.countryId)) {
      context.push('/me/notes/new?entity=${place.id}&kind=place');
      return;
    }
    context.push(
      Uri(
        path: '/countries/${place.countryId}/observe/place/${place.id}',
        queryParameters: {if (observedPhoto != null) 'media': observedPhoto},
      ).toString(),
    );
  }

  Widget observationPage(AtlasPlace place) {
    final content = context.atlas.content;
    final canyon = place.id == 'usa-grand-canyon';
    return AtlasPage(
      title: place.name,
      width: 800,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      actions: [SavedButton(kind: 'place', id: place.id, title: place.name)],
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 7, 16, 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                      canyon
                          ? '/atlas?country=usa&region=conus&layer=water&place=${place.id}'
                          : '/atlas?country=${place.countryId}&place=${place.id}',
                    ),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('在地图上找它'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PrimaryAction(
                    '记下我的发现',
                    orange: true,
                    arrow: false,
                    onPressed: () => writeObservation(place),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canyon) ...[
            Text(place.name, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              place.region,
              style: const TextStyle(color: AtlasPalette.muted),
            ),
            const SizedBox(height: 8),
            Text(place.summary, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
          ],
          PhotoObservation(
            place: place,
            lead: true,
            onMaterial: (id) => observedPhoto = id,
          ),
          const SizedBox(height: 14),
          Text(
            canyon
                ? '先找岩层条带，再沿谷底找一段水。'
                : place.countryId == 'aus'
                ? '先描述颜色与形状，再提出想了解的问题。'
                : '先描述你看到的，再猜用途。',
            style: const TextStyle(color: AtlasPalette.muted, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(place.description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push('/places/${place.id}/gallery'),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('打开图集'),
              ),
              ListenableBuilder(
                listenable: context.atlas.speech,
                builder: (context, _) {
                  final speech = context.atlas.speech;
                  final playing =
                      speech.article?.id == narrationId && speech.playing;
                  return OutlinedButton.icon(
                    onPressed: () => atlasAction(
                      context,
                      () => playing
                          ? speech.pause()
                          : speech.play(narration(place)),
                    ),
                    icon: Icon(
                      playing ? Icons.pause : Icons.headphones_outlined,
                    ),
                    label: Text(playing ? '暂停' : '听讲解'),
                  );
                },
              ),
            ],
          ),
          const EditorialHeading('再读一条线索'),
          for (final a
              in place.articleIds
                  .map(content.article)
                  .whereType<AtlasArticle>())
            ContentRow(
              title: a.title,
              subtitle: a.summary,
              mediaId: a.mediaId,
              outlined: true,
              onTap: () => context.push('/articles/${a.id}'),
            ),
          TextButton.icon(
            onPressed: () => context.push('/credits?entity=${place.id}'),
            icon: const Icon(Icons.info_outline),
            label: const Text('资料来源与图片许可'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atlas.content.place(widget.id);
    if (p == null) {
      return const AtlasPage(
        title: '地标与风景',
        child: AtlasEmpty(title: '暂时没有这个地点的资料', message: '从地图上选择另一个地方。'),
      );
    }
    if (p.countryId == 'norway') return NorwayPlace(p);
    final country = context.atlas.content.country(p.countryId);
    final hasPhoto = p.mediaIds.isNotEmpty;
    if (const {
          'giza',
          'usa-grand-canyon',
          'aus-great-barrier-reef',
        }.contains(p.id) &&
        p.hotspots.isNotEmpty) {
      return observationPage(p);
    }
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: country?.editorial.isNotEmpty == true
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(
                          '/atlas?country=${p.countryId}&place=${p.id}',
                        ),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('在地图上找它'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryAction(
                        '记下我的发现',
                        orange: true,
                        arrow: false,
                        onPressed: () => writeObservation(p),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: hasPhoto
                ? (MediaQuery.sizeOf(context).width >= 700 ? 340 : 286)
                : 140,
            pinned: true,
            backgroundColor: AtlasPalette.navy,
            foregroundColor: Colors.white,
            leading: IconButton(
              tooltip: '返回',
              onPressed: () => backOrHome(context, '/countries/${p.countryId}'),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            ),
            actions: [
              SavedButton(kind: 'place', id: p.id, title: p.name, light: true),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasPhoto)
                    MediaPhoto(
                      p.mediaIds.first,
                      width: double.infinity,
                      height: double.infinity,
                      onTap: () => context.push('/places/${p.id}/gallery'),
                    )
                  else
                    const ColoredBox(color: AtlasPalette.navy),
                  const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [Color(0x65051931), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    bottom: 32,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AtlasPalette.navy,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AtlasPalette.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${p.region.isEmpty ? country?.name ?? '' : p.region} · ${p.category}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: -1,
                    left: 0,
                    right: 0,
                    height: 21,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(fontSize: 32),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.summary,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: AtlasPalette.muted,
                        ),
                      ),
                      if (p.countryId == 'egypt' && p.hotspots.isNotEmpty)
                        PhotoObservation(
                          place: p,
                          onMaterial: (id) => observedPhoto = id,
                        ),
                      const SizedBox(height: 16),
                      AnimatedBuilder(
                        animation: context.atlas.speech,
                        builder: (context, _) {
                          final speech = context.atlas.speech;
                          final active = speech.article?.id == narrationId;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 12,
                                        ),
                                        foregroundColor: AtlasPalette.navy,
                                        side: const BorderSide(
                                          color: AtlasPalette.blue,
                                        ),
                                      ),
                                      onPressed: () =>
                                          context.push('/atlas?place=${p.id}'),
                                      icon: const Icon(Icons.map_outlined),
                                      label: const Text(
                                        '在地图上看',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AtlasPalette.orange,
                                        foregroundColor: AtlasPalette.navy,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 12,
                                        ),
                                      ),
                                      onPressed: active && speech.preparing
                                          ? null
                                          : () => atlasAction(
                                              context,
                                              () async {
                                                if (active && speech.playing) {
                                                  await speech.pause();
                                                } else {
                                                  await speech.play(
                                                    narration(p),
                                                    rate: context
                                                        .atlas
                                                        .preferences
                                                        .speechRate,
                                                  );
                                                }
                                              },
                                            ),
                                      icon: Icon(
                                        active && speech.playing
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_fill,
                                      ),
                                      label: Text(
                                        active && speech.preparing
                                            ? '准备语音'
                                            : active && speech.playing
                                            ? '暂停介绍'
                                            : '听介绍',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (active && speech.error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    speech.error!,
                                    style: const TextStyle(
                                      color: AtlasPalette.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '它在哪里？',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${p.name}位于${country?.name ?? '地图标记区域'}。点开地图，认识它与周围地区的位置关系。',
                                  style: const TextStyle(
                                    color: AtlasPalette.muted,
                                    fontSize: 15,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          SizedBox(
                            width: 132,
                            height: 116,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Semantics(
                                button: true,
                                label: '在地图上查看${p.name}',
                                child: GestureDetector(
                                  onTap: () =>
                                      context.push('/atlas?place=${p.id}'),
                                  child: IgnorePointer(
                                    child: AtlasMap(
                                      countries:
                                          context.atlas.content.countries,
                                      places: [p],
                                      initialCountry: country,
                                      selectedId: p.countryId,
                                      layer: '地标',
                                      showControls: false,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (p.countryId != 'egypt' && p.hotspots.isNotEmpty) ...[
                        PhotoObservation(place: p),
                        const SizedBox(height: 20),
                      ],
                      Text(
                        '仔细看一看',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AtlasPalette.orangeSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: AtlasPalette.orange,
                              size: 27,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                p.observation,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (hasPhoto) ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE5F0FC),
                              foregroundColor: AtlasPalette.navy,
                              padding: const EdgeInsets.all(16),
                            ),
                            onPressed: () =>
                                context.push('/places/${p.id}/gallery'),
                            icon: const Icon(Icons.collections_outlined),
                            label: const Text('查看图集'),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '认识这个地方',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            tooltip: fullDescription ? '收起介绍' : '展开完整介绍',
                            onPressed: () => setState(
                              () => fullDescription = !fullDescription,
                            ),
                            icon: Icon(
                              fullDescription
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        fullDescription
                            ? p.description
                            : '${p.description.split('。').first}。',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      if (p.mediaIds.length > 1)
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: p.mediaIds.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, i) => MediaPhoto(
                              p.mediaIds[i],
                              width: 155,
                              height: 115,
                              radius: 12,
                              onTap: () => context.push(
                                '/places/${p.id}/gallery?image=$i',
                              ),
                            ),
                          ),
                        ),
                      for (final articleId in p.articleIds)
                        if (context.atlas.content.article(articleId)
                            case final article?)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ContentRow(
                              title: article.title,
                              subtitle: article.summary,
                              mediaId: article.mediaId,
                              onTap: () => context.push('/articles/$articleId'),
                            ),
                          ),
                      OutlinedButton.icon(
                        onPressed: () => context.push(
                          '/me/notes/new?entity=${p.id}&kind=place',
                        ),
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('记下我的发现'),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            context.push('/credits?entity=${p.id}'),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('资料来源与摄影署名'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PhotoObservation extends StatefulWidget {
  const PhotoObservation({
    super.key,
    required this.place,
    this.lead = false,
    this.onMaterial,
  });
  final AtlasPlace place;
  final bool lead;
  final ValueChanged<String>? onMaterial;
  @override
  State<PhotoObservation> createState() => _PhotoObservationState();
}

class _PhotoObservationState extends State<PhotoObservation> {
  String? activeMedia;
  int? selected;

  @override
  Widget build(BuildContext context) {
    final p = widget.place;
    final canyon = p.id == 'usa-grand-canyon';
    final groups = <String, List<Json>>{};
    for (final h in p.hotspots) {
      final mediaId = h['mediaId'] as String? ?? p.mediaIds.first;
      groups.putIfAbsent(mediaId, () => []).add(h);
    }
    if (groups.isEmpty) return const SizedBox.shrink();
    final mediaId = activeMedia ?? groups.keys.first;
    final points = groups[mediaId]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.lead) const EditorialHeading('放大照片，找找线索'),
        if (groups.length > 1 && (!widget.lead || canyon))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (i, id) in groups.keys.indexed)
                  ChoiceChip(
                    label: Text(i == 0 ? '全景' : '细节'),
                    selected: mediaId == id,
                    onSelected: (_) => chooseMedia(id),
                  ),
              ],
            ),
          ),
        PhotoPoints(
          key: ValueKey(mediaId),
          mediaId: mediaId,
          points: points,
          selected: selected,
          onSelect: (i) => choosePoint(mediaId, i),
        ),
        const SizedBox(height: 10),
        if (widget.lead && !canyon) ...[
          Text(
            p.countryId == 'aus' ? '珊瑚礁里有哪些线索？' : '金字塔留下了哪些线索？',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Chip(
            avatar: const Icon(Icons.place_outlined, size: 19),
            label: Text('${p.region} · ${p.category}'),
          ),
          for (final (id, values) in groups.entries.map(
            (e) => (e.key, e.value),
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: ContentRow(
                title: values.first['label'],
                subtitle: id == groups.keys.first ? '全景观察' : '石块近景',
                mediaId: id,
                outlined: true,
                onTap: () {
                  chooseMedia(id);
                  choosePoint(id, 0);
                },
              ),
            ),
        ],
        if (canyon) ...[
          const EditorialHeading('在照片里找证据'),
          for (final (i, point) in points.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ContentRow(
                title: '${i + 1}  ${point['label']}',
                subtitle: selected == i ? point['explanation'] : '点选看线索',
                leading: const Icon(Icons.visibility_outlined),
                outlined: true,
                onTap: () => choosePoint(mediaId, i),
              ),
            ),
        ] else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < points.length; i++)
                ChoiceChip(
                  label: Text('${i + 1} ${points[i]['label']}'),
                  selected: selected == i,
                  onSelected: (_) => choosePoint(mediaId, i),
                ),
            ],
          ),
        if (selected != null && !canyon)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              points[selected!]['explanation'],
              style: const TextStyle(fontSize: 18),
            ),
          ),
      ],
    );
  }

  void chooseMedia(String id) {
    setState(() {
      activeMedia = id;
      selected = null;
    });
    widget.onMaterial?.call(id);
  }

  void choosePoint(String id, int i) {
    setState(() => selected = i);
    widget.onMaterial?.call(id);
  }
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.id, this.initial = 0});
  final String id;
  final int initial;
  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late int index = widget.initial;
  PageController? pages;
  bool caption = true;
  @override
  void dispose() {
    pages?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atlas.content.place(widget.id),
        media = context.atlas.content.media;
    final ids = p?.mediaIds ?? <String>[];
    if (ids.isEmpty) {
      return const AtlasPage(
        title: '风景图集',
        child: AtlasEmpty(title: '这个地点尚未收录照片', message: '你仍可以阅读文字介绍。'),
      );
    }
    index = index.clamp(0, ids.length - 1);
    pages ??= PageController(initialPage: index);
    final m = media[ids[index]];
    return Scaffold(
      backgroundColor: const Color(0xFF0C1621),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1621),
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: '返回地标',
          onPressed: () => backOrHome(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: Text(
          '${index + 1} / ${ids.length}',
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: caption ? '收起图片说明' : '显示图片说明',
            onPressed: () => setState(() => caption = !caption),
            icon: const Icon(Icons.info_outline, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: pages,
              itemCount: ids.length,
              onPageChanged: (i) => setState(() => index = i),
              itemBuilder: (context, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: MediaPhoto(
                    ids[i],
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          if (caption && m != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${m.credit} · ${m.license}',
                      style: const TextStyle(
                        color: Color(0xFFC2CFDD),
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => showMediaCredit(context, m),
                      child: const Text(
                        '查看原图来源与许可',
                        style: TextStyle(color: Color(0xFF9ECBF4)),
                      ),
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
