import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:niusic/models/track.dart';
import 'package:niusic/services/player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('onboarding and motion preferences persist', () async {
    final state = AppState();
    addTearDown(state.dispose);
    expect(state.onboardingDone, isFalse);
    expect(state.reduceMotion, isFalse);
    await state.completeOnboarding();
    await state.setReduceMotion(true);
    await state.load();
    expect(state.onboardingDone, isTrue);
    expect(state.reduceMotion, isTrue);
  });

  test('mood tags persist', () async {
    final state = AppState();
    addTearDown(state.dispose);
    await state.setTrackMood('yt:1', 'Calm');
    await state.load();
    expect(state.trackMoods['yt:1'], 'Calm');
  });

  test('resume positions feed continue listening', () async {
    final state = AppState();
    addTearDown(state.dispose);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'library_v2',
      '[{"id":"yt:1","title":"Song","kind":"remote"}]',
    );
    await prefs.setString('resume_positions_v1', '{"yt:1": 30000}');
    await state.load();
    expect(state.resumePositions['yt:1'], 30000);
    expect(state.library.firstWhere((t) => t.id == 'yt:1').title, 'Song');
  });
}
