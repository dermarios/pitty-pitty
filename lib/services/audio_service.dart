import 'dart:async';
import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/track.dart';
import 'lock_screen_audio_handler.dart';

class PittyAudioService {
  late AudioPlayer _player;
  late LockScreenAudioHandler _audioHandler;
  List<Track> _tracks = [];
  Track? _currentTrack;
  bool _tracksLoaded = false;
  int _repeatMode = 0;
  bool _shuffleMode = false;
  StreamSubscription<PlayerState>? _repeatListener;
  StreamSubscription<Duration>? _positionListener;
  Set<String> _likedTracks = {};
  final _random = math.Random();

  PittyAudioService(this._audioHandler) {
    _player = _audioHandler.player;
    _initializeAudioSession().ignore();
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    // Lock screen updates are now handled by LockScreenAudioHandler
  }

  Future<void> _initializeAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidWillPauseWhenDucked: true,
      ));
    } catch (e) {
      print('Error configuring audio session: $e');
    }
  }


  Future<void> loadTracks() async {
    if (_tracksLoaded) return;
    _tracks = [];
    final hardcodedTracks = [
      Track(
        path: 'assets/musicas/01 - Teto De Vidro.mp3',
        title: 'Teto De Vidro',
        imageAsset: 'assets/Jorge-Daux-@jorgedaux.webp',
      ),
      Track(
        path: 'assets/musicas/02 - Admiravel Chip Novo.mp3',
        title: 'Admirável Chip Novo',
        imageAsset: 'assets/Jorge-Daux-@jorgedaux.webp',
      ),
      Track(
        path: 'assets/musicas/03 - Mascara.mp3',
        title: 'Máscara',
        imageAsset: 'assets/Jorge-Daux-@jorgedaux.webp',
      ),
      Track(
        path: 'assets/musicas/04 - Equalize.mp3',
        title: 'Equalize',
        imageAsset: 'assets/Jorge-Daux-@jorgedaux.webp',
      ),
      Track(
        path: 'assets/musicas/05 - O Lobo.mp3',
        title: 'O Lobo',
        imageAsset: 'assets/Jorge-Daux-@jorgedaux.webp',
      ),
      Track(
        path: 'assets/musicas/06 - Emboscada.mp3',
        title: 'Emboscada',
        imageAsset: 'assets/Jorge-Daux-@jorgedaux.webp',
      ),
      Track(
        path: 'assets/musicas/07 - Do Mesmo Lado.mp3',
        title: 'Do Mesmo Lado',
        imageAsset: 'assets/Jorge-Daux-@jorgedaux.webp',
      ),
      Track(
        path: 'assets/musicas/08 - Temporal.mp3',
        title: 'Temporal',
        imageAsset: 'assets/Jorge-Daux-@jorgedaux.webp',
      ),
      Track(
        path: 'assets/musicas/09 - So De Passagem.mp3',
        title: 'Só De Passagem',
        imageAsset: 'assets/Jorge-Daux-@jorgedaux.webp',
      ),
      Track(
        path: 'assets/musicas/10 - I Wanna Be.mp3',
        title: 'I Wanna Be',
        imageAsset: 'assets/Jorge-Daux-@jorgedaux.webp',
      ),
      Track(
        path: 'assets/musicas/11 - Semana Que Vem.mp3',
        title: 'Semana Que Vem',
        imageAsset: 'assets/Jorge-Daux-@jorgedaux.webp',
      ),
    ];

    _tracks.addAll(hardcodedTracks);
    _tracks.sort((a, b) => a.title.compareTo(b.title));

    // Initialize lock screen handler with playlist
    await _audioHandler.initializePlaylist(_tracks);

    if (_tracks.isNotEmpty && _currentTrack == null) {
      _currentTrack = _tracks.first;
    }
    _tracksLoaded = true;
  }

  Future<void> play(Track track) async {
    try {
      _currentTrack = track;
      print('→ Playing: ${track.title}');
      print('  - Artist: Pitty');

      await _activateAudioSession();

      final trackIndex = _tracks.indexOf(track);
      if (trackIndex != -1) {
        await _player.seek(Duration.zero, index: trackIndex);
      }

      await _player.play();
      print('✓ Audio started playing');

      _setupRepeatListener();
    } catch (e) {
      rethrow;
    }
  }

  void _setupRepeatListener() {
    _repeatListener?.cancel();
    _repeatListener = _player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed && _currentTrack != null) {
        if (_repeatMode == 1) {
          await _player.seek(Duration.zero);
          await _player.play();
        } else if (_repeatMode == 2) {
          final currentIndex = _tracks.indexOf(_currentTrack!);
          if (currentIndex != -1 && currentIndex < _tracks.length - 1) {
            await play(_tracks[currentIndex + 1]);
          } else if (currentIndex == _tracks.length - 1) {
            await play(_tracks.first);
          }
        }
      }
    });
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _activateAudioSession();
    await _player.play();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> next() async {
    if (_currentTrack == null) return;
    if (_shuffleMode && _tracks.isNotEmpty) {
      final randomIndex = _random.nextInt(_tracks.length);
      await play(_tracks[randomIndex]);
    } else {
      final currentIndex = _tracks.indexOf(_currentTrack!);
      if (currentIndex != -1 && currentIndex < _tracks.length - 1) {
        await play(_tracks[currentIndex + 1]);
      } else if (currentIndex == _tracks.length - 1 && _repeatMode == 2) {
        await play(_tracks.first);
      }
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
  int get repeatMode => _repeatMode;
  bool get shuffleMode => _shuffleMode;

  void toggleRepeatMode() {
    _repeatMode = (_repeatMode + 1) % 3;
    _setupRepeatListener();
  }

  void toggleShuffle() {
    _shuffleMode = !_shuffleMode;
    if (_shuffleMode && _tracks.isNotEmpty) {
      final randomIndex = _random.nextInt(_tracks.length);
      play(_tracks[randomIndex]);
    }
  }

  bool isLiked(Track track) => _likedTracks.contains(track.path);

  void toggleLike(Track track) {
    if (_likedTracks.contains(track.path)) {
      _likedTracks.remove(track.path);
    } else {
      _likedTracks.add(track.path);
    }
  }

  void dispose() {
    _repeatListener?.cancel();
    _positionListener?.cancel();
    _player.dispose();
  }

  Future<void> _activateAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.setActive(true);
    } catch (e) {
      // Ignore audio session errors
    }
  }
}
