import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/track.dart';

class AudioService {
  late AudioPlayer _player;
  List<Track> _tracks = [];
  Track? _currentTrack;

  AudioService() {
    _player = AudioPlayer();
    _initializeAudioSession();
  }

  Future<void> _initializeAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  Future<void> loadTracks() async {
    final manifestJson = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = jsonDecode(manifestJson);

    _tracks = [];
    if (manifestMap.containsKey('assets/musicas')) {
      final List<dynamic> musicFiles = manifestMap['assets/musicas'];
      for (var asset in musicFiles) {
        if (asset.endsWith('.mp3')) {
          final title = asset
              .split('/')
              .last
              .replaceAll('.mp3', '')
              .replaceAll('_', ' ')
              .replaceAll('-', ' ');
          _tracks.add(Track(path: asset, title: title));
        }
      }
    }

    _tracks.sort((a, b) => a.title.compareTo(b.title));
  }

  Future<void> play(Track track) async {
    try {
      _currentTrack = track;
      await _player.setAsset(track.path);
      await _player.play();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> next() async {
    if (_currentTrack == null) return;
    final currentIndex = _tracks.indexOf(_currentTrack!);
    if (currentIndex != -1 && currentIndex < _tracks.length - 1) {
      await play(_tracks[currentIndex + 1]);
    }
  }

  Future<void> previous() async {
    if (_currentTrack == null) return;
    final currentIndex = _tracks.indexOf(_currentTrack!);
    if (currentIndex > 0) {
      await play(_tracks[currentIndex - 1]);
    }
  }

  AudioPlayer get player => _player;
  List<Track> get tracks => _tracks;
  Track? get currentTrack => _currentTrack;

  void dispose() {
    _player.dispose();
  }
}
