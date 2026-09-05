import 'package:just_audio_background/just_audio_background.dart';

class Track {
  final String path;
  final String title;
  final Duration duration;
  final String? imageAsset;

  Track({
    required this.path,
    required this.title,
    this.duration = Duration.zero,
    this.imageAsset,
  });

  /// Converte para MediaItem para mostrar na tela bloqueada do iOS/Android
  MediaItem toMediaItem() {
    return MediaItem(
      id: path,
      album: 'Pitty Player',
      title: title,
      artist: 'Pitty',
      duration: duration,
      artUri: imageAsset != null ? Uri.parse('asset://$imageAsset') : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;
}
