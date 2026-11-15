import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

class AtlasDatabase extends GeneratedDatabase {
  AtlasDatabase(super.executor);
  AtlasDatabase.production()
    : super(
        driftDatabase(
          name: 'world_atlas_v3',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.dart.js'),
          ),
        ),
      );

  @override
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      for (final statement in _schema) {
        await customStatement(statement);
      }
    },
  );

  static const _schema = [
    'CREATE TABLE preferences (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    'CREATE TABLE bookmarks (kind TEXT NOT NULL, entity_id TEXT NOT NULL, title TEXT NOT NULL, created_at TEXT NOT NULL, PRIMARY KEY(kind, entity_id))',
    'CREATE TABLE reading_progress (article_id TEXT PRIMARY KEY, block_id TEXT NOT NULL, fraction REAL NOT NULL DEFAULT 0, completed INTEGER NOT NULL DEFAULT 0, updated_at TEXT NOT NULL)',
    'CREATE TABLE notes (id TEXT PRIMARY KEY, kind TEXT NOT NULL, text TEXT NOT NULL, question TEXT NOT NULL, entity_id TEXT NOT NULL, title TEXT NOT NULL, updated_at TEXT NOT NULL)',
    'CREATE TABLE history (kind TEXT NOT NULL, entity_id TEXT NOT NULL, title TEXT NOT NULL, updated_at TEXT NOT NULL, PRIMARY KEY(kind, entity_id))',
    'CREATE TABLE pack_content (pack_id TEXT PRIMARY KEY, version TEXT NOT NULL, payload TEXT NOT NULL, hash TEXT NOT NULL, installed_at TEXT NOT NULL)',
    'CREATE TABLE pack_files (pack_id TEXT NOT NULL, path TEXT NOT NULL, bytes BLOB NOT NULL, PRIMARY KEY(pack_id, path))',
    'CREATE TABLE legacy_migrations (id TEXT PRIMARY KEY, payload TEXT NOT NULL, applied_at TEXT NOT NULL)',
    'CREATE TABLE exercise_attempts (exercise_id TEXT PRIMARY KEY, answer_id TEXT NOT NULL, correct INTEGER NOT NULL, updated_at TEXT NOT NULL)',
  ];

  Future<List<Map<String, dynamic>>> rows(
    String sql, [
    List<Object> args = const [],
  ]) async => (await customSelect(
    sql,
    variables: args.map((v) => Variable(v)).toList(),
  ).get()).map((r) => r.data).toList();
  Future<void> execute(String sql, [List<Object?> args = const []]) =>
      customStatement(sql, args);
  Future<Map<String, dynamic>> preferences() async => {
    for (final row in await rows('SELECT * FROM preferences'))
      row['key'] as String: jsonDecode(row['value'] as String),
  };
  Future<void> setPreference(String key, Object? value) => execute(
    'INSERT OR REPLACE INTO preferences(key,value) VALUES (?,?)',
    [key, jsonEncode(value)],
  );
}
