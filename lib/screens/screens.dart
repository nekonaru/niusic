import 'dart:async';
import 'dart:io';

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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      Platform.isAndroid
                          ? strings.scanDeviceMusicDesc
                          : strings.emptyLibrary,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : searchColumns(context) == 1
              ? ListView.separated(
                  addRepaintBoundaries: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 4),
                  itemBuilder: (context, index) =>
                      _libraryTile(filtered[index], context),
                )
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
                    return _libraryTile(filtered[index], context);
                  },
                ),
        ),
      ],
    );
  }

  Widget _libraryTile(Track track, BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    final queueIndex = state.queueIndexOf(track);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.music_note,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          track.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<Track>(
          onSelected: (value) => _addToPlaylist(value),
          itemBuilder: (context) => [
            PopupMenuItem(child: Text(widget.strings.addToPlaylist)),
          ],
        ),
        onTap: () => state.playAt(queueIndex),
      ),
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

  Future<void> _rescanFromHome() async {
    await widget.state.rescanDeviceMusic();
    if (mounted) {
      setState(() {});
    }
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
                    Icons.library_music,
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
                    Platform.isAndroid
                        ? strings.scanDeviceMusicDesc
                        : strings.emptyLibraryHint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (Platform.isAndroid) ...[
                    if (state.scanBusy)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (state.scanGranted)
                      FilledButton.icon(
                        onPressed: _rescanFromHome,
                        icon: const Icon(Icons.refresh),
                        label: Text(strings.scanNow),
                      )
                    else
                      FilledButton.icon(
                        onPressed: _rescanFromHome,
                        icon: const Icon(Icons.library_music),
                        label: Text(strings.scanPermissionNeeded),
                      ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: widget.onImport,
                      icon: const Icon(Icons.folder_open),
                      label: Text(strings.addMusic),
                    ),
                  ] else
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.state,
    required this.strings,
    required this.onChanged,
    super.key,
  });

  final AppState state;
  final AppStrings strings;
  final VoidCallback onChanged;

  static const String version = '2.4.1';
  static const String buildNumber = '25';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _scanning = false;
  String? _scanMessage;

  AppStrings get strings => widget.strings;
  AppState get state => widget.state;

  Future<void> _rescan() async {
    setState(() {
      _scanning = true;
      _scanMessage = null;
    });
    await state.rescanDeviceMusic();
    if (!mounted) {
      return;
    }
    setState(() {
      _scanning = false;
      _scanMessage = state.scanGranted
          ? strings.scanResult(state.lastScanAdded, state.lastScanTotal)
          : (Platform.isAndroid
                ? strings.scanPermissionNeeded
                : strings.scanUnavailable);
    });
  }

  Future<void> _requestNotifications() async {
    try {
      await const MethodChannel('niusic/permission')
          .invokeMethod<bool>('requestNotifications');
    } on MissingPluginException {
      // Not available on this platform.
    } on PlatformException {
      // Keep the UI usable; the user can enable it in system settings.
    }
  }

  String _timeLabel(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _scanSubtitle() {
    if (!Platform.isAndroid) {
      return strings.scanUnavailable;
    }
    if (!state.scanGranted) {
      return strings.scanPermissionNeeded;
    }
    final at = state.lastScanAt;
    if (at == null) {
      return strings.scanDeviceMusicDesc;
    }
    return '${strings.lastScanPrefix}: ${_timeLabel(at)}. '
        '${strings.scanResult(state.lastScanAdded, state.lastScanTotal)}';
  }

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 56);

  Widget _settingRow({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 10),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _accentRow(BuildContext context) {
    const colors = <String, Color>{
      'indigo': Color(0xFF4F46E5),
      'teal': Color(0xFF0F766E),
      'purple': Color(0xFF7E22CE),
      'orange': Color(0xFFEA580C),
    };
    return Row(
      children: [
        for (final entry in colors.entries) ...[
          _AccentSwatch(
            color: entry.value,
            selected: state.accent == entry.key,
            onTap: () => state.setAccent(entry.key),
          ),
          const SizedBox(width: 14),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Image.asset('assets/niusic-mark.png', width: 56, height: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Niusic',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${SettingsScreen.version} (${SettingsScreen.buildNumber})',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _label(context, strings.appearance),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _settingRow(
                icon: Icons.translate,
                title: strings.language,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 'en', label: Text(strings.english)),
                    ButtonSegment(value: 'id', label: Text(strings.indonesian)),
                  ],
                  selected: {state.language},
                  onSelectionChanged: (value) async {
                    await state.setLanguage(value.first);
                    widget.onChanged();
                  },
                ),
              ),
              _divider(),
              _settingRow(
                icon: Icons.brightness_6_outlined,
                title: strings.theme,
                child: SegmentedButton<ThemeChoice>(
                  showSelectedIcon: false,
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
                    widget.onChanged();
                  },
                ),
              ),
              _divider(),
              _settingRow(
                icon: Icons.palette_outlined,
                title: strings.accent,
                child: _accentRow(context),
              ),
            ],
          ),
        ),
        _label(context, strings.playback),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _settingRow(
                icon: Icons.volume_up_outlined,
                title: strings.volume,
                child: Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: state.volume,
                        onChanged: (value) => state.setVolume(value),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${(state.volume * 100).round()}%',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              ),
              _divider(),
              _settingRow(
                icon: Icons.speed,
                title: strings.playbackSpeed,
                child: Row(
                  children: [
                    Expanded(
                      child: Slider(
                        min: 0.5,
                        max: 2.0,
                        divisions: 6,
                        value: state.playbackRate,
                        onChanged: (value) => state.setPlaybackRate(value),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${state.playbackRate.toStringAsFixed(2)}x',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              ),
              _divider(),
              _settingRow(
                icon: Icons.high_quality_outlined,
                title: strings.audioQuality,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: 'low',
                      label: Text(strings.qualityLow),
                    ),
                    ButtonSegment(
                      value: 'high',
                      label: Text(strings.qualityHigh),
                    ),
                  ],
                  selected: {state.streamService.audioQuality},
                  onSelectionChanged: (value) =>
                      state.setAudioQuality(value.first),
                ),
              ),
            ],
          ),
        ),
        _label(context, strings.library),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_mosaic_outlined,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.scanDeviceMusic,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _scanSubtitle(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_scanMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _scanMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _scanning ? null : _rescan,
                    icon: _scanning
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(_scanning ? strings.scanning : strings.scanNow),
                  ),
                ),
              ],
            ),
          ),
        ),
        _label(context, strings.notifications),
        Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            leading: Icon(
              Icons.notifications_outlined,
              size: 22,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              strings.notifications,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(strings.enableNotificationsDesc),
            trailing: OutlinedButton(
              onPressed: _requestNotifications,
              child: Text(strings.allow),
            ),
          ),
        ),
        _label(context, strings.storage),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              FutureBuilder<int>(
                future: state.totalDownloadBytes(),
                builder: (context, snap) {
                  final mb = (snap.data ?? 0) / (1024 * 1024);
                  return ListTile(
                    leading: Icon(
                      Icons.sd_storage_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      '${strings.downloadsSize}: '
                      '${mb.toStringAsFixed(1)} MB',
                    ),
                  );
                },
              ),
              _divider(),
              ListTile(
                leading: Icon(
                  Icons.delete_sweep_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(strings.clearDownloads),
                onTap: () => _confirmAndRun(
                  context,
                  title: strings.clearDownloads,
                  icon: Icons.delete_sweep_outlined,
                  action: state.clearDownloads,
                ),
              ),
              _divider(),
              ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  strings.clearData,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () => _confirmAndRun(
                  context,
                  title: strings.clearData,
                  icon: Icons.delete_forever_outlined,
                  action: state.clearAll,
                ),
              ),
            ],
          ),
        ),
        _label(context, strings.about),
        Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
            title: Text(strings.version),
            trailing: Text(
              '${SettingsScreen.version} (${SettingsScreen.buildNumber})',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndRun(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Future<void> Function() action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: Icon(icon, color: Theme.of(context).colorScheme.error),
          title: Text(title),
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
      await action();
    }
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 3,
                  )
                : Border.all(color: Colors.black12, width: 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : const [],
          ),
          child: selected
              ? const Icon(Icons.check, color: Colors.white, size: 22)
              : null,
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
  String filter = 'videos';
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
        if (!mounted) return;
        setState(() {
          results = found;
          channels = foundChannels;
          onlinePlaylists = foundPlaylists;
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

  void _onFilter(String value) {
    setState(() => filter = value);
    _onChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: TextField(
            controller: _controller,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: strings.searchOnlineHint,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => _onChanged(v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _filterChip(context, 'videos', strings.videos, Icons.music_note),
              const SizedBox(width: 8),
              _filterChip(context, 'channels', strings.channels, Icons.person),
              const SizedBox(width: 8),
              _filterChip(
                context,
                'playlists',
                strings.playlists,
                Icons.playlist_play,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (loading)
          Expanded(child: Center(child: CircularProgressIndicator()))
        else if (failed)
          Expanded(
            child: Center(
              child: Text(strings.searchError, textAlign: TextAlign.center),
            ),
          )
        else if (searched && _itemCount == 0)
          Expanded(
            child: Center(
              child: Text(
                strings.noResults,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else if (_itemCount > 0)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _itemCount,
              itemBuilder: (context, index) => _itemAt(index, strings),
            ),
          )
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.searchOnlineHint,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  int get _itemCount {
    switch (filter) {
      case 'channels':
        return channels.length;
      case 'playlists':
        return onlinePlaylists.length;
      default:
        return results.length;
    }
  }

  Widget _itemAt(int index, AppStrings strings) {
    switch (filter) {
      case 'channels':
        return _channelTile(channels[index], strings);
      case 'playlists':
        return _playlistTile(onlinePlaylists[index], strings);
      default:
        return _videoTile(results[index], strings);
    }
  }

  Widget _filterChip(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final selected = filter == value;
    return Expanded(
      child: Material(
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _onFilter(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? theme.colorScheme.onPrimary : null,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? theme.colorScheme.onPrimary : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _videoTile(VideoResult video, AppStrings strings) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: _squareThumb(video.thumbnailUrl),
        title: Text(
          video.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600, height: 1.2),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            video.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_circle_fill),
          iconSize: 44,
          color: Theme.of(context).colorScheme.primary,
          tooltip: strings.playNow,
          onPressed: () => widget.state.playVideo(video),
        ),
        onTap: () => widget.state.playVideo(video),
      ),
    );
  }

  Widget _channelTile(ChannelResult channel, AppStrings strings) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: _squareThumb(channel.thumbnailUrl, isCircle: true),
        title: Text(channel.name),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            channel.verified == true
                ? '${channel.subscriberCount ?? 0} ${strings.subscribers} · Verified'
                : '${channel.subscriberCount ?? 0} ${strings.subscribers}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => ChannelScreen(
                state: widget.state,
                strings: strings,
                channelId: channel.channelId,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _playlistTile(PlaylistResult playlist, AppStrings strings) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: _squareThumb(playlist.thumbnailUrl),
        title: Text(playlist.name, maxLines: 2),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(playlist.author ?? ''),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => OnlinePlaylistScreen(
                state: widget.state,
                strings: strings,
                playlistId: playlist.playlistId,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _squareThumb(String? url, {bool isCircle = false}) {
    final size = isCircle ? 56.0 : 80.0;
    final fallback = Icon(Icons.music_note, size: size * 0.5);
    if (url == null || url.isEmpty || Uri.tryParse(url)?.scheme != 'https') {
      if (isCircle) {
        return CircleAvatar(radius: 28, child: fallback);
      }
      return SizedBox(width: size, height: size, child: fallback);
    }
    final image = Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
    if (isCircle) {
      return ClipOval(child: image);
    }
    return ClipRRect(borderRadius: BorderRadius.circular(8), child: image);
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
            strings.errorText(state.lastError),
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
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
