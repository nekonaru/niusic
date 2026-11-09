import 'package:flutter_test/flutter_test.dart';
import 'package:niusic/services/lyrics_service.dart';

void main() {
  test('parseSynced parses LRC lines', () {
    final service = LyricsService();
    final lines = service.parseSynced(
      '[00:10.00]Hello\n[00:12.50]World\nno timestamp',
    );
    expect(lines.length, 2);
    expect(lines[0].text, 'Hello');
    expect(lines[0].time.inSeconds, 10);
    expect(lines[1].text, 'World');
    service.dispose();
  });
}
