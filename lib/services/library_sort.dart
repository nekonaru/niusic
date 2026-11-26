import '../models/track.dart';

/// Sort orders supported by the library screen.
enum LibrarySort { name, artist, duration, recent, recentAdded }

/// Lowercases the title and strips a leading article so "The Beatles"
/// sorts under B.
String _titleKey(String title) {
  final lowered = title.toLowerCase().trim();
  return lowered.replaceFirst(RegExp(r'^(the|a|an)\s+'), '');
}

/// Returns a sorted copy of [tracks] without mutating it.
List<Track> sortLibrary(
  List<Track> tracks,
  LibrarySort sort,
  List<String> historyIds,
) {
  final list = List<Track>.of(tracks);
  switch (sort) {
    case LibrarySort.name:
      list.sort((a, b) => _titleKey(a.title).compareTo(_titleKey(b.title)));
    case LibrarySort.artist:
      list.sort(
        (a, b) => (a.author ?? a.title).toLowerCase().compareTo(
          (b.author ?? b.title).toLowerCase(),
        ),
      );
    case LibrarySort.duration:
      list.sort(
        (a, b) => (b.durationSeconds ?? 0).compareTo(a.durationSeconds ?? 0),
      );
    case LibrarySort.recentAdded:
      list.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
    case LibrarySort.recent:
      final index = <String, int>{
        for (var i = 0; i < historyIds.length; i++) historyIds[i]: i,
      };
      list.sort(
        (a, b) => (index[a.id] ?? 1 << 30).compareTo(index[b.id] ?? 1 << 30),
      );
  }
  return list;
}
