import 'package:audio_service/audio_service.dart';

/// Handler that mirrors the app's audioplayers playback into the OS media
/// notification. Playback itself stays in AppState (audioplayers supports
/// Android and Windows); this handler only surfaces the notification and
/// forwards notification actions back into the app.
class NiusicAudioHandler extends BaseAudioHandler with QueueHandler {
  /// Creates the handler and wires notification actions to app callbacks.
  NiusicAudioHandler({
    required this.onSkipNext,
    required this.onSkipPrevious,
    required this.onTogglePlay,
    required this.onSeek,
    required this.onStopPlayback,
  });

  /// Skip-next notification button.
  final Future<void> Function() onSkipNext;

  /// Skip-previous notification button.
  final Future<void> Function() onSkipPrevious;

  /// Play/pause notification button.
  final Future<void> Function() onTogglePlay;

  /// Seek notification action, receiving the target position.
  final Future<void> Function(Duration) onSeek;

  /// Stop notification button.
  final Future<void> Function() onStopPlayback;

  /// Publishes the current playback snapshot into the notification.
  void sync({
    required bool playing,
    required Duration position,
    required Duration duration,
    required String title,
    required String? artist,
    required String id,
    required int queueIndex,
    required List<MediaItem> items,
  }) {
    queue.add(items);
    mediaItem.add(
      MediaItem(id: id, title: title, artist: artist, duration: duration),
    );
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: <MediaAction>{MediaAction.seek},
        androidCompactActionIndices: <int>[0, 1, 2],
        processingState: AudioProcessingState.ready,
        playing: playing,
        updatePosition: position,
        bufferedPosition: position,
        speed: 1.0,
        queueIndex: queueIndex,
      ),
    );
  }

  @override
  Future<void> play() => onTogglePlay();

  @override
  Future<void> pause() => onTogglePlay();

  @override
  Future<void> stop() async {
    await onStopPlayback();
  }

  @override
  Future<void> skipToNext() => onSkipNext();

  @override
  Future<void> skipToPrevious() => onSkipPrevious();

  @override
  Future<void> seek(Duration position) => onSeek(position);
}
