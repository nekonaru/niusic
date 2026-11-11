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
    'https://pipedapi.adminforge.de',
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.reallyaweso.me',
  ];

  Future<List<VideoResult>> search(
    String query, {
    int maxResults = 20,
    String filter = 'videos',
  }) async {
    Object? lastError;
    for (final base in _instances) {
      try {
        final uri = Uri.parse(
          '$base/search?q=${Uri.encodeComponent(query)}&filter=$filter',
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
          final type = item['type'] as String?;
          final url = item['url'] as String? ?? '';
          final videoId = _videoIdFromWatchUrl(url);
          if (type == 'channel') {
            continue;
          }
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
              channelId: _channelIdFromUrl(item['uploaderUrl'] as String?),
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

  Future<List<ChannelResult>> searchChannels(
    String query, {
    int maxResults = 10,
  }) async {
    Object? lastError;
    for (final base in _instances) {
      try {
        final uri = Uri.parse(
          '$base/search?q=${Uri.encodeComponent(query)}&filter=channels',
        );
        final res = await _http
            .get(uri, headers: <String, String>{'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) {
          throw StateError('search ${res.statusCode}');
        }
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final items = decoded['items'] as List<dynamic>? ?? <dynamic>[];
        final out = <ChannelResult>[];
        for (final item in items) {
          if (item is! Map<String, dynamic>) {
            continue;
          }
          final id = _channelIdFromUrl(item['url'] as String?);
          if (id == null) {
            continue;
          }
          out.add(
            ChannelResult(
              channelId: id,
              name: item['name'] as String? ?? '',
              thumbnailUrl: item['thumbnail'] as String?,
              description: item['description'] as String?,
              subscriberCount: item['subscribers'] is int
                  ? item['subscribers'] as int
                  : null,
              verified: item['verified'] == true,
            ),
          );
          if (out.length >= maxResults) {
            break;
          }
        }
        return out;
      } catch (e) {
        lastError = e;
      }
    }
    throw StateError('channel search failed: $lastError');
  }

  Future<ChannelDetail> fetchChannel(String channelId) async {
    Object? lastError;
    for (final base in _instances) {
      try {
        final uri = Uri.parse('$base/channel/$channelId');
        final res = await _http
            .get(uri, headers: <String, String>{'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) {
          throw StateError('channel ${res.statusCode}');
        }
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final uploads = <VideoResult>[];
        final related =
            decoded['relatedStreams'] as List<dynamic>? ?? <dynamic>[];
        for (final item in related) {
          if (item is! Map<String, dynamic>) {
            continue;
          }
          final vid = _videoIdFromWatchUrl(item['url'] as String? ?? '');
          if (vid == null) {
            continue;
          }
          uploads.add(
            VideoResult(
              videoId: vid,
              title: item['title'] as String? ?? vid,
              author: item['uploaderName'] as String? ?? '',
              channelId: channelId,
              thumbnailUrl: item['thumbnail'] as String?,
            ),
          );
        }
        return ChannelDetail(
          channelId: decoded['id'] as String? ?? channelId,
          name: decoded['name'] as String? ?? '',
          avatarUrl: decoded['avatarUrl'] as String?,
          bannerUrl: decoded['bannerUrl'] as String?,
          description: decoded['description'] as String?,
          subscriberCount: decoded['subscriberCount'] is int
              ? decoded['subscriberCount'] as int
              : null,
          uploads: uploads,
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw StateError('channel failed: $lastError');
  }

  Future<List<VideoResult>> related(String videoId) async {
    Object? lastError;
    for (final base in _instances) {
      try {
        final uri = Uri.parse('$base/streams/$videoId');
        final res = await _http
            .get(uri, headers: <String, String>{'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) {
          throw StateError('streams ${res.statusCode}');
        }
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final items =
            decoded['relatedStreams'] as List<dynamic>? ?? <dynamic>[];
        final out = <VideoResult>[];
        for (final item in items) {
          if (item is! Map<String, dynamic>) {
            continue;
          }
          final vid = _videoIdFromWatchUrl(item['url'] as String? ?? '');
          if (vid == null) {
            continue;
          }
          out.add(
            VideoResult(
              videoId: vid,
              title: item['title'] as String? ?? vid,
              author: item['uploaderName'] as String? ?? '',
              thumbnailUrl: item['thumbnail'] as String?,
            ),
          );
        }
        return out;
      } catch (e) {
        lastError = e;
      }
    }
    throw StateError('related failed: $lastError');
  }

  String? _channelIdFromUrl(String? url) {
    if (url == null) {
      return null;
    }
    final parts = url.split('/');
    if (parts.length >= 2 && parts[parts.length - 2] == 'channel') {
      final id = parts.last;
      return id.isEmpty ? null : id;
    }
    return null;
  }

  String? _playlistIdFromUrl(String? url) {
    if (url == null) {
      return null;
    }
    final uri = Uri.tryParse(url);
    return uri?.queryParameters['list'];
  }

  Future<List<PlaylistResult>> searchPlaylists(
    String query, {
    int maxResults = 10,
  }) async {
    Object? lastError;
    for (final base in _instances) {
      try {
        final uri = Uri.parse(
          '$base/search?q=${Uri.encodeComponent(query)}&filter=playlists',
        );
        final res = await _http
            .get(uri, headers: <String, String>{'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) {
          throw StateError('search ${res.statusCode}');
        }
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final items = decoded['items'] as List<dynamic>? ?? <dynamic>[];
        final out = <PlaylistResult>[];
        for (final item in items) {
          if (item is! Map<String, dynamic>) {
            continue;
          }
          final id = _playlistIdFromUrl(item['url'] as String?);
          if (id == null) {
            continue;
          }
          out.add(
            PlaylistResult(
              playlistId: id,
              name: item['name'] as String? ?? '',
              thumbnailUrl: item['thumbnail'] as String?,
              author: item['uploaderName'] as String?,
              videoCount: item['videos'] is int ? item['videos'] as int : null,
            ),
          );
          if (out.length >= maxResults) {
            break;
          }
        }
        return out;
      } catch (e) {
        lastError = e;
      }
    }
    throw StateError('playlist search failed: $lastError');
  }

  Future<OnlinePlaylistDetail> fetchPlaylist(String playlistId) async {
    Object? lastError;
    for (final base in _instances) {
      try {
        final uri = Uri.parse('$base/playlists/$playlistId');
        final res = await _http
            .get(uri, headers: <String, String>{'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) {
          throw StateError('playlist ${res.statusCode}');
        }
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final videos = <VideoResult>[];
        final related =
            decoded['relatedStreams'] as List<dynamic>? ?? <dynamic>[];
        for (final item in related) {
          if (item is! Map<String, dynamic>) {
            continue;
          }
          final vid = _videoIdFromWatchUrl(item['url'] as String? ?? '');
          if (vid == null) {
            continue;
          }
          videos.add(
            VideoResult(
              videoId: vid,
              title: item['title'] as String? ?? vid,
              author: item['uploaderName'] as String? ?? '',
              thumbnailUrl: item['thumbnail'] as String?,
            ),
          );
        }
        return OnlinePlaylistDetail(
          playlistId: playlistId,
          name: decoded['name'] as String? ?? '',
          description: decoded['description'] as String?,
          thumbnailUrl: decoded['thumbnailUrl'] as String?,
          videos: videos,
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw StateError('playlist failed: $lastError');
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
