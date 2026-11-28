import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:niusic/models/track.dart';
import 'package:niusic/services/player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('daily mix merges most played, recent and library without duplicates', () async {
    final state = AppState();
    addTearDown(state.dispose);
    state.library.addAll([
      Track(id: 'a', title: 'A', kind: TrackKind.remote),
      Track(id: 'b', title: 'B', kind: TrackKind.remote),
    ]);
    state.playCounts['a'] = 3;
    state.historyIds.addAll(['b', 'a']);
    final mix = state.dailyMix(limit: 5);
    expect(mix.map((t) => t.id).toList(), ['a', 'b']);
  });

  test('lyrics cache persists', () async {
    final state = AppState();
    addTearDown(state.dispose);
    await state.cacheLyrics('Song', 'Artist', <String, dynamic>{
      'title': 'Song',
      'artist': 'Artist',
      'plain': 'la la',
      'synced': null,
    });
    await state.load();
    final cached = state.cachedLyrics('Song', 'Artist');
    expect(cached, isNotNull);
    expect(cached!['plain'], 'la la');
  });
}
