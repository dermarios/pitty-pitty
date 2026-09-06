import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../models/track.dart';

class LockScreenAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  Map<String, String> _artworkCache = {};
  bool _initialized = false;
  List<MediaItem> _mediaItems = [];

  LockScreenAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Configure audio session for playback (required for lock screen)
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      print('✓ AudioSession configured for lock screen');

      // Broadcast player state changes to audio_service
      _player.playbackEventStream.listen(_broadcastState);

      // Update MediaItem when track changes
      _player.currentIndexStream.listen((index) {
        if (index != null && index < _mediaItems.length) {
          mediaItem.add(_mediaItems[index]);
        }
      });

      // Handle audio interruptions and headphone disconnect
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          if (event.type == AudioInterruptionType.duck) {
            _player.setVolume(0.3);
          } else {
            _player.pause();
          }
        } else {
          if (event.type == AudioInterruptionType.duck) {
            _player.setVolume(1.0);
          } else if (event.type == AudioInterruptionType.pause) {
            _player.play();
          }
        }
      });
      session.becomingNoisyEventStream.listen((_) => _player.pause());

      print('✓ LockScreenAudioHandler initialized');
    } catch (e) {
      print('✗ Error initializing LockScreenAudioHandler: $e');
      rethrow;
    }
  }

  Future<void> initializePlaylist(List<Track> tracks) async {
    try {
      _mediaItems = [];
      _playlist.clear();

      // Prepare artwork for all tracks
      for (final track in tracks) {
        final artworkPath = track.imageAsset != null
            ? await _prepareArtwork(track.imageAsset!)
            : null;

        final item = MediaItem(
          id: track.path,
          title: track.title,
          artist: 'Pitty',
          album: 'Pitty Player',
          duration: track.duration ?? Duration.zero,
          artUri: artworkPath != null ? Uri.file(artworkPath) : null,
        );

        _mediaItems.add(item);
        _playlist.add(AudioSource.asset(track.path, tag: item));
      }

      queue.add(_mediaItems);
      if (_mediaItems.isNotEmpty) {
        mediaItem.add(_mediaItems.first);
      }

      await _player.setAudioSource(_playlist);
      print('✓ Playlist initialized with ${_mediaItems.length} tracks');
    } catch (e) {
      print('✗ Error initializing playlist: $e');
      rethrow;
    }
  }

  Future<String?> _prepareArtwork(String assetPath) async {
    // Check cache first
    if (_artworkCache.containsKey(assetPath)) {
      return _artworkCache[assetPath];
    }

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final fileName = assetPath.split('/').last;
      final destPath = '${appDocDir.path}/$fileName';
      final destFile = File(destPath);

      if (!await destFile.exists()) {
        // Load from assets and write to documents directory
        final assetData = await rootBundle.load(assetPath);
        await destFile.writeAsBytes(
          assetData.buffer.asUint8List(
            assetData.offsetInBytes,
            assetData.lengthInBytes,
          ),
        );
      }

      _artworkCache[assetPath] = destPath;
      return destPath;
    } catch (e) {
      print('✗ Error preparing artwork: $e');
      return null;
    }
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  AudioPlayer get player => _player;

  Future<void> dispose() async {
    await _player.dispose();
  }
}
