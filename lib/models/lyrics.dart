class LyricsResult {
  const LyricsResult({
    required this.title,
    required this.artist,
    this.plainLyrics,
    this.syncedLyrics,
  });

  final String title;
  final String artist;
  final String? plainLyrics;
  final String? syncedLyrics;

  bool get hasLyrics =>
      (plainLyrics != null && plainLyrics!.isNotEmpty) ||
      (syncedLyrics != null && syncedLyrics!.isNotEmpty);
}

class SyncedLine {
  const SyncedLine(this.time, this.text);
  final Duration time;
  final String text;
}
