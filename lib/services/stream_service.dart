import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/video_result.dart';

class _CachedUrl {
  const _CachedUrl(this.url, this.expiresAt);
  final String url;
  final DateTime expiresAt;
}

/// Hybrid provider: Piped instances for search, YouTube manifest for audio.
/// Piped endpoints carry no key and are served over HTTPS.
class StreamService {
  StreamService({
    YoutubeExplode? client,
    http.Client? httpClient,
    String? quality,
  }) : _client = client ?? YoutubeExplode(),
       _http = httpClient ?? http.Client(),
       audioQuality = quality ?? 'high';

  final YoutubeExplode _client;
  final http.Client _http;
  final Map<String, _CachedUrl> _urlCache = <String, _CachedUrl>{};

  /// 'low' picks the lowest bitrate audio, 'high' picks the highest.
  String audioQuality;

  static const List<String> _instances = <String>[
    'https://api.piped.private.coffee',
    'https://pipedapi.ducks.party',
  ];

  Future<List<VideoResult>> search(String query, {int maxResults = 20}) async {
    Object? lastError;
    for (final base in _instances) {
      try {
        final uri = Uri.parse(
          '$base/search?q=${Uri.encodeComponent(query)}&filter=videos',
        );
        final res = await _http
            .get(uri, headers: <String, String>{'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) {
          throw StateError('search ${res.statusCode}');
        }
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final items = decoded['items'] as List<dynamic>? ?? <dynamic>[];
        final results = <VideoResult>[];
        for (final item in items) {
          if (item is! Map<String, dynamic>) {
            continue;
          }
          final url = item['url'] as String? ?? '';
          final videoId = _videoIdFromWatchUrl(url);
          if (videoId == null) {
            continue;
          }
          final durationRaw = item['duration'];
          final duration = durationRaw is int && durationRaw > 0
              ? durationRaw
              : null;
          results.add(
            VideoResult(
              videoId: videoId,
              title: item['title'] as String? ?? videoId,
              author: item['uploaderName'] as String? ?? '',
              thumbnailUrl: item['thumbnail'] as String?,
              durationSeconds: duration,
            ),
          );
          if (results.length >= maxResults) {
            break;
          }
        }
        return results;
      } catch (e) {
        lastError = e;
      }
    }
    throw StateError('search failed: $lastError');
  }

  String? _videoIdFromWatchUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }
    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) {
      return v;
    }
    return null;
  }

  Future<String> resolveAudioUrl(String videoId) async {
    final cached = _urlCache[videoId];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      return cached.url;
    }
    final manifest = await _client.videos.streamsClient.getManifest(videoId);
    final audio = manifest.audioOnly.sortByBitrate();
    if (audio.isEmpty) {
      throw StateError('No audio streams for video $videoId');
    }
    final picked = audioQuality == 'low' ? audio.last : audio.first;
    final url = picked.url.toString();
    // Googlevideo URLs expire. Cache in memory for 1 hour.
    _urlCache[videoId] = _CachedUrl(
      url,
      DateTime.now().add(const Duration(hours: 1)),
    );
    return url;
  }

  void dispose() {
    _http.close();
    _client.close();
  }
}
