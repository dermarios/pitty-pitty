import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';

// Global instance for easy access
late BackgroundAudioHandler _globalHandler;

class BackgroundAudioHandler extends BaseAudioHandler {
  StreamSubscription? _playbackStateSubscription;
  StreamSubscription? _mediaItemSubscription;

  BackgroundAudioHandler() {
    _globalHandler = this;
    mediaItem.add(null);
  }

  static BackgroundAudioHandler get instance => _globalHandler;

  Future<String?> _copyAssetToTemp(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final uint8list = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/artwork_${DateTime.now().millisecondsSinceEpoch}.jpg');
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

  @override
  Future<void> play() async {
    playbackState.add(_playbackState(playing: true));
  }

  @override
  Future<void> pause() async {
    playbackState.add(_playbackState(playing: false));
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
    playbackState.add(_playbackState(playing: true).copyWith(
      updatePosition: position,
    ));
  }
}