import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// System speech only. No generated timing bar or prerecorded-voice claim.
class Narration extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  bool speaking = false;
  bool preparing = false;
  String? error;
  bool _disposed = false;
  int _request = 0;

  Narration() {
    _tts.setCompletionHandler(() {
      speaking = false;
      preparing = false;
      _notify();
    });
    _tts.setCancelHandler(() {
      speaking = false;
      preparing = false;
      _notify();
    });
    _tts.setErrorHandler((message) {
      error = '这台设备暂时无法朗读。可以继续阅读文字，或在系统设置中安装中文语音。';
      speaking = false;
      preparing = false;
      _notify();
    });
  }

  Future<void> speak(String text, {double rate = .45}) async {
    final request = ++_request;
    error = null;
    preparing = true;
    _notify();
    try {
      await _tts.stop();
      final available = await _tts.isLanguageAvailable('zh-CN');
      if (available == false || available == 0) {
        throw StateError('Chinese speech unavailable');
      }
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(rate.clamp(.25, .65));
      await _tts.setVolume(1);
      if (_disposed || request != _request) return;
      speaking = true;
      preparing = false;
      _notify();
      final result = await _tts.speak(text);
      if (result == 0 && request == _request) {
        throw StateError('Speech engine rejected the request');
      }
    } on MissingPluginException {
      error = '当前运行环境没有可用的朗读功能。文字和探索任务仍可正常使用。';
      speaking = false;
      preparing = false;
      _notify();
    } catch (_) {
      if (request != _request || _disposed) return;
      error = '朗读暂时不可用。请检查设备的中文语音设置；你也可以继续阅读。';
      speaking = false;
      preparing = false;
      _notify();
    }
  }

  Future<void> stop() async {
    ++_request;
    speaking = false;
    preparing = false;
    _notify();
    try {
      await _tts.stop();
    } catch (_) {
      // Stopping an absent speech engine does not prevent navigation.
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_request;
    unawaited(_tts.stop().catchError((Object _) => 0));
    super.dispose();
  }
}
