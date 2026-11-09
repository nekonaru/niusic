import 'package:flutter_test/flutter_test.dart';
import 'package:niusic/models/playlist.dart';
import 'package:niusic/models/track.dart';

void main() {
  test('Playlist add is idempotent', () {
    final playlist = Playlist(id: '1', name: 'Mix');
    final track = Track.fromPath('/music/a.mp3');
    playlist.add(track);
    playlist.add(track);
    expect(playlist.length, 1);
    playlist.removeId(track.id);
    expect(playlist.length, 0);
  });

  test('Playlist json round trip', () {
    final playlist = Playlist(
      id: '7',
      name: 'Road',
      trackIds: ['/a.mp3', '/b.mp3'],
    );
    final restored = Playlist.fromJson(playlist.toJson());
    expect(restored.id, '7');
    expect(restored.name, 'Road');
    expect(restored.trackIds, ['/a.mp3', '/b.mp3']);
  });

  test('Playlist reads legacy trackPaths key', () {
    final restored = Playlist.fromJson({
      'id': '7',
      'name': 'Road',
      'trackPaths': ['/a.mp3'],
    });
    expect(restored.trackIds, ['/a.mp3']);
  });
}
