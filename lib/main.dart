import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'l10n/app_strings.dart';
import 'screens/screens.dart';
import 'services/player_service.dart';

void main() {
  runApp(NiusicApp());
}

class NiusicApp extends StatefulWidget {
  const NiusicApp({super.key});

  @override
  State<NiusicApp> createState() => _NiusicAppState();
}

class _NiusicAppState extends State<NiusicApp>
    with SingleTickerProviderStateMixin {
  final AppState state = AppState();
  int index = 0;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    state.addListener(_onStateChanged);
    state.load().then((_) {
      if (mounted) {
        setState(() => loaded = true);
      }
    });
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
    final paths = files.map((f) => f.path).whereType<String>().toList();
    await state.addPaths(paths);
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

  @override
  Widget build(BuildContext context) {
    final strings = _strings;
    final pages = <Widget>[
      HomeScreen(
        state: state,
        strings: strings,
        onImport: _import,
        onOpenNowPlaying: _openNowPlaying,
      ),
      LibraryScreen(state: state, strings: strings),
      PlaylistsScreen(state: state, strings: strings),
      SettingsScreen(
        state: state,
        strings: strings,
        onChanged: () => setState(() {}),
      ),
    ];
    final current = state.current;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Niusic',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _themeMode,
      home: Scaffold(
        appBar: AppBar(title: Text('Niusic')),
        body: loaded
            ? pages[index]
            : Center(child: CircularProgressIndicator()),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (current != null)
              ListTile(
                leading: Icon(
                  state.isPlaying ? Icons.pause_circle : Icons.play_circle,
                ),
                title: Text(current.title),
                subtitle: Text(current.fileName),
                trailing: IconButton(
                  icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: state.toggle,
                ),
                onTap: _openNowPlaying,
              ),
            NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home),
                  label: strings.home,
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_music),
                  label: strings.library,
                ),
                NavigationDestination(
                  icon: Icon(Icons.queue_music),
                  label: strings.playlists,
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings),
                  label: strings.settings,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
