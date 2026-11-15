import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_explorer/app/atlas_app.dart';
import 'package:world_explorer/app/services.dart';
import 'package:world_explorer/data/content/content_repository.dart';
import 'package:world_explorer/data/database/atlas_database.dart';
import 'package:world_explorer/data/database/user_repositories.dart';
import 'package:world_explorer/data/speech/speech_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AtlasDatabase database;
  late JournalRepository journal;
  setUp(() async {
    database = AtlasDatabase(NativeDatabase.memory());
    journal = JournalRepository(database);
    await journal.load();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (call) async => call.method == 'isLanguageAvailable' ? true : 1,
        );
  });
  tearDown(() async {
    journal.dispose();
    await database.close();
  });

  test(
    'backup is an independent snapshot and includes understanding answers',
    () async {
      await journal.saveNote(
        id: 'n',
        kind: 'discovery',
        text: '原笔记',
        question: '',
        entityId: 'giza',
        title: '金字塔',
      );
      await journal.answer('egypt-water', 'water', true);
      final backup = jsonDecode(jsonEncode(await journal.backup()));
      backup['notes'][0]['text'] = '修改备份';
      expect(journal.notes.single['text'], '原笔记');
      await journal.restore(backup, replace: true);
      expect(journal.notes.single['text'], '修改备份');
      expect(journal.attempts['egypt-water']?['correct'], 1);
      backup.remove('exerciseAttempts');
      expect(
        () => JournalRepository.validateBackup(jsonEncode(backup)),
        returnsNormally,
      );
    },
  );

  test(
    'merge uses most recent location and preserves completed reading',
    () async {
      await database.execute(
        'INSERT INTO reading_progress VALUES (?,?,?,?,?)',
        ['egypt-nature', 'b1', .3, 1, '2026-11-05T12:00:00Z'],
      );
      await database.execute('INSERT INTO history VALUES (?,?,?,?)', [
        'article',
        'egypt-nature',
        '旧标题',
        '2026-11-05T12:00:00Z',
      ]);
      await journal.load();
      final backup = jsonDecode(jsonEncode(await journal.backup()));
      backup['readingProgress'][0].addAll({
        'block_id': 'b3',
        'fraction': .8,
        'completed': 0,
        'updated_at': '2026-11-06T12:00:00Z',
      });
      backup['history'][0].addAll({
        'title': '新标题',
        'updated_at': '2026-11-06T12:00:00Z',
      });
      await journal.restore(backup, replace: false);
      expect(journal.progress['egypt-nature']?['block_id'], 'b3');
      expect(journal.progress['egypt-nature']?['completed'], 1);
      expect(journal.history.single['title'], '新标题');
      backup['readingProgress'][0].addAll({
        'block_id': 'b0',
        'updated_at': '2026-11-04T12:00:00Z',
      });
      await journal.restore(backup, replace: false);
      expect(journal.progress['egypt-nature']?['block_id'], 'b3');
    },
  );

  test(
    'repeated merge does not duplicate a conflicting imported note',
    () async {
      await journal.saveNote(
        id: 'n',
        kind: 'discovery',
        text: '本机',
        question: '',
        entityId: 'giza',
        title: '金字塔',
      );
      final backup = jsonDecode(jsonEncode(await journal.backup()));
      backup['notes'][0]['text'] = '另一台设备';
      await journal.restore(backup, replace: false);
      await journal.restore(backup, replace: false);
      expect(journal.notes.length, 2);
    },
  );

  test(
    'deleting a note removes its recovery draft in the same transaction',
    () async {
      await journal.saveNote(
        id: 'n',
        kind: 'discovery',
        text: '待删除',
        question: '',
        entityId: 'giza',
        title: '金字塔',
      );
      await database.setPreference('note-draft-n', {'id': 'n', 'text': '待恢复'});
      await journal.deleteNote('n', draftKey: 'note-draft-n');
      expect(journal.notes, isEmpty);
      expect(
        (await database.preferences()).containsKey('note-draft-n'),
        isFalse,
      );
    },
  );

  test('replace removes settings absent from backup and rejects invalid timestamps', () async {
    await database.setPreference('nickname', '旧名字');
    final backup = await journal.backup();
    backup['preferences'] = <String, dynamic>{};
    await journal.restore(backup, replace: true);
    expect((await database.preferences()).containsKey('nickname'), isFalse);
    backup['history'] = [
      {
        'kind': 'country',
        'entity_id': 'egypt',
        'title': '埃及',
        'updated_at': 'not-a-date',
      },
    ];
    expect(() => journal.restore(backup, replace: true), throwsFormatException);
  });

  test('a stale speech start cannot replace a newer request', () async {
    final content = ContentRepository.fromJson(
      jsonDecode(File('assets/atlas/catalog.json').readAsStringSync()),
    );
    final stops = <Completer<int>>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
          call,
        ) async {
          if (call.method == 'stop' && stops.length < 2) {
            final gate = Completer<int>();
            stops.add(gate);
            return gate.future;
          }
          return call.method == 'isLanguageAvailable' ? true : 1;
        });
    final speech = SpeechRepository();
    final first = speech.play(content.articles.first);
    final second = speech.play(content.articles.last);
    while (stops.length < 2) {
      await Future<void>.delayed(Duration.zero);
    }
    stops[1].complete(1);
    await second;
    stops[0].complete(1);
    await first;
    expect(speech.article?.id, content.articles.last.id);
    expect(speech.playing, isTrue);
    speech.dispose();
    content.dispose();
  });

  testWidgets(
    'finishing while autosave is running persists edits and kind made during save',
    (tester) async {
      final base = await tester.runAsync(
        () => AtlasServices.load(database: database, migrate: false),
      );
      final slow = _SlowJournal(database);
      await tester.runAsync(slow.load);
      final services = AtlasServices(
        database: database,
        content: base!.content,
        preferences: base.preferences,
        journal: slow,
        packs: base.packs,
        speech: base.speech,
      );
      await tester.pumpWidget(
        WorldAtlasApp(
          services: services,
          initialLocation: '/me/notes/new?entity=egypt-nature',
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '第一次输入');
      await tester.pump(const Duration(milliseconds: 700));
      await tester.runAsync(() async {
        for (var i = 0; !slow.entered && i < 50; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      expect(slow.entered, isTrue);
      await tester.enterText(find.byType(TextField).first, '保存过程中补充的新发现');
      await tester.tap(find.text('还想知道').first);
      await tester.tap(find.text('完成'));
      slow.gate.complete();
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pumpAndSettle();
      expect(slow.notes.single['text'], '保存过程中补充的新发现');
      expect(slow.notes.single['kind'], 'question');
      expect(base.preferences.values['note-draft-new-egypt-nature'], isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      base.journal.dispose();
      slow.dispose();
      base.preferences.dispose();
      base.packs.dispose();
      base.speech.dispose();
      base.content.dispose();
    },
  );
}

class _SlowJournal extends JournalRepository {
  _SlowJournal(super.database);
  final gate = Completer<void>();
  bool entered = false;
  @override
  Future<void> saveNote({
    required String id,
    required String kind,
    required String text,
    required String question,
    required String entityId,
    required String title,
  }) async {
    if (!entered) {
      entered = true;
      await gate.future;
    }
    await super.saveNote(
      id: id,
      kind: kind,
      text: text,
      question: question,
      entityId: entityId,
      title: title,
    );
  }
}
