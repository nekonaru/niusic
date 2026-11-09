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
    expect(restored.id, '/music/a.mp3');
    expect(restored.title, 'a');
    expect(restored.kind, TrackKind.local);
  });

  test('Track reads legacy json without id and kind', () {
    final restored = Track.fromJson({'path': '/music/a.mp3', 'title': 'a'});
    expect(restored.id, '/music/a.mp3');
    expect(restored.kind, TrackKind.local);
  });

  test('Track remote json round trip', () {
    final track = Track.remote(
      videoId: 'dQw4w9WgXcQ',
      title: 'Test Song',
      author: 'Test Artist',
    );
    final restored = Track.fromJson(track.toJson());
    expect(restored.id, 'yt:dQw4w9WgXcQ');
    expect(restored.kind, TrackKind.remote);
    expect(restored.videoId, 'dQw4w9WgXcQ');
    expect(restored.author, 'Test Artist');
  });
}
