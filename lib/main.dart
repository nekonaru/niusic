import 'package:audio_service/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'l10n/app_strings.dart';
import 'screens/screens.dart';
import 'services/audio_handler.dart';
import 'services/player_service.dart';
import 'ui/niusic_theme.dart';
import 'ui/keyboard_shortcuts.dart';
import 'ui/responsive.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  try {
    final handler = await AudioService.init(
      builder: () => NiusicAudioHandler(
        onSkipNext: () => state.next(),
        onSkipPrevious: () => state.previous(),
        onTogglePlay: () => state.toggle(),
        onSeek: (d) => state.seek(d),
        onStopPlayback: () => state.player.stop(),
      ),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.niusic.app.channel.audio',
        androidNotificationChannelName: 'Niusic playback',
        androidNotificationOngoing: true,
      ),
    );
    state.audioHandler = handler;
  } catch (_) {
    // Media notification is not available on this platform. The UI still works.
  }
  runApp(NiusicApp(state: state));
}

class NiusicApp extends StatefulWidget {
  const NiusicApp({required this.state, super.key});

  final AppState state;

  @override
  State<NiusicApp> createState() => _NiusicAppState();
}

class _NiusicAppState extends State<NiusicApp> {
  late final AppState state = widget.state;
  int index = 0;
  bool loaded = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    state.addListener(_onStateChanged);
    state
        .load()
        .then((_) {
          if (mounted) {
            setState(() => loaded = true);
          }
        })
        .catchError((Object error) {
          if (mounted) {
            setState(() {
              loadError = error.toString();
              loaded = true;
            });
          }
        });
  }

  @override
  void dispose() {
    state.removeListener(_onStateChanged);
    state.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  AppStrings get _strings => AppStrings(state.language);

  ThemeMode get _themeMode {
    switch (state.theme) {
      case ThemeChoice.light:
        return ThemeMode.light;
      case ThemeChoice.dark:
        return ThemeMode.dark;
      case ThemeChoice.system:
        return ThemeMode.system;
    }
  }

  Future<void> _import() async {
    final files = await FilePicker.pickFiles(type: FileType.audio);
    if (files.isEmpty) {
      return;
    }
    await state.importPickedFiles(files);
  }

  void _openNowPlaying() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) {
          return NowPlayingScreen(state: state, strings: _strings);
        },
      ),
    );
  }

  Widget _miniPlayer(AppStrings strings) {
    final current = state.current;
    if (current == null) {
      return SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        visualDensity: VisualDensity.compact,
        leading: Icon(
          state.isPlaying ? Icons.pause_circle : Icons.play_circle,
          color: Theme.of(context).colorScheme.primary,
          size: 30,
        ),
        title: Text(
          current.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          current.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: state.toggle,
        ),
        onTap: _openNowPlaying,
      ),
    );
  }

  Widget _navBar(AppStrings strings) {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (value) => setState(() => index = value),
      destinations: [
        NavigationDestination(icon: Icon(Icons.home), label: strings.home),
        NavigationDestination(
          icon: Icon(Icons.library_music),
          label: strings.library,
        ),
        NavigationDestination(icon: Icon(Icons.search), label: strings.stream),
        NavigationDestination(
          icon: Icon(Icons.queue_music),
          label: strings.playlists,
        ),
        NavigationDestination(
          icon: Icon(Icons.settings),
          label: strings.settings,
        ),
      ],
    );
  }

  Widget _rail(AppStrings strings) {
    final wide = isDesktop(context);
    return NavigationRail(
      extended: wide,
      selectedIndex: index,
      onDestinationSelected: (value) => setState(() => index = value),
      labelType: wide
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      destinations: [
        NavigationRailDestination(
          icon: Icon(Icons.home),
          label: Text(strings.home),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.library_music),
          label: Text(strings.library),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.search),
          label: Text(strings.stream),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.queue_music),
          label: Text(strings.playlists),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text(strings.settings),
        ),
      ],
    );
  }

  Color _seedColor(AppState state) {
    switch (state.accent) {
      case 'teal':
        return const Color(0xFF0F766E);
      case 'purple':
        return const Color(0xFF7E22CE);
      case 'orange':
        return const Color(0xFFEA580C);
      case 'indigo':
      default:
        return const Color(0xFF4F46E5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = _strings;
    final seed = _seedColor(state);
    final pages = <Widget>[
      HomeScreen(
        state: state,
        strings: strings,
        onImport: _import,
        onOpenNowPlaying: _openNowPlaying,
      ),
      LibraryScreen(state: state, strings: strings),
      SearchScreen(state: state, strings: strings),
      PlaylistsScreen(state: state, strings: strings),
      SettingsScreen(
        state: state,
        strings: strings,
        onChanged: () => setState(() {}),
      ),
    ];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Niusic',
      theme: niusicTheme(Brightness.light, seed: seed),
      darkTheme: niusicTheme(Brightness.dark, seed: seed),
      themeMode: _themeMode,
      home: Builder(
        builder: (context) {
          final desktop = isDesktop(context) || isTabletOrMore(context);
          final body = loaded
              ? Column(
                  children: [
                    if (loadError != null)
                      Material(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: ListTile(
                          leading: Icon(Icons.error_outline),
                          title: Text('Local data failed to load.'),
                          subtitle: Text(loadError!),
                        ),
                      ),
                    Expanded(
                      child: IndexedStack(index: index, children: pages),
                    ),
                  ],
                )
              : Center(child: CircularProgressIndicator());
          final scaffold = desktop
              ? Scaffold(
                  appBar: AppBar(title: Text('Niusic')),
                  body: Row(
                    children: [
                      _rail(strings),
                      VerticalDivider(width: 1),
                      Expanded(child: body),
                    ],
                  ),
                )
              : Scaffold(
                  appBar: AppBar(title: Text('Niusic')),
                  body: body,
                  bottomNavigationBar: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [_miniPlayer(strings), _navBar(strings)],
                  ),
                );
          return Focus(
            autofocus: true,
            child: Shortcuts(
              shortcuts: niusicShortcuts,
              child: Actions(
                actions: <Type, Action<Intent>>{
                  TogglePlayIntent: CallbackAction<TogglePlayIntent>(
                    onInvoke: (_) => state.toggle(),
                  ),
                  SeekForwardIntent: CallbackAction<SeekForwardIntent>(
                    onInvoke: (i) => state.seekRelative(i.seconds),
                  ),
                  SeekBackwardIntent: CallbackAction<SeekBackwardIntent>(
                    onInvoke: (i) => state.seekRelative(-i.seconds),
                  ),
                  NextTrackIntent: CallbackAction<NextTrackIntent>(
                    onInvoke: (_) => state.next(),
                  ),
                  PreviousTrackIntent: CallbackAction<PreviousTrackIntent>(
                    onInvoke: (_) => state.previous(),
                  ),
                  VolumeUpIntent: CallbackAction<VolumeUpIntent>(
                    onInvoke: (_) => state.adjustVolume(0.05),
                  ),
                  VolumeDownIntent: CallbackAction<VolumeDownIntent>(
                    onInvoke: (_) => state.adjustVolume(-0.05),
                  ),
                },
                child: scaffold,
              ),
            ),
          );
        },
      ),
    );
  }
}
