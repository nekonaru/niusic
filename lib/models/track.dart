class Track {
  const Track({required this.path, required this.title});

  final String path;
  final String title;

  String get id => path;

  String get fileName {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isEmpty ? path : parts.last;
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
    return Track(path: path, title: titleFromPath(path));
  }

  Map<String, String> toJson() {
    return <String, String>{'path': path, 'title': title};
  }

  factory Track.fromJson(Map<String, dynamic> json) {
    final path = json['path'] as String? ?? '';
    final title = json['title'] as String? ?? titleFromPath(path);
    return Track(path: path, title: title);
  }

  @override
  bool operator ==(Object other) {
    return other is Track && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;
}
