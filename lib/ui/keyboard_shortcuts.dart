import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Global keyboard shortcut intents for desktop control.
class TogglePlayIntent extends Intent {
  const TogglePlayIntent();
}

class SeekForwardIntent extends Intent {
  const SeekForwardIntent(this.seconds);

  final int seconds;
}

class SeekBackwardIntent extends Intent {
  const SeekBackwardIntent(this.seconds);

  final int seconds;
}

class NextTrackIntent extends Intent {
  const NextTrackIntent();
}

class PreviousTrackIntent extends Intent {
  const PreviousTrackIntent();
}

class VolumeUpIntent extends Intent {
  const VolumeUpIntent();
}

class VolumeDownIntent extends Intent {
  const VolumeDownIntent();
}

/// Keyboard shortcuts for desktop playback control.
final Map<ShortcutActivator, Intent> niusicShortcuts =
    <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.space): const TogglePlayIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowRight):
          const SeekForwardIntent(5),
      const SingleActivator(LogicalKeyboardKey.arrowLeft):
          const SeekBackwardIntent(5),
      const SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
          const NextTrackIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
          const PreviousTrackIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowUp): const VolumeUpIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowDown):
          const VolumeDownIntent(),
    };
