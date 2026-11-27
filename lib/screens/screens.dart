import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/app_strings.dart';
import '../models/lyrics.dart';
import '../models/playlist.dart';
import '../models/radio_station.dart';
import '../models/track.dart';
import '../models/video_result.dart';
import '../services/backup_service.dart';
import '../services/lyrics_service.dart';
import '../services/library_sort.dart';
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
  String filter = 'all';
  String view = 'songs';
  final Set<String> _selected = <String>{};

  bool get _selecting => _selected.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  List<Track> _selectedTracks() {
    return widget.state.library
        .where((track) => _selected.contains(track.id))
        .toList();
  }

  Future<void> _addSelectedToQueue() async {
    await widget.state.addTracksToQueue(_selectedTracks());
    setState(_selected.clear);
  }

  Future<void> _addSelectedToFavorites() async {
    await widget.state.addManyToFavorites(_selectedTracks());
    setState(_selected.clear);
  }

  Future<void> _addSelectedToPlaylist() async {
    final state = widget.state;
    final strings = widget.strings;
    final playlists = state.playlists
        .where((playlist) => playlist.id != 'favorites')
        .toList();
    Playlist? target;
    if (playlists.isEmpty) {
      target = await state.createPlaylist(strings.newPlaylist);
    } else if (playlists.length == 1) {
      target = playlists.first;
    } else {
      target = await showModalBottomSheet<Playlist>(
        context: context,
        builder: (context) {
          return ListView.builder(
            shrinkWrap: true,
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(playlists[index].name),
                onTap: () => Navigator.pop(context, playlists[index]),
              );
            },
          );
        },
      );
    }
    if (target != null) {
      await state.addTracksToPlaylist(target, _selectedTracks());
    }
    setState(_selected.clear);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final strings = widget.strings;
    final filtered = sortLibrary(
      state.searchLibrary(query).where((track) {
        switch (filter) {
          case 'local':
            return track.isLocal && !track.isDownloaded;
          case 'downloaded':
            return track.isDownloaded;
          case 'online':
            return track.isRemote &&
                !(track.videoId?.startsWith('radio:') ?? false);
          case 'radio':
            return track.videoId?.startsWith('radio:') ?? false;
          default:
            return true;
        }
      }).toList(),
      state.librarySort,
      state.historyIds,
    );
    final queueIndexById = <String, int>{
      for (var i = 0; i < state.queue.length; i++) state.queue[i].id: i,
    };
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
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
              const SizedBox(width: 8),
              Tooltip(
                message: strings.sortBy,
                child: PopupMenuButton<LibrarySort>(
                  icon: const Icon(Icons.sort),
                  initialValue: state.librarySort,
                  onSelected: (value) => state.setLibrarySort(value),
                  itemBuilder: (context) => [
                    for (final sort in LibrarySort.values)
                      PopupMenuItem<LibrarySort>(
                        value: sort,
                        child: Row(
                          children: [
                            Icon(
                              sort == state.librarySort ? Icons.check : null,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(_sortLabel(sort, strings)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (final entry in <String, String>{
                'all': strings.all,
                'local': strings.sourceLocal,
                'downloaded': strings.downloads,
                'online': strings.sourceOnline,
                'radio': strings.radio,
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(entry.value),
                    selected: filter == entry.key,
                    onSelected: (_) => setState(() => filter = entry.key),
                  ),
                ),
              const SizedBox(width: 4),
              FilterChip(
                avatar: Icon(
                  view == 'songs'
                      ? Icons.music_note
                      : view == 'artists'
                      ? Icons.person
                      : Icons.album,
                  size: 18,
                ),
                label: Text(
                  view == 'songs'
                      ? strings.songs
                      : view == 'artists'
                      ? strings.artists
                      : strings.albums,
                ),
                selected: view != 'songs',
                onSelected: (_) => setState(() {
                  view = view == 'songs'
                      ? 'artists'
                      : view == 'artists'
                      ? 'albums'
                      : 'songs';
                }),
              ),
            ],
          ),
        ),
        if (_selecting)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text(
                  '${_selected.length} ${strings.selectedCount}',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.queue_music),
                  tooltip: strings.enqueue,
                  onPressed: _addSelectedToQueue,
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  tooltip: strings.addToFavorites,
                  onPressed: _addSelectedToFavorites,
                ),
                IconButton(
                  icon: const Icon(Icons.playlist_add),
                  tooltip: strings.addToPlaylist,
                  onPressed: _addSelectedToPlaylist,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: strings.clearSelection,
                  onPressed: () => setState(_selected.clear),
                ),
              ],
            ),
          ),
        Expanded(
          child: view != 'songs'
              ? _groupedView(filtered, view, strings)
              : filtered.isEmpty
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
              : (state.libraryGrid || searchColumns(context) > 1)
              ? GridView.builder(
                  addRepaintBoundaries: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: state.libraryGrid
                        ? (searchColumns(context) > 1
                              ? searchColumns(context)
                              : 2)
                        : searchColumns(context),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _libraryTile(
                      filtered[index],
                      context,
                      queueIndexById,
                    );
                  },
                )
              : ListView.separated(
                  addRepaintBoundaries: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 4),
                  itemBuilder: (context, index) =>
                      _libraryTile(filtered[index], context, queueIndexById),
                ),
        ),
      ],
    );
  }

  Widget _groupedView(List<Track> tracks, String view, AppStrings strings) {
    final state = widget.state;
    final grouped = <String, List<Track>>{};
    for (final track in tracks) {
      final key = view == 'artists'
          ? (track.author ?? 'Unknown').trim().isEmpty
                ? 'Unknown'
                : track.author!.trim()
          : (track.album ?? 'Unknown album').trim().isEmpty
          ? 'Unknown album'
          : track.album!.trim();
      grouped.putIfAbsent(key, () => <Track>[]).add(track);
    }
    final keys = grouped.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (keys.isEmpty) {
      return Center(child: Text(strings.emptyLibrary));
    }
    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final children = grouped[key]!;
        return ExpansionTile(
          leading: CircleAvatar(
            child: Icon(view == 'artists' ? Icons.person : Icons.album),
          ),
          title: Text(key, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${children.length} ${strings.tracksCount}'),
          children: children.map((track) {
            final queueIndex = state.queueIndexOf(track);
            return ListTile(
              dense: true,
              title: Text(track.title),
              subtitle: Text(track.subtitle ?? ''),
              onTap: () {
                if (queueIndex >= 0) state.playAt(queueIndex);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _libraryTile(
    Track track,
    BuildContext context,
    Map<String, int> queueIndexById,
  ) {
    final state = widget.state;
    final theme = Theme.of(context);
    final queueIndex = queueIndexById[track.id] ?? -1;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: _selected.contains(track.id)
              ? theme.colorScheme.primary
              : theme.colorScheme.primaryContainer,
          child: Icon(
            _selected.contains(track.id) ? Icons.check : Icons.music_note,
            color: _selected.contains(track.id)
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onPrimaryContainer,
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
            PopupMenuItem(
              onTap: () => state.toggleFavorite(track),
              child: Row(
                children: [
                  Icon(
                    state.isFavoriteId(track.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 18,
                    color: state.isFavoriteId(track.id)
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    state.isFavoriteId(track.id)
                        ? widget.strings.removeFromFavorites
                        : widget.strings.addToFavorites,
                  ),
                ],
              ),
            ),
            PopupMenuItem(child: Text(widget.strings.addToPlaylist)),
            PopupMenuItem(
              onTap: () =>
                  showTrackDetails(context, state, widget.strings, track),
              child: Text(widget.strings.trackDetails),
            ),
          ],
        ),
        onTap: () {
          if (_selecting) {
            _toggleSelection(track.id);
          } else if (queueIndex >= 0) {
            state.playAt(queueIndex);
          }
        },
        onLongPress: () => _toggleSelection(track.id),
      ),
    );
  }

  String _sortLabel(LibrarySort sort, AppStrings strings) {
    switch (sort) {
      case LibrarySort.name:
        return strings.sortByName;
      case LibrarySort.artist:
        return strings.sortByArtist;
      case LibrarySort.duration:
        return strings.sortByDuration;
      case LibrarySort.recent:
        return strings.sortByRecent;
      case LibrarySort.recentAdded:
        return strings.sortByRecentAdded;
    }
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
    if (widget.state.offlineMode) {
      setState(() => chartLoaded = true);
      return;
    }
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
    final topPlayed = state.topPlayed();
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
          Row(
            children: [
              Expanded(child: _sectionTitle(strings.recent, Icons.history)),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          HistoryScreen(state: state, strings: strings),
                    ),
                  );
                },
                child: Text(strings.seeAll),
              ),
            ],
          ),
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
        if (topPlayed.isNotEmpty) ...[
          _sectionTitle(strings.mostPlayed, Icons.trending_up),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: topPlayed.take(5).map((track) {
                final plays = state.playCounts[track.id] ?? 0;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.music_note,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${track.subtitle ?? ''} · $plays ${strings.playsCountSuffix}',
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.queue),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: strings.saveAsPlaylist,
            onPressed: state.queue.isEmpty
                ? null
                : () => _saveAsPlaylist(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: strings.clearQueue,
            onPressed: state.queue.isEmpty ? null : () => _clearQueue(context),
          ),
        ],
      ),
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
                  // Include the index so duplicate tracks get distinct keys.
                  key: ValueKey<String>('${track.id}#$index'),
                  tileColor: isCurrent
                      ? theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.5,
                        )
                      : null,
                  leading: Icon(
                    isCurrent ? Icons.graphic_eq : Icons.audiotrack,
                    color: isCurrent ? theme.colorScheme.primary : null,
                  ),
                  title: Text(
                    track.title,
                    style: isCurrent
                        ? TextStyle(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                  ),
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

  Future<void> _saveAsPlaylist(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.saveAsPlaylist),
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
              child: Text(strings.save),
            ),
          ],
        );
      },
    );
    if (name != null && name.trim().isNotEmpty) {
      await state.saveQueueAsPlaylist(name.trim());
    }
  }

  Future<void> _clearQueue(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.clearQueue),
          content: Text(strings.clearQueueConfirm),
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
      await state.clearQueue();
    }
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
    final theme = Theme.of(context);
    final favorite = state.favoritesPlaylist;
    final normal = state.playlists
        .where((playlist) => playlist.id != 'favorites')
        .toList();
    final byId = <String, Track>{
      for (final track in state.library) track.id: track,
    };
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _nameDialog(context, create: true),
                  icon: const Icon(Icons.playlist_add),
                  label: Text(strings.newPlaylist),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.merge_type),
                tooltip: strings.duplicates,
                onPressed: () => _showDuplicates(context),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.new_releases),
                title: Text(strings.smartPlaylists),
                subtitle: Text(strings.recentlyAdded),
                onTap: () {
                  final tracks = sortLibrary(
                    state.library,
                    LibrarySort.recentAdded,
                    state.historyIds,
                  ).take(50).toList();
                  _openSmartList(context, strings.recentlyAdded, tracks);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.play_disabled),
                title: Text(strings.neverPlayed),
                subtitle: Text(
                  '${state.library.where((t) => !state.playCounts.containsKey(t.id)).length} '
                  '${strings.tracksCount}',
                ),
                onTap: () {
                  final tracks = state.library
                      .where((t) => !state.playCounts.containsKey(t.id))
                      .toList();
                  _openSmartList(context, strings.neverPlayed, tracks);
                },
              ),
              if (state.favoriteStations.isNotEmpty) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.radio),
                  title: Text(strings.stationFavorites),
                  subtitle: Text(
                    '${state.favoriteStations.length} ${strings.tracksCount}',
                  ),
                  onTap: () => _openSmartList(
                    context,
                    strings.stationFavorites,
                    state.favoriteStations,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (favorite != null)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: ListTile(
              leading: Icon(Icons.favorite, color: theme.colorScheme.error),
              title: Text(strings.favorites),
              subtitle: Text('${favorite.length} ${strings.tracksCount}'),
              trailing: Icon(
                Icons.push_pin,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onTap: () =>
                  _openPlaylist(context, favorite, title: strings.favorites),
            ),
          ),
        Expanded(
          child: normal.isEmpty
              ? favorite == null
                    ? Center(child: Text(strings.emptyPlaylist))
                    : const SizedBox.shrink()
              : ReorderableListView.builder(
                  itemCount: normal.length,
                  onReorderItem: (oldIndex, newIndex) {
                    state.reorderPlaylists(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final playlist = normal[index];
                    var seconds = 0;
                    for (final id in playlist.trackIds) {
                      seconds += byId[id]?.durationSeconds ?? 0;
                    }
                    return Card(
                      key: ValueKey<String>(playlist.id),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: ListTile(
                        leading: const Icon(Icons.queue_music),
                        title: Text(playlist.name),
                        subtitle: Text(
                          '${playlist.length} ${strings.tracksCount}'
                          '${seconds > 0 ? ' · ${fmt(Duration(seconds: seconds))}' : ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: strings.renamePlaylist,
                              onPressed: () =>
                                  _nameDialog(context, playlist: playlist),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: strings.delete,
                              onPressed: () => _delete(context, playlist),
                            ),
                          ],
                        ),
                        onTap: () => _openPlaylist(context, playlist),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showDuplicates(BuildContext context) async {
    final groups = state.duplicates();
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.duplicates),
          content: groups.isEmpty
              ? Text(strings.noDuplicates)
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return ListTile(
                        title: Text(group.first.title),
                        subtitle: Text(
                          '${group.length} ${strings.tracksCount}',
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            for (final duplicate in group.skip(1)) {
                              await state.removeTrack(duplicate);
                            }
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Text(strings.mergeDuplicates),
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.cancel),
            ),
          ],
        );
      },
    );
  }

  void _openSmartList(BuildContext context, String title, List<Track> tracks) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: tracks.isEmpty
                ? Center(child: Text(strings.emptyPlaylist))
                : ListView.separated(
                    itemCount: tracks.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      final queueIndex = state.queueIndexOf(track);
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.music_note),
                        ),
                        title: Text(track.title),
                        subtitle: Text(track.subtitle ?? ''),
                        onTap: () {
                          if (queueIndex >= 0) state.playAt(queueIndex);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Future<void> _nameDialog(
    BuildContext context, {
    Playlist? playlist,
    bool create = false,
  }) async {
    final controller = TextEditingController(text: playlist?.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(create ? strings.newPlaylist : strings.renamePlaylist),
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
              child: Text(create ? strings.create : strings.save),
            ),
          ],
        );
      },
    );
    if (name == null || name.trim().isEmpty) {
      return;
    }
    if (create) {
      await state.createPlaylist(name);
    } else if (playlist != null) {
      await state.renamePlaylist(playlist, name);
    }
  }

  Future<void> _delete(BuildContext context, Playlist playlist) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.deletePlaylist),
          content: Text(strings.deletePlaylistConfirm),
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
      await state.deletePlaylist(playlist);
    }
  }

  void _openPlaylist(BuildContext context, Playlist playlist, {String? title}) {
    final byId = <String, Track>{for (final t in state.library) t.id: t};
    final tracks = playlist.trackIds
        .map((id) => byId[id])
        .whereType<Track>()
        .toList();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(title ?? playlist.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: strings.playAll,
                  onPressed: tracks.isEmpty
                      ? null
                      : () => state.playAllFromPlaylist(playlist),
                ),
                IconButton(
                  icon: const Icon(Icons.shuffle),
                  tooltip: strings.shuffleAll,
                  onPressed: tracks.isEmpty
                      ? null
                      : () => state.playAllFromPlaylist(
                          playlist,
                          shuffleAll: true,
                        ),
                ),
              ],
            ),
            body: tracks.isEmpty
                ? Center(child: Text(strings.emptyPlaylist))
                : ListView.separated(
                    itemCount: tracks.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          track.subtitle ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          tooltip: strings.removeFromPlaylist,
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

  static const String version = '9.0.0';
  static const String buildNumber = '39';

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
      'system': Color(0xFF607D8B),
      'indigo': Color(0xFF4F46E5),
      'teal': Color(0xFF0F766E),
      'purple': Color(0xFF7E22CE),
      'orange': Color(0xFFEA580C),
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
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
      ),
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
              _divider(),
              SwitchListTile(
                secondary: const Icon(Icons.fullscreen),
                title: Text(strings.immersivePlayer),
                value: state.immersivePlayer,
                onChanged: state.setImmersivePlayer,
              ),
              _divider(),
              SwitchListTile(
                secondary: const Icon(Icons.grid_view),
                title: Text(strings.gridView),
                value: state.libraryGrid,
                onChanged: state.setLibraryGrid,
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
              _divider(),
              SwitchListTile(
                secondary: Icon(
                  Icons.bedtime_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(strings.fadeOutSleep),
                subtitle: Text(strings.fadeOutSleepDesc),
                value: state.sleepFade,
                onChanged: (value) => state.setSleepFade(value),
              ),
              _divider(),
              SwitchListTile(
                secondary: const Icon(Icons.graphic_eq),
                title: Text(strings.skipSilence),
                subtitle: Text(strings.skipSilenceDesc),
                value: state.skipSilence,
                onChanged: (value) => state.setSkipSilence(value),
              ),
              _divider(),
              SwitchListTile(
                secondary: const Icon(Icons.cached),
                title: Text(strings.cacheOnline),
                subtitle: Text(strings.cacheOnlineDesc),
                value: state.cacheOnlineAudio,
                onChanged: (value) => state.setCacheOnlineAudio(value),
              ),
              _divider(),
              SwitchListTile(
                secondary: const Icon(Icons.wifi_off),
                title: Text(strings.offlineMode),
                subtitle: Text(strings.offlineModeDesc),
                value: state.offlineMode,
                onChanged: state.setOfflineMode,
              ),
              _settingRow(
                icon: Icons.tune,
                title: strings.pitch,
                child: Row(
                  children: [
                    Expanded(
                      child: Slider(
                        min: 0.5,
                        max: 2,
                        divisions: 6,
                        value: state.pitch,
                        onChanged: state.setPitch,
                      ),
                    ),
                    Text('${state.pitch.toStringAsFixed(2)}x'),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (Platform.isAndroid) ...[
          _label(context, strings.equalizer),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                      Icons.graphic_eq,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(strings.equalizer),
                    subtitle: Text(strings.equalizerDesc),
                    value: state.equalizerEnabled,
                    onChanged: (value) => state.setEqualizerEnabled(value),
                  ),
                  if (state.equalizerEnabled) ...[
                    const SizedBox(height: 8),
                    FutureBuilder<AndroidEqualizerParameters>(
                      future: state.equalizer.parameters,
                      builder: (context, snap) {
                        final params = snap.data;
                        if (params == null) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            for (var i = 0; i < params.bands.length; i++)
                              _EqBandRow(
                                band: params.bands[i],
                                minDecibels: params.minDecibels,
                                maxDecibels: params.maxDecibels,
                                gain: i < state.equalizerGains.length
                                    ? state.equalizerGains[i]
                                    : 0,
                                onChanged: (dB) =>
                                    state.setEqualizerBandGain(i, dB),
                              ),
                            const SizedBox(height: 4),
                            const Divider(),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              secondary: Icon(
                                Icons.volume_up,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(strings.loudnessEnhancer),
                              value: state.loudnessEnabled,
                              onChanged: (value) =>
                                  state.setLoudnessEnabled(value),
                            ),
                            if (state.loudnessEnabled)
                              Row(
                                children: [
                                  const Icon(Icons.graphic_eq, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Slider(
                                      min: 0,
                                      max: 10,
                                      divisions: 10,
                                      value: state.loudnessGain,
                                      onChanged: state.setLoudnessGain,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 44,
                                    child: Text(
                                      '+${state.loudnessGain.toStringAsFixed(0)}',
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: state.resetEqualizer,
                                icon: const Icon(Icons.restart_alt),
                                label: Text(strings.reset),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
                future: state.storageBytes(),
                builder: (context, snap) {
                  final mb = (snap.data ?? 0) / (1024 * 1024);
                  return ListTile(
                    leading: Icon(
                      Icons.sd_storage_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      '${strings.cacheSize}: ${mb.toStringAsFixed(1)} MB',
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
                title: Text(strings.clearCache),
                onTap: () => state.clearWaveformCache(),
              ),
              _divider(),
              ListTile(
                leading: Icon(
                  Icons.backup_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(strings.exportBackup),
                onTap: () async {
                  await BackupService().exportJson(
                    library: state.library,
                    playlists: state.playlists,
                    metaTitle: state.metaTitle,
                    metaArtist: state.metaArtist,
                  );
                },
              ),
              _divider(),
              ListTile(
                leading: Icon(
                  Icons.restore_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(strings.importBackup),
                onTap: () async {
                  final backup = await BackupService().importJson();
                  if (backup == null) return;
                  final added = await state.importBackup(
                    backup.tracks,
                    backup.playlists,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(strings.restoreDone(added))),
                    );
                  }
                },
              ),
              _divider(),
              ListTile(
                leading: Icon(
                  Icons.bar_chart,
                  color: theme.colorScheme.primary,
                ),
                title: Text(strings.statsTitle),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          StatsScreen(state: state, strings: strings),
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
      if (widget.state.offlineMode) {
        setState(() {
          failed = true;
          searched = false;
        });
        return;
      }
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
        if (filter != 'radio')
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
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: filter == 'radio' ? 16 : 0,
          ),
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
              const SizedBox(width: 8),
              _filterChip(context, 'radio', strings.radio, Icons.radio),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (filter == 'radio')
          Expanded(
            child: RadioOnlineView(state: widget.state, strings: strings),
          )
        else if (loading)
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
    if (widget.state.offlineMode) {
      setState(() {
        loading = false;
        failed = true;
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
          if (state.immersivePlayer) const _ImmersiveController(enabled: true),
          Builder(
            builder: (context) {
              final current = state.current;
              final favorite =
                  current != null && state.isFavoriteId(current.id);
              return IconButton(
                icon: Icon(
                  favorite ? Icons.favorite : Icons.favorite_border,
                  color: favorite ? Theme.of(context).colorScheme.error : null,
                ),
                tooltip: favorite
                    ? strings.removeFromFavorites
                    : strings.addToFavorites,
                onPressed: current == null
                    ? null
                    : () => state.toggleFavorite(current),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.share),
            tooltip: strings.share,
            onPressed: () => state.shareCurrent(),
          ),
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
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: strings.trackDetails,
            onPressed: track == null
                ? null
                : () => showTrackDetails(context, state, strings, track),
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
                        Expanded(
                          child: Center(
                            child: GestureDetector(
                              onHorizontalDragEnd: (details) {
                                final velocity = details.primaryVelocity ?? 0;
                                if (velocity < -300) {
                                  HapticFeedback.lightImpact();
                                  state.next();
                                } else if (velocity > 300) {
                                  HapticFeedback.lightImpact();
                                  state.previous();
                                }
                              },
                              child: _artwork(track),
                            ),
                          ),
                        ),
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

  bool _isRadio(Track? track) => track?.videoId?.startsWith('radio:') ?? false;

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
        if (state.sleepDeadline != null) ...[
          SizedBox(height: 12),
          _SleepCountdown(
            state: state,
            strings: strings,
            onCancel: state.setSleepTimer,
          ),
        ],
        SizedBox(height: 16),
        if (_isRadio(track))
          Chip(
            avatar: const Icon(Icons.radio, size: 18, color: Colors.white),
            label: Text(
              '${strings.live} · ${strings.radio}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            backgroundColor: Colors.redAccent.shade400,
            side: BorderSide.none,
          )
        else
          _WaveformBar(
            state: state,
            track: track,
            duration: max,
            onSeek: (v) => state.seek(v),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(fmt(state.position)), Text(fmt(state.duration))],
        ),
        if (_isRadio(track) && state.icyTitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${strings.nowOnRadio}: ${state.icyTitle}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          )
        else if (!_isRadio(track))
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final rate in <double>[0.75, 1, 1.25, 1.5, 2])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text('${rate}x'),
                      selected: (state.playbackRate - rate).abs() < 0.01,
                      onSelected: (_) => state.setPlaybackRate(rate),
                    ),
                  ),
              ],
            ),
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
            if (state.isBuffering)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(strokeWidth: 4),
                ),
              )
            else
              IconButton(
                icon: Icon(
                  state.isPlaying ? Icons.pause_circle : Icons.play_circle,
                ),
                iconSize: 56,
                tooltip: state.isPlaying ? strings.pause : strings.play,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  state.toggle();
                },
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

class _EqBandRow extends StatelessWidget {
  const _EqBandRow({
    required this.band,
    required this.minDecibels,
    required this.maxDecibels,
    required this.gain,
    required this.onChanged,
  });

  final AndroidEqualizerBand band;
  final double minDecibels;
  final double maxDecibels;
  final double gain;
  final ValueChanged<double> onChanged;

  String _freq(double hz) {
    if (hz >= 1000) {
      final khz = hz / 1000;
      return '${khz >= 10 ? khz.toStringAsFixed(0) : khz.toStringAsFixed(1)}k';
    }
    return hz.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final clampedGain = gain.clamp(minDecibels, maxDecibels);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              _freq(band.centerFrequency),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Expanded(
            child: Slider(
              min: minDecibels,
              max: maxDecibels,
              value: clampedGain,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '${clampedGain >= 0 ? '+' : ''}${clampedGain.toStringAsFixed(1)}',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepCountdown extends StatefulWidget {
  const _SleepCountdown({
    required this.state,
    required this.strings,
    required this.onCancel,
  });

  final AppState state;
  final AppStrings strings;
  final void Function(int?) onCancel;

  @override
  State<_SleepCountdown> createState() => _SleepCountdownState();
}

class _SleepCountdownState extends State<_SleepCountdown> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deadline = widget.state.sleepDeadline;
    if (deadline == null) {
      return const SizedBox.shrink();
    }
    var remaining = deadline.difference(DateTime.now());
    if (remaining.isNegative) {
      remaining = Duration.zero;
    }
    final m = remaining.inMinutes;
    final s = remaining.inSeconds % 60;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bedtime,
            size: 18,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Text(
            '${widget.strings.sleepTimer}: $m:${s.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          InkResponse(
            onTap: () => widget.onCancel(null),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                size: 18,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RadioOnlineView extends StatefulWidget {
  const RadioOnlineView({
    required this.state,
    required this.strings,
    super.key,
  });

  final AppState state;
  final AppStrings strings;

  @override
  State<RadioOnlineView> createState() => _RadioOnlineViewState();
}

class _RadioOnlineViewState extends State<RadioOnlineView> {
  final TextEditingController _controller = TextEditingController();
  List<RadioStation> stations = <RadioStation>[];
  bool loading = true;
  bool failed = false;
  Timer? _debounce;
  String? countryFilter;

  @override
  void initState() {
    super.initState();
    _loadTop();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadTop() async {
    if (widget.state.offlineMode) {
      setState(() {
        loading = false;
        failed = true;
      });
      return;
    }
    setState(() {
      loading = true;
      failed = false;
      countryFilter = null;
    });
    try {
      final found = await widget.state.radioService.topStations();
      if (!mounted) return;
      setState(() {
        stations = found;
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

  Future<void> _loadCountry(String country) async {
    if (widget.state.offlineMode) {
      setState(() {
        loading = false;
        failed = true;
      });
      return;
    }
    setState(() {
      loading = true;
      failed = false;
      countryFilter = country;
    });
    try {
      final found = await widget.state.radioService.byCountry(country);
      if (!mounted) return;
      setState(() {
        stations = found;
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

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final q = value.trim();
      if (q.isEmpty) {
        await _loadTop();
        return;
      }
      setState(() {
        loading = true;
        failed = false;
      });
      try {
        final found = await widget.state.radioService.search(q);
        if (!mounted) return;
        setState(() {
          stations = found;
          loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          loading = false;
          failed = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _controller,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: strings.radioSearchHint,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => _onChanged(v),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              FilterChip(
                label: Text(strings.topStations),
                selected: countryFilter == null,
                onSelected: (_) => _loadTop(),
              ),
              for (final country in <String>[
                'Indonesia',
                'United States',
                'United Kingdom',
                'Germany',
                'France',
              ])
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: FilterChip(
                    label: Text(country),
                    selected: countryFilter == country,
                    onSelected: (_) => _loadCountry(country),
                  ),
                ),
            ],
          ),
        ),
        if (loading)
          Expanded(child: Center(child: CircularProgressIndicator()))
        else if (failed)
          Expanded(
            child: Center(
              child: Text(strings.searchError, textAlign: TextAlign.center),
            ),
          )
        else if (stations.isEmpty)
          Expanded(child: Center(child: Text(strings.noStations)))
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: stations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) =>
                  _stationTile(stations[index], strings),
            ),
          ),
      ],
    );
  }

  String _subtitle(RadioStation station) {
    return <String?>[
      station.country,
      if (station.codec != null && station.codec!.isNotEmpty)
        station.codec!.toUpperCase(),
      if (station.bitrate != null && station.bitrate! > 0)
        '${station.bitrate} kbps',
    ].where((e) => e != null && e.isNotEmpty).join(' · ');
  }

  Widget _stationTile(RadioStation station, AppStrings strings) {
    final theme = Theme.of(context);
    final favicon = station.favicon;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: favicon == null
              ? Icon(Icons.radio, color: theme.colorScheme.onPrimaryContainer)
              : ClipOval(
                  child: Image.network(
                    favicon,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.radio,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
        ),
        title: Text(
          station.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _subtitle(station),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                widget.state.isFavoriteStation(station.stationUuid)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: widget.state.isFavoriteStation(station.stationUuid)
                    ? theme.colorScheme.error
                    : null,
              ),
              tooltip: strings.favorites,
              onPressed: () => widget.state.toggleFavoriteStation(station),
            ),
            Icon(
              Icons.play_circle_fill,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
        onTap: () => widget.state.playRadioStation(station),
      ),
    );
  }
}

/// Seekable waveform bar for Android local files. Falls back to a plain
/// slider while the waveform is unavailable (remote streams, missing
/// playback metadata, unsupported devices).
class _WaveformBar extends StatefulWidget {
  const _WaveformBar({
    required this.state,
    required this.track,
    required this.duration,
    required this.onSeek,
  });

  final AppState state;
  final Track? track;
  final double duration;
  final ValueChanged<Duration> onSeek;

  @override
  State<_WaveformBar> createState() => _WaveformBarState();
}

class _WaveformBarState extends State<_WaveformBar> {
  List<int>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_WaveformBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track != widget.track) {
      _data = null;
      _load();
    }
  }

  Future<void> _load() async {
    final track = widget.track;
    final path = track?.path;
    if (track == null || path == null || !Platform.isAndroid) {
      return;
    }
    try {
      final tmp = await getTemporaryDirectory();
      final waveFile = File('${tmp.path}/niusic_${track.id}.wave');
      final done = await JustWaveform.extract(
        audioInFile: File(path),
        waveOutFile: waveFile,
      ).firstWhere((p) => p.waveform != null);
      if (!mounted) return;
      setState(() => _data = done.waveform!.data);
    } catch (e) {
      debugPrint('waveform extraction failed: $e');
    }
  }

  void _seekTo(BuildContext context, Offset local) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || box.size.width <= 0) return;
    final fraction = (local.dx / box.size.width).clamp(0.0, 1.0);
    final duration = widget.duration <= 0 ? 1.0 : widget.duration;
    widget.onSeek(Duration(seconds: (fraction * duration).toInt()));
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null || data.isEmpty) {
      // Fallback to the classic slider.
      return SizedBox(
        height: 34,
        child: Slider(
          value: widget.state.position.inSeconds.toDouble(),
          max: widget.duration,
          onChanged: (v) => widget.onSeek(Duration(seconds: v.toInt())),
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (e) => _seekTo(context, e.localPosition),
      onPanStart: (d) => _seekTo(context, d.localPosition),
      onPanUpdate: (d) => _seekTo(context, d.localPosition),
      child: SizedBox(
        height: 36,
        width: double.infinity,
        child: CustomPaint(
          painter: _WaveformPainter(
            data: data,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({required this.data, required this.color});

  final List<int> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final n = data.length;
    if (n < 2 || size.width <= 0 || size.height <= 0) return;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final half = size.height / 2;
    for (var i = 0; i < n; i += 2) {
      final x = i.toDouble() / (n - 1) * size.width;
      final up = (data[i] / 32768).abs().clamp(0.0, 1.0);
      final down = (data[i + 1] / 32768).abs().clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(x, half - half * up),
        Offset(x, half + half * down),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) {
    return identical(old.data, data) == false || old.color != color;
  }
}

void showTrackDetails(
  BuildContext context,
  AppState state,
  AppStrings strings,
  Track track,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      final plays = state.playCounts[track.id] ?? 0;
      final isRadio = track.videoId?.startsWith('radio:') == true;
      final source = isRadio
          ? strings.sourceRadio
          : track.isDownloaded
          ? strings.sourceDownloaded
          : track.isLocal
          ? strings.sourceLocal
          : strings.sourceOnline;

      Widget info(IconData icon, String text) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                track.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(track.subtitle ?? '', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              info(Icons.category, '${strings.sourceKind}: $source'),
              info(Icons.play_arrow, '$plays ${strings.playsCountSuffix}'),
              if (track.durationSeconds != null)
                info(
                  Icons.schedule,
                  fmt(Duration(seconds: track.durationSeconds!)),
                ),
              if (track.isLocal && track.path != null)
                info(Icons.folder_outlined, track.path!),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        state.playNext(track);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.skip_next),
                      label: Text(strings.playNext),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      state.isFavoriteId(track.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                    tooltip: strings.favorites,
                    onPressed: () => state.toggleFavorite(track),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: strings.share,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      state.shareTrack(track);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: strings.editMetadata,
                    onPressed: () =>
                        _editMetaDialog(context, state, strings, track),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _editMetaDialog(
  BuildContext context,
  AppState state,
  AppStrings strings,
  Track track,
) {
  final titleController = TextEditingController(text: track.title);
  final artistController = TextEditingController(text: track.author ?? '');
  final albumController = TextEditingController(text: track.album ?? '');
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(strings.editMetadata),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: strings.trackDetails),
              ),
              TextField(
                controller: artistController,
                decoration: InputDecoration(labelText: strings.sortByArtist),
              ),
              TextField(
                controller: albumController,
                decoration: InputDecoration(labelText: strings.albums),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () async {
              await state.setTrackMeta(
                track,
                title: titleController.text,
                artist: artistController.text,
                album: albumController.text,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(strings.save),
          ),
        ],
      );
    },
  );
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.state, required this.strings, super.key});

  final AppState state;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final tracks = state.recentTracks();
    return Scaffold(
      appBar: AppBar(title: Text(strings.recent)),
      body: tracks.isEmpty
          ? Center(child: Text(strings.emptyHistory))
          : ListView.separated(
              itemCount: tracks.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final track = tracks[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.history)),
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    track.subtitle ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    tooltip: strings.trackDetails,
                    onPressed: () =>
                        showTrackDetails(context, state, strings, track),
                  ),
                  onTap: () {
                    final queueIndex = state.queueIndexOf(track);
                    if (queueIndex >= 0) {
                      state.playAt(queueIndex);
                    }
                    Navigator.pop(context);
                  },
                );
              },
            ),
    );
  }
}

class StatsScreen extends StatelessWidget {
  const StatsScreen({required this.state, required this.strings, super.key});

  final AppState state;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = state.totalListenSeconds;
    final weekly = state.weeklyStats;
    final maxSeconds = weekly.fold<int>(
      1,
      (max, entry) => entry.value > max ? entry.value : max,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.statsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: strings.exportCsv,
            onPressed: () => BackupService().exportCsv(weekly),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.headphones,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fmt(Duration(seconds: total)),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(strings.totalListening),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            strings.thisWeek,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final entry in weekly)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 84,
                            child: Text(entry.key.substring(5)),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: entry.value / maxSeconds,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${entry.value}s'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImmersiveController extends StatefulWidget {
  const _ImmersiveController({required this.enabled});

  final bool enabled;

  @override
  State<_ImmersiveController> createState() => _ImmersiveControllerState();
}

class _ImmersiveControllerState extends State<_ImmersiveController> {
  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void didUpdateWidget(_ImmersiveController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled && !widget.enabled) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
