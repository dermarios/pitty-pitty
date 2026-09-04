import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/audio_service.dart';
import '../widgets/progress_bar.dart';
import '../widgets/player_controls.dart';
import '../widgets/track_list_item.dart';

class PlayerScreen extends StatefulWidget {
  final AudioService audioService;

  const PlayerScreen({
    super.key,
    required this.audioService,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    await widget.audioService.loadTracks();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final audioService = widget.audioService;
    final player = audioService.player;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pitty Player'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Player section (top 50%)
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Track title and artwork
                    StreamBuilder<Duration?>(
                      stream: player.durationStream,
                      builder: (context, snapshot) {
                        return Column(
                          children: [
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.music_note,
                                size: 80,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _getCurrentTrackTitle(),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    // Progress bar
                    ProgressBar(
                      player: player,
                      onSeek: () {},
                    ),
                    // Controls
                    PlayerControls(
                      player: player,
                      onPrevious: _previousTrack,
                      onNext: _nextTrack,
                    ),
                  ],
                ),
              ),
            ),
            // Divider
            const Divider(height: 1),
            // Tracks list section (bottom 50%)
            Expanded(
              flex: 1,
              child: audioService.tracks.isEmpty
                  ? const Center(
                      child: Text('No tracks found in assets/musicas/'),
                    )
                  : ListView.builder(
                      itemCount: audioService.tracks.length,
                      itemBuilder: (context, index) {
                        final track = audioService.tracks[index];
                        final isPlaying = audioService.currentTrack == track;
                        return TrackListItem(
                          track: track,
                          isPlaying: isPlaying,
                          onTap: () => _playTrack(track),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentTrackTitle() {
    final currentTrack = widget.audioService.currentTrack;
    return currentTrack?.title ?? 'Select a track';
  }

  Future<void> _playTrack(Track track) async {
    await widget.audioService.play(track);
    setState(() {});
  }

  Future<void> _nextTrack() async {
    await widget.audioService.next();
    setState(() {});
  }

  Future<void> _previousTrack() async {
    await widget.audioService.previous();
    setState(() {});
  }
}
