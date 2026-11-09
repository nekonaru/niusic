import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DownloadService {
  DownloadService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static String sanitizeId(String id) {
    final cleaned = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return cleaned.isEmpty ? 'download' : cleaned;
  }

  Future<String> downloadTo(String url, String videoId) async {
    final safe = sanitizeId(videoId);
    final ext = _extensionFor(url);
    final dir = await getApplicationDocumentsDirectory();
    final downloads = Directory('${dir.path}/downloads');
    await downloads.create(recursive: true);
    final dest = File('${downloads.path}/$safe$ext');
    if (await dest.exists()) {
      return dest.path;
    }
    final resp = await _client.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      throw StateError('download failed: ${resp.statusCode}');
    }
    await dest.writeAsBytes(resp.bodyBytes, flush: true);
    return dest.path;
  }

  String _extensionFor(String url) {
    final uri = Uri.tryParse(url);
    final path = uri?.path ?? '';
    final dot = path.lastIndexOf('.');
    final ext = dot >= 0 ? path.substring(dot).toLowerCase() : '';
    const allowed = <String>{'.m4a', '.mp3', '.ogg', '.opus', '.webm', '.wav'};
    if (allowed.contains(ext)) {
      return ext;
    }
    return '.m4a';
  }

  Future<int> sizeOf(String? path) async {
    if (path == null) {
      return 0;
    }
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  Future<void> deleteFile(String? path) async {
    if (path == null || path.isEmpty) {
      return;
    }
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  void dispose() {
    _client.close();
  }
}
