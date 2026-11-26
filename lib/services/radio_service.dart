import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/radio_station.dart';

/// Community radio directory. Public, key-free, HTTPS.
/// See https://www.radio-browser.info for the API.
class RadioService {
  RadioService({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  static const List<String> _instances = <String>[
    'https://de1.api.radio-browser.info',
    'https://nl1.api.radio-browser.info',
    'https://de2.api.radio-browser.info',
  ];

  Future<List<RadioStation>> topStations({int limit = 40}) {
    return _getStations('/json/stations/topvote/$limit?hidebroken=true');
  }

  Future<List<RadioStation>> search(String query, {int limit = 40}) {
    final encoded = Uri.encodeQueryComponent(query.trim());
    return _getStations(
      '/json/stations/byname/$encoded?hidebroken=true&limit=$limit',
    );
  }

  /// Top voted stations from a country name.
  Future<List<RadioStation>> byCountry(String country, {int limit = 40}) {
    final encoded = Uri.encodeQueryComponent(country.trim());
    return _getStations(
      '/json/stations/search?country=$encoded&hidebroken=true&order=votes&reverse=true&limit=$limit',
    );
  }

  Future<List<RadioStation>> _getStations(String path) async {
    Object? lastError;
    for (final base in _instances) {
      try {
        final res = await _http
            .get(
              Uri.parse('$base$path'),
              headers: <String, String>{'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) {
          throw StateError('radio ${res.statusCode}');
        }
        final decoded = jsonDecode(res.body);
        if (decoded is! List) {
          throw StateError('radio malformed response');
        }
        final out = <RadioStation>[];
        for (final item in decoded) {
          if (item is! Map<String, dynamic>) {
            continue;
          }
          final station = RadioStation.fromJson(item);
          if (station.playable) {
            out.add(station);
          }
        }
        return out;
      } catch (e) {
        lastError = e;
      }
    }
    throw StateError('radio failed: $lastError');
  }

  void dispose() {
    _http.close();
  }
}
