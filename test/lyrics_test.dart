import 'package:flutter_test/flutter_test.dart';
import 'package:niusic/models/lyrics.dart';
import 'package:niusic/services/lyrics_service.dart';

void main() {
  test('activeLineIndex tracks position', () {
    List<SyncedLine> mk() => [
      SyncedLine(Duration(seconds: 10), 'a'),
      SyncedLine(Duration(seconds: 20), 'b'),
      SyncedLine(Duration(seconds: 30), 'c'),
    ];
    expect(LyricsService.activeLineIndex(mk(), Duration(seconds: 5)), -1);
    expect(LyricsService.activeLineIndex(mk(), Duration(seconds: 10)), 0);
    expect(LyricsService.activeLineIndex(mk(), Duration(seconds: 15)), 0);
    expect(LyricsService.activeLineIndex(mk(), Duration(seconds: 25)), 1);
    expect(LyricsService.activeLineIndex(mk(), Duration(seconds: 99)), 2);
  });

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
