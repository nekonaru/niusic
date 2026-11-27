import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:niusic/services/player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('native preferences persist across reload', () async {
    final state = AppState();
    addTearDown(state.dispose);
    await state.setImmersivePlayer(true);
    await state.setLibraryGrid(true);
    await state.setOfflineMode(true);
    await state.setAccent('system');
    await state.load();
    expect(state.immersivePlayer, isTrue);
    expect(state.libraryGrid, isTrue);
    expect(state.offlineMode, isTrue);
    expect(state.accent, 'system');
  });
}
