import 'package:flutter/widgets.dart';

import 'dart:convert';
import 'dart:typed_data';

import '../domain/atlas_content.dart';

import '../data/content/content_repository.dart';
import '../data/database/atlas_database.dart';
import '../data/database/user_repositories.dart';
import '../data/downloads/pack_repository.dart';
import '../data/speech/speech_repository.dart';

class AtlasServices {
  AtlasServices({
    required this.database,
    required this.content,
    required this.preferences,
    required this.journal,
    required this.packs,
    required this.speech,
  });
  final AtlasDatabase database;
  final ContentRepository content;
  final PreferencesRepository preferences;
  final JournalRepository journal;
  final PackRepository packs;
  final SpeechRepository speech;
  static Future<AtlasServices> load({
    AtlasDatabase? database,
    ContentRepository? content,
    SpeechRepository? speech,
    bool migrate = true,
  }) async {
    final db = database ?? AtlasDatabase.production();
    final data = content ?? await ContentRepository.load();
    if (migrate) await migrateLegacy(db, data);
    final preferences = PreferencesRepository(db),
        journal = JournalRepository(db);
    const endpoint = String.fromEnvironment('CONTENT_BASE_URL');
    final packs = PackRepository(
      db,
      baseUrl: endpoint.isEmpty
          ? null
          : Uri.parse(endpoint.endsWith('/') ? endpoint : '$endpoint/'),
    );
    packs.bundled
      ..clear()
      ..addAll(data.featured.map((country) => country.id));
    await Future.wait([preferences.load(), journal.load(), packs.load()]);
    Future<void> refreshDownloads() async {
      final installed = await db.rows('SELECT payload FROM pack_content');
      final files = await db.rows(
        'SELECT pack_id, path, bytes FROM pack_files',
      );
      data.applyDownloaded(
        installed
            .map((r) => jsonDecode(r['payload'] as String) as Json)
            .toList(),
        {
          for (final file in files)
            '${file['pack_id']}/${file['path']}': file['bytes'] as Uint8List,
        },
      );
      await journal.reconcileContent(data);
    }

    packs.onContentChanged = refreshDownloads;
    await refreshDownloads();
    return AtlasServices(
      database: db,
      content: data,
      preferences: preferences,
      journal: journal,
      packs: packs,
      speech: speech ?? SpeechRepository(),
    );
  }

  Future<void> dispose() async {
    preferences.dispose();
    journal.dispose();
    packs.dispose();
    speech.dispose();
    content.dispose();
    await database.close();
  }
}

class AtlasScope extends InheritedNotifier<ContentRepository> {
  AtlasScope({super.key, required this.services, required super.child})
    : super(notifier: services.content);
  final AtlasServices services;
  static AtlasServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AtlasScope>()!.services;
  @override
  bool updateShouldNotify(AtlasScope oldWidget) =>
      services != oldWidget.services;
}

extension AtlasContext on BuildContext {
  AtlasServices get atlas => AtlasScope.of(this);
}
