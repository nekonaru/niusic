import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:niusic/models/track.dart';
import 'package:niusic/services/player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('advanced playback preferences persist', () async {
    final state = AppState();
    addTearDown(state.dispose);
    await state.setSkipIntro(10);
    await state.setSkipOutro(15);
    await state.setBufferPreset(2);
    await state.setEndAction('pause');
    await state.setFocusMode(true);
    await state.setEqPreset('bass');
    await state.load();
    expect(state.skipIntroSeconds, 10);
    expect(state.skipOutroSeconds, 15);
    expect(state.bufferPreset, 2);
    expect(state.endAction, 'pause');
    expect(state.focusMode, isTrue);
    expect(state.eqPreset, 'bass');
  });

  test('resume positions and replay gains persist', () async {
    final state = AppState();
    addTearDown(state.dispose);
    final track = Track(id: 'a', title: 'A', kind: TrackKind.remote);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('resume_positions_v1', '{"a": 12345}');
    await prefs.setString('replay_gain_v1', '{"a": 3.0}');
    await state.load();
    expect(state.resumePositions['a'], 12345);
    await state.setTrackGain(track, 4.5);
    await state.load();
    expect(state.replayGains['a'], 4.5);
  });

  test('A-B loop markers validate order and clear', () async {
    final state = AppState();
    addTearDown(state.dispose);
    state.queue = [Track(id: 'a', title: 'A', kind: TrackKind.remote)];
    state.queueIndex = 0;
    state.position = const Duration(seconds: 10);
    state.markAbLoopA();
    state.position = const Duration(seconds: 5);
    state.markAbLoopB();
    expect(state.abLoopB, isNull);
    state.position = const Duration(seconds: 30);
    state.markAbLoopB();
    expect(state.abLoopActive, isTrue);
    state.clearAbLoop();
    expect(state.abLoopActive, isFalse);
  });
}
