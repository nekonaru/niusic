import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:niusic/services/player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('car mode preference persists', () async {
    final state = AppState();
    addTearDown(state.dispose);
    await state.setCarMode(true);
    await state.load();
    expect(state.carMode, isTrue);
  });

  test('weekly stats expose seven days', () {
    final state = AppState();
    addTearDown(state.dispose);
    expect(state.weeklyStats.length, 7);
    expect(state.totalListenSeconds, 0);
  });
}
