import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:niusic/models/track.dart';
import 'package:niusic/services/player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('reorderPlaylists keeps Favorites pinned at the top', () async {
    final state = AppState();
    addTearDown(state.dispose);
    await state.createPlaylist('A');
    await state.createPlaylist('B');
    await state.createPlaylist('C');
    await state.toggleFavorite(
      Track(id: 'fav', title: 'Fav', kind: TrackKind.remote),
    );
    expect(state.playlists.first.id, 'favorites');
    state.reorderPlaylists(0, 2);
    expect(state.playlists.map((p) => p.name).toList(), [
      'Favorites',
      'B',
      'A',
      'C',
    ]);
  });

  test('rename and delete playlists persist', () async {
    final state = AppState();
    addTearDown(state.dispose);
    final playlist = await state.createPlaylist('Old');
    await state.renamePlaylist(playlist, 'New');
    await state.load();
    expect(state.playlists.single.name, 'New');
    await state.deletePlaylist(state.playlists.single);
    await state.load();
    expect(state.playlists, isEmpty);
  });

  test('sleepFade preference persists', () async {
    final state = AppState();
    addTearDown(state.dispose);
    expect(state.sleepFade, isTrue);
    await state.setSleepFade(false);
    await state.load();
    expect(state.sleepFade, isFalse);
  });

  test('playAllFromPlaylist replaces queue and starts playback', () async {
    final state = AppState();
    addTearDown(state.dispose);
    final tracks = [
      Track(id: 'a', title: 'A', kind: TrackKind.remote),
      Track(id: 'b', title: 'B', kind: TrackKind.remote),
    ];
    state.library.addAll(tracks);
    final playlist = await state.createPlaylist('Mix');
    await state.addTracksToPlaylist(playlist, tracks);
    await state.playAllFromPlaylist(playlist);
    expect(state.queue.map((t) => t.id).toList(), ['a', 'b']);
    expect(state.queueIndex, 0);
  });
}
