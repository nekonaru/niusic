class RadioStation {
  const RadioStation({
    required this.stationUuid,
    required this.name,
    required this.streamUrl,
    this.favicon,
    this.country,
    this.codec,
    this.bitrate,
    this.votes,
  });

  final String stationUuid;
  final String name;
  final String streamUrl;
  final String? favicon;
  final String? country;
  final String? codec;
  final int? bitrate;
  final int? votes;

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    final uuid = (json['stationuuid'] as String? ?? '').trim();
    final streamUrl =
        (json['url_resolved'] as String? ?? json['url'] as String? ?? '')
            .trim();
    final name = (json['name'] as String? ?? '').trim();
    final favicon = (json['favicon'] as String?)?.trim();
    return RadioStation(
      stationUuid: uuid,
      name: name,
      streamUrl: streamUrl,
      favicon: favicon != null && favicon.startsWith('http') ? favicon : null,
      country: (json['country'] as String?)?.trim(),
      codec: (json['codec'] as String?)?.trim().toLowerCase(),
      bitrate: json['bitrate'] is int
          ? json['bitrate'] as int
          : int.tryParse('${json['bitrate']}'),
      votes: json['votes'] is int
          ? json['votes'] as int
          : int.tryParse('${json['votes']}'),
    );
  }

  bool get playable {
    if (stationUuid.isEmpty || name.isEmpty || streamUrl.isEmpty) {
      return false;
    }
    final lower = streamUrl.toLowerCase();
    if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
      return false;
    }
    // ExoPlayer cannot decode Ogg Vorbis, and raw .pls / .m3u playlist files
    // are not audio streams.
    if (lower.endsWith('.pls') || lower.endsWith('.m3u')) {
      return false;
    }
    if (codec == 'ogg' || codec == 'vorbis') {
      return false;
    }
    return true;
  }
}
