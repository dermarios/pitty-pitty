import 'package:flutter/material.dart';
import 'services/audio_service.dart';
import 'screens/player_screen.dart';

void main() {
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
      home: PlayerScreen(audioService: audioService),
    );
  }
}
