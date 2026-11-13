import '../models/track.dart';
import 'scanner_service.dart';

/// Outcome of a library merge pass.
class MergeResult {
  const MergeResult(this.added, this.pruned);

  final int added;
  final int pruned;
}

String _normalize(String path) => path.replaceAll('\\', '/').toLowerCase();

/// Merges scanned device audio into [library].
///
/// * New paths (matched case-insensitively) are appended as local tracks.
///   Track ids keep the raw `local:<path>` scheme used by the rest of the app.
/// * Tracks already present are skipped; duplicate paths never appear twice.
/// * Local entries whose path is missing from the scan and whose file does
///   not exist according to [fileExists] are removed, and stale queue
///   references are dropped.
MergeResult mergeScannedTracksInto(
  List<Track> library,
  List<Track> queue,
  List<ScannedTrack> scanned, {
  required bool Function(String path) fileExists,
}) {
  final byId = <String, Track>{for (final t in library) t.id: t};
  final byPath = <String, Track>{
    for (final t in library)
      if (t.isLocal && t.path != null) _normalize(t.path!): t,
  };
  var added = 0;
  for (final item in scanned) {
    final norm = _normalize(item.path);
    final id = 'local:${item.path}';
    if (byId.containsKey(id) || byPath.containsKey(norm)) {
      continue;
    }
    final title = item.title.isEmpty || item.title == '<unknown>'
        ? Track.titleFromPath(item.path)
        : item.title;
    final artist =
        item.artist == null ||
            item.artist!.isEmpty ||
            item.artist == '<unknown>'
        ? null
        : item.artist;
    final track = Track(
      id: id,
      title: title,
      path: item.path,
      author: artist,
      durationSeconds: item.durationSeconds,
    );
    library.add(track);
    byId[id] = track;
    byPath[norm] = track;
    added++;
  }
  final scannedPaths = scanned.map((t) => _normalize(t.path)).toSet();
  final stale = library
      .where(
        (t) =>
            t.isLocal &&
            t.path != null &&
            !scannedPaths.contains(_normalize(t.path!)),
      )
      .toList();
  var pruned = 0;
  for (final track in stale) {
    if (!fileExists(track.path!)) {
      library.remove(track);
      pruned++;
    }
  }
  if (pruned > 0) {
    queue.removeWhere((t) => !library.contains(t));
  }
  return MergeResult(added, pruned);
}
