import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:niusic/models/track.dart';
import 'package:niusic/services/player_service.dart';

List<Track> _tracks(List<String> ids) {
  return [
    for (final id in ids) Track(id: id, title: id, kind: TrackKind.remote),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('addTracksToQueue appends and skips duplicates', () async {
    final state = AppState();
    addTearDown(state.dispose);
    state.queue = _tracks(['a']);
    final version = state.queueVersion;
    await state.addTracksToQueue(_tracks(['b', 'a', 'c']));
    expect(state.queue.map((t) => t.id).toList(), ['a', 'b', 'c']);
    expect(state.queueVersion, version + 1);
  });

  test('playNext inserts after the current track', () async {
    final state = AppState();
    addTearDown(state.dispose);
    state.queue = _tracks(['a', 'b', 'c']);
    state.queueIndex = 0;
    await state.playNext(_tracks(['x']).single);
    expect(state.queue.map((t) => t.id).toList(), ['a', 'x', 'b', 'c']);
    expect(state.queueIndex, 0);
  });

  test('bulk favorites and playlist writes are idempotent', () async {
    final state = AppState();
    addTearDown(state.dispose);
    final tracks = _tracks(['a', 'b']);
    await state.addManyToFavorites(tracks);
    await state.addManyToFavorites(tracks);
    expect(state.favoritesPlaylist!.trackIds, ['a', 'b']);
    final playlist = await state.createPlaylist('Mix');
    await state.addTracksToPlaylist(playlist, tracks);
    await state.addTracksToPlaylist(playlist, tracks);
    expect(playlist.trackIds, ['a', 'b']);
  });
}
