import 'package:flutter_test/flutter_test.dart';

import 'package:niusic/models/track.dart';
import 'package:niusic/services/library_sort.dart';

List<Track> _tracks() => [
  Track(
    id: 'local:/a',
    title: 'Banana',
    path: '/a',
    author: 'Zebra',
    durationSeconds: 300,
  ),
  Track(
    id: 'local:/b',
    title: 'Cherry pie',
    path: '/b',
    author: 'Ant',
    durationSeconds: 100,
  ),
  Track(
    id: 'yt:x',
    title: 'apple',
    videoId: 'x',
    kind: TrackKind.remote,
    author: 'Miles',
    durationSeconds: 200,
  ),
];

void main() {
  test('sort by name strips leading articles', () {
    final sorted = sortLibrary(_tracks(), LibrarySort.name, const []);
    expect(sorted.map((t) => t.title).toList(), [
      'apple',
      'Banana',
      'Cherry pie',
    ]);
  });

  test('sort by artist is case insensitive', () {
    final sorted = sortLibrary(_tracks(), LibrarySort.artist, const []);
    expect(sorted.map((t) => t.author).toList(), ['Ant', 'Miles', 'Zebra']);
  });

  test('sort by duration descending', () {
    final sorted = sortLibrary(_tracks(), LibrarySort.duration, const []);
    expect(sorted.map((t) => t.durationSeconds).toList(), [300, 200, 100]);
  });

  test('sort by recent orders by history', () {
    final sorted = sortLibrary(_tracks(), LibrarySort.recent, const [
      'yt:x',
      'local:/a',
    ]);
    expect(sorted.first.id, 'yt:x');
    expect(sorted[1].id, 'local:/a');
  });
}
