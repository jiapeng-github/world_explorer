import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/atlas_content.dart';
import 'narration_catalog.dart';
import 'narration_player.dart';

class SpeechRepository extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  AtlasArticle? article;
  int blockIndex = 0;
  bool playing = false, preparing = false;
  String? error;
  bool _disposed = false;
  int _token = 0;
  double _rate = .45;
  final Future<NarrationCatalog> Function() _loadCatalog;
  final NarrationPlayer Function() _createPlayer;
  NarrationCatalog? _catalog;
  NarrationPlayer? _player;
  StreamSubscription<void>? _completion;
  bool naturalAudio = false;
  bool paused = false;
  String? notice;
  String get modeLabel => naturalAudio ? '自然讲解' : '设备朗读';

  SpeechRepository({
    Future<NarrationCatalog> Function()? loadCatalog,
    NarrationPlayer Function()? createPlayer,
  }) : _loadCatalog = loadCatalog ?? NarrationCatalog.load,
       _createPlayer = createPlayer ?? BundledNarrationPlayer.new {
    _tts.setCompletionHandler(() {
      if (naturalAudio || !playing || article == null || _disposed) return;
      if (blockIndex + 1 < article!.blocks.length) {
        blockIndex++;
        unawaited(_speakBlock(_token));
      } else {
        playing = false;
        _notify();
      }
    });
    _tts.setErrorHandler((_) {
      if (naturalAudio || _disposed) return;
      playing = false;
      preparing = false;
      error = '这台设备暂时没有可用的中文语音，文字仍可阅读。';
      _notify();
    });
  }
  Future<void> play(
    AtlasArticle value, {
    int start = 0,
    double rate = .45,
  }) async {
    final token = ++_token;
    playing = false;
    preparing = true;
    paused = false;
    final oldPlayer = _releasePlayer();
    await oldPlayer;
    await _tts.stop().catchError((Object _) => 0);
    if (token != _token || _disposed) return;
    if (value.blocks.isEmpty) {
      preparing = false;
      error = '这篇文章暂时没有可朗读的段落。';
      _notify();
      return;
    }
    article = value;
    blockIndex = start.clamp(0, value.blocks.length - 1);
    _rate = rate;
    error = null;
    notice = null;
    naturalAudio = false;
    preparing = true;
    playing = false;
    _notify();
    try {
      try {
        _catalog ??= await _loadCatalog();
      } catch (_) {
        // Optional audio must never prevent reading or device speech.
      }
      if (token != _token || _disposed) return;
      naturalAudio = _catalog?.covers(value) ?? false;
      if (naturalAudio) {
        playing = true;
        await _speakBlock(token);
        return;
      }
      notice = '本篇使用设备朗读';
      final available = await _tts.isLanguageAvailable('zh-CN');
      if (available == false || available == 0) throw StateError('语音不可用');
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(_rate.clamp(.25, .65));
      await _tts.setVolume(1);
      if (token != _token || _disposed) return;
      playing = true;
      preparing = false;
      await _speakBlock(token);
    } catch (_) {
      if (token == _token && !_disposed) {
        error = '这台设备暂时没有可用的中文语音，文字仍可阅读。';
        playing = false;
        preparing = false;
        _notify();
      }
    }
  }

  Future<void> _speakBlock(int token) async {
    if (_disposed || token != _token || !playing || article == null) return;
    if (naturalAudio) {
      await _playRecording(token);
      return;
    }
    _notify();
    final block = article!.blocks[blockIndex];
    try {
      final script = _catalog?.scriptFor(article!, blockIndex);
      final result = await _tts.speak(script ?? '${block.title}。${block.text}');
      if (result == 0) throw StateError('语音不可用');
    } catch (_) {
      if (token == _token) {
        playing = false;
        preparing = false;
        error = '朗读暂时不可用，可以继续阅读文字。';
        _notify();
      }
    }
  }

  Future<void> _playRecording(int token) async {
    await _releasePlayer();
    if (_disposed || token != _token || !playing) return;
    final player = _createPlayer();
    _player = player;
    preparing = true;
    _notify();
    _completion = player.completed.listen((_) {
      if (_disposed || _player != player || !playing || token != _token) return;
      if (blockIndex + 1 < article!.blocks.length) {
        blockIndex++;
        unawaited(_speakBlock(token));
      } else {
        playing = false;
        paused = false;
        _notify();
      }
    });
    try {
      await player.prepare(
        _catalog!.assetFor(article!, blockIndex)!,
        (_rate / .45).clamp(.75, 1.35),
      );
      if (_disposed || _player != player || token != _token) return;
      preparing = false;
      if (!playing) return;
      await player.resume();
      if (_disposed || _player != player || token != _token) return;
      if (!playing) await player.pause();
      _notify();
    } catch (_) {
      if (_disposed || _player != player || token != _token) return;
      // A missing/corrupt bundled file falls back visibly, not silently.
      final value = article!;
      final index = blockIndex;
      _catalog = NarrationCatalog([]);
      await play(value, start: index, rate: _rate);
      notice = '讲解音频暂时不可用，已切换设备朗读';
      _notify();
    }
  }

  Future<void> _releasePlayer() async {
    final player = _player;
    _player = null;
    final completion = _completion;
    _completion = null;
    await completion?.cancel();
    try {
      await player?.dispose();
    } catch (_) {
      /* Already released. */
    }
  }

  Future<void> pause() async {
    playing = false;
    paused = article != null;
    if (naturalAudio && _player != null && !preparing) {
      try {
        await _player!.pause();
      } catch (_) {
        /* Route may have closed. */
      }
    } else {
      ++_token;
      preparing = false;
      await _releasePlayer();
      await _tts.stop().catchError((Object _) => 0);
    }
    _notify();
  }

  Future<void> resume({double? rate}) async {
    if (article == null || _disposed) return;
    if (naturalAudio &&
        paused &&
        _player != null &&
        (rate == null || rate == _rate)) {
      final player = _player!;
      final token = _token;
      paused = false;
      playing = true;
      try {
        await player.resume();
        if (_player == player && token == _token && !playing) {
          await player.pause();
        }
      } catch (_) {
        if (_player == player && token == _token) {
          playing = false;
          paused = true;
          error = '播放暂时中断，请重新选择段落。';
        }
      }
      _notify();
    } else {
      await play(article!, start: blockIndex, rate: rate ?? _rate);
    }
  }

  Future<void> move(int delta) async {
    final value = article;
    if (value == null || value.blocks.isEmpty) return;
    await play(
      value,
      start: (blockIndex + delta).clamp(0, value.blocks.length - 1),
      rate: _rate,
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_token;
    unawaited(_releasePlayer());
    unawaited(_tts.stop().catchError((Object _) => 0));
    super.dispose();
  }
}
