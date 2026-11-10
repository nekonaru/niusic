import 'dart:async';

import 'package:flutter/material.dart';

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
    final recent = state.recentTracks();
    final downloads = state.downloadedTracks();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: widget.onImport,
          icon: Icon(Icons.folder_open),
          label: Text(strings.addMusic),
        ),
        SizedBox(height: 16),
        if (chart.isNotEmpty) ...[
          Text(strings.topToday, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop(context) ? 5 : 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.85,
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
                  child: Container(
                    width: 140,
                    margin: EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cover != null &&
                            Uri.tryParse(cover)?.scheme == 'https')
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              cover,
                              height: 110,
                              cacheWidth: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.album, size: 110),
                            ),
                          )
                        else
                          Icon(Icons.album, size: 110),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
        ],
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
                    widget.onOpenNowPlaying();
                  },
                ),
              ),
        ],
        SizedBox(height: 16),
        Text(strings.downloads, style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 8),
        if (downloads.isEmpty)
          Text(strings.noDownloads)
        else
          ...downloads.map(
            (track) => ListTile(
              leading: Icon(Icons.download_done),
              title: Text(track.title),
              subtitle: Text(strings.downloaded),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline),
                tooltip: strings.deleteDownload,
                onPressed: () => state.deleteDownload(track),
              ),
              onTap: () => widget.onOpenNowPlaying(),
            ),
          ),
        SizedBox(height: 16),
        Text(
          '${state.library.length} ${strings.tracksCount}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
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
        Text(
          strings.audioQuality,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'low', label: Text(strings.qualityLow)),
            ButtonSegment(value: 'high', label: Text(strings.qualityHigh)),
          ],
          selected: {state.streamService.audioQuality},
          onSelectionChanged: (value) => state.setAudioQuality(value.first),
        ),
        SizedBox(height: 16),
        Text(
          strings.playbackSpeed,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text('${state.playbackRate.toStringAsFixed(2)}x'),
        Slider(
          min: 0.5,
          max: 2.0,
          divisions: 6,
          value: state.playbackRate,
          onChanged: (value) => state.setPlaybackRate(value),
        ),
        SizedBox(height: 16),
        Text(strings.accent, style: Theme.of(context).textTheme.titleLarge),
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
        SizedBox(height: 16),
        Text(strings.storage, style: Theme.of(context).textTheme.titleLarge),
        FutureBuilder<int>(
          future: state.totalDownloadBytes(),
          builder: (context, snap) {
            final bytes = snap.data ?? 0;
            final mb = bytes / (1024 * 1024);
            return Text(
              '${strings.downloadsSize}: ${mb.toStringAsFixed(1)} MB',
            );
          },
        ),
        SizedBox(height: 8),
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
          icon: Icon(Icons.delete_sweep),
          label: Text(strings.clearDownloads),
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
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: isDesktop(context)
                ? Row(
                    children: [
                      Expanded(child: _artwork(track)),
                      SizedBox(width: 32),
                      Expanded(child: _controls(context, track, value, max)),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _artwork(track),
                      SizedBox(height: 16),
                      ..._controlRows(context, track, value, max),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _artwork(Track? track) {
    if (track?.thumbnailUrl != null &&
        Uri.tryParse(track!.thumbnailUrl!)?.scheme == 'https') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          track.thumbnailUrl!,
          height: 240,
          cacheWidth: 480,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.album, size: 120),
        ),
      );
    }
    return Icon(Icons.album, size: 120);
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
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 8),
        Text(track?.subtitle ?? ''),
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
                color: state.repeat != NiRepeatMode.off ? Colors.indigo : null,
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
