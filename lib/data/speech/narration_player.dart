import 'package:audioplayers/audioplayers.dart';

abstract class NarrationPlayer {
  Stream<void> get completed;
  Future<void> prepare(String asset, double speed);
  Future<void> resume();
  Future<void> pause();
  Future<void> dispose();
}

class BundledNarrationPlayer implements NarrationPlayer {
  final AudioPlayer _player = AudioPlayer();
  @override
  Stream<void> get completed => _player.onPlayerComplete;
  @override
  Future<void> prepare(String asset, double speed) async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setSource(AssetSource(asset.substring('assets/'.length)));
    await _player.setPlaybackRate(speed);
  }

  @override
  Future<void> resume() => _player.resume();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> dispose() => _player.dispose();
}
