import 'package:flutter_test/flutter_test.dart';

import 'package:niusic/models/track.dart';
import 'package:niusic/services/library_merge.dart';
import 'package:niusic/services/scanner_service.dart';

void main() {
  test('mergeScannedTracksInto adds device tracks without duplicates', () {
    final library = <Track>[];
    final queue = <Track>[];
    final result = mergeScannedTracksInto(library, queue, const [
      ScannedTrack(
        path: '/storage/emulated/0/Music/a.mp3',
        title: 'Song A',
        artist: 'Artist A',
        durationSeconds: 123,
      ),
      ScannedTrack(path: '/storage/emulated/0/Music/b.mp3', title: ''),
    ], fileExists: (_) => true);
    expect(result.added, 2);
    expect(result.pruned, 0);
    expect(library.length, 2);
    expect(library.first.path, '/storage/emulated/0/Music/a.mp3');
    expect(library.first.author, 'Artist A');
    expect(library.first.durationSeconds, 123);
    // Empty title falls back to the file name.
    expect(library.last.title, isNotEmpty);
    // Merging again with an overlapping list skips a.mp3.
    final again = mergeScannedTracksInto(library, queue, const [
      ScannedTrack(path: '/storage/emulated/0/Music/a.mp3', title: 'Song A'),
      ScannedTrack(path: '/storage/emulated/0/Music/c.mp3', title: 'Song C'),
    ], fileExists: (_) => true);
    expect(again.added, 1);
    expect(again.pruned, 0);
    expect(
      library.map((t) => t.path),
      containsAll(<String>[
        '/storage/emulated/0/Music/a.mp3',
        '/storage/emulated/0/Music/c.mp3',
      ]),
    );
  });

  test('mergeScannedTracksInto flags unknown artists as missing', () {
    final library = <Track>[];
    final queue = <Track>[];
    mergeScannedTracksInto(library, queue, const [
      ScannedTrack(path: '/x/y.mp3', title: 'Song', artist: '<unknown>'),
    ], fileExists: (_) => true);
    expect(library.single.author, isNull);
  });

  test('mergeScannedTracksInto prunes local entries missing on disk', () {
    final library = <Track>[];
    final queue = <Track>[];
    mergeScannedTracksInto(library, queue, const [
      ScannedTrack(path: '/gone/track.mp3', title: 'Gone'),
    ], fileExists: (_) => true);
    expect(library.length, 1);
    // The next scan no longer reports the file, and the file does not exist,
    // so the stale entry is removed.
    final result = mergeScannedTracksInto(library, queue, const [
      ScannedTrack(path: '/kept/track.mp3', title: 'Kept'),
    ], fileExists: (_) => false);
    expect(result.added, 1);
    expect(result.pruned, 1);
    expect(library.map((t) => t.path), contains('/kept/track.mp3'));
    expect(library.any((t) => t.path == '/gone/track.mp3'), isFalse);
  });

  test('mergeScannedTracksInto keeps entries when disk is reachable', () {
    final library = <Track>[];
    final queue = <Track>[];
    mergeScannedTracksInto(library, queue, const [
      ScannedTrack(path: '/sd/track.mp3', title: 'Card'),
    ], fileExists: (_) => true);
    // Path absent from the next scan but still readable on disk: kept.
    final result = mergeScannedTracksInto(library, queue, const [
      ScannedTrack(path: '/other/track.mp3', title: 'Other'),
    ], fileExists: (_) => true);
    expect(result.pruned, 0);
    expect(library.any((t) => t.path == '/sd/track.mp3'), isTrue);
  });
}
