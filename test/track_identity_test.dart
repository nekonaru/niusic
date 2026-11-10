import 'package:flutter_test/flutter_test.dart';
import 'package:niusic/models/playlist.dart';
import 'package:niusic/models/track.dart';

void main() {
  test('queue id is stable for local tracks', () {
    final a = Track.fromPath('/music/a.mp3');
    final b = Track.fromPath('/music/a.mp3');
    expect(a.id, b.id);
    expect(a == b, true);
  });

  test('remote and local ids do not collide', () {
    final local = Track.fromPath('/music/dQw4w9WgXcQ.mp3');
    final remote = Track.remote(videoId: 'dQw4w9WgXcQ', title: 'Test');
    expect(local.id, 'local:/music/dQw4w9WgXcQ.mp3');
    expect(remote.id, 'yt:dQw4w9WgXcQ');
    expect(local.id != remote.id, true);
  });

  test('legacy local json gets local prefix', () {
    final restored = Track.fromJson({'path': '/music/a.mp3', 'title': 'a'});
    expect(restored.id, 'local:/music/a.mp3');
  });

  test('playlist keeps remote and local entries separate', () {
    final playlist = Playlist(id: 'p1', name: 'Mix');
    playlist.add(Track.fromPath('/music/a.mp3'));
    playlist.add(Track.remote(videoId: 'vid', title: 'Remote'));
    expect(playlist.length, 2);
  });

  test('track subtitle prefers author for remote', () {
    final remote = Track.remote(
      videoId: 'vid',
      title: 'Title',
      author: 'Artist',
    );
    expect(remote.subtitle, 'Artist');
  });

  test('track subtitle falls back to videoId for remote', () {
    final remote = Track.remote(videoId: 'vid', title: 'Title');
    expect(remote.subtitle, 'vid');
  });

  test('downloaded track keeps remote identity', () {
    final remote = Track.remote(
      videoId: 'vid',
      title: 'Title',
    ).copyWithDownload('/downloads/vid.m4a');
    expect(remote.isDownloaded, true);
    expect(remote.id, 'yt:vid');
  });
}
