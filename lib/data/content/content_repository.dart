import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../../domain/atlas_content.dart';

class ContentRepository extends ChangeNotifier {
  ContentRepository.fromJson(Json j)
    : regions = (j['regions'] as List? ?? [])
          .map((e) => AtlasRegion.fromJson(e))
          .toList(),
      countries = (j['countries'] as List)
          .where((e) => e['id'] != 'twn')
          .map((e) => AtlasCountry.fromJson(e))
          .toList(),
      articles = (j['articles'] as List)
          .map((e) => AtlasArticle.fromJson(e))
          .toList(),
      places = (j['places'] as List)
          .map((e) => AtlasPlace.fromJson(e))
          .toList(),
      topics = (j['topics'] as List)
          .map((e) => AtlasTopic.fromJson(e))
          .toList(),
      exercises = (j['exercises'] as List)
          .map((e) => AtlasExercise.fromJson(e))
          .toList(),
      media = {
        for (final m in j['media'] as List)
          m['id'] as String: MediaItem.fromJson(m),
      },
      raw = j;

  final List<AtlasRegion> regions;
  final List<AtlasCountry> countries;
  final List<AtlasArticle> articles;
  final List<AtlasPlace> places;
  final List<AtlasTopic> topics;
  final List<AtlasExercise> exercises;
  final Map<String, MediaItem> media;
  final Json raw;
  final Map<String, Uint8List> memoryMedia = {};

  void applyDownloaded(List<Json> payloads, Map<String, Uint8List> files) {
    final base = ContentRepository.fromJson(raw);
    countries
      ..clear()
      ..addAll(base.countries);
    articles
      ..clear()
      ..addAll(base.articles);
    places
      ..clear()
      ..addAll(base.places);
    exercises
      ..clear()
      ..addAll(base.exercises);
    media
      ..clear()
      ..addAll(base.media);
    memoryMedia.clear();
    for (final payload in payloads) {
      final c = AtlasCountry.fromJson(payload['country']);
      if (c.id == 'twn') continue;
      final bundled = (raw['countries'] as List)
          .cast<Json>()
          .where((row) => row['id'] == c.id)
          .firstOrNull;
      // An older installed pack must not replace a newer bundled country.
      final bundledRevision = (bundled?['revision'] as num?)?.toInt() ?? 1;
      final installedRevision =
          ((payload['country'] as Json)['revision'] as num?)?.toInt() ?? 1;
      if (installedRevision < bundledRevision) continue;
      countries.removeWhere((old) => old.id == c.id);
      countries.add(c);
      articles.removeWhere((old) => old.countryId == c.id);
      articles.addAll(
        (payload['articles'] as List).map((j) => AtlasArticle.fromJson(j)),
      );
      places.removeWhere((old) => old.countryId == c.id);
      places.addAll(
        (payload['places'] as List? ?? []).map((j) => AtlasPlace.fromJson(j)),
      );
      exercises.removeWhere((old) => old.countryId == c.id);
      exercises.addAll(
        (payload['exercises'] as List? ?? []).map(
          (j) => AtlasExercise.fromJson(j),
        ),
      );
      for (final j in payload['media'] as List? ?? []) {
        final m = MediaItem.fromJson(j);
        media[m.id] = m;
        final bytes = files['${c.id}/${m.asset}'];
        if (bytes != null) memoryMedia[m.id] = bytes;
      }
    }
    base.dispose();
    notifyListeners();
  }

  static Future<ContentRepository> load() async {
    final j = jsonDecode(
      await rootBundle.loadString('assets/atlas/catalog.json'),
    ) as Json;
    final r = jsonDecode(
      await rootBundle.loadString('assets/atlas/antarctica-region.json'),
    ) as Json;
    j['regions'] = [
      {...r, 'id': 'antarctica', 'name': '南极洲'},
    ];
    for (final key in ['articles', 'places', 'exercises', 'media']) {
      (j[key] as List).addAll(r[key] as List);
    }
    return ContentRepository.fromJson(j);
  }

  AtlasRegion? region(String id) =>
      regions.where((e) => e.id == id).firstOrNull;
  AtlasCountry? country(String id) =>
      countries.where((e) => e.id == (id == 'twn' ? 'china' : id)).firstOrNull;
  AtlasArticle? article(String id) =>
      articles.where((e) => e.id == id).firstOrNull;
  AtlasPlace? place(String id) => places.where((e) => e.id == id).firstOrNull;
  AtlasTopic? topic(String id) => topics.where((e) => e.id == id).firstOrNull;
  AtlasExercise? exercise(String id) =>
      exercises.where((e) => e.id == id).firstOrNull;
  List<AtlasPlace> placesIn(String id) =>
      places.where((e) => e.countryId == id).toList();
  List<AtlasArticle> articlesIn(String id) =>
      articles.where((e) => e.countryId == id).toList();
  List<AtlasCountry> get featured =>
      countries.where((e) => e.hasArticles).toList();

  List<SearchHit> search(String input, {String kind = '全部'}) {
    final q = input.trim().toLowerCase().replaceAll(' ', '');
    if (q.isEmpty) return [];
    final hits = <SearchHit>[];
    void add(SearchHit h, String extra) {
      if (kind != '全部' && kind != h.kind) return;
      if ('${h.title}${h.subtitle}$extra'
          .toLowerCase()
          .replaceAll(' ', '')
          .contains(q)) {
        hits.add(h);
      }
    }

    for (final item in [
      ('china-taiwan', '中国台湾', '台湾 Taiwan 台灣'),
      ('china-diaoyu', '钓鱼岛', '钓鱼岛 钓鱼台 Diaoyu'),
    ]) {
      add(
        SearchHit(
          id: item.$1,
          kind: '地点',
          title: item.$2,
          subtitle: '中国 · 地图位置',
          route: '/atlas?country=china&feature=${item.$1}',
          countryId: 'china',
          mediaId: '',
        ),
        item.$3,
      );
    }
    for (final r in regions) {
      add(
        SearchHit(
          id: r.id,
          kind: '专题',
          title: r.name,
          subtitle: '自然地理专题',
          route: '/regions/${r.id}',
          mediaId: 'antarctica-m15',
        ),
        '南极 Antarctica 南大洋 冰雪',
      );
    }
    for (final c in countries) {
      if (c.id == 'ata' && region('antarctica') != null) continue;
      add(
        SearchHit(
          id: c.id,
          kind: '国家',
          title: c.name,
          subtitle: c.tagline.isEmpty ? '${c.continent} · 国家基础资料' : c.tagline,
          route: '/countries/${c.id}',
          mediaId: c.mediaId,
          countryId: c.id,
        ),
        '${c.englishName}${c.capital}${c.intro}',
      );
    }
    for (final p in places) {
      add(
        SearchHit(
          id: p.id,
          kind: '地点',
          title: p.name,
          subtitle: p.summary,
          route: '/places/${p.id}',
          mediaId: p.mediaIds.firstOrNull ?? '',
          countryId: p.countryId,
        ),
        p.description,
      );
    }
    for (final a in articles) {
      add(
        SearchHit(
          id: a.id,
          kind: '文章',
          title: a.title,
          subtitle: a.summary,
          route: '/articles/${a.id}',
          mediaId: a.mediaId,
          countryId: a.countryId,
        ),
        a.blocks.map((b) => b.text).join(),
      );
    }
    for (final t in topics) {
      add(
        SearchHit(
          id: t.id,
          kind: '专题',
          title: t.title,
          subtitle: t.question,
          route: '/topics/${t.id}',
          mediaId: t.mediaId,
        ),
        t.description,
      );
    }
    int score(SearchHit h) => h.title.toLowerCase() == q
        ? 0
        : h.title.toLowerCase().contains(q)
        ? 1
        : 2;
    hits.sort((a, b) {
      final byScore = score(a).compareTo(score(b));
      return byScore == 0 ? a.title.compareTo(b.title) : byScore;
    });
    return hits;
  }
}
