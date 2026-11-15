import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_explorer/data/speech/narration_catalog.dart';
import 'package:world_explorer/data/speech/narration_player.dart';
import 'package:world_explorer/data/speech/speech_repository.dart';
import 'package:world_explorer/domain/atlas_content.dart';

class FakePlayer implements NarrationPlayer {
  final events = StreamController<void>.broadcast(sync: true);
  Completer<void>? gate;
  bool disposed = false;
  int resumes = 0, pauses = 0;
  bool fail = false;
  @override
  Stream<void> get completed => events.stream;
  @override
  Future<void> prepare(String asset, double speed) async {
    if (fail) throw StateError('missing file');
    await gate?.future;
  }

  @override
  Future<void> resume() async {
    resumes++;
  }

  @override
  Future<void> pause() async {
    pauses++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final json =
      (jsonDecode(
                    File('assets/atlas/catalog.json').readAsStringSync(),
                  )['articles']
                  as List)
              .firstWhere((a) => a['id'] == 'china-geography')
          as Map<String, dynamic>;
  final article = AtlasArticle.fromJson(json);
  final recorded = NarrationCatalog([
    for (final b in article.blocks)
      {
        'articleId': article.id,
        'revision': article.revision,
        'blockId': b.id,
        'sourceHash': NarrationCatalog.fingerprint(b),
        'reviewStatus': 'approved',
        'asset': 'assets/audio/${b.id}.mp3',
      },
  ]);
  final spoken = <String>[];
  setUp(() {
    spoken.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
          call,
        ) async {
          if (call.method == 'speak') {
            spoken.add(
              call.arguments is String
                  ? call.arguments as String
                  : (call.arguments as Map)['text'] as String,
            );
          }
          return call.method == 'isLanguageAvailable' ? true : 1;
        });
  });

  test('only complete reviewed current recordings enable natural mode', () {
    expect(recorded.covers(article), isTrue);
    expect(
      NarrationCatalog(recorded.tracks.sublist(1)).covers(article),
      isFalse,
    );
    final updated = AtlasArticle.fromJson({
      ...json,
      'revision': article.revision + 1,
    });
    expect(recorded.covers(updated), isFalse);
    final changed = AtlasArticle.fromJson({
      ...json,
      'blocks': [
        {
          ...(json['blocks'] as List).first as Map<String, dynamic>,
          'text': '新版正文',
        },
        ...(json['blocks'] as List).skip(1),
      ],
    });
    expect(recorded.covers(changed), isFalse);
    expect(
      NarrationCatalog([
        for (final t in recorded.tracks)
          {...t, 'asset': 'https://example.com/a.mp3'},
      ]).covers(article),
      isFalse,
    );
  });

  test('pending recordings use reviewed listening scripts without claiming natural audio', () async {
    final bundled = await NarrationCatalog.load();
    final catalog = NarrationCatalog([
      for (final track in bundled.tracks)
        {...track, 'reviewStatus': 'awaitingAudio'},
    ]);
    expect(catalog.covers(article), isFalse);
    expect(catalog.scriptFor(article, 0), startsWith('地图上的陆地'));
    final speech = SpeechRepository(loadCatalog: () async => catalog);
    await speech.play(article);
    expect(speech.naturalAudio, isFalse);
    expect(speech.modeLabel, '设备朗读');
    expect(spoken.single, catalog.scriptFor(article, 0));
    speech.dispose();
  });

  test(
    'pause and resume retain the same recording and completion advances',
    () async {
      final players = <FakePlayer>[];
      final speech = SpeechRepository(
        loadCatalog: () async => recorded,
        createPlayer: () {
          final player = FakePlayer();
          players.add(player);
          return player;
        },
      );
      await speech.play(article);
      expect(speech.naturalAudio, isTrue);
      expect(spoken, isEmpty);
      await speech.pause();
      expect(speech.paused, isTrue);
      await speech.resume();
      expect(players.length, 1);
      expect(players.first.resumes, 2);
      players.first.events.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(speech.blockIndex, 1);
      expect(players.length, 2);
      expect(players.first.disposed, isTrue);
      speech.dispose();
    },
  );

  test('cancel while loading cannot start stale audio', () async {
    final player = FakePlayer()..gate = Completer<void>();
    final speech = SpeechRepository(
      loadCatalog: () async => recorded,
      createPlayer: () => player,
    );
    final start = speech.play(article);
    while (!speech.naturalAudio) {
      await Future<void>.delayed(Duration.zero);
    }
    await Future<void>.delayed(Duration.zero);
    await speech.pause();
    player.gate!.complete();
    await start;
    expect(player.resumes, 0);
    expect(player.disposed, isTrue);
    expect(speech.playing, isFalse);
    speech.dispose();
  });

  test(
    'missing recording falls back to device speech with a visible notice',
    () async {
      final speech = SpeechRepository(
        loadCatalog: () async => recorded,
        createPlayer: () => FakePlayer()..fail = true,
      );
      await speech.play(article);
      expect(speech.naturalAudio, isFalse);
      expect(speech.playing, isTrue);
      expect(spoken.length, 1);
      expect(speech.notice, contains('已切换设备朗读'));
      speech.dispose();
    },
  );

  test(
    'paragraph navigation clamps and final completion allows replay',
    () async {
      final players = <FakePlayer>[];
      final speech = SpeechRepository(
        loadCatalog: () async => recorded,
        createPlayer: () {
          final player = FakePlayer();
          players.add(player);
          return player;
        },
      );
      await speech.play(article, start: 4);
      players.last.events.add(null);
      expect(speech.playing, isFalse);
      expect(speech.paused, isFalse);
      await speech.move(-1);
      expect(speech.blockIndex, 3);
      await speech.move(-20);
      expect(speech.blockIndex, 0);
      speech.dispose();
    },
  );

  test(
    'bundled narration covers every paragraph of each recorded article',
    () async {
      final catalog = await NarrationCatalog.load();
      final all = [
        ...jsonDecode(
              File('assets/atlas/catalog.json').readAsStringSync(),
            )['articles']
            as List,
        ...jsonDecode(
              File('assets/atlas/antarctica-region.json').readAsStringSync(),
            )['articles']
            as List,
      ].map((a) => AtlasArticle.fromJson(a as Map<String, dynamic>)).toList();
      final assets = (await AssetManifest.loadFromAssetBundle(rootBundle))
          .listAssets()
          .toSet();
      expect(catalog.tracks, isNotEmpty);
      for (final id in catalog.tracks.map((t) => t['articleId']).toSet()) {
        final a = all.firstWhere((a) => a.id == id);
        expect(catalog.covers(a), isTrue, reason: a.id);
        for (var i = 0; i < a.blocks.length; i++) {
          final asset = catalog.assetFor(a, i)!;
          expect(assets, contains(asset));
          final track = catalog.tracks.singleWhere(
            (t) => t['articleId'] == id && t['blockId'] == a.blocks[i].id,
          );
          expect(track['script'], isNotEmpty);
          if (track['scriptReviewed'] == true) {
            expect(catalog.scriptFor(a, i), track['script']);
          }
        }
      }
    },
  );
}
