import 'dart:convert';

import 'package:flutter/services.dart';

class Catalog {
  const Catalog({required this.countries, required this.themes});
  final List<Country> countries;
  final List<JourneyTheme> themes;
  Country country(String id) => countries.firstWhere((c) => c.id == id);
  static Future<Catalog> load() async => Catalog.fromJson(
    jsonDecode(await rootBundle.loadString('assets/content/catalog.json'))
        as Map<String, dynamic>,
  );
  factory Catalog.fromJson(Map<String, dynamic> json) => Catalog(
    countries: (json['countries'] as List)
        .map((e) => Country.fromJson(e as Map<String, dynamic>))
        .toList(),
    themes: (json['themes'] as List? ?? [])
        .map((e) => JourneyTheme.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class Country {
  const Country({
    required this.id,
    required this.name,
    required this.englishName,
    required this.continent,
    required this.greeting,
    required this.subtitle,
    required this.question,
    required this.latitude,
    required this.longitude,
    required this.color,
    required this.heroAsset,
    required this.flagEmoji,
    required this.facts,
    required this.topics,
    required this.story,
    required this.quiz,
    required this.sources,
    required this.profile,
    required this.landmarks,
  });
  final String id,
      name,
      englishName,
      continent,
      greeting,
      subtitle,
      question,
      color,
      heroAsset,
      flagEmoji;
  final double latitude, longitude;
  final List<CountryFact> facts;
  final List<CountryTopic> topics;
  final CountryStory story;
  final List<QuizQuestion> quiz;
  final List<ContentSource> sources;
  final CountryProfile profile;
  final List<Landmark> landmarks;
  factory Country.fromJson(Map<String, dynamic> j) => Country(
    id: j['id'],
    profile: CountryProfile.fromJson(j['profile']),
    landmarks: (j['landmarks'] as List)
        .map((e) => Landmark.fromJson(e))
        .toList(),
    name: j['name'],
    englishName: j['englishName'],
    continent: j['continent'],
    greeting: j['greeting'],
    subtitle: j['subtitle'],
    question: j['question'],
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
    color: j['color'],
    heroAsset: j['heroAsset'],
    flagEmoji: j['flagEmoji'],
    facts: (j['facts'] as List)
        .map((e) => CountryFact(e['label'], e['value']))
        .toList(),
    topics: (j['topics'] as List).map((e) => CountryTopic.fromJson(e)).toList(),
    story: CountryStory.fromJson(j['story']),
    quiz: (j['quiz'] as List).map((e) => QuizQuestion.fromJson(e)).toList(),
    sources: (j['sources'] as List)
        .map((e) => ContentSource(e['title'], e['url'], e['checkedAt']))
        .toList(),
  );
}

class CountryFact {
  const CountryFact(this.label, this.value);
  final String label, value;
}

class CountryTopic {
  const CountryTopic({
    required this.id,
    required this.title,
    required this.icon,
    required this.summary,
    required this.body,
    required this.sections,
    required this.term,
    required this.definition,
    required this.question,
    required this.answer,
  });
  final String id,
      title,
      icon,
      summary,
      body,
      term,
      definition,
      question,
      answer;
  final List<ArticleSection> sections;
  factory CountryTopic.fromJson(Map<String, dynamic> j) => CountryTopic(
    id: j['id'],
    title: j['title'],
    icon: j['icon'],
    summary: j['summary'],
    body: j['body'],
    sections: (j['sections'] as List)
        .map((e) => ArticleSection(e['title'], e['body']))
        .toList(),
    term: j['glossary']['term'],
    definition: j['glossary']['definition'],
    question: j['question'],
    answer: j['answer'],
  );
}

class CountryStory {
  const CountryStory({
    required this.title,
    required this.paragraphs,
    required this.observation,
    required this.prompt,
  });
  final String title, observation, prompt;
  final List<String> paragraphs;
  factory CountryStory.fromJson(Map<String, dynamic> j) => CountryStory(
    title: j['title'],
    paragraphs: List<String>.from(j['paragraphs']),
    observation: j['observation'],
    prompt: j['prompt'],
  );
}

class QuizOption {
  const QuizOption(this.id, this.text);
  final String id, text;
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.type,
    required this.question,
    required this.hint,
    required this.options,
    required this.answerId,
    required this.explanation,
  });
  final String id, type, question, hint, answerId, explanation;
  final List<QuizOption> options;
  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
    id: j['id'],
    type: j['type'],
    question: j['question'],
    hint: j['hint'],
    options: (j['options'] as List)
        .map((e) => QuizOption(e['id'], e['text']))
        .toList(),
    answerId: j['answerId'],
    explanation: j['explanation'],
  );
}

class ContentSource {
  const ContentSource(this.title, this.url, this.checkedAt);
  final String title, url, checkedAt;
}

class JourneyTheme {
  const JourneyTheme({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.countryIds,
    required this.asset,
    required this.icon,
  });
  final String id, title, subtitle, asset, icon;
  final List<String> countryIds;
  factory JourneyTheme.fromJson(Map<String, dynamic> j) => JourneyTheme(
    id: j['id'],
    title: j['title'],
    subtitle: j['subtitle'],
    countryIds: List<String>.from(j['countryIds']),
    asset: j['asset'],
    icon: j['icon'],
  );
}

class ArticleSection {
  const ArticleSection(this.title, this.body);
  final String title, body;
}

class CountryPhoto {
  const CountryPhoto({
    required this.asset,
    required this.caption,
    required this.credit,
    required this.license,
    required this.licenseUrl,
    required this.sourceUrl,
  });
  final String asset, caption, credit, license, licenseUrl, sourceUrl;
  factory CountryPhoto.fromJson(Map<String, dynamic> j) => CountryPhoto(
    asset: j['asset'],
    caption: j['caption'],
    credit: j['credit'],
    license: j['license'],
    licenseUrl: j['licenseUrl'],
    sourceUrl: j['sourceUrl'],
  );
}

class TimelineEvent {
  const TimelineEvent(this.period, this.title, this.body);
  final String period, title, body;
}

class CountryProfile {
  const CountryProfile({
    required this.intro,
    required this.tagline,
    required this.capital,
    required this.localName,
    required this.takeaways,
    required this.photo,
    required this.timeline,
  });
  final String intro, tagline, capital, localName;
  final List<String> takeaways;
  final CountryPhoto photo;
  final List<TimelineEvent> timeline;
  factory CountryProfile.fromJson(Map<String, dynamic> j) => CountryProfile(
    intro: j['intro'],
    tagline: j['tagline'],
    capital: j['capital'],
    localName: j['localName'],
    takeaways: List<String>.from(j['takeaways']),
    photo: CountryPhoto.fromJson(j['photo']),
    timeline: (j['timeline'] as List)
        .map((e) => TimelineEvent(e['period'], e['title'], e['body']))
        .toList(),
  );
}

class Landmark {
  const Landmark({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.teaser,
    required this.description,
    required this.observation,
    required this.photoAsset,
    required this.sourceUrl,
  });
  final String id, name, category, teaser, description, observation, sourceUrl;
  final String? photoAsset;
  final double latitude, longitude;
  factory Landmark.fromJson(Map<String, dynamic> j) => Landmark(
    id: j['id'],
    name: j['name'],
    category: j['category'],
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
    teaser: j['teaser'],
    description: j['description'],
    observation: j['observation'],
    photoAsset: j['photoAsset'],
    sourceUrl: j['sourceUrl'],
  );
}
