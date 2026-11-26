import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:niusic/models/track.dart';
import 'package:niusic/services/library_sort.dart';
import 'package:niusic/services/player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('sort by recently added', () {
    final tracks = [
      Track(id: 'a', title: 'A', kind: TrackKind.remote, dateAdded: 100),
      Track(id: 'b', title: 'B', kind: TrackKind.remote, dateAdded: 300),
      Track(id: 'c', title: 'C', kind: TrackKind.remote, dateAdded: 200),
    ];
    final sorted = sortLibrary(tracks, LibrarySort.recentAdded, const []);
    expect(sorted.map((t) => t.id).toList(), ['b', 'c', 'a']);
  });

  test('artists and albums groups are sorted', () async {
    final state = AppState();
    addTearDown(state.dispose);
    state.library.addAll([
      Track(
        id: 'a',
        title: 'A',
        kind: TrackKind.remote,
        author: 'Zebra',
        album: 'One',
      ),
      Track(
        id: 'b',
        title: 'B',
        kind: TrackKind.remote,
        author: 'Ant',
        album: 'Two',
      ),
    ]);
    expect(state.artists().keys.toList(), ['Ant', 'Zebra']);
    expect(state.albums().keys.toList(), ['One', 'Two']);
  });

  test('duplicates detection and removal', () async {
    final state = AppState();
    addTearDown(state.dispose);
    state.library.addAll([
      Track(
        id: 'a',
        title: 'Song',
        kind: TrackKind.remote,
        author: 'Artist',
        durationSeconds: 100,
      ),
      Track(
        id: 'b',
        title: 'Song',
        kind: TrackKind.remote,
        author: 'Artist',
        durationSeconds: 100,
      ),
    ]);
    expect(state.duplicates().length, 1);
    await state.removeTrack(state.library.last);
    expect(state.duplicates(), isEmpty);
    expect(state.library.length, 1);
  });

  test('metadata overrides persist and apply', () async {
    final state = AppState();
    addTearDown(state.dispose);
    final track = Track(
      id: 'local:/music/a.mp3',
      title: 'Old',
      path: '/music/a.mp3',
      author: 'Artist',
      album: 'Album',
    );
    state.library.add(track);
    await state.setTrackMeta(
      track,
      title: 'New',
      artist: 'Singer',
      album: 'EP',
    );
    expect(state.library.first.title, 'New');
    expect(state.library.first.author, 'Singer');
    expect(state.library.first.album, 'EP');
    await state.load();
    expect(state.library.first.title, 'New');
    expect(state.library.first.author, 'Singer');
    expect(state.library.first.album, 'EP');
  });

  test('backup import merges without duplicates', () async {
    final state = AppState();
    addTearDown(state.dispose);
    state.library.add(Track(id: 'a', title: 'A', kind: TrackKind.remote));
    final added = await state.importBackup([
      Track(id: 'a', title: 'A', kind: TrackKind.remote),
      Track(id: 'b', title: 'B', kind: TrackKind.remote),
    ], const []);
    expect(added, 1);
    expect(state.library.length, 2);
  });
}
