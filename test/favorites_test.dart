import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:niusic/models/track.dart';
import 'package:niusic/services/player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('favorites: add, toggle, pin and dedupe', () async {
    final state = AppState();
    addTearDown(state.dispose);
    expect(state.favoritesPlaylist, isNull);
    expect(state.isFavoriteId('yt:1'), isFalse);
    await state.toggleFavorite(
      Track.remote(videoId: '1', title: 'A', author: 'B'),
    );
    final fav = state.favoritesPlaylist;
    expect(fav, isNotNull);
    expect(fav!.name, 'Favorites');
    expect(fav.length, 1);
    expect(fav.contains('yt:1'), isTrue);
    expect(state.isFavoriteId('yt:1'), isTrue);
    expect(state.isFavoriteId('yt:2'), isFalse);
    // Favorites is pinned at the top of the playlists list.
    expect(state.playlists.first.id, 'favorites');
    // Toggling the same track off empties it again.
    await state.toggleFavorite(
      Track.remote(videoId: '1', title: 'A', author: 'B'),
    );
    expect(state.favoritesPlaylist!.length, 0);
    expect(state.isFavoriteId('yt:1'), isFalse);
  });

  test('favorites: persist across reload', () async {
    final state = AppState();
    addTearDown(state.dispose);
    await state.toggleFavorite(Track.remote(videoId: '9', title: 'S9'));
    await state.load();
    final fav = state.favoritesPlaylist;
    expect(fav, isNotNull);
    expect(fav!.contains('yt:9'), isTrue);
    expect(state.isFavoriteId('yt:9'), isTrue);
    // Toggle off and reload: empty.
    await state.toggleFavorite(Track.remote(videoId: '9', title: 'S9'));
    await state.load();
    expect(state.favoritesPlaylist!.contains('yt:9'), isFalse);
  });

  test('queue: saveQueueAsPlaylist saves queued tracks', () async {
    final state = AppState();
    addTearDown(state.dispose);
    final track = Track(id: 'yt:q1', title: 'Queued', kind: TrackKind.remote);
    state.queue.add(track);
    await state.saveQueueAsPlaylist('Selected');
    final playlist = state.playlists.firstWhere((p) => p.name == 'Selected');
    expect(playlist.trackIds, contains('yt:q1'));
  });
}
