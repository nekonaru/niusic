import 'track.dart';

class Playlist {
  Playlist({required this.id, required this.name, List<String>? trackPaths})
    : trackPaths = trackPaths ?? <String>[];

  final String id;
  String name;
  List<String> trackPaths;

  int get length => trackPaths.length;

  bool contains(String path) => trackPaths.contains(path);

  void add(Track track) {
    if (!trackPaths.contains(track.path)) {
      trackPaths.add(track.path);
    }
  }

  void removePath(String path) {
    trackPaths.remove(path);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'name': name, 'trackPaths': trackPaths};
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final raw = json['trackPaths'];
    final paths = <String>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is String) {
          paths.add(item);
        }
      }
    }
    return Playlist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled',
      trackPaths: paths,
    );
  }
}
