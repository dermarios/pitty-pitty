import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';

// Global instance for easy access
late BackgroundAudioHandler _globalHandler;

class BackgroundAudioHandler extends BaseAudioHandler {
  Future<void> Function()? onPlay;
  Future<void> Function()? onPause;
  Future<void> Function()? onNext;
  Future<void> Function()? onPrevious;
  Future<void> Function(Duration position)? onSeek;
  Future<void> Function()? onStop;

  String? _lastArtworkPath;
  static const String _tempArtworkName = 'lock_screen_artwork.tmp';

  BackgroundAudioHandler() {
    _globalHandler = this;
    mediaItem.add(null);
    playbackState.add(
      PlaybackState(
        controls: const [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1.0,
      ),
    );
  }

  static BackgroundAudioHandler get instance => _globalHandler;

  void setCallbacks({
    Future<void> Function()? play,
    Future<void> Function()? pause,
    Future<void> Function()? next,
    Future<void> Function()? previous,
    Future<void> Function(Duration position)? seek,
  }) {
    onPlay = play;
    onPause = pause;
    onNext = next;
    onPrevious = previous;
    onSeek = seek;
  }

  Future<String?> _copyAssetToTemp(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final uint8list = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      final tempDir = Directory.systemTemp;
      final extension = assetPath.split('.').last;
      final tempFile = File(
        '${tempDir.path}/$_tempArtworkName.$extension',
      );

      // Remove old artwork se existir
      if (_lastArtworkPath != null && _lastArtworkPath != tempFile.path) {
        try {
          await File(_lastArtworkPath!).delete();
        } catch (_) {}
      }

      await tempFile.writeAsBytes(uint8list);
      _lastArtworkPath = tempFile.path;

      return tempFile.path;
    } catch (e) {
      print('Error copying asset to temp: $e');
      return null;
    }
  }

  Future<void> updateNowPlaying({
    required String id,
    required String title,
    required String artist,
    required String album,
    required Duration duration,
    String? artworkAssetPath,
    Duration? elapsedTime,
  }) async {
    try {
      final artUri = artworkAssetPath != null
          ? await _copyAssetToTemp(artworkAssetPath)
          : null;

      final item = MediaItem(
        id: id,
        title: title,
        artist: artist,
        album: album,
        duration: duration,
        artUri: artUri != null ? Uri.file(artUri) : null,
      );

      mediaItem.add(item);

      // Atualizar posição se provided
      if (elapsedTime != null) {
        updateElapsedTime(elapsedTime);
      }
    } catch (e) {
      print('Error updating now playing: $e');
    }
  }

  void clearNowPlaying() {
    mediaItem.add(null);
    _lastArtworkPath = null;
  }

  void updateElapsedTime(Duration elapsedTime) {
    final state = playbackState.value;
    playbackState.add(
      state.copyWith(updatePosition: elapsedTime),
    );
  }

  void updatePlaybackState({
    required bool playing,
    required AudioProcessingState processingState,
    required Duration position,
    required Duration bufferedPosition,
    required double speed,
  }) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      processingState: processingState,
      playing: playing,
      updatePosition: position,
      bufferedPosition: bufferedPosition,
      speed: speed,
    ));
  }

  @override
  Future<void> play() async {
    await onPlay?.call();
  }

  @override
  Future<void> pause() async {
    await onPause?.call();
  }

  @override
  Future<void> stop() async {
    await onStop?.call();
    playbackState.add(_playbackState(playing: false));
    mediaItem.add(null);
    _lastArtworkPath = null;
  }

  PlaybackState _playbackState({required bool playing}) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: {MediaAction.seek},
      processingState: AudioProcessingState.ready,
      playing: playing,
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: 1.0,
    );
  }

  @override
  Future<void> seek(Duration position) async {
    await onSeek?.call(position);
  }

  @override
  Future<void> skipToNext() async {
    await onNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    await onPrevious?.call();
  }
}
