import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:niusic/models/radio_station.dart';
import 'package:niusic/services/player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('audio preferences persist', () async {
    final state = AppState();
    addTearDown(state.dispose);
    await state.setSkipSilence(true);
    await state.setPitch(1.5);
    await state.setCacheOnlineAudio(true);
    await state.load();
    expect(state.skipSilence, isTrue);
    expect(state.pitch, 1.5);
    expect(state.cacheOnlineAudio, isTrue);
  });

  test('favorite stations toggle and persist', () async {
    final state = AppState();
    addTearDown(state.dispose);
    const station = RadioStation(
      stationUuid: 'abc',
      name: 'Radio Test',
      streamUrl: 'https://example.test/stream.mp3',
    );
    expect(state.isFavoriteStation('abc'), isFalse);
    await state.toggleFavoriteStation(station);
    expect(state.isFavoriteStation('abc'), isTrue);
    await state.load();
    expect(state.isFavoriteStation('abc'), isTrue);
    expect(state.favoriteStations.single.title, 'Radio Test');
    await state.toggleFavoriteStation(station);
    expect(state.isFavoriteStation('abc'), isFalse);
  });
}
