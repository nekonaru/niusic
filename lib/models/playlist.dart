import 'track.dart';

class Playlist {
  Playlist({required this.id, required this.name, List<String>? trackIds})
    : trackIds = trackIds ?? <String>[];

  final String id;
  String name;
  List<String> trackIds;

  int get length => trackIds.length;

  bool contains(String id) => trackIds.contains(id);

  void add(Track track) {
    if (!trackIds.contains(track.id)) {
      trackIds.add(track.id);
    }
  }

  void removeId(String id) {
    trackIds.remove(id);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'name': name, 'trackIds': trackIds};
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final ids = <String>[];
    // Read both new key and legacy key for backward compat.
    final raw = json['trackIds'] ?? json['trackPaths'];
    if (raw is List) {
      for (final item in raw) {
        if (item is String) {
          ids.add(item);
        }
      }
    }
    return Playlist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled',
      trackIds: ids,
    );
  }
}
