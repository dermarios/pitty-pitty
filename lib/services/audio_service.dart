import 'dart:async';
import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import '../models/track.dart';
import 'background_audio_handler.dart';

class AudioService {
  late AudioPlayer _player;
  List<Track> _tracks = [];
  Track? _currentTrack;
  bool _tracksLoaded = false;
  int _repeatMode = 0; // 0: no repeat, 1: repeat one, 2: repeat all
  bool _shuffleMode = false;
  StreamSubscription<PlayerState>? _repeatListener;
  StreamSubscription<Duration>? _positionListener;
  Set<String> _likedTracks = {};
  final _random = math.Random();

  AudioService() {
    _player = AudioPlayer();
    _initializeAudioSession().ignore();
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    // Listener para mudanças de estado do player
    _player.playerStateStream.listen((state) {
      _updateBackgroundHandler();
    });

    // Listener para mudanças de posição (atualiza lock screen)
    _positionListener?.cancel();
    _positionListener = _player.positionStream.listen((position) {
      if (_currentTrack != null) {
        BackgroundAudioHandler.instance.updateElapsedTime(position);
      }
    });
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

  Future<void> _updateBackgroundHandler() async {
    if (_currentTrack == null) return;

    try {
      // Atualizar metadados e artwork na tela bloqueada
      await BackgroundAudioHandler.instance.updateNowPlaying(
        id: _currentTrack!.path,
        title: _currentTrack!.title,
        artist: 'Pitty',
        album: 'Pitty Player',
        duration: _currentTrack!.duration,
        artworkAssetPath: _currentTrack!.imageAsset,
        elapsedTime: _player.position,
      );

      // Atualizar estado de playback
      final playerState = _player.playerState;
      BackgroundAudioHandler.instance.updatePlaybackState(
        playing: playerState.playing,
        processingState: _convertProcessingState(playerState.processingState),
        position: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      );

      // Registrar callbacks se ainda não foram registrados
      _registerBackgroundCallbacks();
    } catch (e) {
      print('Error updating background handler: $e');
    }
  }

  AudioProcessingState _convertProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  void _registerBackgroundCallbacks() {
    BackgroundAudioHandler.instance.setCallbacks(
      play: () async {
        if (_currentTrack != null) {
          await resume();
        }
      },
      pause: pause,
      next: next,
      previous: previous,
      seek: seekTo,
    );
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

    // Adicionar tracks sem bloquear no carregamento de duração
    _tracks.addAll(hardcodedTracks);
    _tracks.sort((a, b) => a.title.compareTo(b.title));

    if (_tracks.isNotEmpty && _currentTrack == null) {
      _currentTrack = _tracks.first;
      await _setCurrentAudioSource(_currentTrack!);
    }
    _tracksLoaded = true;
  }

  Future<void> play(Track track) async {
    try {
      _currentTrack = track;
      print('→ Playing: ${track.title}');
      print('  - Artist: Pitty');

      await _activateAudioSession();
      await _setCurrentAudioSource(track);
      await _player.play();
      print('✓ Audio started playing');

      _setupRepeatListener();

      // Atualizar lock screen
      await _updateBackgroundHandler();
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
    await _updateBackgroundHandler();
  }

  Future<void> resume() async {
    await _activateAudioSession();
    await _player.play();
    await _updateBackgroundHandler();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
    await _updateBackgroundHandler();
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
    await _updateBackgroundHandler();
  }

  Future<void> previous() async {
    if (_currentTrack == null) return;
    final currentIndex = _tracks.indexOf(_currentTrack!);
    if (currentIndex > 0) {
      await play(_tracks[currentIndex - 1]);
    }
    await _updateBackgroundHandler();
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
    BackgroundAudioHandler.instance.clearNowPlaying();
    _player.dispose();
  }

  Future<void> _setCurrentAudioSource(Track track) async {
    await _player.setAudioSource(
      AudioSource.asset(
        track.path,
        tag: track.toMediaItem(),
      ),
    );
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
