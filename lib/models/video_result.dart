class VideoResult {
  const VideoResult({
    required this.videoId,
    required this.title,
    required this.author,
    this.channelId,
    this.thumbnailUrl,
    this.durationSeconds,
  });

  final String videoId;
  final String title;
  final String author;
  final String? channelId;
  final String? thumbnailUrl;
  final int? durationSeconds;
}

class PlaylistResult {
  const PlaylistResult({
    required this.playlistId,
    required this.name,
    this.thumbnailUrl,
    this.author,
    this.videoCount,
  });

  final String playlistId;
  final String name;
  final String? thumbnailUrl;
  final String? author;
  final int? videoCount;
}

class OnlinePlaylistDetail {
  const OnlinePlaylistDetail({
    required this.playlistId,
    required this.name,
    this.description,
    this.thumbnailUrl,
    this.videos = const <VideoResult>[],
  });

  final String playlistId;
  final String name;
  final String? description;
  final String? thumbnailUrl;
  final List<VideoResult> videos;
}

class ChannelResult {
  const ChannelResult({
    required this.channelId,
    required this.name,
    this.thumbnailUrl,
    this.description,
    this.subscriberCount,
    this.verified = false,
  });

  final String channelId;
  final String name;
  final String? thumbnailUrl;
  final String? description;
  final int? subscriberCount;
  final bool verified;
}

class ChannelDetail {
  const ChannelDetail({
    required this.channelId,
    required this.name,
    this.avatarUrl,
    this.bannerUrl,
    this.description,
    this.subscriberCount,
    this.uploads = const <VideoResult>[],
  });

  final String channelId;
  final String name;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? description;
  final int? subscriberCount;
  final List<VideoResult> uploads;
}
