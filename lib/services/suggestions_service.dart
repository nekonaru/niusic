import 'dart:convert';

import 'package:http/http.dart' as http;

class SuggestionsService {
  SuggestionsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<String>> fetch(String query) async {
    final uri = Uri.parse(
      'https://suggestqueries-clients6.youtube.com/complete/search?client=youtube&hl=en&gl=en&q=${Uri.encodeComponent(query)}&callback=x',
    );
    final res = await _client
        .get(
          uri,
          headers: <String, String>{'User-Agent': 'Niusic/0.7 (Flutter)'},
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      return <String>[];
    }
    final body = res.body;
    final start = body.indexOf('x(');
    if (start < 0) {
      return <String>[];
    }
    final jsonStr = body.substring(start + 2, body.length - 1);
    final data = jsonDecode(jsonStr) as List<dynamic>;
    final items = data.length > 1 ? data[1] as List<dynamic> : <dynamic>[];
    return items
        .map((e) => (e as List<dynamic>).first as String)
        .take(8)
        .toList();
  }

  void dispose() {
    _client.close();
  }
}
