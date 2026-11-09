class VideoResult {
  const VideoResult({
    required this.videoId,
    required this.title,
    required this.author,
    this.thumbnailUrl,
    this.durationSeconds,
  });

  final String videoId;
  final String title;
  final String author;
  final String? thumbnailUrl;
  final int? durationSeconds;
}
