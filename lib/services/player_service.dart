import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
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

class AppState {
  AppState() {
    player.onPlayerComplete.listen((_) => next(auto: true));
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
  String? lastError;
  final List<void Function()> _listeners = <void Function()>[];

  void addListener(void Function() listener) {
    _listeners.add(listener);
    player.onPlayerStateChanged.listen((s) {
      isPlaying = s == PlayerState.playing;
      notify();
    });
    player.onPositionChanged.listen((d) {
      position = d;
      notify();
    });
    player.onDurationChanged.listen((d) {
      duration = d;
      notify();
    });
  }

  void notify() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  Track? get current {
    if (queueIndex < 0 || queueIndex >= queue.length) {
      return null;
    }
    return queue[queueIndex];
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final libRaw = prefs.getString(_keyLibrary);
    if (libRaw != null) {
      final decoded = jsonDecode(libRaw) as List<dynamic>;
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          library.add(Track.fromJson(item));
        }
      }
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
    notify();
  }

  Future<void> addPaths(List<String> paths) async {
    final existing = library.map((t) => t.path).toSet();
    for (final path in paths) {
      if (!existing.contains(path)) {
        library.add(Track.fromPath(path));
      }
    }
    await _saveLibrary();
    queue = List<Track>.of(library);
    notify();
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
    notify();
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
      nextIndex = (queueIndex + 1 + _pseudoRandom(queue.length)) % queue.length;
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
    volume = value.clamp(0, 1);
    await player.setVolume(volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVolume, volume);
    notify();
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    notify();
  }

  void cycleRepeat() {
    repeat = NiRepeatMode.values[(repeat.index + 1) % NiRepeatMode.values.length];
    notify();
  }

  Future<void> setLanguage(String value) async {
    language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, value);
    notify();
  }

  Future<void> setTheme(ThemeChoice value) async {
    theme = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, value.name);
    notify();
  }

  Future<Playlist> createPlaylist(String name) async {
    final playlist = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'Untitled' : name.trim(),
    );
    playlists.add(playlist);
    await _savePlaylists();
    notify();
    return playlist;
  }

  Future<void> renamePlaylist(Playlist playlist, String name) async {
    playlist.name = name.trim();
    await _savePlaylists();
    notify();
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    playlists.remove(playlist);
    await _savePlaylists();
    notify();
  }

  Future<void> addToPlaylist(Playlist playlist, Track track) async {
    playlist.add(track);
    await _savePlaylists();
    notify();
  }

  Future<void> removeFromPlaylist(Playlist playlist, String path) async {
    playlist.removePath(path);
    await _savePlaylists();
    notify();
  }

  Future<void> clearAll() async {
    await player.stop();
    library.clear();
    queue = <Track>[];
    playlists.clear();
    historyPaths.clear();
    queueIndex = -1;
    await _saveLibrary();
    await _savePlaylists();
    await _saveHistory();
    notify();
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyLibrary,
      jsonEncode(library.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyPlaylists,
      jsonEncode(playlists.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> _saveHistory() async {
    if (historyPaths.length > 100) {
      historyPaths.length = 100;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHistory, jsonEncode(historyPaths));
  }

  int _pseudoRandom(int max) {
    if (max <= 0) {
      return 0;
    }
    return (DateTime.now().microsecondsSinceEpoch % max).abs();
  }
}
