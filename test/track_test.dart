import 'package:flutter_test/flutter_test.dart';
import 'package:niusic/models/track.dart';

void main() {
  test('titleFromPath strips extension and separators', () {
    expect(Track.titleFromPath(r'C:\music\My_Song-Name.mp3'), 'My Song Name');
    expect(Track.titleFromPath('plain'), 'plain');
  });

  test('Track json round trip', () {
    final track = Track.fromPath('/music/a.mp3');
    final restored = Track.fromJson(track.toJson());
    expect(restored.path, '/music/a.mp3');
    expect(restored.title, 'a');
  });
}
