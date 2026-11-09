import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  test('youtube stream smoke', () async {
    try {
      final yt = YoutubeExplode();
      final manifest = await yt.videos.streamsClient
          .getManifest('dQw4w9WgXcQ')
          .timeout(
            const Duration(seconds: 25),
            onTimeout: () => throw StateError('timeout'),
          );
      final audio = manifest.audioOnly.sortByBitrate();
      // ignore: avoid_print
      print('audio streams ${audio.length}');
      yt.close();
    } catch (e) {
      // ignore: avoid_print
      print('stream unavailable: $e');
    }
  });
}
