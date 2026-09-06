import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_service/audio_service.dart' as audio_service;
import 'services/audio_service.dart';
import 'services/background_audio_handler.dart';
import 'services/ios_lock_screen_handler.dart';
import 'screens/liquid_player_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/credits_screen.dart';
import 'screens/artist_screen.dart';

Future<void> _audioServiceEntrypoint() async {
  audio_service.AudioServiceBackground.run(() async {
    return BackgroundAudioHandler();
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.forven.pittyplayer.channel.audio',
    androidNotificationChannelName: 'Pitty Player',
    androidNotificationOngoing: true,
  );

  await audio_service.AudioService.init(
    builder: () => BackgroundAudioHandler(),
    config: const audio_service.AudioServiceConfig(
      androidResumeOnClick: true,
      androidStopForegroundOnPause: true,
      notificationColor: 0xFF667eea,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();

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
  final AudioService audioService;

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
    // Initialize iOS lock screen handler for control center and lock screen buttons
    IosLockScreenHandler.initialize(widget.audioService);
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
