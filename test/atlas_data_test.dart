import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:world_explorer/data/content/content_repository.dart';
import 'package:world_explorer/data/database/atlas_database.dart';
import 'package:world_explorer/data/database/user_repositories.dart';
import 'package:world_explorer/data/downloads/pack_repository.dart';
import 'package:world_explorer/domain/atlas_content.dart';
import 'package:world_explorer/map_engine/atlas_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AtlasDatabase db;
  late ContentRepository content;
  late JournalRepository journal;
  setUp(() async {
    db = AtlasDatabase(NativeDatabase.memory());
    content = ContentRepository.fromJson(
      jsonDecode(File('assets/atlas/catalog.json').readAsStringSync()),
    );
    journal = JournalRepository(db);
    await journal.load();
  });
  tearDown(() async {
    journal.dispose();
    content.dispose();
    await db.close();
  });

  test(
    'every content reference points to bundled content and an existing asset',
    () {
      expect(content.countries.length, greaterThanOrEqualTo(170));
      expect(
        content.articles.map((a) => a.id).toSet().length,
        content.articles.length,
      );
      for (final c in content.countries) {
        for (final id in c.sections.values.expand((e) => e)) {
          expect(content.article(id)?.countryId, c.id, reason: '${c.id} → $id');
        }
      }
      for (final a in content.articles) {
        expect(a.blocks, isNotEmpty);
        expect(a.sourceUrls, isNotEmpty);
        expect(content.country(a.countryId), isNotNull);
        expect(content.media[a.mediaId], isNotNull);
      }
      for (final m in content.media.values) {
        expect(File(m.asset).existsSync(), isTrue, reason: m.asset);
        expect(m.sourceUrl, startsWith('https://'));
        expect(m.license, isNotEmpty);
      }
      for (final t in content.topics) {
        for (final id in t.articleIds) {
          expect(content.article(id), isNotNull);
        }
      }
      for (final e in content.exercises) {
        expect(content.article(e.articleId), isNotNull);
        expect(e.options.any((o) => o['id'] == e.answerId), isTrue);
      }
    },
  );
  test(
    'Nile search finds country, place, article and topic with real routes',
    () {
      final hits = content.search('尼罗河');
      expect(
        hits.map((h) => h.kind).toSet(),
        containsAll(['国家', '地点', '文章', '专题']),
      );
      expect(content.search('not-a-country-zzzz'), isEmpty);
      expect(content.search('Egypt').first.id, 'egypt');
      expect(
        content.search('尼罗河', kind: '文章').every((h) => h.kind == '文章'),
        isTrue,
      );
    },
  );
  test('legacy migration is transactional and idempotent, preserving original data', () async {
    final legacy = <String, dynamic>{
      'onboarded': true,
      'nickname': '小探索家',
      'favorites': ['egypt'],
      'visited': ['china'],
      'readTopics': ['china/geography'],
      'completed': ['egypt'],
      'questions': [
        {
          'id': 'q-1',
          'text': '为什么有沙漠？',
          'countryId': 'egypt',
          'createdAt': '2026-10-26T12:00:00',
        },
      ],
    };
    await migrateLegacy(db, content, legacy: legacy);
    await migrateLegacy(db, content, legacy: legacy);
    await journal.load();
    expect(journal.bookmarks.single['entity_id'], 'egypt');
    expect(journal.notes.single['question'], '为什么有沙漠？');
    expect(journal.progress['china-geography']?['completed'], 1);
    expect((await db.preferences())['nickname'], '小探索家');
    final rows = await db.rows('SELECT payload FROM legacy_migrations');
    expect(rows.length, 1);
    expect(jsonDecode(rows.single['payload'])['completed'], ['egypt']);
  });
  test(
    'backup merge preserves conflicting notes and never embeds earlier backups',
    () async {
      await journal.saveNote(
        id: 'n1',
        kind: 'discovery',
        text: '本机的发现',
        question: '',
        entityId: 'egypt-nature',
        title: '河流',
      );
      await journal.toggle('article', 'egypt-nature', '河流');
      final backup = JournalRepository.validateBackup(
        jsonEncode(await journal.backup()),
      );
      backup['notes'][0]['text'] = '另一台设备的发现';
      await journal.restore(backup, replace: false);
      expect(journal.notes.length, 2);
      expect(journal.bookmarks.length, 1);
      expect(
        journal.notes.map((n) => n['text']),
        containsAll(['本机的发现', '另一台设备的发现']),
      );
      final exported = await journal.backup();
      expect(
        (exported['preferences'] as Json).containsKey('backup-before-import'),
        isFalse,
      );
      await journal.restore(exported, replace: true);
      expect(journal.notes.length, 2);
    },
  );
  test('malformed backup fails before modifying personal records', () async {
    await journal.toggle('country', 'china', '中国');
    final backup = await journal.backup();
    backup['preferences'] = {'textScale': 'huge'};
    expect(
      () => JournalRepository.validateBackup(jsonEncode(backup)),
      throwsFormatException,
    );
    expect(journal.bookmarks.length, 1);
  });
  test('reading progress and notes survive repository recreation', () async {
    await journal.recordReading('egypt-nature', 'egypt-nature-b2', .45);
    await journal.answer('egypt-water', 'water', true);
    final reopened = JournalRepository(db);
    await reopened.load();
    expect(reopened.progress['egypt-nature']?['fraction'], .45);
    expect(reopened.attempts['egypt-water']?['correct'], 1);
    reopened.dispose();
  });
  test('map projection and polygon holes preserve geographic selection', () {
    expect(project(0, 0), const Offset(900, 450));
    final path = AtlasGeometry.path({
      'type': 'Polygon',
      'coordinates': [
        [
          [0, 0],
          [10, 0],
          [10, 10],
          [0, 10],
          [0, 0],
        ],
        [
          [3, 3],
          [7, 3],
          [7, 7],
          [3, 7],
          [3, 3],
        ],
      ],
    });
    expect(path.contains(project(1, 1)), isTrue);
    expect(path.contains(project(5, 5)), isFalse);
  });
  test('content package paths reject traversal and external URLs', () {
    for (final path in [
      '../secret',
      '/secret',
      'https://example.com/a',
      'foo/../../a',
      '%2e%2e/a',
      r'foo\bar',
      'media.jpg?x=1',
    ]) {
      expect(
        () => PackRepository.validatePath(path),
        throwsFormatException,
        reason: path,
      );
    }
    PackRepository.validatePath('media/photo.jpg');
  });
  test(
    'verified package installs atomically; bad updates keep working version',
    () async {
      final baseCountry = Map<String, dynamic>.from(
        content.raw['countries'].firstWhere((j) => j['id'] == 'japan'),
      );
      baseCountry['sections'] = {
        'geography': ['japan-test'],
      };
      final article = Map<String, dynamic>.from(content.raw['articles'].first)
        ..['id'] = 'japan-test'
        ..['countryId'] = 'japan';
      final payload = jsonEncode({
        'country': baseCountry,
        'articles': [article],
        'places': [],
        'media': [],
        'exercises': [],
      });
      final bytes = utf8.encode(payload);
      var valid = true;
      final packs = PackRepository(
        db,
        baseUrl: Uri.parse('https://content.test/packs/'),
        client: MockClient((request) async {
          if (request.url.path.endsWith('manifest.json')) {
            return http.Response(
              jsonEncode({
                'schemaVersion': 1,
                'packId': 'japan',
                'contentVersion': '1',
                'files': [
                  {
                    'path': 'articles.json',
                    'bytes': bytes.length,
                    'sha256': valid
                        ? sha256.convert(bytes).toString()
                        : 'bad-hash',
                  },
                ],
              }),
              200,
            );
          }
          return http.Response.bytes(bytes, 200);
        }),
      );
      await packs.install('japan');
      expect(packs.installed('japan'), isTrue);
      expect((await db.rows('SELECT * FROM pack_content')).length, 1);
      valid = false;
      await packs.install('japan');
      expect(packs.installed('japan'), isTrue);
      expect(packs.states['japan']?.error, contains('原有内容'));
      expect(
        (await db.rows('SELECT payload FROM pack_content')).single['payload'],
        payload,
      );
      await journal.saveNote(
        id: 'pack-note',
        kind: 'discovery',
        text: '这是一条发现',
        question: '',
        entityId: 'japan-test',
        title: '日本',
      );
      await packs.remove('japan');
      expect(await db.rows('SELECT * FROM pack_content'), isEmpty);
      expect(journal.notes.length, 1);
      packs.dispose();
    },
  );
  test('downloaded articles become searchable and removal restores bundled catalog', () {
    final country = Map<String, dynamic>.from(
      content.raw['countries'].firstWhere((j) => j['id'] == 'japan'),
    );
    country['sections'] = {
      'geography': ['japan-test'],
    };
    final article = Map<String, dynamic>.from(content.raw['articles'].first)
      ..['id'] = 'japan-test'
      ..['countryId'] = 'japan'
      ..['title'] = '测试新知识';
    content.applyDownloaded([
      {
        'country': country,
        'articles': [article],
      },
    ], <String, Uint8List>{});
    expect(content.search('测试新知识').single.id, 'japan-test');
    content.applyDownloaded([], {});
    expect(content.article('japan-test'), isNull);
  });
}
