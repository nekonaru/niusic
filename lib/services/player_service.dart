import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/playlist.dart';
import '../models/track.dart';

enum NiRepeatMode { off, all, one }

enum ThemeChoice { system, light, dark }

const String _keyLibrary = 'library_v1';
const String _keyPlaylists = 'playlists_v1';
const String _keyHistory = 'history_v1';
const String _keyLanguage = 'language';
const String _keyTheme = 'theme';
const String _keyVolume = 'volume';
const int _maxHistory = 100;

class AppState extends ChangeNotifier {
  AppState() {
    _completion = player.onPlayerComplete.listen((_) => next(auto: true));
    _stateSub = player.onPlayerStateChanged.listen((s) {
      final playing = s == PlayerState.playing;
      if (playing != isPlaying) {
        isPlaying = playing;
        notifyListeners();
      }
    });
    _positionSub = player.onPositionChanged.listen((d) {
      // Position events fire several times per second. Notifying on every
      // tick rebuilds the whole app. Only notify once per second.
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
  final List<Track> library = <Track>[];
  final List<Playlist> playlists = <Playlist>[];
  final List<String> historyPaths = <String>[];
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

  StreamSubscription<void>? _completion;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  SharedPreferences? _prefs;
  Timer? _volumeTimer;

  // Index maps avoid O(n) scans per list tile.
  final Map<String, int> _libraryIndex = <String, int>{};
  final Map<String, String> _lowerTitles = <String, String>{};

  Track? get current {
    if (queueIndex < 0 || queueIndex >= queue.length) {
      return null;
    }
    return queue[queueIndex];
  }

  int queueIndexOf(Track track) => _libraryIndex[track.path] ?? -1;

  List<Track> searchLibrary(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return library;
    }
    return library
        .where((t) => (_lowerTitles[t.path] ?? '').contains(needle))
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
          historyPaths.add(item);
        }
      }
    }
    language = prefs.getString(_keyLanguage) ?? 'en';
    theme =
        ThemeChoice.values.asNameMap()[prefs.getString(_keyTheme)] ??
        ThemeChoice.system;
    volume = prefs.getDouble(_keyVolume) ?? 1;
    await player.setVolume(volume);
    queue = List<Track>.of(library);
    notifyListeners();
  }

  Future<void> addPaths(List<String> paths) async {
    final existing = library.map((t) => t.path).toSet();
    var added = false;
    for (final path in paths) {
      if (!existing.contains(path)) {
        final track = Track.fromPath(path);
        library.add(track);
        _libraryIndex[track.path] = library.length - 1;
        _lowerTitles[track.path] = track.title.toLowerCase();
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
    historyPaths.remove(track.path);
    historyPaths.insert(0, track.path);
    await _saveHistory();
    await player.play(DeviceFileSource(track.path));
    notifyListeners();
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
      nextIndex =
          (queueIndex + 1 + _nextInt(queue.length)) % queue.length;
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
    // Debounce disk writes while dragging the slider.
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

  Future<void> removeFromPlaylist(Playlist playlist, String path) async {
    playlist.removePath(path);
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
    historyPaths.clear();
    queueIndex = -1;
    _volumeTimer?.cancel();
    await _saveLibrary();
    await _savePlaylists();
    await _saveHistory();
    notifyListeners();
  }

  List<Track> recentTracks() {
    final byPath = <String, Track>{for (final t in library) t.path: t};
    final result = <Track>[];
    for (final path in historyPaths) {
      final track = byPath[path];
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
    if (historyPaths.length > _maxHistory) {
      historyPaths.length = _maxHistory;
    }
    final prefs = await _getPrefs();
    await prefs.setString(_keyHistory, jsonEncode(historyPaths));
  }

  void _rebuildIndexes() {
    _libraryIndex.clear();
    _lowerTitles.clear();
    for (var i = 0; i < library.length; i++) {
      _libraryIndex[library[i].path] = i;
      _lowerTitles[library[i].path] = library[i].title.toLowerCase();
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
    super.dispose();
  }
}
