import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_explorer/core/explorer_store.dart';
import 'package:world_explorer/models/catalog.dart';

Catalog _catalog() => Catalog.fromJson(
  jsonDecode(File('assets/content/catalog.json').readAsStringSync())
      as Map<String, dynamic>,
);

Future<ExplorerStore> _reopen(Catalog catalog, ProgressStorage storage) async {
  final store = ExplorerStore(catalog: catalog, storage: storage);
  await store.load();
  return store;
}

/// Delays the oldest write, allowing an incorrectly concurrent implementation
/// to overwrite newer actions after they have already reached storage.
class DelayedStorage extends MemoryProgressStorage {
  final firstWriteStarted = Completer<void>();
  final releaseFirstWrite = Completer<void>();
  int _writeCount = 0;

  @override
  Future<void> write(Map<String, dynamic> value) async {
    if (_writeCount++ == 0) {
      firstWriteStarted.complete();
      await releaseFirstWrite.future;
    }
    await super.write(value);
  }
}

class FailingStorage extends MemoryProgressStorage {
  int failuresRemaining = 1;

  @override
  Future<void> write(Map<String, dynamic> value) async {
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw const FileSystemException('Simulated full device storage');
    }
    await super.write(value);
  }
}

void main() {
  late Catalog catalog;

  setUp(() {
    catalog = _catalog();
  });

  test('article reading survives restart, deduplicates and resets', () async {
    final storage = MemoryProgressStorage();
    final store = ExplorerStore(catalog: catalog, storage: storage);
    addTearDown(store.dispose);
    await store.markTopicRead('china', 'geography');
    await store.markTopicRead('china', 'geography');
    final restored = await _reopen(catalog, storage);
    addTearDown(restored.dispose);
    expect(restored.readTopics, {'china/geography'});
    await restored.resetProgress();
    final cleared = await _reopen(catalog, storage);
    addTearDown(cleared.dispose);
    expect(cleared.readTopics, isEmpty);
  });

  test(
    'a new session restores the child’s discoveries and reading preferences',
    () async {
      final storage = MemoryProgressStorage();
      final store = ExplorerStore(catalog: catalog, storage: storage);
      addTearDown(store.dispose);

      await store.saveProfile(
        name: ' 小河 ',
        selectedAvatar: '🐼',
        prefersVoice: false,
      );
      await store.updateSettings(
        textScale: 1.2,
        speechRate: .5,
        breakMinutes: 15,
      );
      await store.markVisited('egypt');
      await store.toggleFavorite('brazil');
      await store.saveReading('egypt', 2);
      await store.saveQuiz('china', 1);
      await store.addQuestion('  河流为什么会弯曲？  ', countryId: 'egypt');

      final restored = await _reopen(catalog, storage);
      addTearDown(restored.dispose);

      expect(restored.nickname, '小河');
      expect(restored.avatar, '🐼');
      expect(restored.onboarded, isTrue);
      expect(restored.voiceEnabled, isFalse);
      expect(restored.textScale, 1.2);
      expect(restored.speechRate, .5);
      expect(restored.breakMinutes, 15);
      expect(restored.visited, {'egypt'});
      expect(restored.favorites, {'brazil'});
      expect(restored.readingPositions, {'egypt': 2});
      expect(restored.quizPositions, {'china': 1});
      expect(restored.lastCountryId, 'egypt');
      expect(restored.questions.single.text, '河流为什么会弯曲？');
      expect(restored.questions.single.countryId, 'egypt');
      expect(restored.questions.single.id, isNotEmpty);
      expect(DateTime.tryParse(restored.questions.single.createdAt), isNotNull);
    },
  );

  test(
    'finishing a destination twice creates one stamp and clears its quiz',
    () async {
      final storage = MemoryProgressStorage();
      final store = ExplorerStore(catalog: catalog, storage: storage);
      addTearDown(store.dispose);
      await store.saveQuiz('egypt', 2);
      await store.saveQuiz('china', 1);
      await store.completeCountry('egypt');
      await store.completeCountry('egypt');

      final restored = await _reopen(catalog, storage);
      addTearDown(restored.dispose);
      expect(restored.completed, {'egypt'});
      expect(restored.visited, {'egypt'});
      expect(restored.quizPositions.containsKey('egypt'), isFalse);
      expect(restored.quizPositions['china'], 1);
    },
  );

  test(
    'rapid actions survive an older delayed save without losing latest state',
    () async {
      final storage = DelayedStorage();
      final store = ExplorerStore(catalog: catalog, storage: storage);
      addTearDown(store.dispose);

      final olderSave = store.saveReading('egypt', 0);
      await storage.firstWriteStarted.future;
      final latestReading = store.saveReading('egypt', 2);
      final favoriteSave = store.toggleFavorite('brazil');
      final latestSettings = store.updateSettings(textScale: 1.25);
      // Give any wrongly unqueued writes a chance to reach storage first.
      await Future<void>.delayed(Duration.zero);
      storage.releaseFirstWrite.complete();
      await Future.wait([
        olderSave,
        latestReading,
        favoriteSave,
        latestSettings,
      ]);

      final restored = await _reopen(catalog, storage);
      addTearDown(restored.dispose);
      expect(restored.readingPositions['egypt'], 2);
      expect(restored.favorites, {'brazil'});
      expect(restored.textScale, 1.25);
    },
  );

  test(
    'a failed save reports an error and retry preserves the unsaved action',
    () async {
      final storage = FailingStorage();
      final store = ExplorerStore(catalog: catalog, storage: storage);
      addTearDown(store.dispose);
      final reportedErrors = <String?>[];
      store.addListener(() => reportedErrors.add(store.storageError));

      await store.toggleFavorite('egypt');
      expect(store.storageError, isNotNull);
      expect(reportedErrors.whereType<String>(), isNotEmpty);
      expect(store.favorites, {'egypt'});

      final beforeRetry = await _reopen(catalog, storage);
      addTearDown(beforeRetry.dispose);
      expect(beforeRetry.favorites, isEmpty);

      await store.retrySave();
      expect(store.storageError, isNull);
      expect(reportedErrors.last, isNull);
      final afterRetry = await _reopen(catalog, storage);
      addTearDown(afterRetry.dispose);
      expect(afterRetry.favorites, {'egypt'});
    },
  );

  test(
    'removed favorites and deleted questions stay removed after reopening',
    () async {
      final storage = MemoryProgressStorage();
      final store = ExplorerStore(catalog: catalog, storage: storage);
      addTearDown(store.dispose);
      await store.toggleFavorite('china');
      await store.addQuestion('运河怎样开凿？', countryId: 'china');
      final questionId = store.questions.single.id;
      await store.toggleFavorite('china');
      await store.deleteQuestion(questionId);
      await store.addQuestion('   ');

      final restored = await _reopen(catalog, storage);
      addTearDown(restored.dispose);
      expect(restored.favorites, isEmpty);
      expect(restored.questions, isEmpty);
    },
  );

  test(
    'reset clears exploration records while keeping profile and settings',
    () async {
      final storage = MemoryProgressStorage();
      final store = ExplorerStore(catalog: catalog, storage: storage);
      addTearDown(store.dispose);
      await store.saveProfile(
        name: '小河',
        selectedAvatar: '🐼',
        prefersVoice: false,
      );
      await store.updateSettings(
        textScale: 1.2,
        speechRate: .5,
        breakMinutes: 10,
      );
      await store.markVisited('china');
      await store.toggleFavorite('china');
      await store.saveReading('china', 2);
      await store.saveQuiz('brazil', 1);
      await store.completeCountry('egypt');
      await store.addQuestion('森林为什么会涨水？', countryId: 'brazil');
      await store.resetProgress();

      final restored = await _reopen(catalog, storage);
      addTearDown(restored.dispose);
      expect(restored.visited, isEmpty);
      expect(restored.favorites, isEmpty);
      expect(restored.completed, isEmpty);
      expect(restored.readingPositions, isEmpty);
      expect(restored.quizPositions, isEmpty);
      expect(restored.questions, isEmpty);
      expect(restored.lastCountryId, isNull);
      expect(restored.nickname, '小河');
      expect(restored.avatar, '🐼');
      expect(restored.onboarded, isTrue);
      expect(restored.voiceEnabled, isFalse);
      expect(restored.textScale, 1.2);
      expect(restored.speechRate, .5);
      expect(restored.breakMinutes, 10);
    },
  );
}
