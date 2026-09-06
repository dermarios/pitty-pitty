import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'dart:io';

// Global instance for easy access
late BackgroundAudioHandler _globalHandler;

class BackgroundAudioHandler extends BaseAudioHandler {
  Future<void> Function()? onPlay;
  Future<void> Function()? onPause;
  Future<void> Function()? onNext;
  Future<void> Function()? onPrevious;
  Future<void> Function(Duration position)? onSeek;

  BackgroundAudioHandler() {
    _globalHandler = this;
    mediaItem.add(null);
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
        '${tempDir.path}/artwork_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      await tempFile.writeAsBytes(uint8list);

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
    } catch (e) {
      print('Error updating now playing: $e');
    }
  }

  void clearNowPlaying() {
    mediaItem.add(null);
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
    playbackState.add(_playbackState(playing: false));
    mediaItem.add(null);
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
