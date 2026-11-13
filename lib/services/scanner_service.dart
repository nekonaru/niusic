import 'dart:async';

import 'package:flutter/services.dart';

/// A single audio file reported by the platform scanner.
class ScannedTrack {
  const ScannedTrack({
    required this.path,
    required this.title,
    this.artist,
    this.displayName,
    this.durationSeconds,
  });

  final String path;
  final String title;
  final String? artist;
  final String? displayName;
  final int? durationSeconds;
}

/// Reads the device music library through the native MediaStore scanner.
///
/// The scanner only works on Android. On other platforms the methods are
/// no-ops that report an empty library.
class ScannerService {
  static const MethodChannel _channel = MethodChannel('niusic/scanner');
  static const EventChannel _events = EventChannel('niusic/scanner_events');

  /// True when the app can read on-device audio files.
  Future<bool> areScanGranted() async {
    try {
      return await _channel.invokeMethod<bool>('areScanGranted') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Asks the OS for read access to audio files. Returns immediately.
  ///
  /// The result of the request is asynchronous; callers should re-check
  /// [areScanGranted] afterwards.
  Future<void> requestScanPermission() async {
    try {
      await _channel.invokeMethod<bool>('requestScanPermission');
    } on MissingPluginException {
      // Not supported on this platform.
    } on PlatformException {
      // Keep going; the UI can still offer a retry.
    }
  }

  /// Returns every audio file the system indexes as music.
  Future<List<ScannedTrack>> scanLibrary() async {
    try {
      final raw = await _channel.invokeListMethod<Object?>('scanLibrary');
      if (raw == null) {
        return <ScannedTrack>[];
      }
      final out = <ScannedTrack>[];
      for (final entry in raw) {
        if (entry is! Map) {
          continue;
        }
        final path = entry['path'] as String?;
        if (path == null || path.isEmpty) {
          continue;
        }
        final durationMs = entry['duration'];
        out.add(
          ScannedTrack(
            path: path,
            title: (entry['title'] as String? ?? '').trim(),
            artist: (entry['artist'] as String? ?? '').trim(),
            displayName: (entry['name'] as String? ?? '').trim(),
            durationSeconds: durationMs is int
                ? (durationMs / 1000).round()
                : null,
          ),
        );
      }
      return out;
    } on MissingPluginException {
      return <ScannedTrack>[];
    } on PlatformException {
      return <ScannedTrack>[];
    }
  }

  /// Emits an event whenever the audio MediaStore changes.
  Stream<void> get changes {
    return _events.receiveBroadcastStream().map((_) {});
  }
}
