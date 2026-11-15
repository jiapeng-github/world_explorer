import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_explorer/models/catalog.dart';

void main() {
  late Catalog catalog;

  setUpAll(() {
    catalog = Catalog.fromJson(
      jsonDecode(File('assets/content/catalog.json').readAsStringSync())
          as Map<String, dynamic>,
    );
  });

  test('each destination contains a complete readable learning journey', () {
    expect(catalog.countries.map((c) => c.id).toSet(), {
      'egypt',
      'china',
      'brazil',
    });
    expect(catalog.countries, hasLength(3));
    for (final country in catalog.countries) {
      expect(country.name.trim(), isNotEmpty);
      expect(country.facts, hasLength(8));
      expect(country.topics.map((t) => t.id).toSet(), {
        'geography',
        'nature',
        'people',
        'culture',
        'history',
        'explore',
      });
      expect(country.topics, hasLength(6));
      expect(country.story.paragraphs, hasLength(3));
      for (final text in [
        country.story.title,
        country.story.observation,
        country.story.prompt,
        ...country.story.paragraphs,
        ...country.topics.map((topic) => topic.body),
      ]) {
        expect(text.trim(), isNotEmpty, reason: country.id);
      }
      expect(
        File(country.heroAsset).existsSync(),
        isTrue,
        reason: 'Missing bundled illustration for ${country.id}',
      );
    }
  });

  test(
    'encyclopedia chapters and landmarks are complete, sourced and bundled',
    () {
      final allLandmarks = catalog.countries
          .expand((c) => c.landmarks)
          .toList();
      expect(allLandmarks.map((l) => l.id).toSet().length, allLandmarks.length);
      for (final c in catalog.countries) {
        expect(c.profile.intro, isNotEmpty);
        expect(c.profile.timeline, hasLength(4));
        expect(c.profile.takeaways, hasLength(3));
        expect(c.landmarks, hasLength(3));
        final photo = File(c.profile.photo.asset).readAsBytesSync();
        expect(photo.take(2), [
          0xff,
          0xd8,
        ], reason: 'Photo must be a real JPEG');
        expect(
          Uri.parse(c.profile.photo.licenseUrl).host,
          'creativecommons.org',
        );
        expect(c.profile.photo.credit, isNotEmpty);
        for (final topic in c.topics) {
          expect(topic.sections, hasLength(3));
          expect(topic.body, topic.sections.map((s) => s.body).join('\n\n'));
          expect(topic.term, isNotEmpty);
          expect(topic.definition, isNotEmpty);
          expect(topic.question, isNotEmpty);
          expect(topic.answer, isNotEmpty);
        }
        for (final l in c.landmarks) {
          expect(l.latitude, inInclusiveRange(-90, 90));
          expect(l.longitude, inInclusiveRange(-180, 180));
          expect(c.sources.map((s) => s.url), contains(l.sourceUrl));
          if (l.photoAsset != null) {
            expect(File(l.photoAsset!).existsSync(), isTrue);
          }
        }
      }
    },
  );

  test('all nine questions can be answered with a unique available option', () {
    final countryIds = catalog.countries.map((c) => c.id).toSet();
    final questions = catalog.countries.expand((c) => c.quiz).toList();
    expect(questions, hasLength(9));
    expect(questions.map((q) => q.id).toSet(), hasLength(questions.length));

    for (final country in catalog.countries) {
      expect(country.quiz, hasLength(3));
      expect(country.quiz.first.type, 'location');
      expect(country.quiz.first.answerId, country.id);
      expect(country.quiz.first.options.map((o) => o.id).toSet(), countryIds);
      for (final question in country.quiz) {
        expect(question.type, isIn(['location', 'choice']));
        final optionIds = question.options.map((o) => o.id).toList();
        expect(optionIds, hasLength(3));
        expect(optionIds.toSet(), hasLength(optionIds.length));
        expect(optionIds, contains(question.answerId));
        expect(question.question.trim(), isNotEmpty);
        expect(question.hint.trim(), isNotEmpty);
        expect(question.explanation.trim(), isNotEmpty);
      }
    }
  });

  test(
    'theme routes only lead to bundled destinations and existing artwork',
    () {
      final countryIds = catalog.countries.map((c) => c.id).toSet();
      expect(catalog.themes, hasLength(3));
      expect(catalog.themes.map((t) => t.id).toSet(), hasLength(3));
      for (final theme in catalog.themes) {
        expect(theme.countryIds, isNotEmpty);
        expect(theme.countryIds.toSet(), hasLength(theme.countryIds.length));
        expect(countryIds.containsAll(theme.countryIds), isTrue);
        expect(
          File(theme.asset).existsSync(),
          isTrue,
          reason: 'Missing artwork for theme ${theme.id}',
        );
      }
    },
  );

  test('representative map points are inside their destination regions', () {
    final egypt = catalog.country('egypt');
    expect(egypt.latitude, inInclusiveRange(22, 32));
    expect(egypt.longitude, inInclusiveRange(25, 35));
    final china = catalog.country('china');
    expect(china.latitude, inInclusiveRange(25, 45));
    expect(china.longitude, inInclusiveRange(90, 120));
    final brazil = catalog.country('brazil');
    expect(brazil.latitude, inInclusiveRange(-20, 0));
    expect(brazil.longitude, inInclusiveRange(-65, -40));

    for (final country in catalog.countries) {
      expect(country.latitude.isFinite, isTrue);
      expect(country.longitude.isFinite, isTrue);
      expect(country.latitude, inInclusiveRange(-90, 90));
      expect(country.longitude, inInclusiveRange(-180, 180));
    }
  });

  test('country facts retain traceable source URLs and valid review dates', () {
    final releaseReviewDate = DateTime(2026, 10, 26);
    for (final country in catalog.countries) {
      expect(country.sources, isNotEmpty);
      for (final source in country.sources) {
        final url = Uri.tryParse(source.url);
        expect(url, isNotNull, reason: source.title);
        expect(url!.scheme, 'https', reason: source.title);
        expect(url.host.contains('.'), isTrue, reason: source.title);
        expect(source.title.trim(), isNotEmpty);
        final date = DateTime.tryParse(source.checkedAt);
        expect(date, isNotNull, reason: source.title);
        expect(
          date!.isAfter(releaseReviewDate),
          isFalse,
          reason: 'Review date is after this content pack: ${source.title}',
        );
      }
    }
  });
}
