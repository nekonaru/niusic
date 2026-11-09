import 'dart:convert';

import 'package:http/http.dart' as http;

class ChartItem {
  const ChartItem({
    required this.title,
    required this.artist,
    this.coverUrl,
    this.position,
  });

  final String title;
  final String artist;
  final String? coverUrl;
  final int? position;
}

/// Daily chart from Deezer (public, no key, HTTPS).
class ChartService {
  ChartService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<ChartItem>> topTracks({int limit = 10}) async {
    final uri = Uri.parse('https://api.deezer.com/chart/0/tracks?limit=$limit');
    final res = await _client
        .get(
          uri,
          headers: <String, String>{'User-Agent': 'Niusic/0.5 (Flutter)'},
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw StateError('chart failed: ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>? ?? <dynamic>[];
    final items = <ChartItem>[];
    for (var i = 0; i < data.length; i++) {
      final item = data[i] as Map<String, dynamic>;
      final artistRaw = item['artist'];
      final artistName = artistRaw is Map<String, dynamic>
          ? artistRaw['name'] as String? ?? ''
          : '';
      items.add(
        ChartItem(
          title: item['title'] as String? ?? '',
          artist: artistName,
          coverUrl: item['album'] is Map
              ? (item['album']['cover_medium'] as String?)
              : null,
          position: i + 1,
        ),
      );
    }
    return items;
  }

  void dispose() {
    _client.close();
  }
}
