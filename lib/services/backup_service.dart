import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/playlist.dart';
import '../models/track.dart';

/// Backup data as a portable JSON document. No accounts, no uploads.
class BackupService {
  Future<void> exportJson({
    required List<Track> library,
    required List<Playlist> playlists,
    required Map<String, String> metaTitle,
    required Map<String, String> metaArtist,
  }) async {
    final payload = <String, dynamic>{
      'format': 'niusic_backup_v1',
      'exportedAt': DateTime.now().toIso8601String(),
      'library': library.map((t) => t.toJson()).toList(),
      'playlists': playlists.map((p) => p.toJson()).toList(),
      'metaTitle': metaTitle,
      'metaArtist': metaArtist,
    };
    final temp = await getTemporaryDirectory();
    final file = File('${temp.path}/niusic_backup.json');
    await file.writeAsString(jsonEncode(payload), flush: true);
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'Niusic backup',
          text: 'Niusic library backup',
        ),
      );
    } catch (_) {
      // Share sheet not available. The file remains in temp for manual copy.
    }
  }

  Future<({List<Track> tracks, List<Playlist> playlists})?> importJson() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (files.isEmpty || files.first.path == null) {
      return null;
    }
    final decoded = jsonDecode(await File(files.first.path!).readAsString());
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != 'niusic_backup_v1') {
      throw const FormatException('Not a Niusic backup file');
    }
    final libraryRaw = decoded['library'];
    final playlistsRaw = decoded['playlists'];
    if (libraryRaw is! List || playlistsRaw is! List) {
      throw const FormatException('Invalid backup contents');
    }
    final tracks = <Track>[];
    for (final item in libraryRaw) {
      if (item is Map<String, dynamic>) {
        tracks.add(Track.fromJson(item));
      }
    }
    final playlists = <Playlist>[];
    for (final item in playlistsRaw) {
      if (item is Map<String, dynamic>) {
        playlists.add(Playlist.fromJson(item));
      }
    }
    return (tracks: tracks, playlists: playlists);
  }

  Future<String> exportCsv(List<MapEntry<String, int>> stats) async {
    final buffer = StringBuffer('date,seconds listened\n');
    for (final entry in stats) {
      buffer.writeln('${entry.key},${entry.value}');
    }
    final temp = await getTemporaryDirectory();
    final file = File('${temp.path}/niusic_stats.csv');
    await file.writeAsString(buffer.toString(), flush: true);
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          subject: 'Niusic listening stats',
        ),
      );
    } catch (_) {
      // Share sheet not available.
    }
    return file.path;
  }
}
