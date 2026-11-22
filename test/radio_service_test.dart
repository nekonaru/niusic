import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'package:niusic/models/radio_station.dart';
import 'package:niusic/services/radio_service.dart';

const _stationJson = '''
[
  {
    "stationuuid": "abc-123",
    "name": "Stasiun PMR",
    "url_resolved": "https://live.example/stream.mp3",
    "favicon": "https://live.example/favicon.ico",
    "country": "Indonesia",
    "codec": "mp3",
    "bitrate": 128,
    "votes": 42
  },
  {
    "stationuuid": "def-456",
    "name": "Old ogg",
    "url_resolved": "https://live.example/stream.ogg",
    "codec": "ogg",
    "bitrate": 96
  }
]
''';

void main() {
  test('parses stations and filters unplayable ones', () async {
    var count = 0;
    final service = RadioService(
      client: MockClient((request) async {
        count++;
        return http.Response(_stationJson, 200);
      }),
    );
    final stations = await service.topStations();
    expect(count, 1);
    expect(stations.length, 1);
    final station = stations.single;
    expect(station.stationUuid, 'abc-123');
    expect(station.name, 'Stasiun PMR');
    expect(station.streamUrl, 'https://live.example/stream.mp3');
    expect(station.favicon, 'https://live.example/favicon.ico');
    expect(station.country, 'Indonesia');
    expect(station.bitrate, 128);
    expect(station.votes, 42);
    expect(station.playable, isTrue);
  });

  test('search falls back to other instances on error', () async {
    var calls = 0;
    final service = RadioService(
      client: MockClient((request) async {
        calls++;
        if (calls == 1) {
          return http.Response('{}', 500);
        }
        return http.Response(_stationJson, 200);
      }),
    );
    final stations = await service.search('query');
    expect(calls, greaterThan(1));
    expect(stations.length, 1);
  });

  test('throws when every instance fails', () async {
    final service = RadioService(
      client: MockClient((request) async {
        return http.Response('nope', 404);
      }),
    );
    await expectLater(service.topStations(), throwsA(isA<StateError>()));
  });

  test('RadioStation.playable rejects incomplete entries', () {
    expect(
      RadioStation(stationUuid: 'a', name: '', streamUrl: '').playable,
      false,
    );
    expect(
      RadioStation(
        stationUuid: 'a',
        name: 'B',
        streamUrl: 'http://x.y/z.pls',
      ).playable,
      false,
    );
    expect(
      RadioStation(
        stationUuid: 'a',
        name: 'B',
        streamUrl: 'ftp://x.y/z.mp3',
      ).playable,
      false,
    );
  });
}
