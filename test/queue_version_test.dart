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

  test('queueVersion increments on queue mutations', () async {
    final state = AppState();
    addTearDown(state.dispose);
    state.queue = _tracks(['a', 'b', 'c']);
    final before = state.queueVersion;
    state.moveQueueItem(0, 2);
    expect(state.queueVersion, before + 1);
    state.removeQueueItem(1);
    expect(state.queueVersion, before + 2);
    state.queue = _tracks(['x']);
    await state.playAt(0);
    expect(state.queueVersion, before + 3);
    await state.clearQueue();
    expect(state.queueVersion, before + 4);
    expect(state.queue, isEmpty);
  });

  test('moveQueueItem preserves the current track and list', () {
    final state = AppState();
    addTearDown(state.dispose);
    state.queue = _tracks(['a', 'b', 'c', 'd']);
    state.queueIndex = 0;
    state.moveQueueItem(0, 3);
    expect(state.queue.length, 4);
    expect(state.queue[state.queueIndex].id, 'a');
    expect(state.queue.map((t) => t.id).toSet().length, 4);
    state.moveQueueItem(3, 0);
    expect(state.queue.length, 4);
    expect(state.queue[state.queueIndex].id, 'a');
    expect(state.queue.map((t) => t.id).toSet().length, 4);
  });
}
