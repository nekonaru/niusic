import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/playlist.dart';
import '../models/track.dart';
import '../models/video_result.dart';
import 'chart_service.dart';
import 'download_service.dart';
import 'lyrics_service.dart';
import 'stream_service.dart';
import 'suggestions_service.dart';

enum NiRepeatMode { off, all, one }

enum ThemeChoice { system, light, dark }

const String _keyLibrary = 'library_v1';
const String _keyPlaylists = 'playlists_v1';
const String _keyHistory = 'history_v1';
const String _keyLanguage = 'language';
const String _keyTheme = 'theme';
const String _keyVolume = 'volume';
const String _keyQuality = 'audio_quality';
const String _keyRate = 'playback_rate';
const String _keyAccent = 'accent';
const int _maxHistory = 100;

class AppState extends ChangeNotifier {
  AppState({StreamService? stream, DownloadService? downloads})
    : streamService = stream ?? StreamService(),
      downloadService = downloads ?? DownloadService(),
      lyricsService = LyricsService(),
      chartService = ChartService(),
      suggestionsService = SuggestionsService() {
    _completion = player.onPlayerComplete.listen((_) => next(auto: true));
    _stateSub = player.onPlayerStateChanged.listen((s) {
      final playing = s == PlayerState.playing;
      if (playing != isPlaying) {
        isPlaying = playing;
        notifyListeners();
      }
    });
    _positionSub = player.onPositionChanged.listen((d) {
      final nextSecond = d.inSeconds;
      if (nextSecond != position.inSeconds || duration == Duration.zero) {
        position = d;
        notifyListeners();
      } else {
        position = d;
      }
    });
    _durationSub = player.onDurationChanged.listen((d) {
      duration = d;
      notifyListeners();
    });
  }

  final AudioPlayer player = AudioPlayer();
  final StreamService streamService;
  final DownloadService downloadService;
  final LyricsService lyricsService;
  final ChartService chartService;
  final SuggestionsService suggestionsService;
  final List<Track> library = <Track>[];
  final List<Playlist> playlists = <Playlist>[];
  final List<String> historyIds = <String>[];
  List<Track> queue = <Track>[];
  int queueIndex = -1;
  bool shuffle = false;
  NiRepeatMode repeat = NiRepeatMode.off;
  double volume = 1;
  String language = 'en';
  ThemeChoice theme = ThemeChoice.system;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  String? lastError;
  double playbackRate = 1;
  String accent = 'indigo';
  Timer? _sleepTimer;
  int? sleepMinutes;

  StreamSubscription<void>? _completion;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  SharedPreferences? _prefs;
  Timer? _volumeTimer;

  final Map<String, int> _libraryIndex = <String, int>{};
  final Map<String, String> _lowerTitles = <String, String>{};

  Track? get current {
    if (queueIndex < 0 || queueIndex >= queue.length) {
      return null;
    }
    return queue[queueIndex];
  }

  int queueIndexOf(Track track) => queue.indexWhere((t) => t.id == track.id);

  List<Track> searchLibrary(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return library;
    }
    return library
        .where((t) => (_lowerTitles[t.id] ?? '').contains(needle))
        .toList();
  }

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> load() async {
    final prefs = await _getPrefs();
    final libRaw = prefs.getString(_keyLibrary);
    if (libRaw != null) {
      final decoded = jsonDecode(libRaw) as List<dynamic>;
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          library.add(Track.fromJson(item));
        }
      }
      _rebuildIndexes();
    }
    final plRaw = prefs.getString(_keyPlaylists);
    if (plRaw != null) {
      final decoded = jsonDecode(plRaw) as List<dynamic>;
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          playlists.add(Playlist.fromJson(item));
        }
      }
    }
    final histRaw = prefs.getString(_keyHistory);
    if (histRaw != null) {
      final decoded = jsonDecode(histRaw) as List<dynamic>;
      for (final item in decoded) {
        if (item is String) {
          historyIds.add(item);
        }
      }
    }
    language = prefs.getString(_keyLanguage) ?? 'en';
    theme =
        ThemeChoice.values.asNameMap()[prefs.getString(_keyTheme)] ??
        ThemeChoice.system;
    volume = prefs.getDouble(_keyVolume) ?? 1;
    streamService.audioQuality = prefs.getString(_keyQuality) ?? 'high';
    playbackRate = prefs.getDouble(_keyRate) ?? 1;
    accent = prefs.getString(_keyAccent) ?? 'indigo';
    await player.setPlaybackRate(playbackRate);
    await player.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          audioFocus: AndroidAudioFocus.gain,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
        ),
      ),
    );
    await player.setVolume(volume);
    final queueRaw = prefs.getString('queue_v1');
    if (queueRaw != null) {
      final decoded = jsonDecode(queueRaw) as List<dynamic>;
      final byId = <String, Track>{for (final t in library) t.id: t};
      final restored = <Track>[];
      for (final id in decoded) {
        if (id is String && byId.containsKey(id)) {
          restored.add(byId[id]!);
        }
      }
      queue = restored.isEmpty ? List<Track>.of(library) : restored;
      final savedIndex = prefs.getInt('queue_index');
      if (savedIndex != null && savedIndex >= 0 && savedIndex < queue.length) {
        queueIndex = savedIndex;
      }
    } else {
      queue = List<Track>.of(library);
    }
    notifyListeners();
  }

  Future<void> _saveQueue() async {
    final prefs = await _getPrefs();
    await prefs.setString(
      'queue_v1',
      jsonEncode(queue.map((t) => t.id).toList()),
    );
    await prefs.setInt('queue_index', queueIndex);
  }

  Future<void> addPaths(List<String> paths) async {
    final existing = library.map((t) => t.id).toSet();
    var added = false;
    for (final path in paths) {
      if (!existing.contains(path)) {
        final track = Track.fromPath(path);
        library.add(track);
        _libraryIndex[track.id] = library.length - 1;
        _lowerTitles[track.id] = track.title.toLowerCase();
        added = true;
      }
    }
    if (added) {
      await _saveLibrary();
      queue = List<Track>.of(library);
      notifyListeners();
    }
  }

  Future<void> playAt(int index) async {
    if (index < 0 || index >= queue.length) {
      return;
    }
    queueIndex = index;
    final track = queue[index];
    historyIds.remove(track.id);
    historyIds.insert(0, track.id);
    await _saveHistory();
    await _saveQueue();
    await _playTrack(track);
    notifyListeners();
  }

  Future<void> _playTrack(Track track) async {
    if (track.isLocal) {
      final path = track.path;
      if (path == null) {
        lastError = 'missing_path';
        notifyListeners();
        return;
      }
      await player.play(DeviceFileSource(path));
      return;
    }
    if (track.isDownloaded) {
      await player.play(DeviceFileSource(track.downloadPath!));
      return;
    }
    // Remote: resolve a fresh audio URL (cache lives in StreamService).
    final videoId = track.videoId;
    if (videoId == null) {
      lastError = 'missing_video_id';
      notifyListeners();
      return;
    }
    try {
      final url = await streamService.resolveAudioUrl(videoId);
      queue[queueIndex] = track.copyWithUrl(url);
      await player.play(UrlSource(url));
      lastError = null;
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
    }
  }

  void playVideo(VideoResult video) {
    final track = Track.remote(
      videoId: video.videoId,
      title: video.title,
      author: video.author,
      thumbnailUrl: video.thumbnailUrl,
      durationSeconds: video.durationSeconds,
    );
    final existing = queue.indexWhere((t) => t.id == track.id);
    if (existing >= 0) {
      unawaited(playAt(existing));
      return;
    }
    queue.add(track);
    library.add(track);
    _libraryIndex[track.id] = library.length - 1;
    _lowerTitles[track.id] = track.title.toLowerCase();
    unawaited(_saveLibrary());
    unawaited(playAt(queue.length - 1));
  }

  void addToQueue(VideoResult video) {
    final track = Track.remote(
      videoId: video.videoId,
      title: video.title,
      author: video.author,
      thumbnailUrl: video.thumbnailUrl,
      durationSeconds: video.durationSeconds,
    );
    if (queue.any((t) => t.id == track.id)) {
      return;
    }
    queue.add(track);
    library.add(track);
    _libraryIndex[track.id] = library.length - 1;
    _lowerTitles[track.id] = track.title.toLowerCase();
    unawaited(_saveLibrary());
    notifyListeners();
  }

  List<Track> downloadedTracks() {
    return library.where((t) => t.isDownloaded).toList();
  }

  Future<void> downloadVideo(VideoResult video) async {
    final videoId = video.videoId;
    final url = await streamService.resolveAudioUrl(videoId);
    final path = await downloadService.downloadTo(url, videoId);
    final existing = library.indexWhere((t) => t.id == 'yt:$videoId');
    if (existing >= 0) {
      library[existing] = library[existing].copyWithDownload(path);
      final q = queue.indexWhere((t) => t.id == 'yt:$videoId');
      if (q >= 0) {
        queue[q] = queue[q].copyWithDownload(path);
      }
    } else {
      final track = Track.remote(
        videoId: videoId,
        title: video.title,
        author: video.author,
        thumbnailUrl: video.thumbnailUrl,
        durationSeconds: video.durationSeconds,
      ).copyWithDownload(path);
      library.add(track);
      _libraryIndex[track.id] = library.length - 1;
      _lowerTitles[track.id] = track.title.toLowerCase();
    }
    await _saveLibrary();
    notifyListeners();
  }

  Future<void> deleteDownload(Track track) async {
    await downloadService.deleteFile(track.downloadPath);
    final li = library.indexWhere((t) => t.id == track.id);
    if (li >= 0) {
      final cleared = library[li].copyWithDownload(null);
      library[li] = cleared;
      final q = queue.indexWhere((t) => t.id == track.id);
      if (q >= 0) {
        queue[q] = cleared;
      }
    }
    await _saveLibrary();
    notifyListeners();
  }

  Future<void> setAudioQuality(String value) async {
    streamService.audioQuality = value;
    final prefs = await _getPrefs();
    await prefs.setString(_keyQuality, value);
    notifyListeners();
  }

  void moveQueueItem(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= queue.length || newIndex < 0) {
      return;
    }
    var target = newIndex;
    if (oldIndex < newIndex) {
      target = newIndex - 1;
    }
    final item = queue.removeAt(oldIndex);
    queue.insert(target, item);
    if (queueIndex == oldIndex) {
      queueIndex = target;
    } else if (oldIndex < queueIndex && target >= queueIndex) {
      queueIndex--;
    } else if (oldIndex > queueIndex && target <= queueIndex) {
      queueIndex++;
    }
    notifyListeners();
  }

  void removeQueueItem(int index) {
    if (index < 0 || index >= queue.length) {
      return;
    }
    queue.removeAt(index);
    if (queueIndex >= queue.length) {
      queueIndex = queue.isEmpty ? -1 : queue.length - 1;
    } else if (index < queueIndex) {
      queueIndex--;
    }
    notifyListeners();
  }

  Future<void> setSleepTimerTestOnly(int? minutes) {
    setSleepTimer(minutes);
    return Future.value();
  }

  void setSleepTimer(int? minutes) {
    _sleepTimer?.cancel();
    sleepMinutes = minutes;
    if (minutes != null && minutes > 0) {
      _sleepTimer = Timer(Duration(minutes: minutes), () {
        if (isPlaying) {
          unawaited(player.pause());
        }
        notifyListeners();
      });
    }
    notifyListeners();
  }

  Future<void> playRadioFor(Track track) async {
    // Prefer true related streams for remote tracks, fall back to search.
    final videoId = track.videoId;
    final relatedResults = videoId != null
        ? await streamService.related(videoId)
        : <VideoResult>[];
    final candidates = relatedResults.isNotEmpty
        ? relatedResults
        : await streamService.search(
            '${track.title} ${track.author ?? ''}'.trim(),
          );
    final seen = <String>{track.id};
    var added = 0;
    for (final v in candidates) {
      if (added >= 5) {
        break;
      }
      final id = 'yt:${v.videoId}';
      if (seen.contains(id)) {
        continue;
      }
      seen.add(id);
      addToQueue(v);
      added++;
    }
  }

  Future<void> setPlaybackRate(double value) async {
    playbackRate = value.clamp(0.5, 2.0);
    await player.setPlaybackRate(playbackRate);
    final prefs = await _getPrefs();
    await prefs.setDouble(_keyRate, playbackRate);
    notifyListeners();
  }

  Future<void> setAccent(String value) async {
    accent = value;
    final prefs = await _getPrefs();
    await prefs.setString(_keyAccent, value);
    notifyListeners();
  }

  Future<int> totalDownloadBytes() async {
    var total = 0;
    for (final track in library) {
      if (track.isDownloaded) {
        total += await downloadService.sizeOf(track.downloadPath);
      }
    }
    return total;
  }

  Future<void> clearDownloads() async {
    final tracks = downloadedTracks();
    for (final track in tracks) {
      await deleteDownload(track);
    }
  }

  Future<void> toggle() async {
    if (isPlaying) {
      await player.pause();
    } else {
      await player.resume();
    }
  }

  Future<void> seek(Duration d) async {
    await player.seek(d);
  }

  Future<void> next({bool auto = false}) async {
    if (queue.isEmpty) {
      return;
    }
    if (repeat == NiRepeatMode.one && auto) {
      await player.seek(Duration.zero);
      await player.resume();
      return;
    }
    int nextIndex;
    if (shuffle) {
      nextIndex = (queueIndex + 1 + _nextInt(queue.length)) % queue.length;
    } else {
      nextIndex = queueIndex + 1;
      if (nextIndex >= queue.length) {
        if (repeat == NiRepeatMode.all || !auto) {
          nextIndex = 0;
        } else {
          nextIndex = queueIndex;
        }
      }
    }
    await playAt(nextIndex);
  }

  Future<void> previous() async {
    if (queue.isEmpty) {
      return;
    }
    int prevIndex = queueIndex - 1;
    if (prevIndex < 0) {
      prevIndex = 0;
    }
    await playAt(prevIndex);
  }

  Future<void> setVolume(double value) async {
    volume = value.clamp(0, 1).toDouble();
    await player.setVolume(volume);
    _volumeTimer?.cancel();
    _volumeTimer = Timer(const Duration(milliseconds: 300), () async {
      final prefs = await _getPrefs();
      await prefs.setDouble(_keyVolume, volume);
    });
    notifyListeners();
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    notifyListeners();
  }

  void cycleRepeat() {
    repeat =
        NiRepeatMode.values[(repeat.index + 1) % NiRepeatMode.values.length];
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    language = value;
    final prefs = await _getPrefs();
    await prefs.setString(_keyLanguage, value);
    notifyListeners();
  }

  Future<void> setTheme(ThemeChoice value) async {
    theme = value;
    final prefs = await _getPrefs();
    await prefs.setString(_keyTheme, value.name);
    notifyListeners();
  }

  Future<Playlist> createPlaylist(String name) async {
    final playlist = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'Untitled' : name.trim(),
    );
    playlists.add(playlist);
    await _savePlaylists();
    notifyListeners();
    return playlist;
  }

  Future<void> renamePlaylist(Playlist playlist, String name) async {
    playlist.name = name.trim();
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    playlists.remove(playlist);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> addToPlaylist(Playlist playlist, Track track) async {
    playlist.add(track);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> removeFromPlaylist(Playlist playlist, String id) async {
    playlist.removeId(id);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> clearAll() async {
    await player.stop();
    library.clear();
    _libraryIndex.clear();
    _lowerTitles.clear();
    queue = <Track>[];
    playlists.clear();
    historyIds.clear();
    queueIndex = -1;
    _volumeTimer?.cancel();
    await _saveLibrary();
    await _savePlaylists();
    await _saveHistory();
    notifyListeners();
  }

  List<Track> recentTracks() {
    final byId = <String, Track>{for (final t in library) t.id: t};
    final result = <Track>[];
    for (final id in historyIds) {
      final track = byId[id];
      if (track != null) {
        result.add(track);
      }
    }
    return result;
  }

  Future<void> _saveLibrary() async {
    final prefs = await _getPrefs();
    await prefs.setString(
      _keyLibrary,
      jsonEncode(library.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> _savePlaylists() async {
    final prefs = await _getPrefs();
    await prefs.setString(
      _keyPlaylists,
      jsonEncode(playlists.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> _saveHistory() async {
    if (historyIds.length > _maxHistory) {
      historyIds.length = _maxHistory;
    }
    final prefs = await _getPrefs();
    await prefs.setString(_keyHistory, jsonEncode(historyIds));
  }

  void _rebuildIndexes() {
    _libraryIndex.clear();
    _lowerTitles.clear();
    for (var i = 0; i < library.length; i++) {
      _libraryIndex[library[i].id] = i;
      _lowerTitles[library[i].id] = library[i].title.toLowerCase();
    }
  }

  int _nextInt(int max) {
    if (max <= 0) {
      return 0;
    }
    return (DateTime.now().microsecondsSinceEpoch % max).abs();
  }

  @override
  void dispose() {
    _volumeTimer?.cancel();
    unawaited(_completion?.cancel());
    unawaited(_stateSub?.cancel());
    unawaited(_positionSub?.cancel());
    unawaited(_durationSub?.cancel());
    unawaited(player.dispose());
    streamService.dispose();
    downloadService.dispose();
    lyricsService.dispose();
    chartService.dispose();
    suggestionsService.dispose();
    _sleepTimer?.cancel();
    super.dispose();
  }
}
