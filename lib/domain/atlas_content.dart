typedef Json = Map<String, dynamic>;

class MediaItem {
  const MediaItem({
    required this.id,
    required this.asset,
    required this.caption,
    required this.credit,
    required this.sourceUrl,
    required this.license,
    required this.licenseUrl,
    this.kind = 'realPhoto',
    this.width = 1600,
    this.height = 1067,
  });
  final String id, asset, caption, credit, sourceUrl, license, licenseUrl, kind;
  final int width, height;
  factory MediaItem.fromJson(Json j) => MediaItem(
    id: j['id'],
    asset: j['asset'],
    caption: j['caption'],
    credit: j['credit'],
    sourceUrl: j['sourceUrl'],
    license: j['license'],
    licenseUrl: j['licenseUrl'],
    kind: j['kind'] ?? 'realPhoto',
    width: j['width'] ?? 1600,
    height: j['height'] ?? 1067,
  );
}

class FactItem {
  const FactItem(this.label, this.value);
  final String label, value;
  factory FactItem.fromJson(Json j) => FactItem(j['label'], j['value']);
}

class AtlasCountry {
  const AtlasCountry({
    required this.id,
    required this.code,
    required this.name,
    required this.englishName,
    required this.continent,
    required this.latitude,
    required this.longitude,
    required this.capital,
    required this.intro,
    required this.tagline,
    required this.mediaId,
    required this.coverage,
    required this.facts,
    required this.takeaways,
    required this.timeline,
    required this.sources,
    required this.sections,
    this.editorial = const {},
  });
  final String id,
      code,
      name,
      englishName,
      continent,
      capital,
      intro,
      tagline,
      mediaId,
      coverage;
  final double latitude, longitude;
  final List<FactItem> facts;
  final List<String> takeaways;
  final List<Json> timeline, sources;
  final Map<String, List<String>> sections;
  final Json editorial;
  bool get hasArticles => sections.values.any((v) => v.isNotEmpty);
  String get flag => code.length == 2
      ? String.fromCharCodes(code.toUpperCase().runes.map((r) => r + 127397))
      : '🌐';
  factory AtlasCountry.fromJson(Json j) => AtlasCountry(
    id: j['id'],
    code: j['code'] ?? '',
    name: j['name'],
    englishName: j['englishName'] ?? '',
    continent: j['continent'],
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
    capital: j['capital'] ?? '',
    intro: j['intro'] ?? '',
    tagline: j['tagline'] ?? '',
    mediaId: j['mediaId'] ?? '',
    coverage: j['coverage'] ?? 'basic',
    facts: (j['facts'] as List? ?? [])
        .map((e) => FactItem.fromJson(e))
        .toList(),
    takeaways: List<String>.from(j['takeaways'] ?? []),
    timeline: List<Json>.from(j['timeline'] ?? []),
    sources: List<Json>.from(j['sources'] ?? []),
    sections: (j['sections'] as Json? ?? {}).map(
      (k, v) => MapEntry(k, List<String>.from(v)),
    ),
    editorial: Map<String, dynamic>.from(j['editorial'] ?? {}),
  );
}

class ArticleBlock {
  const ArticleBlock({
    required this.id,
    required this.title,
    required this.text,
    this.mediaId,
  });
  final String id, title, text;
  final String? mediaId;
  factory ArticleBlock.fromJson(Json j) => ArticleBlock(
    id: j['id'],
    title: j['title'],
    text: j['text'],
    mediaId: j['mediaId'],
  );
}

class AtlasArticle {
  const AtlasArticle({
    required this.id,
    required this.countryId,
    this.regionId = '',
    required this.sectionId,
    required this.title,
    required this.summary,
    required this.mediaId,
    required this.blocks,
    required this.term,
    required this.definition,
    required this.question,
    required this.answer,
    required this.sourceUrls,
    this.glossary = const [],
    this.diagram = '',
    this.activity = const {},
    this.exerciseId = '',
    this.placeId = '',
    this.mapFeatureId = '',
    this.readingMinutes = 4,
    this.revision = 1,
  });
  final String regionId;
  final String id,
      countryId,
      sectionId,
      title,
      summary,
      mediaId,
      term,
      definition,
      question,
      answer;
  final List<ArticleBlock> blocks;
  final List<String> sourceUrls;
  final List<Json> glossary;
  final String diagram, exerciseId, placeId, mapFeatureId;
  final Json activity;
  final int readingMinutes, revision;
  factory AtlasArticle.fromJson(Json j) => AtlasArticle(
    id: j['id'],
    countryId: j['countryId'] ?? '',
    regionId: j['regionId'] ?? '',
    sectionId: j['sectionId'],
    title: j['title'],
    summary: j['summary'],
    mediaId: j['mediaId'],
    blocks: (j['blocks'] as List).map((e) => ArticleBlock.fromJson(e)).toList(),
    term: j['term'] ?? '',
    definition: j['definition'] ?? '',
    question: j['question'] ?? '',
    answer: j['answer'] ?? '',
    sourceUrls: List<String>.from(j['sourceUrls'] ?? []),
    glossary: List<Json>.from(j['glossary'] ?? []),
    diagram: j['diagram'] ?? '',
    activity: Map<String, dynamic>.from(j['activity'] ?? {}),
    exerciseId: j['exerciseId'] ?? '',
    placeId: j['placeId'] ?? '',
    mapFeatureId: j['mapFeatureId'] ?? '',
    readingMinutes: j['readingMinutes'] ?? 4,
    revision: j['revision'] ?? 1,
  );
}

class AtlasPlace {
  const AtlasPlace({
    required this.id,
    required this.countryId,
    this.regionId = '',
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.summary,
    required this.description,
    required this.observation,
    required this.mediaIds,
    required this.sourceUrl,
    this.region = '',
    this.articleIds = const [],
    this.hotspots = const [],
    this.aliases = const [],
  });
  final String regionId;
  final String id,
      countryId,
      name,
      category,
      summary,
      description,
      observation,
      sourceUrl;
  final double latitude, longitude;
  final List<String> mediaIds;
  final String region;
  final List<String> articleIds, aliases;
  final List<Json> hotspots;
  factory AtlasPlace.fromJson(Json j) => AtlasPlace(
    id: j['id'],
    countryId: j['countryId'] ?? '',
    regionId: j['regionId'] ?? '',
    name: j['name'],
    category: j['category'],
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
    summary: j['summary'],
    description: j['description'],
    observation: j['observation'],
    mediaIds: List<String>.from(j['mediaIds'] ?? []),
    sourceUrl: j['sourceUrl'],
    region: j['region'] ?? '',
    articleIds: List<String>.from(j['articleIds'] ?? []),
    hotspots: List<Json>.from(j['hotspots'] ?? []),
    aliases: List<String>.from(j['aliases'] ?? []),
  );
}

class AtlasTopic {
  const AtlasTopic({
    required this.id,
    required this.title,
    required this.question,
    required this.description,
    required this.category,
    required this.mediaId,
    required this.articleIds,
  });
  final String id, title, question, description, category, mediaId;
  final List<String> articleIds;
  factory AtlasTopic.fromJson(Json j) => AtlasTopic(
    id: j['id'],
    title: j['title'],
    question: j['question'],
    description: j['description'],
    category: j['category'],
    mediaId: j['mediaId'],
    articleIds: List<String>.from(j['articleIds']),
  );
}

class AtlasExercise {
  const AtlasExercise({
    required this.id,
    required this.countryId,
    this.regionId = '',
    required this.articleId,
    required this.type,
    required this.question,
    required this.options,
    required this.answerId,
    required this.explanation,
    required this.hint,
    this.mediaId = '',
    this.mediaIds = const [],
    this.diagram = '',
    this.diagramStep = 0,
    this.mapScope = '',
    this.photoHotspots = const [],
    this.evidenceBlockIds = const [],
  });
  final String regionId;
  final String id,
      countryId,
      articleId,
      type,
      question,
      answerId,
      explanation,
      hint;
  final List<Json> options;
  final List<Json> photoHotspots;
  final String mediaId, diagram, mapScope;
  final int diagramStep;
  final List<String> mediaIds, evidenceBlockIds;
  factory AtlasExercise.fromJson(Json j) => AtlasExercise(
    id: j['id'],
    countryId: j['countryId'] ?? '',
    regionId: j['regionId'] ?? '',
    articleId: j['articleId'],
    type: j['type'],
    question: j['question'],
    options: List<Json>.from(j['options']),
    answerId: j['answerId'],
    explanation: j['explanation'],
    hint: j['hint'],
    mediaId: j['mediaId'] ?? '',
    mediaIds: List<String>.from(j['mediaIds'] ?? []),
    diagram: j['diagram'] ?? '',
    diagramStep: j['diagramStep'] ?? 0,
    mapScope: j['mapScope'] ?? '',
    photoHotspots: List<Json>.from(j['photoHotspots'] ?? []),
    evidenceBlockIds: List<String>.from(j['evidenceBlockIds'] ?? []),
  );
}

class SearchHit {
  const SearchHit({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.route,
    this.mediaId = '',
    this.countryId = '',
  });
  final String id, kind, title, subtitle, route, mediaId, countryId;
}

const countrySections = <String, String>{
  'overview': '国家名片',
  'geography': '地理与气候',
  'people': '人们与语言',
  'daily': '日常生活',
  'food': '饮食与物产',
  'culture': '艺术与节日',
  'landmarks': '城市与地标',
  'nature': '动物与生态',
  'history': '历史故事',
  'questions': '有趣问题',
};

class AtlasRegion {
  AtlasRegion.fromJson(Json j)
    : id = j['id'],
      name = j['name'],
      sections = List<Json>.from(j['sections']),
      journeys = List<Json>.from(j['journeys']),
      observations = List<Json>.from(j['observations']);
  final String id, name;
  final List<Json> sections, journeys, observations;
}
