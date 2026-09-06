import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../models/track.dart';

class LockScreenAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  String? _artworkPath;
  bool _initialized = false;
  List<MediaItem> _mediaItems = [];

  LockScreenAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1) Configure audio session: playback category is required for lock screen
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      print('✓ AudioSession configured for lock screen');

      // 2) Broadcast every just_audio event to audio_service
      _player.playbackEventStream.listen(_broadcastState);

      // 3) When track changes, update the current MediaItem
      _player.currentIndexStream.listen((index) {
        if (index != null && index < _mediaItems.length) {
          mediaItem.add(_mediaItems[index]);
        }
      });

      // 4) Handle interruptions and headphone disconnect
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

      print('✓ LockScreenAudioHandler initialized successfully');
    } catch (e) {
      print('✗ Error initializing LockScreenAudioHandler: $e');
      rethrow;
    }
  }

  Future<void> initializePlaylist(List<Track> tracks) async {
    try {
      _mediaItems = [];
      _playlist.children.clear();

      // Prepare artwork first (copy from assets to filesystem)
      if (tracks.isNotEmpty && tracks.first.imageAsset != null) {
        await _prepareArtwork(tracks.first.imageAsset!);
      }

      // Build playlist from tracks
      final items = <MediaItem>[
        for (final track in tracks)
          MediaItem(
            id: track.path,
            title: track.title,
            artist: 'Pitty',
            album: 'Pitty Player',
            duration: track.duration,
            artUri: _artworkPath != null ? Uri.file(_artworkPath!) : null,
          ),
      ];

      _mediaItems = items;
      queue.add(items);
      if (items.isNotEmpty) {
        mediaItem.add(items.first);
      }

      // Load audio sources from assets
      await _playlist.addAll([
        for (final track in tracks) AudioSource.asset(track.path, tag: track.toMediaItem()),
      ]);
      await _player.setAudioSource(_playlist);
      print('✓ Playlist initialized with ${_mediaItems.length} tracks');
    } catch (e) {
      print('✗ Error initializing playlist: $e');
      rethrow;
    }
  }

  Future<void> _prepareArtwork(String assetPath) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final destPath = '${appDocDir.path}/cover.jpg';
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
      _artworkPath = destPath;
    } catch (e) {
      print('Error preparing artwork: $e');
      _artworkPath = null;
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
}