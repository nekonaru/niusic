import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/lyrics.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../models/video_result.dart';
import '../services/lyrics_service.dart';
import '../services/player_service.dart';
import '../ui/responsive.dart';

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
              : GridView.builder(
                  addRepaintBoundaries: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: searchColumns(context),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: searchColumns(context) == 1 ? 6.5 : 1.2,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final track = filtered[index];
                    final queueIndex = state.queueIndexOf(track);
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.audiotrack),
                        title: Text(track.title),
                        subtitle: Text(track.fileName),
                        trailing: PopupMenuButton<Track>(
                          onSelected: (value) => _addToPlaylist(value),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: Text(widget.strings.addToPlaylist),
                            ),
                          ],
                        ),
                        onTap: () => state.playAt(queueIndex),
                      ),
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

class HomeScreen extends StatefulWidget {
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> chart = <dynamic>[];
  bool chartLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadChart();
  }

  Future<void> _loadChart() async {
    try {
      final items = await widget.state.chartService.topTracks(limit: 10);
      if (!mounted) return;
      setState(() {
        chart = items;
        chartLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        chartLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final strings = widget.strings;
    final theme = Theme.of(context);
    final recent = state.recentTracks();
    final downloads = state.downloadedTracks();
    final current = state.current;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Row(
          children: [
            Text(
              strings.appName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              onPressed: widget.onImport,
              icon: const Icon(Icons.add, size: 18),
              label: Text(strings.addMusic),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (current != null) ...[
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onOpenNowPlaying,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _heroArtwork(current, 92),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.nowPlaying.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.4,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            current.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            current.subtitle ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      iconSize: 44,
                      icon: Icon(
                        state.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                      ),
                      onPressed: state.toggle,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (recent.isEmpty && downloads.isEmpty && state.library.isEmpty) ...[
          const SizedBox(height: 8),
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.music_note,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.emptyLibrary,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.emptyLibraryHint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: widget.onImport,
                    icon: const Icon(Icons.folder_open),
                    label: Text(strings.addMusic),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (chart.isNotEmpty) ...[
          _sectionTitle(strings.topToday, Icons.show_chart),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                mainAxisSpacing: 8,
                childAspectRatio: 0.72,
              ),
              itemCount: chart.length,
              itemBuilder: (context, index) {
                final item = chart[index];
                final title = item.title as String;
                final artist = item.artist as String;
                final cover = item.coverUrl as String?;
                return GestureDetector(
                  onTap: () async {
                    final query = '$title $artist'.trim();
                    final results = await state.streamService.search(query);
                    if (results.isNotEmpty) {
                      state.playVideo(results.first);
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _coverArt(cover, 140),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (recent.isNotEmpty) ...[
          _sectionTitle(strings.recent, Icons.history),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: recent.take(5).map((track) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.music_note,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    track.subtitle ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    Icons.play_arrow,
                    color: theme.colorScheme.primary,
                  ),
                  onTap: () {
                    final index = state.queueIndexOf(track);
                    if (index >= 0) {
                      state.playAt(index);
                    }
                    widget.onOpenNowPlaying();
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
        _sectionTitle(strings.downloads, Icons.download),
        const SizedBox(height: 12),
        if (downloads.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                strings.noDownloads,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: downloads.map((track) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.download_done,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(strings.downloaded),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: strings.deleteDownload,
                    onPressed: () => state.deleteDownload(track),
                  ),
                  onTap: () => widget.onOpenNowPlaying(),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _heroArtwork(Track track, double size) {
    final url = track.thumbnailUrl;
    if (url != null && url.isNotEmpty && Uri.tryParse(url)?.scheme == 'https') {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: 256,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.album, size: size * 0.6),
      );
    }
    return Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.album, size: size * 0.6),
    );
  }

  Widget _coverArt(String? url, double width) {
    if (url != null && url.isNotEmpty && Uri.tryParse(url)?.scheme == 'https') {
      return Image.network(
        url,
        width: width,
        fit: BoxFit.cover,
        cacheWidth: 256,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.album, size: 56),
      );
    }
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.album, size: 56),
    );
  }
}

class QueueScreen extends StatelessWidget {
  const QueueScreen({required this.state, required this.strings, super.key});

  final AppState state;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(strings.queue)),
      body: state.queue.isEmpty
          ? Center(child: Text(strings.noTrack))
          : ReorderableListView.builder(
              itemCount: state.queue.length,
              onReorderItem: (oldIndex, newIndex) {
                state.moveQueueItem(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final track = state.queue[index];
                final isCurrent = index == state.queueIndex;
                return ListTile(
                  key: ValueKey<String>(track.id),
                  leading: Icon(
                    isCurrent ? Icons.graphic_eq : Icons.audiotrack,
                  ),
                  title: Text(track.title),
                  subtitle: Text(track.subtitle ?? ''),
                  trailing: IconButton(
                    icon: Icon(Icons.remove_circle_outline),
                    onPressed: () => state.removeQueueItem(index),
                  ),
                  onTap: () => state.playAt(index),
                );
              },
            ),
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
    final byId = <String, Track>{for (final t in state.library) t.id: t};
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: Text(playlist.name)),
            body: playlist.trackIds.isEmpty
                ? Center(child: Text(strings.emptyPlaylist))
                : ListView.builder(
                    itemCount: playlist.trackIds.length,
                    itemBuilder: (context, index) {
                      final track = byId[playlist.trackIds[index]];
                      if (track == null) {
                        return SizedBox.shrink();
                      }
                      return ListTile(
                        title: Text(track.title),
                        subtitle: Text(track.subtitle ?? ''),
                        trailing: IconButton(
                          icon: Icon(Icons.remove_circle_outline),
                          onPressed: () async {
                            await state.removeFromPlaylist(playlist, track.id);
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        _section(context, strings.language),
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
        const SizedBox(height: 20),
        _section(context, strings.theme),
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
        const SizedBox(height: 20),
        _section(context, strings.accent),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'indigo', label: Text('Indigo')),
            ButtonSegment(value: 'teal', label: Text('Teal')),
            ButtonSegment(value: 'purple', label: Text('Purple')),
            ButtonSegment(value: 'orange', label: Text('Orange')),
          ],
          selected: {state.accent},
          onSelectionChanged: (value) => state.setAccent(value.first),
        ),
        const SizedBox(height: 20),
        _section(context, strings.volume),
        Slider(
          value: state.volume,
          onChanged: (value) => state.setVolume(value),
        ),
        const SizedBox(height: 20),
        _section(context, strings.audioQuality),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'low', label: Text(strings.qualityLow)),
            ButtonSegment(value: 'high', label: Text(strings.qualityHigh)),
          ],
          selected: {state.streamService.audioQuality},
          onSelectionChanged: (value) => state.setAudioQuality(value.first),
        ),
        const SizedBox(height: 20),
        _section(context, strings.notifications),
        OutlinedButton.icon(
          onPressed: () {
            const MethodChannel('niusic/permission')
                .invokeMethod<bool>('requestNotifications');
          },
          icon: const Icon(Icons.notifications),
          label: Text(strings.enableNotifications),
        ),
        const SizedBox(height: 20),
        _section(context, strings.playbackSpeed),
        Text('${state.playbackRate.toStringAsFixed(2)}x'),
        Slider(
          min: 0.5,
          max: 2.0,
          divisions: 6,
          value: state.playbackRate,
          onChanged: (value) => state.setPlaybackRate(value),
        ),
        const SizedBox(height: 20),
        _section(context, strings.storage),
        FutureBuilder<int>(
          future: state.totalDownloadBytes(),
          builder: (context, snap) {
            final bytes = snap.data ?? 0;
            final mb = bytes / (1024 * 1024);
            return Text(
              '${strings.downloadsSize}: ${mb.toStringAsFixed(1)} MB',
              style: Theme.of(context).textTheme.bodyLarge,
            );
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(strings.clearDownloads),
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
              await state.clearDownloads();
            }
          },
          icon: const Icon(Icons.delete_sweep),
          label: Text(strings.clearDownloads),
        ),
        const SizedBox(height: 20),
        _section(context, strings.clearData),
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
          icon: const Icon(Icons.delete_forever),
          label: Text(strings.clearData),
        ),
      ],
    );
  }

  Widget _section(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({required this.state, required this.strings, super.key});

  final AppState state;
  final AppStrings strings;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<VideoResult> results = <VideoResult>[];
  List<ChannelResult> channels = <ChannelResult>[];
  List<PlaylistResult> onlinePlaylists = <PlaylistResult>[];
  List<String> suggestions = <String>[];
  bool loading = false;
  bool failed = false;
  bool searched = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final query = value.trim();
      if (query.isEmpty) {
        setState(() {
          results = <VideoResult>[];
          channels = <ChannelResult>[];
          onlinePlaylists = <PlaylistResult>[];
          suggestions = <String>[];
          searched = false;
          failed = false;
          loading = false;
        });
        return;
      }
      setState(() {
        loading = true;
        failed = false;
      });
      try {
        final found = await widget.state.streamService.search(query);
        List<ChannelResult> foundChannels = <ChannelResult>[];
        List<PlaylistResult> foundPlaylists = <PlaylistResult>[];
        try {
          foundChannels = await widget.state.streamService.searchChannels(
            query,
          );
        } catch (_) {
          foundChannels = <ChannelResult>[];
        }
        try {
          foundPlaylists = await widget.state.streamService.searchPlaylists(
            query,
          );
        } catch (_) {
          foundPlaylists = <PlaylistResult>[];
        }
        List<String> foundHints = <String>[];
        try {
          foundHints = await widget.state.suggestionsService.fetch(query);
        } catch (_) {
          foundHints = <String>[];
        }
        if (!mounted) return;
        setState(() {
          results = found;
          channels = foundChannels;
          onlinePlaylists = foundPlaylists;
          suggestions = foundHints;
          loading = false;
          searched = true;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          loading = false;
          searched = true;
          failed = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: strings.searchOnlineHint,
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => _onChanged(v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            strings.needsInternet,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (loading) Center(child: CircularProgressIndicator()),
        if (!loading && failed) Center(child: Text(strings.searchError)),
        if (!loading && !failed && searched && results.isEmpty)
          Center(child: Text(strings.noResults)),
        if (!loading && suggestions.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(suggestions[index]),
                    onPressed: () {
                      _controller.text = suggestions[index];
                      _onChanged(suggestions[index]);
                    },
                  ),
                );
              },
            ),
          ),
        if (!loading && channels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: channels.length,
                itemBuilder: (context, index) {
                  final ch = channels[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: Icon(Icons.person),
                      label: Text(ch.name),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) {
                              return ChannelScreen(
                                state: widget.state,
                                strings: strings,
                                channelId: ch.channelId,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        if (!loading && onlinePlaylists.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: onlinePlaylists.length,
                itemBuilder: (context, index) {
                  final p = onlinePlaylists[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: Icon(Icons.playlist_play),
                      label: Text(p.name),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) {
                              return OnlinePlaylistScreen(
                                state: widget.state,
                                strings: strings,
                                playlistId: p.playlistId,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        if (!loading && !failed && results.isNotEmpty)
          Expanded(
            child: GridView.builder(
              addRepaintBoundaries: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: searchColumns(context),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: searchColumns(context) == 1 ? 6.5 : 1.1,
              ),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final video = results[index];
                return Card(
                  child: ListTile(
                    leading: _thumb(video.thumbnailUrl),
                    title: Text(video.title),
                    subtitle: Text(video.author),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'queue') {
                          widget.state.addToQueue(video);
                        } else if (value == 'playlist') {
                          await _addToPlaylist(video);
                        } else if (value == 'download') {
                          setState(() => loading = true);
                          try {
                            await widget.state.downloadVideo(video);
                          } catch (_) {
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(content: Text(strings.searchError)),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => loading = false);
                            }
                          }
                        } else if (value == 'channel') {
                          final id = video.channelId;
                          if (id != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) {
                                  return ChannelScreen(
                                    state: widget.state,
                                    strings: strings,
                                    channelId: id,
                                  );
                                },
                              ),
                            );
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'queue',
                          child: Text(strings.enqueue),
                        ),
                        PopupMenuItem(
                          value: 'playlist',
                          child: Text(strings.addToPlaylist),
                        ),
                        PopupMenuItem(
                          value: 'download',
                          child: Text(strings.download),
                        ),
                        if (video.channelId != null)
                          PopupMenuItem(
                            value: 'channel',
                            child: Text(strings.channel),
                          ),
                      ],
                    ),
                    onTap: () => widget.state.playVideo(video),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _thumb(String? url) {
    if (url == null || url.isEmpty || Uri.tryParse(url)?.scheme != 'https') {
      return Icon(Icons.audiotrack);
    }
    return SizedBox(
      width: 72,
      height: 40,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        cacheWidth: 144,
        // ignore: unused_element_parameter
        errorBuilder: (context, error, stackTrace) => Icon(Icons.audiotrack),
      ),
    );
  }

  Future<void> _addToPlaylist(VideoResult video) async {
    final state = widget.state;
    final track = Track.remote(
      videoId: video.videoId,
      title: video.title,
      author: video.author,
      thumbnailUrl: video.thumbnailUrl,
      durationSeconds: video.durationSeconds,
    );
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

class ChannelScreen extends StatefulWidget {
  const ChannelScreen({
    required this.state,
    required this.strings,
    required this.channelId,
    super.key,
  });

  final AppState state;
  final AppStrings strings;
  final String channelId;

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  ChannelDetail? detail;
  bool loading = true;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await widget.state.streamService.fetchChannel(widget.channelId);
      if (!mounted) return;
      setState(() {
        detail = d;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return Scaffold(
      appBar: AppBar(title: Text(detail?.name ?? strings.channel)),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : failed || detail == null
          ? Center(child: Text(strings.searchError))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (detail!.bannerUrl != null &&
                    Uri.tryParse(detail!.bannerUrl!)?.scheme == 'https')
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      detail!.bannerUrl!,
                      height: 120,
                      fit: BoxFit.cover,
                      cacheWidth: 1024,
                    ),
                  ),
                SizedBox(height: 16),
                Row(
                  children: [
                    if (detail!.avatarUrl != null &&
                        Uri.tryParse(detail!.avatarUrl!)?.scheme == 'https')
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(detail!.avatarUrl!),
                      ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail!.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          if (detail!.subscriberCount != null)
                            Text(
                              '${detail!.subscriberCount} ${strings.subscribers}',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (detail!.description != null &&
                    detail!.description!.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Text(detail!.description!),
                ],
                SizedBox(height: 16),
                Text(
                  strings.uploads,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                if (detail!.uploads.isEmpty)
                  Text(strings.noResults)
                else
                  ...detail!.uploads.map(
                    (video) => ListTile(
                      title: Text(video.title),
                      subtitle: Text(video.author),
                      onTap: () => widget.state.playVideo(video),
                    ),
                  ),
              ],
            ),
    );
  }
}

class OnlinePlaylistScreen extends StatefulWidget {
  const OnlinePlaylistScreen({
    required this.state,
    required this.strings,
    required this.playlistId,
    super.key,
  });

  final AppState state;
  final AppStrings strings;
  final String playlistId;

  @override
  State<OnlinePlaylistScreen> createState() => _OnlinePlaylistScreenState();
}

class _OnlinePlaylistScreenState extends State<OnlinePlaylistScreen> {
  OnlinePlaylistDetail? detail;
  bool loading = true;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await widget.state.streamService.fetchPlaylist(
        widget.playlistId,
      );
      if (!mounted) return;
      setState(() {
        detail = d;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(detail?.name ?? widget.strings.newPlaylist)),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : failed || detail == null
          ? Center(child: Text(widget.strings.searchError))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (detail!.description != null &&
                    detail!.description!.isNotEmpty)
                  Text(detail!.description!),
                SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {
                    if (detail!.videos.isNotEmpty) {
                      widget.state.playVideo(detail!.videos.first);
                    }
                  },
                  icon: Icon(Icons.play_arrow),
                  label: Text(widget.strings.playNow),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final playlist = await widget.state.createPlaylist(
                      detail!.name,
                    );
                    for (final v in detail!.videos) {
                      final track = Track.remote(
                        videoId: v.videoId,
                        title: v.title,
                        author: v.author,
                        thumbnailUrl: v.thumbnailUrl,
                        durationSeconds: v.durationSeconds,
                      );
                      await widget.state.addToPlaylist(playlist, track);
                    }
                  },
                  icon: Icon(Icons.download),
                  label: Text(widget.strings.addToPlaylist),
                ),
                SizedBox(height: 8),
                ...detail!.videos.map(
                  (video) => ListTile(
                    title: Text(video.title),
                    subtitle: Text(video.author),
                    onTap: () => widget.state.playVideo(video),
                  ),
                ),
              ],
            ),
    );
  }
}

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({required this.state, required this.strings, super.key});

  final AppState state;
  final AppStrings strings;

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  LyricsResult? result;
  bool loading = true;
  bool failed = false;
  List<SyncedLine> lines = <SyncedLine>[];
  int activeLine = -1;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onTick);
    _load();
  }

  @override
  void dispose() {
    widget.state.removeListener(_onTick);
    _scroll.dispose();
    super.dispose();
  }

  void _onTick() {
    if (lines.isEmpty || !mounted) {
      return;
    }
    final next = LyricsService.activeLineIndex(lines, widget.state.position);
    if (next != activeLine) {
      setState(() => activeLine = next);
      _scrollToActive();
    }
  }

  void _scrollToActive() {
    if (activeLine < 0 || !mounted) {
      return;
    }
    final lineHeight = 44.0;
    final target = activeLine * lineHeight;
    _scroll.animateTo(
      target - 80,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _load() async {
    final track = widget.state.current;
    if (track == null) {
      setState(() {
        loading = false;
      });
      return;
    }
    try {
      final r = await widget.state.lyricsService.fetch(
        track.title,
        track.subtitle ?? '',
      );
      if (!mounted) return;
      lines = r?.syncedLyrics != null
          ? widget.state.lyricsService.parseSynced(r!.syncedLyrics!)
          : <SyncedLine>[];
      setState(() {
        result = r;
        loading = false;
        failed = r == null;
      });
      _onTick();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return Scaffold(
      appBar: AppBar(title: Text(strings.lyricsTitle)),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : failed || result == null || !result!.hasLyrics
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  failed ? strings.lyricsError : strings.noLyrics,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : lines.isNotEmpty
          ? ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final isActive = index == activeLine;
                return SizedBox(
                  height: 44,
                  child: Text(
                    lines[index].text,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                );
              },
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Text(
                result!.plainLyrics ?? '',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
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
      appBar: AppBar(
        title: Text(strings.nowPlaying),
        actions: [
          IconButton(
            icon: Icon(Icons.lyrics),
            tooltip: strings.lyrics,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) {
                    return LyricsScreen(state: state, strings: strings);
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.radio),
            tooltip: strings.radio,
            onPressed: () async {
              final track = state.current;
              if (track != null) {
                await state.playRadioFor(track);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.timer),
            tooltip: strings.sleepTimer,
            onPressed: () async {
              final minutes = await showDialog<int>(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: Text(strings.sleepTimer),
                    children: [
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, 15),
                        child: Text(strings.minutes15),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, 30),
                        child: Text(strings.minutes30),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, 60),
                        child: Text(strings.minutes60),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, 0),
                        child: Text(strings.sleepOff),
                      ),
                    ],
                  );
                },
              );
              state.setSleepTimer(minutes == 0 ? null : minutes);
            },
          ),
          IconButton(
            icon: Icon(Icons.queue_music),
            tooltip: strings.queue,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) {
                    return QueueScreen(state: state, strings: strings);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.6),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: isDesktop(context)
                  ? Row(
                      children: [
                        Expanded(child: Center(child: _artwork(track))),
                        const SizedBox(width: 32),
                        Expanded(child: _controls(context, track, value, max)),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _artwork(track, size: 260),
                        const SizedBox(height: 28),
                        ..._controlRows(context, track, value, max),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _artwork(Track? track, {double size = 300}) {
    final radius = 28.0;
    if (track?.thumbnailUrl != null &&
        Uri.tryParse(track!.thumbnailUrl!)?.scheme == 'https') {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.network(
            track.thumbnailUrl!,
            fit: BoxFit.cover,
            cacheWidth: 640,
            errorBuilder: (context, error, stackTrace) =>
                _placeholderArt(size, radius),
          ),
        ),
      );
    }
    return _placeholderArt(size, radius);
  }

  Widget _placeholderArt(double size, double radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E2E2E), Color(0xFF0D0D0D)],
        ),
      ),
      child: Icon(Icons.album, size: size * 0.4, color: Colors.white54),
    );
  }

  Widget _controls(
    BuildContext context,
    Track? track,
    double value,
    double max,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          track?.title ?? strings.noTrack,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        const SizedBox(height: 6),
        Text(
          track?.subtitle ?? '',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        if (state.lastError != null) ...[
          SizedBox(height: 12),
          Text(
            state.lastError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red),
          ),
        ],
        SizedBox(height: 16),
        Slider(
          value: value,
          max: max,
          onChanged: (v) => state.seek(Duration(seconds: v.toInt())),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(fmt(state.position)), Text(fmt(state.duration))],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.shuffle,
                color: state.shuffle
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
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
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
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
    );
  }

  List<Widget> _controlRows(
    BuildContext context,
    Track? track,
    double value,
    double max,
  ) {
    final controls = _controls(context, track, value, max);
    return [controls];
  }
}
