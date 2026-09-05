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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;
}
