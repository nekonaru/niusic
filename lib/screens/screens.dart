import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/lyrics.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../models/video_result.dart';
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
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
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
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final query = value.trim();
      if (query.isEmpty) {
        setState(() {
          results = <VideoResult>[];
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
        if (!mounted) return;
        setState(() {
          results = found;
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
        if (!loading && !failed && results.isNotEmpty)
          Expanded(
            child: ListView.builder(
              addRepaintBoundaries: true,
              itemCount: results.length,
              itemBuilder: (context, index) {
                final video = results[index];
                return ListTile(
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
                    ],
                  ),
                  onTap: () => widget.state.playVideo(video),
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

  @override
  void initState() {
    super.initState();
    _load();
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
      setState(() {
        result = r;
        loading = false;
        failed = r == null;
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Text(
                result!.plainLyrics ?? result!.syncedLyrics ?? '',
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (track?.thumbnailUrl != null &&
                  Uri.tryParse(track!.thumbnailUrl!)?.scheme == 'https')
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    track.thumbnailUrl!,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.album, size: 120),
                  ),
                )
              else
                Icon(Icons.album, size: 120),
              SizedBox(height: 16),
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
