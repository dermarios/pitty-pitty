import 'package:flutter/material.dart';
import 'dart:ui' show Color;
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_service/audio_service.dart';
import 'services/audio_service.dart' as pitty_audio;
import 'services/background_audio_handler.dart';
import 'screens/liquid_player_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/credits_screen.dart';
import 'screens/artist_screen.dart';

late AudioHandler _audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.forven.pittyplayer.channel.audio',
    androidNotificationChannelName: 'Pitty Player',
    androidNotificationOngoing: true,
  );

  _audioHandler = await AudioService.init(
    builder: () => BackgroundAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.forven.pittyplayer.channel.audio',
      androidNotificationChannelName: 'Pitty Player',
      androidNotificationOngoing: true,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final audioService = pitty_audio.PittyAudioService();

    return MaterialApp(
      title: 'Pitty Player',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomeWithSwipe(audioService: audioService),
    );
  }
}

class HomeWithSwipe extends StatefulWidget {
  final pitty_audio.PittyAudioService audioService;

  const HomeWithSwipe({
    super.key,
    required this.audioService,
  });

  @override
  State<HomeWithSwipe> createState() => _HomeWithSwipeState();
}

class _HomeWithSwipeState extends State<HomeWithSwipe> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      children: [
        ArtistScreen(
          audioService: widget.audioService,
          onBackPressed: () {
            _pageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          onPlayPressed: () {
            _pageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
        LiquidPlayerScreen(
          audioService: widget.audioService,
          onNavigateToSide: () {
            _pageController.animateToPage(
              2,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          onNavigateToArtist: () {
            _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
        GalleryScreen(
          audioService: widget.audioService,
        ),
        CreditsScreen(
          audioService: widget.audioService,
        ),
      ],
    );
  }
}
