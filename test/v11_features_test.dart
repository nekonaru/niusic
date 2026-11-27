import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:niusic/models/track.dart';
import 'package:niusic/services/player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('smart preferences persist', () async {
    final state = AppState();
    addTearDown(state.dispose);
    await state.setThemeFromArt(true);
    await state.setSleepUntilEnd(true);
    await state.setTextScale(1.25);
    await state.load();
    expect(state.themeFromArt, isTrue);
    expect(state.sleepUntilEnd, isTrue);
    expect(state.textScale, 1.25);
  });

  test('queue presets save, load and delete', () async {
    final state = AppState();
    addTearDown(state.dispose);
    final tracks = [
      Track(id: 'a', title: 'A', kind: TrackKind.remote),
      Track(id: 'b', title: 'B', kind: TrackKind.remote),
    ];
    state.library.addAll(tracks);
    state.queue = List<Track>.of(tracks);
    await state.saveQueuePreset('Road');
    expect(state.queuePresets.single.name, 'Road');
    expect(state.queuePresets.single.ids, ['a', 'b']);
    state.queue = <Track>[];
    await state.loadQueuePreset(0);
    expect(state.queue.map((t) => t.id).toList(), ['a', 'b']);
    await state.load();
    expect(state.queuePresets.single.ids, ['a', 'b']);
    await state.deleteQueuePreset(0);
    expect(state.queuePresets, isEmpty);
  });

  test('playlist cover persists', () async {
    final state = AppState();
    addTearDown(state.dispose);
    final playlist = await state.createPlaylist('Mix');
    await state.setPlaylistCover(playlist, 'yt:1');
    await state.load();
    expect(state.playlists.single.coverTrackId, 'yt:1');
  });
}
