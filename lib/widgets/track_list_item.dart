import 'package:flutter/material.dart';
import '../models/track.dart';

class TrackListItem extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback onTap;

  const TrackListItem({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isPlaying,
      selectedTileColor: Colors.blue.withValues(alpha: 0.3),
      leading: Icon(
        isPlaying ? Icons.music_note : Icons.music_note_outlined,
        color: isPlaying ? Colors.blue : Colors.white70,
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
          color: isPlaying ? Colors.blue : Colors.white,
        ),
      ),
      onTap: onTap,
    );
  }
}