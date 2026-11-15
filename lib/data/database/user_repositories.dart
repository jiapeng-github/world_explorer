import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/atlas_content.dart';
import '../content/content_repository.dart';
import 'atlas_database.dart';

class PreferencesRepository extends ChangeNotifier {
  PreferencesRepository(this.database);
  final AtlasDatabase database;
  Map<String, dynamic> values = {};
  bool get onboarded => values['onboarded'] == true;
  String get nickname => values['nickname'] as String? ?? '小小探索家';
  double get textScale =>
      ((values['textScale'] as num?)?.toDouble() ?? 1).clamp(1, 1.6);
  double get speechRate =>
      ((values['speechRate'] as num?)?.toDouble() ?? .45).clamp(.25, .65);
  int get breakMinutes => (values['breakMinutes'] as int? ?? 20).clamp(5, 60);
  bool get breakEnabled => values['breakEnabled'] != false;
  String get readingBackground =>
      values['readingBackground'] as String? ?? 'white';
  List<String> get interests => List<String>.from(values['interests'] ?? []);
  Future<void> load() async {
    values = await database.preferences();
    notifyListeners();
  }

  Future<void> set(String key, Object? value) async {
    await database.setPreference(key, value);
    values[key] = value;
    notifyListeners();
  }

  Future<void> onboard(List<String> interests) async {
    await database.transaction(() async {
      await database.setPreference('interests', interests);
      await database.setPreference('onboarded', true);
    });
    await load();
  }
}

class JournalRepository extends ChangeNotifier {
  JournalRepository(this.database);
  final AtlasDatabase database;
  List<Json> bookmarks = [], notes = [], history = [];
  Map<String, Json> progress = {}, attempts = {};
  Future<void> load() async {
    bookmarks = await database.rows(
      'SELECT * FROM bookmarks ORDER BY created_at DESC',
    );
    notes = await database.rows('SELECT * FROM notes ORDER BY updated_at DESC');
    history = await database.rows(
      'SELECT * FROM history ORDER BY updated_at DESC',
    );
    progress = {
      for (final r in await database.rows(
        'SELECT * FROM reading_progress ORDER BY updated_at DESC',
      ))
        r['article_id'] as String: r,
    };
    attempts = {
      for (final r in await database.rows('SELECT * FROM exercise_attempts'))
        r['exercise_id'] as String: r,
    };
    notifyListeners();
  }

  bool saved(String kind, String id) =>
      bookmarks.any((b) => b['kind'] == kind && b['entity_id'] == id);

  /// A rewritten article must not inherit a completion flag for unrelated text.
  /// Keep the old progress snapshot; bookmarks and notes retain their stable IDs.
  Future<void> reconcileContent(ContentRepository content) async {
    final stale = progress.entries.where((entry) {
      final article = content.article(entry.key);
      return article != null &&
          article.revision > 1 &&
          article.blocks.isNotEmpty &&
          !article.blocks.any((block) => block.id == entry.value['block_id']);
    }).toList();
    if (stale.isEmpty) return;
    await database.transaction(() async {
      for (final entry in stale) {
        final article = content.article(entry.key)!;
        await database.setPreference(
          'reading-archive-${entry.key}-${entry.value['block_id']}',
          entry.value,
        );
        await database.execute(
          'UPDATE reading_progress SET block_id=?, fraction=0, completed=0 WHERE article_id=?',
          [article.blocks.first.id, article.id],
        );
      }
    });
    await load();
  }

  Future<void> toggle(String kind, String id, String title) async {
    if (saved(kind, id)) {
      await database.execute(
        'DELETE FROM bookmarks WHERE kind=? AND entity_id=?',
        [kind, id],
      );
    } else {
      await database.execute(
        'INSERT OR REPLACE INTO bookmarks VALUES (?,?,?,?)',
        [kind, id, title, DateTime.now().toIso8601String()],
      );
    }
    await load();
  }

  Future<void> visit(String kind, String id, String title) async {
    await database.execute('INSERT OR REPLACE INTO history VALUES (?,?,?,?)', [
      kind,
      id,
      title,
      DateTime.now().toIso8601String(),
    ]);
    await load();
  }

  Future<void> recordReading(
    String id,
    String block,
    double fraction, {
    bool? completed,
  }) async {
    final done = completed ?? (progress[id]?['completed'] == 1);
    await database.execute(
      'INSERT OR REPLACE INTO reading_progress VALUES (?,?,?,?,?)',
      [
        id,
        block,
        fraction.clamp(0, 1),
        done ? 1 : 0,
        DateTime.now().toIso8601String(),
      ],
    );
    await load();
  }

  Future<void> saveNote({
    required String id,
    required String kind,
    required String text,
    required String question,
    required String entityId,
    required String title,
  }) async {
    if (text.trim().isEmpty && question.trim().isEmpty) {
      throw const FormatException('先写下一个发现或问题吧');
    }
    await database.execute(
      'INSERT OR REPLACE INTO notes VALUES (?,?,?,?,?,?,?)',
      [
        id,
        kind,
        text.trim(),
        question.trim(),
        entityId,
        title,
        DateTime.now().toIso8601String(),
      ],
    );
    await load();
  }

  Future<void> deleteNote(String id, {String? draftKey}) async {
    await database.transaction(() async {
      await database.execute('DELETE FROM notes WHERE id=?', [id]);
      if (draftKey != null) {
        await database.execute('DELETE FROM preferences WHERE key=?', [
          draftKey,
        ]);
      }
    });
    await load();
  }

  Future<void> answer(String id, String answerId, bool correct) async {
    await database.execute(
      'INSERT OR REPLACE INTO exercise_attempts VALUES (?,?,?,?)',
      [id, answerId, correct ? 1 : 0, DateTime.now().toIso8601String()],
    );
    await load();
  }

  Future<Json> backup() async => {
    'formatVersion': 1,
    'appVersion': '0.3.0',
    'exportedAt': DateTime.now().toIso8601String(),
    'preferences': {
      for (final entry in (await database.preferences()).entries)
        if ([
          'nickname',
          'interests',
          'textScale',
          'speechRate',
          'breakMinutes',
          'breakEnabled',
          'readingBackground',
          'onboarded',
        ].contains(entry.key))
          entry.key: entry.value,
    },
    'bookmarks': await database.rows('SELECT * FROM bookmarks'),
    'readingProgress': await database.rows('SELECT * FROM reading_progress'),
    'notes': await database.rows('SELECT * FROM notes'),
    'history': await database.rows('SELECT * FROM history'),
    'exerciseAttempts': await database.rows('SELECT * FROM exercise_attempts'),
  };
  static Json validateBackup(String source) {
    if (source.length > 10000000) throw const FormatException('备份文件过大');
    final j = jsonDecode(source);
    if (j is! Json || j['formatVersion'] != 1) {
      throw const FormatException('这不是支持的世界大百科备份');
    }
    for (final key in ['bookmarks', 'readingProgress', 'notes', 'history']) {
      if (j[key] is! List || (j[key] as List).any((e) => e is! Json)) {
        throw FormatException('备份中的 $key 格式有误');
      }
    }
    if (j['preferences'] is! Json) throw const FormatException('阅读设置格式有误');
    final prefs = j['preferences'] as Json;
    for (final key in ['textScale', 'speechRate', 'breakMinutes']) {
      if (prefs.containsKey(key) &&
          (prefs[key] is! num || !(prefs[key] as num).isFinite)) {
        throw const FormatException('阅读设置数值无效');
      }
    }
    if (prefs.containsKey('breakMinutes') && prefs['breakMinutes'] is! int) {
      throw const FormatException('提醒间隔格式有误');
    }
    for (final key in ['onboarded', 'breakEnabled']) {
      if (prefs.containsKey(key) && prefs[key] is! bool) {
        throw const FormatException('阅读设置开关格式有误');
      }
    }
    for (final key in ['nickname', 'readingBackground']) {
      if (prefs.containsKey(key) && prefs[key] is! String) {
        throw const FormatException('阅读设置文字格式有误');
      }
    }
    if (prefs.containsKey('interests') &&
        (prefs['interests'] is! List ||
            (prefs['interests'] as List).any((e) => e is! String))) {
      throw const FormatException('兴趣格式有误');
    }
    for (final n in j['notes']) {
      for (final key in [
        'id',
        'kind',
        'text',
        'question',
        'entity_id',
        'title',
        'updated_at',
      ]) {
        if (n[key] is! String) throw const FormatException('笔记内容格式有误');
      }
    }
    for (final b in j['bookmarks']) {
      for (final key in ['kind', 'entity_id', 'title', 'created_at']) {
        if (b[key] is! String) throw const FormatException('收藏格式有误');
      }
    }
    for (final h in j['history']) {
      for (final key in ['kind', 'entity_id', 'title', 'updated_at']) {
        if (h[key] is! String) throw const FormatException('足迹格式有误');
      }
    }
    for (final p in j['readingProgress']) {
      if (p['article_id'] is! String ||
          p['block_id'] is! String ||
          p['fraction'] is! num ||
          !(p['fraction'] as num).isFinite ||
          p['updated_at'] is! String ||
          ![0, 1].contains(p['completed'])) {
        throw const FormatException('阅读进度格式有误');
      }
    }
    for (final key in ['notes', 'history', 'readingProgress', 'bookmarks']) {
      final timestamp = key == 'bookmarks' ? 'created_at' : 'updated_at';
      for (final row in j[key]) {
        if (DateTime.tryParse(row[timestamp]) == null) {
          throw const FormatException('记录时间格式有误');
        }
      }
    }
    if (j.containsKey('exerciseAttempts')) {
      final attempts = j['exerciseAttempts'];
      if (attempts is! List ||
          attempts.any(
            (a) =>
                a is! Json ||
                a['exercise_id'] is! String ||
                a['answer_id'] is! String ||
                ![0, 1].contains(a['correct']) ||
                a['updated_at'] is! String ||
                DateTime.tryParse(a['updated_at']) == null,
          )) {
        throw const FormatException('互动记录格式有误');
      }
    }
    return j;
  }

  Future<void> restore(Json j, {required bool replace}) async {
    validateBackup(jsonEncode(j));
    final before = await backup();
    await database.transaction(() async {
      await database.setPreference('backup-before-import', before);
      if (replace) {
        for (final table in [
          'bookmarks',
          'reading_progress',
          'notes',
          'history',
          'exercise_attempts',
        ]) {
          await database.execute('DELETE FROM $table');
        }
      }
      for (final b in j['bookmarks']) {
        await database.execute(
          'INSERT OR IGNORE INTO bookmarks VALUES (?,?,?,?)',
          [b['kind'], b['entity_id'], b['title'], b['created_at']],
        );
      }
      for (final h in j['history']) {
        await database.execute(
          'INSERT INTO history VALUES (?,?,?,?) ON CONFLICT(kind, entity_id) DO UPDATE SET title=excluded.title, updated_at=excluded.updated_at WHERE julianday(excluded.updated_at) > julianday(history.updated_at)',
          [h['kind'], h['entity_id'], h['title'], h['updated_at']],
        );
      }
      for (final p in j['readingProgress']) {
        await database.execute(
          'INSERT INTO reading_progress VALUES (?,?,?,?,?) ON CONFLICT(article_id) DO UPDATE SET block_id=CASE WHEN julianday(excluded.updated_at) > julianday(reading_progress.updated_at) THEN excluded.block_id ELSE reading_progress.block_id END, fraction=CASE WHEN julianday(excluded.updated_at) > julianday(reading_progress.updated_at) THEN excluded.fraction ELSE reading_progress.fraction END, completed=MAX(reading_progress.completed, excluded.completed), updated_at=CASE WHEN julianday(excluded.updated_at) > julianday(reading_progress.updated_at) THEN excluded.updated_at ELSE reading_progress.updated_at END',
          [
            p['article_id'],
            p['block_id'],
            (p['fraction'] as num).clamp(0, 1),
            p['completed'],
            p['updated_at'],
          ],
        );
      }
      for (final a in j['exerciseAttempts'] as List? ?? []) {
        await database.execute(
          'INSERT INTO exercise_attempts VALUES (?,?,?,?) ON CONFLICT(exercise_id) DO UPDATE SET answer_id=excluded.answer_id, correct=excluded.correct, updated_at=excluded.updated_at WHERE julianday(excluded.updated_at) > julianday(exercise_attempts.updated_at)',
          [a['exercise_id'], a['answer_id'], a['correct'], a['updated_at']],
        );
      }
      for (final n in j['notes']) {
        var id = n['id'] as String;
        final conflict = await database.rows('SELECT * FROM notes WHERE id=?', [
          id,
        ]);
        if (conflict.isNotEmpty) {
          final matching = await database.rows(
            'SELECT id FROM notes WHERE (id=? OR id LIKE ?) AND kind=? AND text=? AND question=? AND entity_id=? AND title=?',
            [
              id,
              '$id-import-%',
              n['kind'],
              n['text'],
              n['question'],
              n['entity_id'],
              n['title'],
            ],
          );
          if (matching.isNotEmpty) {
            continue;
          }
          id = '$id-import-${DateTime.now().microsecondsSinceEpoch}';
        }
        await database.execute('INSERT INTO notes VALUES (?,?,?,?,?,?,?)', [
          id,
          n['kind'],
          n['text'],
          n['question'],
          n['entity_id'],
          n['title'],
          n['updated_at'],
        ]);
      }
      if (replace) {
        for (final key in [
          'nickname',
          'interests',
          'textScale',
          'speechRate',
          'breakMinutes',
          'breakEnabled',
          'readingBackground',
          'onboarded',
        ]) {
          if ((j['preferences'] as Json).containsKey(key)) {
            await database.setPreference(key, j['preferences'][key]);
          } else {
            await database.execute('DELETE FROM preferences WHERE key=?', [
              key,
            ]);
          }
        }
      }
    });
    await load();
  }
}

Future<void> migrateLegacy(
  AtlasDatabase db,
  ContentRepository content, {
  Json? legacy,
}) async {
  if ((await db.rows('SELECT id FROM legacy_migrations WHERE id=?', [
    'progress-v1',
  ])).isNotEmpty) {
    return;
  }
  final Json j;
  if (legacy != null) {
    j = legacy;
  } else {
    final source = await SharedPreferencesAsync().getString(
      'world_explorer.progress.v1',
    );
    j = source == null ? {} : jsonDecode(source) as Json;
  }
  final now = DateTime.now().toIso8601String();
  await db.transaction(() async {
    for (final key in [
      'nickname',
      'onboarded',
      'textScale',
      'speechRate',
      'breakMinutes',
    ]) {
      if (j.containsKey(key)) await db.setPreference(key, j[key]);
    }
    for (final id in j['favorites'] as List? ?? []) {
      await db.execute('INSERT OR IGNORE INTO bookmarks VALUES (?,?,?,?)', [
        'country',
        id,
        content.country(id)?.name ?? id,
        now,
      ]);
    }
    for (final id in j['visited'] as List? ?? []) {
      await db.execute('INSERT OR IGNORE INTO history VALUES (?,?,?,?)', [
        'country',
        id,
        content.country(id)?.name ?? id,
        now,
      ]);
    }
    for (final old in j['readTopics'] as List? ?? []) {
      final id = (old as String).replaceAll('/', '-');
      final a = content.article(id);
      if (a != null) {
        await db.execute(
          'INSERT OR IGNORE INTO reading_progress VALUES (?,?,?,?,?)',
          [id, a.blocks.last.id, 1, 1, now],
        );
      }
    }
    for (final q in j['questions'] as List? ?? []) {
      await db.execute('INSERT OR IGNORE INTO notes VALUES (?,?,?,?,?,?,?)', [
        q['id'],
        'question',
        '',
        q['text'],
        q['countryId'],
        content.country(q['countryId'])?.name ?? q['countryId'],
        q['createdAt'],
      ]);
    }
    await db.execute('INSERT INTO legacy_migrations VALUES (?,?,?)', [
      'progress-v1',
      jsonEncode(j),
      now,
    ]);
  });
}
