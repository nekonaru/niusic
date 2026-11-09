import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../services/player_service.dart';

String fmt(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({required this.state, required this.strings, super.key});

  final AppState state;
  final AppStrings strings;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final strings = widget.strings;
    final filtered = state.searchLibrary(query);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: strings.searchHint,
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => setState(() => query = value),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(strings.emptyLibrary))
              : ListView.builder(
                  addRepaintBoundaries: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final track = filtered[index];
                    final queueIndex = state.queueIndexOf(track);
                    return ListTile(
                      leading: Icon(Icons.audiotrack),
                      title: Text(track.title),
                      subtitle: Text(track.fileName),
                      trailing: PopupMenuButton<Track>(
                        onSelected: (value) => _addToPlaylist(value),
                        itemBuilder: (context) => [
                          const PopupMenuItem(child: Text('Add to playlist')),
                        ],
                      ),
                      onTap: () => state.playAt(queueIndex),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _addToPlaylist(Track track) async {
    final state = widget.state;
    if (state.playlists.isEmpty) {
      final playlist = await state.createPlaylist('Favorites');
      await state.addToPlaylist(playlist, track);
      return;
    }
    final picked = await showModalBottomSheet<Playlist>(
      context: context,
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: state.playlists.length,
          itemBuilder: (context, index) {
            final playlist = state.playlists[index];
            return ListTile(
              title: Text(playlist.name),
              subtitle: Text(
                '${playlist.length} ${widget.strings.tracksCount}',
              ),
              onTap: () => Navigator.pop(context, playlist),
            );
          },
        );
      },
    );
    if (picked != null) {
      await state.addToPlaylist(picked, track);
    }
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.state,
    required this.strings,
    required this.onImport,
    required this.onOpenNowPlaying,
    super.key,
  });

  final AppState state;
  final AppStrings strings;
  final VoidCallback onImport;
  final VoidCallback onOpenNowPlaying;

  @override
  Widget build(BuildContext context) {
    final recent = state.recentTracks();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: onImport,
          icon: Icon(Icons.folder_open),
          label: Text(strings.addMusic),
        ),
        SizedBox(height: 16),
        if (recent.isEmpty)
          Text(strings.emptyLibrary)
        else ...[
          Text(strings.recent, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 8),
          ...recent
              .take(5)
              .map(
                (track) => ListTile(
                  leading: Icon(Icons.history),
                  title: Text(track.title),
                  onTap: () {
                    final index = state.queueIndexOf(track);
                    if (index >= 0) {
                      state.playAt(index);
                    }
                    onOpenNowPlaying();
                  },
                ),
              ),
        ],
        SizedBox(height: 16),
        Text(
          '${state.library.length} ${strings.tracksCount}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({
    required this.state,
    required this.strings,
    super.key,
  });

  final AppState state;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => _createDialog(context),
            icon: Icon(Icons.playlist_add),
            label: Text(strings.newPlaylist),
          ),
        ),
        Expanded(
          child: state.playlists.isEmpty
              ? Center(child: Text(strings.emptyPlaylist))
              : ListView.builder(
                  itemCount: state.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = state.playlists[index];
                    return ListTile(
                      leading: Icon(Icons.queue_music),
                      title: Text(playlist.name),
                      subtitle: Text(
                        '${playlist.length} ${strings.tracksCount}',
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline),
                        onPressed: () => state.deletePlaylist(playlist),
                      ),
                      onTap: () => _openPlaylist(context, playlist),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _createDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.newPlaylist),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: strings.playlistName),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(strings.create),
            ),
          ],
        );
      },
    );
    if (name != null) {
      await state.createPlaylist(name);
    }
  }

  void _openPlaylist(BuildContext context, Playlist playlist) {
    final byPath = <String, Track>{for (final t in state.library) t.path: t};
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: Text(playlist.name)),
            body: playlist.trackPaths.isEmpty
                ? Center(child: Text(strings.emptyPlaylist))
                : ListView.builder(
                    itemCount: playlist.trackPaths.length,
                    itemBuilder: (context, index) {
                      final track = byPath[playlist.trackPaths[index]];
                      if (track == null) {
                        return SizedBox.shrink();
                      }
                      return ListTile(
                        title: Text(track.title),
                        trailing: IconButton(
                          icon: Icon(Icons.remove_circle_outline),
                          onPressed: () async {
                            await state.removeFromPlaylist(
                              playlist,
                              track.path,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        onTap: () {
                          final queueIndex = state.queueIndexOf(track);
                          if (queueIndex >= 0) {
                            state.playAt(queueIndex);
                          }
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.state,
    required this.strings,
    required this.onChanged,
    super.key,
  });

  final AppState state;
  final AppStrings strings;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(strings.language, style: Theme.of(context).textTheme.titleLarge),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'en', label: Text(strings.english)),
            ButtonSegment(value: 'id', label: Text(strings.indonesian)),
          ],
          selected: {state.language},
          onSelectionChanged: (value) async {
            await state.setLanguage(value.first);
            onChanged();
          },
        ),
        SizedBox(height: 16),
        Text(strings.theme, style: Theme.of(context).textTheme.titleLarge),
        SegmentedButton<ThemeChoice>(
          segments: [
            ButtonSegment(
              value: ThemeChoice.system,
              label: Text(strings.themeSystem),
            ),
            ButtonSegment(
              value: ThemeChoice.light,
              label: Text(strings.themeLight),
            ),
            ButtonSegment(
              value: ThemeChoice.dark,
              label: Text(strings.themeDark),
            ),
          ],
          selected: {state.theme},
          onSelectionChanged: (value) async {
            await state.setTheme(value.first);
            onChanged();
          },
        ),
        SizedBox(height: 16),
        Text(strings.volume, style: Theme.of(context).textTheme.titleLarge),
        Slider(
          value: state.volume,
          onChanged: (value) => state.setVolume(value),
        ),
        SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(strings.clearData),
                  content: Text(strings.clearDataConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(strings.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(strings.delete),
                    ),
                  ],
                );
              },
            );
            if (ok == true) {
              await state.clearAll();
            }
          },
          icon: Icon(Icons.delete_forever),
          label: Text(strings.clearData),
        ),
      ],
    );
  }
}

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({
    required this.state,
    required this.strings,
    super.key,
  });

  final AppState state;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final track = state.current;
    final max = state.duration.inSeconds > 0
        ? state.duration.inSeconds.toDouble()
        : 1.0;
    final value = state.position.inSeconds.toDouble().clamp(0.0, max);
    return Scaffold(
      appBar: AppBar(title: Text(strings.nowPlaying)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.album, size: 120),
              SizedBox(height: 16),
              Text(
                track?.title ?? strings.noTrack,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 8),
              Text(track?.fileName ?? ''),
              SizedBox(height: 16),
              Slider(
                value: value,
                max: max,
                onChanged: (v) => state.seek(Duration(seconds: v.toInt())),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(fmt(state.position)),
                  Text(fmt(state.duration)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: state.shuffle ? Colors.indigo : null,
                    ),
                    tooltip: strings.shuffle,
                    onPressed: state.toggleShuffle,
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_previous),
                    tooltip: strings.previous,
                    onPressed: state.previous,
                  ),
                  IconButton(
                    icon: Icon(
                      state.isPlaying ? Icons.pause_circle : Icons.play_circle,
                    ),
                    iconSize: 56,
                    tooltip: state.isPlaying ? strings.pause : strings.play,
                    onPressed: state.toggle,
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next),
                    tooltip: strings.next,
                    onPressed: () => state.next(),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.repeat,
                      color: state.repeat != NiRepeatMode.off
                          ? Colors.indigo
                          : null,
                    ),
                    tooltip: strings.repeat,
                    onPressed: state.cycleRepeat,
                  ),
                ],
              ),
              if (state.repeat != NiRepeatMode.off)
                Text(
                  state.repeat == NiRepeatMode.one
                      ? strings.repeatOne
                      : strings.repeatAll,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
