import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lyrics.dart';

/// Lyrics from LRCLIB (public, no key, HTTPS).
class LyricsService {
  LyricsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<LyricsResult?> fetch(String title, String artist) async {
    final query = Uri.encodeQueryComponent('$title $artist'.trim());
    final uri = Uri.parse('https://lrclib.net/api/search?q=$query');
    final res = await _client
        .get(
          uri,
          headers: <String, String>{'User-Agent': 'Niusic/0.5 (Flutter)'},
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      return null;
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    if (decoded.isEmpty) {
      return null;
    }
    final best = decoded.first as Map<String, dynamic>;
    final plain = best['plainLyrics'] as String?;
    final synced = best['syncedLyrics'] as String?;
    return LyricsResult(
      title: best['trackName'] as String? ?? title,
      artist: best['artistName'] as String? ?? artist,
      plainLyrics: plain,
      syncedLyrics: synced,
    );
  }

  List<SyncedLine> parseSynced(String synced) {
    final lines = <SyncedLine>[];
    final pattern = RegExp(r'\[(\d+):(\d{2})(?:[.:](\d{2}))?\]\s*(.*)');
    for (final raw in synced.split('\n')) {
      final m = pattern.firstMatch(raw.trim());
      if (m == null) {
        continue;
      }
      final minutes = int.parse(m.group(1)!);
      final seconds = int.parse(m.group(2)!);
      final centis = int.tryParse(m.group(3) ?? '') ?? 0;
      final time = Duration(
        minutes: minutes,
        seconds: seconds,
        milliseconds: centis * 10,
      );
      lines.add(SyncedLine(time, m.group(4) ?? ''));
    }
    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }

  void dispose() {
    _client.close();
  }
}
