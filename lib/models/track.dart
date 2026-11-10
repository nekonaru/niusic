enum TrackKind { local, remote }

class Track {
  const Track({
    required this.id,
    required this.title,
    this.kind = TrackKind.local,
    this.path,
    this.url,
    this.author,
    this.thumbnailUrl,
    this.videoId,
    this.durationSeconds,
    this.downloadPath,
  });

  final String id;
  final String title;
  final TrackKind kind;
  final String? path;
  final String? url;
  final String? author;
  final String? thumbnailUrl;
  final String? videoId;
  final int? durationSeconds;
  final String? downloadPath;

  bool get isLocal => kind == TrackKind.local;
  bool get isRemote => kind == TrackKind.remote;
  bool get isDownloaded => downloadPath != null && downloadPath!.isNotEmpty;

  String get fileName {
    if (path != null) {
      final normalized = path!.replaceAll('\\', '/');
      final parts = normalized.split('/');
      return parts.isEmpty ? path! : parts.last;
    }
    return author ?? title;
  }

  String? get subtitle {
    if (isRemote) {
      if (author != null && author!.isNotEmpty) {
        return author;
      }
      return videoId;
    }
    return fileName;
  }

  static String titleFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    final name = parts.isEmpty ? path : parts.last;
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    final cleaned = base.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    return cleaned.isEmpty ? base : cleaned;
  }

  factory Track.fromPath(String path) {
    return Track(id: 'local:$path', title: titleFromPath(path), path: path);
  }

  factory Track.remote({
    required String videoId,
    required String title,
    String? author,
    String? thumbnailUrl,
    int? durationSeconds,
    String? url,
  }) {
    return Track(
      id: 'yt:$videoId',
      title: title,
      kind: TrackKind.remote,
      author: author,
      thumbnailUrl: thumbnailUrl,
      videoId: videoId,
      durationSeconds: durationSeconds,
      url: url,
    );
  }

  Track copyWithUrl(String? newUrl) {
    return Track(
      id: id,
      title: title,
      kind: kind,
      path: path,
      url: newUrl,
      author: author,
      thumbnailUrl: thumbnailUrl,
      videoId: videoId,
      durationSeconds: durationSeconds,
      downloadPath: downloadPath,
    );
  }

  Track copyWithDownload(String? newPath) {
    return Track(
      id: id,
      title: title,
      kind: kind,
      path: path,
      url: url,
      author: author,
      thumbnailUrl: thumbnailUrl,
      videoId: videoId,
      durationSeconds: durationSeconds,
      downloadPath: newPath,
    );
  }

  Map<String, String> toJson() {
    final map = <String, String>{'id': id, 'title': title};
    map['kind'] = kind.name;
    final p = path;
    if (p != null) map['path'] = p;
    final u = url;
    if (u != null) map['url'] = u;
    final a = author;
    if (a != null) map['author'] = a;
    final t = thumbnailUrl;
    if (t != null) map['thumb'] = t;
    final v = videoId;
    if (v != null) map['vid'] = v;
    final d = durationSeconds;
    if (d != null) map['dur'] = d.toString();
    final dp = downloadPath;
    if (dp != null && dp.isNotEmpty) map['dpath'] = dp;
    return map;
  }

  factory Track.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? '';
    final kindName = json['kind'] as String?;
    final pathJson = json['path'] as String?;
    final idJson = json['id'] as String?;
    // Backward compat: old entries only have path and title.
    if (kindName == null && idJson == null && pathJson != null) {
      final t = title.isEmpty ? titleFromPath(pathJson) : title;
      return Track(id: 'local:$pathJson', title: t, path: pathJson);
    }
    final kind = kindName == 'remote' ? TrackKind.remote : TrackKind.local;
    var id = idJson ?? pathJson ?? '';
    // Old entries used the bare path as id. Normalize so local and remote
    // ids cannot collide after the v1.0 id scheme change.
    if (kind == TrackKind.local &&
        !id.startsWith('local:') &&
        pathJson != null) {
      id = 'local:$pathJson';
    }
    if (kind == TrackKind.remote && !id.startsWith('yt:')) {
      id = 'yt:${json['vid'] as String? ?? id}';
    }
    final durRaw = json['dur'];
    int? dur;
    if (durRaw is String) {
      dur = int.tryParse(durRaw);
    } else if (durRaw is int) {
      dur = durRaw;
    }
    return Track(
      id: id,
      title: title.isEmpty && pathJson != null
          ? titleFromPath(pathJson)
          : title,
      kind: kind,
      path: pathJson,
      url: json['url'] as String?,
      author: json['author'] as String?,
      thumbnailUrl: json['thumb'] as String?,
      videoId: json['vid'] as String?,
      durationSeconds: dur,
      downloadPath: json['dpath'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Track && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
