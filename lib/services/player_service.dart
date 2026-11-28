import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import '../models/playlist.dart';
import '../models/radio_station.dart';
import '../models/track.dart';
import '../models/video_result.dart';
import 'audio_handler.dart';
import 'chart_service.dart';
import 'download_service.dart';
import 'library_merge.dart';
import 'library_sort.dart';
import 'lyrics_service.dart';
import 'radio_service.dart';
import 'scanner_service.dart';
import 'stream_service.dart';
import 'suggestions_service.dart';

enum NiRepeatMode { off, all, one }

class QueuePreset {
  const QueuePreset({required this.name, required this.ids});

  final String name;
  final List<String> ids;

  Map<String, dynamic> toJson() => <String, dynamic>{'name': name, 'ids': ids};

  factory QueuePreset.fromJson(Map<String, dynamic> json) {
    return QueuePreset(
      name: json['name'] as String? ?? 'Preset',
      ids:
          (json['ids'] as List<dynamic>?)?.whereType<String>().toList() ??
          <String>[],
    );
  }
}

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
const String _keyLibraryV2 = 'library_v2';
const String _keyHistoryV2 = 'history_v2';
const String _keyScanAsked = 'scan_permission_asked';
const String _keyPlayCounts = 'play_counts_v1';
const String _keySleepFade = 'sleep_fade_enabled';
const String _keyMetaOverrides = 'meta_overrides_v1';
const String _keyStats = 'stats_v1';
const String _keySkipSilence = 'skip_silence_enabled';
const String _keyPitch = 'pitch';
const String _keyCacheOnline = 'cache_online_audio';
const String _keyFavoriteStations = 'favorite_stations_v1';
const String _keyImmersive = 'immersive_player';
const String _keyLibraryGrid = 'library_grid';
const String _keyOfflineMode = 'offline_mode';
const String _keyResumePositions = 'resume_positions_v1';
const String _keySkipIntro = 'skip_intro_seconds';
const String _keySkipOutro = 'skip_outro_seconds';
const String _keyReplayGain = 'replay_gain_v1';
const String _keyBufferPreset = 'buffer_preset';
const String _keyFocusMode = 'focus_mode';
const String _keyEndAction = 'end_action';
const String _keyAbLoop = 'ab_loop_v1';
const String _keyEqPreset = 'eq_preset';
const String _keyThemeFromArt = 'theme_from_art';
const String _keySleepUntilEnd = 'sleep_until_end';
const String _keyQueuePresets = 'queue_presets_v1';
const String _keyTextScale = 'text_scale';
const String _keyReduceMotion = 'reduce_motion';
const String _keyOnboardingDone = 'onboarding_done_v1';
const String _keyMoods = 'track_moods_v1';
const String _keyLyricsCache = 'lyrics_cache_v1';
const String _keyLibrarySort = 'library_sort';
const String _keyEqEnabled = 'equalizer_enabled';
const String _keyEqGains = 'equalizer_gains';
const String _keyLoudnessEnabled = 'loudness_enhancer_enabled';
const String _keyLoudnessGain = 'loudness_enhancer_gain';
const int _maxHistory = 100;

class AppState extends ChangeNotifier {
  AppState({StreamService? stream, DownloadService? downloads})
    : streamService = stream ?? StreamService(),
      downloadService = downloads ?? DownloadService(),
      lyricsService = LyricsService(),
      chartService = ChartService(),
      suggestionsService = SuggestionsService() {
    _playerStateSub = player.playerStateStream.listen((s) {
      final completed = s.processingState == ProcessingState.completed;
      if (completed) {
        if (sleepUntilEnd) {
          sleepUntilEnd = false;
          unawaited(player.pause());
          unawaited(
            _getPrefs().then(
              (prefs) => prefs.setBool(_keySleepUntilEnd, false),
            ),
          );
          notifyListeners();
          return;
        }
        unawaited(next(auto: true));
        return;
      }
      final buffering =
          s.processingState == ProcessingState.loading ||
          s.processingState == ProcessingState.buffering;
      if (buffering != isBuffering) {
        isBuffering = buffering;
        notifyListeners();
      }
      final playing = s.playing;
      if (playing != isPlaying) {
        isPlaying = playing;
        notifyListeners();
      }
    });
    _positionSub = player.positionStream.listen((d) {
      final nextSecond = d.inSeconds;
      if (abLoopActive && abLoopB != null && d.inSeconds >= abLoopB!) {
        unawaited(player.seek(Duration(seconds: abLoopA!)));
      }
      if (isPlaying &&
          skipOutroSeconds > 0 &&
          duration > Duration.zero &&
          !(current?.videoId?.startsWith('radio:') ?? false) &&
          duration - d <= Duration(seconds: skipOutroSeconds)) {
        unawaited(next(auto: true));
      }
      if (nextSecond != position.inSeconds || duration == Duration.zero) {
        position = d;
        _recordListenSecond();
        notifyListeners();
      } else {
        position = d;
      }
    });
    _durationSub = player.durationStream.listen((d) {
      final newDuration = d ?? Duration.zero;
      if (newDuration != duration) {
        duration = newDuration;
        notifyListeners();
      }
    });
    _errorSub = player.errorStream.listen((e) {
      debugPrint('playback error: ${e.message}');
      lastError = 'playback_failed';
      notifyListeners();
    });
    _icySub = player.icyMetadataStream.listen((metadata) {
      final title = metadata?.info?.title;
      if (title != null && title != icyTitle) {
        icyTitle = title;
        notifyListeners();
      }
    });
  }

  final AndroidEqualizer equalizer = AndroidEqualizer();
  final AndroidLoudnessEnhancer loudnessEnhancer = AndroidLoudnessEnhancer();
  late final AudioPlayer player = AudioPlayer(
    audioPipeline: AudioPipeline(
      androidAudioEffects: [loudnessEnhancer, equalizer],
    ),
    audioLoadConfiguration: AudioLoadConfiguration(
      androidLoadControl: _loadControlFor(initialBufferPreset),
    ),
  );

  /// Set by main() before construction so the buffering preset is applied.
  static int initialBufferPreset = 1;

  static AndroidLoadControl _loadControlFor(int preset) {
    switch (preset) {
      case 0:
        return const AndroidLoadControl(
          minBufferDuration: Duration(seconds: 15),
          maxBufferDuration: Duration(seconds: 30),
          bufferForPlaybackDuration: Duration(milliseconds: 1000),
        );
      case 2:
        return const AndroidLoadControl(
          minBufferDuration: Duration(seconds: 120),
          maxBufferDuration: Duration(seconds: 300),
          bufferForPlaybackDuration: Duration(milliseconds: 5000),
        );
      default:
        return const AndroidLoadControl();
    }
  }

  final StreamService streamService;
  final DownloadService downloadService;
  final LyricsService lyricsService;
  final ChartService chartService;
  final RadioService radioService = RadioService();
  final SuggestionsService suggestionsService;
  final ScannerService scannerService = ScannerService();

  /// Handler that mirrors playback into the OS media notification.
  /// Assigned by main() after AudioService.init; null on unsupported platforms.
  NiusicAudioHandler? audioHandler;

  static const MethodChannel _widgetChannel = MethodChannel('niusic/widget');
  String? _widgetTitle;
  String? _widgetArtist;
  String? _widgetPlaying;
  final List<Track> library = <Track>[];
  final List<Playlist> playlists = <Playlist>[];
  final List<String> historyIds = <String>[];
  List<Track> queue = <Track>[];
  // Incremented whenever the queue content changes; lets _syncNotification
  // skip rebuilding the media notification items every second.
  int queueVersion = 0;
  int queueIndex = -1;
  bool shuffle = false;
  NiRepeatMode repeat = NiRepeatMode.off;
  double volume = 1;
  String language = 'en';
  ThemeChoice theme = ThemeChoice.system;
  bool isPlaying = false;
  bool isBuffering = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  String? lastError;
  double playbackRate = 1;
  String accent = 'indigo';
  Timer? _sleepTimer;
  Timer? _fadeTimer;
  int? sleepMinutes;
  DateTime? sleepDeadline;
  bool sleepFade = true;
  bool skipSilence = false;
  double pitch = 1.0;
  bool cacheOnlineAudio = false;
  bool immersivePlayer = false;
  bool libraryGrid = false;
  bool offlineMode = false;
  final Map<String, int> resumePositions = <String, int>{};
  final Map<String, double> replayGains = <String, double>{};
  int skipIntroSeconds = 0;
  int skipOutroSeconds = 0;
  int bufferPreset = 1;
  bool focusMode = false;
  String endAction = 'next';
  String? abLoopTrackId;
  int? abLoopA;
  int? abLoopB;
  String eqPreset = 'flat';
  bool themeFromArt = false;
  bool sleepUntilEnd = false;
  final List<QueuePreset> queuePresets = <QueuePreset>[];
  double textScale = 1;
  bool reduceMotion = false;
  bool onboardingDone = false;
  final Map<String, String> trackMoods = <String, String>{};
  final Map<String, Map<String, dynamic>> lyricsCache =
      <String, Map<String, dynamic>>{};
  String? icyTitle;
  final List<Track> favoriteStations = <Track>[];
  LibrarySort librarySort = LibrarySort.name;
  final Map<String, String> metaTitle = <String, String>{};
  final Map<String, String> metaArtist = <String, String>{};
  final Map<String, String> metaAlbum = <String, String>{};
  final Map<String, int> listenSecondsByDay = <String, int>{};
  final Map<String, int> playCounts = <String, int>{};
  bool equalizerEnabled = false;
  List<double> equalizerGains = <double>[];
  bool loudnessEnabled = false;
  double loudnessGain = 0;

  /// Scanner state for the UI.
  bool scanGranted = false;
  bool scanBusy = false;
  int lastScanAdded = 0;
  int lastScanTotal = 0;
  DateTime? lastScanAt;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerException>? _errorSub;
  StreamSubscription<IcyMetadata?>? _icySub;
  StreamSubscription<void>? _scanSub;
  Timer? _scanDebounce;
  Timer? _scanRetryTimer;
  Timer? _equalizerTimer;
  bool _equalizerApplied = false;
  bool _sourceLoaded = false;
  SharedPreferences? _prefs;
  Timer? _volumeTimer;
  final Random _random = Random();

  final Map<String, int> _libraryIndex = <String, int>{};
  final Map<String, String> _lowerTitles = <String, String>{};

  @override
  void notifyListeners() {
    _syncNotification();
    unawaited(_persistWidget());
    unawaited(_persistPlaylistWidget());
    super.notifyListeners();
  }

  String? _widgetPlaylistNames;

  Future<void> _persistPlaylistWidget() async {
    final names = playlists
        .where((playlist) => playlist.id != 'favorites')
        .take(4)
        .map((playlist) => playlist.name)
        .toList();
    final key = names.join('|');
    if (key == _widgetPlaylistNames) return;
    _widgetPlaylistNames = key;
    final prefs = await _getPrefs();
    for (var i = 0; i < 4; i++) {
      await prefs.setString(
        'widget_playlist_${i + 1}',
        i < names.length ? names[i] : 'Niusic',
      );
    }
    try {
      await _widgetChannel.invokeMethod<void>('update');
    } catch (_) {
      // Widget channel is Android only.
    }
  }

  Future<void> _persistWidget() async {
    final cur = current;
    final title = cur?.title;
    final artist = cur?.subtitle;
    final playing = isPlaying.toString();
    if (title == _widgetTitle &&
        artist == _widgetArtist &&
        playing == _widgetPlaying) {
      return;
    }
    try {
      final prefs = await _getPrefs();
      await prefs.setString('widget_title', title ?? 'Niusic');
      await prefs.setString('widget_artist', artist ?? 'Tap to open');
      await prefs.setString('widget_playing', playing);
      _widgetTitle = title;
      _widgetArtist = artist;
      _widgetPlaying = playing;
      await _widgetChannel.invokeMethod<void>('update');
    } catch (_) {
      // Widget channel is only available on Android.
    }
  }

  final List<MediaItem> _cachedItems = <MediaItem>[];
  int _cachedQueueVersion = -1;
  String _lastSyncKey = '';

  void _syncNotification() {
    final handler = audioHandler;
    if (handler == null) {
      return;
    }
    final cur = current;
    if (cur == null) {
      return;
    }
    if (queueVersion != _cachedQueueVersion || _cachedItems.isEmpty) {
      _cachedItems
        ..clear()
        ..addAll(queue.map(_toMediaItem));
      _cachedQueueVersion = queueVersion;
    }
    final syncKey =
        '${cur.id}|$queueIndex|${isPlaying ? 1 : 0}|${position.inSeconds}';
    if (syncKey == _lastSyncKey) {
      return;
    }
    _lastSyncKey = syncKey;
    handler.sync(
      playing: isPlaying,
      position: position,
      duration: duration,
      title: cur.title,
      artist: cur.subtitle,
      id: cur.id,
      queueIndex: queueIndex,
      items: _cachedItems,
    );
  }

  MediaItem _toMediaItem(Track track) {
    return MediaItem(
      id: track.id,
      title: track.title,
      artist: track.subtitle,
      duration: track.durationSeconds != null && track.durationSeconds! > 0
          ? Duration(seconds: track.durationSeconds!)
          : null,
      artUri: () {
        final thumb = track.thumbnailUrl;
        if (thumb != null && Uri.tryParse(thumb)?.scheme == 'https') {
          return Uri.tryParse(thumb);
        }
        final art = track.albumArtUri;
        if (art != null && Uri.tryParse(art)?.scheme == 'content') {
          return Uri.tryParse(art);
        }
        return null;
      }(),
    );
  }

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
    // load() must be idempotent: reloading (for example in tests or after a
    // settings change) must not duplicate stored tracks or playlists.
    library.clear();
    playlists.clear();
    historyIds.clear();
    _libraryIndex.clear();
    _lowerTitles.clear();
    _cachedItems.clear();
    _lastSyncKey = '';
    final prefs = await _getPrefs();
    final libRaw =
        prefs.getString(_keyLibraryV2) ?? prefs.getString(_keyLibrary);
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
    final histRaw =
        prefs.getString(_keyHistoryV2) ?? prefs.getString(_keyHistory);
    if (histRaw != null) {
      final decoded = jsonDecode(histRaw) as List<dynamic>;
      for (final item in decoded) {
        if (item is String) {
          historyIds.add(
            item.startsWith('local:') || item.startsWith('yt:')
                ? item
                : 'local:$item',
          );
        }
      }
    }
    language = prefs.getString(_keyLanguage) ?? 'en';
    theme =
        ThemeChoice.values.asNameMap()[prefs.getString(_keyTheme)] ??
        ThemeChoice.dark;
    volume = prefs.getDouble(_keyVolume) ?? 1;
    streamService.audioQuality = prefs.getString(_keyQuality) ?? 'high';
    playbackRate = prefs.getDouble(_keyRate) ?? 1;
    accent = prefs.getString(_keyAccent) ?? 'indigo';
    sleepFade = prefs.getBool(_keySleepFade) ?? true;
    skipSilence = prefs.getBool(_keySkipSilence) ?? false;
    pitch = prefs.getDouble(_keyPitch) ?? 1;
    cacheOnlineAudio = prefs.getBool(_keyCacheOnline) ?? false;
    immersivePlayer = prefs.getBool(_keyImmersive) ?? false;
    libraryGrid = prefs.getBool(_keyLibraryGrid) ?? false;
    offlineMode = prefs.getBool(_keyOfflineMode) ?? false;
    skipIntroSeconds = prefs.getInt(_keySkipIntro) ?? 0;
    skipOutroSeconds = prefs.getInt(_keySkipOutro) ?? 0;
    bufferPreset = prefs.getInt(_keyBufferPreset) ?? 1;
    focusMode = prefs.getBool(_keyFocusMode) ?? false;
    endAction = prefs.getString(_keyEndAction) ?? 'next';
    eqPreset = prefs.getString(_keyEqPreset) ?? 'flat';
    themeFromArt = prefs.getBool(_keyThemeFromArt) ?? false;
    sleepUntilEnd = prefs.getBool(_keySleepUntilEnd) ?? false;
    textScale = prefs.getDouble(_keyTextScale) ?? 1;
    reduceMotion = prefs.getBool(_keyReduceMotion) ?? false;
    onboardingDone = prefs.getBool(_keyOnboardingDone) ?? false;
    final moodsRaw = prefs.getString(_keyMoods);
    if (moodsRaw != null) {
      try {
        final decoded = jsonDecode(moodsRaw) as Map<String, dynamic>;
        trackMoods
          ..clear()
          ..addAll(decoded.map((k, v) => MapEntry(k, v as String)));
      } catch (_) {
        trackMoods.clear();
      }
    }
    final lyricsRaw = prefs.getString(_keyLyricsCache);
    if (lyricsRaw != null) {
      try {
        final decoded = jsonDecode(lyricsRaw) as Map<String, dynamic>;
        lyricsCache
          ..clear()
          ..addAll(
            decoded.map((k, v) => MapEntry(k, v as Map<String, dynamic>)),
          );
      } catch (_) {
        lyricsCache.clear();
      }
    }
    final presetsRaw = prefs.getString(_keyQueuePresets);
    if (presetsRaw != null) {
      try {
        final decoded = jsonDecode(presetsRaw) as List<dynamic>;
        queuePresets
          ..clear()
          ..addAll(
            decoded.whereType<Map<String, dynamic>>().map(QueuePreset.fromJson),
          );
      } catch (_) {
        queuePresets.clear();
      }
    }
    final resumeRaw = prefs.getString(_keyResumePositions);
    if (resumeRaw != null) {
      try {
        final decoded = jsonDecode(resumeRaw) as Map<String, dynamic>;
        resumePositions
          ..clear()
          ..addAll(decoded.map((k, v) => MapEntry(k, (v as num).toInt())));
      } catch (_) {
        resumePositions.clear();
      }
    }
    final gainRaw = prefs.getString(_keyReplayGain);
    if (gainRaw != null) {
      try {
        final decoded = jsonDecode(gainRaw) as Map<String, dynamic>;
        replayGains
          ..clear()
          ..addAll(decoded.map((k, v) => MapEntry(k, (v as num).toDouble())));
      } catch (_) {
        replayGains.clear();
      }
    }
    final loopRaw = prefs.getString(_keyAbLoop);
    if (loopRaw != null) {
      try {
        final decoded = jsonDecode(loopRaw) as Map<String, dynamic>;
        abLoopTrackId = decoded['id'] as String?;
        abLoopA = decoded['a'] as int?;
        abLoopB = decoded['b'] as int?;
      } catch (_) {
        abLoopTrackId = null;
        abLoopA = null;
        abLoopB = null;
      }
    }
    final stationsRaw = prefs.getString(_keyFavoriteStations);
    if (stationsRaw != null) {
      try {
        final decoded = jsonDecode(stationsRaw) as List<dynamic>;
        favoriteStations
          ..clear()
          ..addAll(
            decoded.whereType<Map<String, dynamic>>().map(Track.fromJson),
          );
      } catch (_) {
        favoriteStations.clear();
      }
    }
    librarySort =
        LibrarySort.values.asNameMap()[prefs.getString(_keyLibrarySort)] ??
        LibrarySort.name;
    final countsRaw = prefs.getString(_keyPlayCounts);
    if (countsRaw != null) {
      try {
        final decoded = jsonDecode(countsRaw) as Map<String, dynamic>;
        playCounts
          ..clear()
          ..addAll(
            decoded.map((key, value) => MapEntry(key, (value as num).toInt())),
          );
      } catch (_) {
        playCounts.clear();
      }
    }
    final metaRaw = prefs.getString(_keyMetaOverrides);
    if (metaRaw != null) {
      try {
        final decoded = jsonDecode(metaRaw) as Map<String, dynamic>;
        metaTitle.clear();
        metaArtist.clear();
        metaAlbum.clear();
        for (final entry in decoded.entries) {
          final value = entry.value;
          if (value is! Map<String, dynamic>) continue;
          final t = value['title'] as String?;
          final a = value['artist'] as String?;
          final al = value['album'] as String?;
          if (t != null && t.isNotEmpty) metaTitle[entry.key] = t;
          if (a != null && a.isNotEmpty) metaArtist[entry.key] = a;
          if (al != null && al.isNotEmpty) metaAlbum[entry.key] = al;
        }
      } catch (_) {
        metaTitle.clear();
        metaArtist.clear();
        metaAlbum.clear();
      }
    }
    final statsRaw = prefs.getString(_keyStats);
    if (statsRaw != null) {
      try {
        final decoded = jsonDecode(statsRaw) as Map<String, dynamic>;
        listenSecondsByDay
          ..clear()
          ..addAll(
            decoded.map((key, value) => MapEntry(key, (value as num).toInt())),
          );
      } catch (_) {
        listenSecondsByDay.clear();
      }
    }
    // just_audio's platform is created on first playback. Volume, speed,
    // and equalizer state are applied in _playTrack once it exists.
    await loadEqualizer();
    final queueRaw = prefs.getString('queue_v2') ?? prefs.getString('queue_v1');
    if (queueRaw != null) {
      final decoded = jsonDecode(queueRaw) as List<dynamic>;
      final byId = <String, Track>{for (final t in library) t.id: t};
      final restored = <Track>[];
      for (final id in decoded) {
        if (id is! String) {
          continue;
        }
        final normalized = id.startsWith('local:') || id.startsWith('yt:')
            ? id
            : 'local:$id';
        final match = byId[normalized] ?? byId[id];
        if (match != null) {
          restored.add(match);
        }
      }
      queue = restored.isEmpty ? List<Track>.of(library) : restored;
      queueVersion++;
      final savedIndex = prefs.getInt('queue_index');
      if (savedIndex != null && savedIndex >= 0 && savedIndex < queue.length) {
        queueIndex = savedIndex;
      }
    } else {
      queue = List<Track>.of(library);
      queueVersion++;
    }
    notifyListeners();
    unawaited(initScanner());
    unawaited(_consumeIncomingAudio());
  }

  static const MethodChannel _intentChannel = MethodChannel('niusic/intent');

  Future<void> _consumeIncomingAudio() async {
    try {
      final path = await _intentChannel.invokeMethod<String>('getPending');
      if (path != null && path.isNotEmpty) {
        await addPaths([path]);
      }
    } catch (_) {
      // Channel only exists on Android.
    }
  }

  /// Restores equalizer preferences into memory and enables the effects.
  /// The band gains are applied to the platform by [_ensureEqualizerApplied]
  /// once it exists, which happens on first playback.
  Future<void> loadEqualizer() async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      final prefs = await _getPrefs();
      equalizerEnabled = prefs.getBool(_keyEqEnabled) ?? false;
      loudnessEnabled = prefs.getBool(_keyLoudnessEnabled) ?? false;
      loudnessGain = prefs.getDouble(_keyLoudnessGain) ?? 0;
      final gainsRaw = prefs.getString(_keyEqGains);
      if (gainsRaw != null) {
        try {
          equalizerGains = (jsonDecode(gainsRaw) as List<dynamic>)
              .map((e) => (e as num).toDouble())
              .toList();
        } catch (_) {
          equalizerGains = <double>[];
        }
      }
      // setEnabled only flips an in-memory flag until the platform exists.
      await equalizer.setEnabled(equalizerEnabled);
      await loudnessEnhancer.setEnabled(loudnessEnabled);
      await loudnessEnhancer.setTargetGain(loudnessGain);
    } catch (_) {
      // Effects are not supported here. Sliders stay at their stored values.
    }
  }

  /// Applies the stored band gains to the platform the first time audio
  /// exists. Safe to call any number of times.
  Future<void> _ensureEqualizerApplied() async {
    if (_equalizerApplied) {
      return;
    }
    _equalizerApplied = true;
    await _applyEqualizerControls();
  }

  Future<void> _applyEqualizerControls() async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      final params = await equalizer.parameters;
      final bandCount = params.bands.length;
      if (equalizerGains.length != bandCount) {
        equalizerGains = List<double>.generate(
          bandCount,
          (i) => i < equalizerGains.length ? equalizerGains[i] : 0,
        );
        await _saveEqualizerGains();
      }
      for (var i = 0; i < bandCount; i++) {
        await params.bands[i].setGain(equalizerGains[i]);
      }
      if (loudnessEnabled) {
        await loudnessEnhancer.setTargetGain(loudnessGain);
      }
    } catch (_) {
      // Unsupported device or activation not finished. Try again on play.
      _equalizerApplied = false;
    }
  }

  Future<void> setEqualizerEnabled(bool value) async {
    equalizerEnabled = value;
    try {
      await equalizer.setEnabled(value);
    } catch (_) {
      // Unsupported device. Keep the preference.
    }
    final prefs = await _getPrefs();
    await prefs.setBool(_keyEqEnabled, value);
    notifyListeners();
  }

  /// Sets the gain (in dB) for [index] and debounces the prefs write.
  Future<void> setEqualizerBandGain(int index, double dB) async {
    if (index < 0) {
      return;
    }
    if (equalizerGains.length <= index) {
      equalizerGains = List<double>.filled(index + 1, 0, growable: true);
    }
    equalizerGains[index] = dB;
    _equalizerTimer?.cancel();
    _equalizerTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_saveEqualizerGains());
    });
    notifyListeners();
    // Apply to the platform when it exists. Before first playback the gains
    // are applied on activation instead.
    try {
      final params = await equalizer.parameters;
      if (index < params.bands.length) {
        await params.bands[index].setGain(dB);
      }
    } catch (_) {
      // Activation not done yet. Gains live in equalizerGains.
    }
  }

  Future<void> resetEqualizer() async {
    equalizerGains = List<double>.filled(
      equalizerGains.length,
      0,
      growable: true,
    );
    await _saveEqualizerGains();
    notifyListeners();
    try {
      final params = await equalizer.parameters;
      for (final band in params.bands) {
        await band.setGain(0);
      }
    } catch (_) {
      // Activation not done yet. Gains live in equalizerGains.
    }
  }

  Future<void> _saveEqualizerGains() async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyEqGains, jsonEncode(equalizerGains));
  }

  Future<void> setLoudnessEnabled(bool value) async {
    loudnessEnabled = value;
    try {
      await loudnessEnhancer.setEnabled(value);
    } catch (_) {
      // Unsupported device. Keep the preference.
    }
    final prefs = await _getPrefs();
    await prefs.setBool(_keyLoudnessEnabled, value);
    notifyListeners();
  }

  Future<void> setLoudnessGain(double value) async {
    loudnessGain = value.clamp(0, 10).toDouble();
    try {
      await loudnessEnhancer.setTargetGain(loudnessGain);
    } catch (_) {
      // Unsupported device. Keep the preference.
    }
    _equalizerTimer?.cancel();
    _equalizerTimer = Timer(const Duration(milliseconds: 300), () async {
      final prefs = await _getPrefs();
      await prefs.setDouble(_keyLoudnessGain, loudnessGain);
    });
    notifyListeners();
  }

  /// Sets the library sort order and persists it.
  Future<void> setLibrarySort(LibrarySort sort) async {
    librarySort = sort;
    final prefs = await _getPrefs();
    await prefs.setString(_keyLibrarySort, sort.name);
    notifyListeners();
  }

  /// Tracks most played by this install. Not sent anywhere.
  List<Track> topPlayed({int limit = 8}) {
    final byId = <String, Track>{for (final t in library) t.id: t};
    final entries = playCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final out = <Track>[];
    for (final entry in entries) {
      final track = byId[entry.key];
      if (track != null) {
        out.add(track);
      }
      if (out.length >= limit) {
        break;
      }
    }
    return out;
  }

  void _recordPlay(Track track) {
    playCounts[track.id] = (playCounts[track.id] ?? 0) + 1;
    _savePlayCountsSoon();
  }

  /// Applies a user edit to a track in library and queue.
  Future<void> setTrackMeta(
    Track track, {
    String? title,
    String? artist,
    String? album,
  }) async {
    if (title != null && title.trim().isNotEmpty) {
      metaTitle[track.id] = title.trim();
    } else {
      metaTitle.remove(track.id);
    }
    if (artist != null && artist.trim().isNotEmpty) {
      metaArtist[track.id] = artist.trim();
    } else {
      metaArtist.remove(track.id);
    }
    if (album != null && album.trim().isNotEmpty) {
      metaAlbum[track.id] = album.trim();
    } else {
      metaAlbum.remove(track.id);
    }
    final updated = track.copyWith(
      titleOverride: metaTitle[track.id],
      authorOverride: metaArtist[track.id],
      albumOverride: metaAlbum[track.id],
    );
    final li = library.indexWhere((t) => t.id == track.id);
    if (li >= 0) library[li] = updated;
    queue = queue.map((t) => t.id == track.id ? updated : t).toList();
    queueVersion++;
    _rebuildIndexes();
    final prefs = await _getPrefs();
    final allMetaIds = <String>{
      ...metaTitle.keys,
      ...metaArtist.keys,
      ...metaAlbum.keys,
    };
    await prefs.setString(
      _keyMetaOverrides,
      jsonEncode(<String, Map<String, String>>{
        for (final id in allMetaIds)
          id: <String, String>{
            'title': metaTitle[id] ?? '',
            'artist': metaArtist[id] ?? '',
            'album': metaAlbum[id] ?? '',
          },
      }),
    );
    await _saveLibrary();
    notifyListeners();
  }

  /// Records one second of listening for the statistics screen.
  void _recordListenSecond() {
    if (!isPlaying) return;
    final key = DateTime.now().toString().substring(0, 10);
    listenSecondsByDay[key] = (listenSecondsByDay[key] ?? 0) + 1;
    if (_resumeTick++ % 10 == 0) {
      final cur = current;
      if (cur != null && !(cur.videoId?.startsWith('radio:') ?? false)) {
        resumePositions[cur.id] = position.inMilliseconds;
        _saveResumeSoon();
      }
    }
    _statsTimer ??= Timer(const Duration(seconds: 5), () async {
      final prefs = await _getPrefs();
      await prefs.setString(_keyStats, jsonEncode(listenSecondsByDay));
      _statsTimer = null;
    });
  }

  Timer? _statsTimer;
  Timer? _resumeTimer;
  int _resumeTick = 0;

  void _saveResumeSoon() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 2), () async {
      final prefs = await _getPrefs();
      await prefs.setString(_keyResumePositions, jsonEncode(resumePositions));
    });
  }

  int get totalListenSeconds =>
      listenSecondsByDay.values.fold(0, (sum, value) => sum + value);

  List<MapEntry<String, int>> get weeklyStats {
    final now = DateTime.now();
    final out = <MapEntry<String, int>>[];
    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i)).toString().substring(0, 10);
      out.add(MapEntry(day, listenSecondsByDay[day] ?? 0));
    }
    return out;
  }

  Future<void>? _playCountsSaveFuture;

  void _savePlayCountsSoon() {
    _playCountsSaveFuture ??= Future<void>.delayed(
      const Duration(seconds: 1),
      () async {
        final prefs = await _getPrefs();
        await prefs.setString(_keyPlayCounts, jsonEncode(playCounts));
        _playCountsSaveFuture = null;
      },
    );
  }

  /// Shares the current track. Uses the platform share sheet.
  Future<void> shareCurrent() async {
    final cur = current;
    if (cur != null) {
      await shareTrack(cur);
    }
  }

  /// Shares any track, with a YouTube link for online tracks.
  Future<void> shareTrack(Track track) async {
    final parts = <String>[
      if (track.author != null && track.author!.isNotEmpty)
        '${track.title} - ${track.author}'
      else
        track.title,
    ];
    if (track.isRemote &&
        track.videoId != null &&
        !track.videoId!.startsWith('radio:')) {
      parts.add('https://www.youtube.com/watch?v=${track.videoId}');
    }
    if (track.isRemote && track.videoId?.startsWith('radio:') == true) {
      final url = track.url;
      if (url != null) {
        parts.add(url);
      }
    }
    try {
      await SharePlus.instance.share(
        ShareParams(text: parts.join('\n'), subject: track.title),
      );
    } catch (_) {
      // Share sheet is not available on this platform.
    }
  }

  /// Android only: grants access if needed, starts the real-time observer,
  /// and runs the first scan.
  Future<void> initScanner() async {
    if (!Platform.isAndroid) {
      return;
    }
    scanGranted = await scannerService.areScanGranted();
    _startScanObserver();
    if (scanGranted) {
      await scanDeviceMusic();
      return;
    }
    final prefs = await _getPrefs();
    final asked = prefs.getBool(_keyScanAsked) ?? false;
    if (!asked) {
      // One automatic prompt on first launch. The UI stays usable underneath.
      await prefs.setBool(_keyScanAsked, true);
      await scannerService.requestScanPermission();
      _scanRetryTimer = Timer(const Duration(seconds: 3), () async {
        scanGranted = await scannerService.areScanGranted();
        if (scanGranted) {
          await scanDeviceMusic();
        }
        notifyListeners();
      });
    }
    notifyListeners();
  }

  /// Re-checks the permission and rescans. Used by the Settings action and
  /// the app-resume hook. The resume hook passes
  /// [requestIfNotGranted] = false so a denied permission is not re-asked
  /// every time the app comes to the foreground.
  Future<void> rescanDeviceMusic({bool requestIfNotGranted = true}) async {
    scanGranted = await scannerService.areScanGranted();
    if (!scanGranted && requestIfNotGranted) {
      await scannerService.requestScanPermission();
      scanGranted = await scannerService.areScanGranted();
    }
    if (scanGranted) {
      await scanDeviceMusic();
    } else {
      notifyListeners();
    }
  }

  void _startScanObserver() {
    if (_scanSub != null) {
      return;
    }
    try {
      _scanSub = scannerService.changes.listen(
        (_) => _queueScanRefresh(),
        onError: (_) {},
      );
    } catch (_) {
      _scanSub = null;
    }
  }

  void _queueScanRefresh() {
    _scanDebounce?.cancel();
    _scanDebounce = Timer(const Duration(milliseconds: 1200), () {
      unawaited(scanDeviceMusic());
    });
  }

  /// Merges scanned device files into the library. Returns the number of
  /// newly added tracks. Local tracks whose file disappeared from both the
  /// scan results and disk are pruned.
  int mergeScannedTracks(List<ScannedTrack> scanned) {
    final result = mergeScannedTracksInto(
      library,
      queue,
      scanned,
      fileExists: (path) => File(path).existsSync(),
    );
    if (result.pruned > 0) {
      if (queue.isEmpty) {
        queueIndex = -1;
      } else if (queueIndex >= queue.length) {
        queueIndex = queue.length - 1;
      }
    }
    if (result.added > 0 || result.pruned > 0) {
      _rebuildIndexes();
      queueVersion++;
      if (queue.isEmpty && library.isNotEmpty) {
        queue = List<Track>.of(library);
      }
    }
    return result.added;
  }

  /// Scans the device for music files and merges them into the library.
  Future<bool> scanDeviceMusic() async {
    if (scanBusy) {
      return false;
    }
    scanBusy = true;
    notifyListeners();
    try {
      final granted = await scannerService.areScanGranted();
      scanGranted = granted;
      if (!granted) {
        return false;
      }
      final scanned = await scannerService.scanLibrary();
      lastScanTotal = scanned.length;
      lastScanAt = DateTime.now();
      final added = mergeScannedTracks(scanned);
      lastScanAdded = added;
      // Always persist the post-merge library. It is small and the scan is
      // infrequent (debounced), so the cost is negligible.
      await _saveLibrary();
      return true;
    } finally {
      scanBusy = false;
      notifyListeners();
    }
  }

  Future<void> _saveQueue() async {
    final prefs = await _getPrefs();
    await prefs.setString(
      'queue_v2',
      jsonEncode(queue.map((t) => t.id).toList()),
    );
    await prefs.setInt('queue_index', queueIndex);
  }

  Future<void> addPaths(List<String> paths) async {
    final existing = library.map((t) => t.id).toSet();
    var added = false;
    for (final path in paths) {
      final id = 'local:$path';
      if (!existing.contains(id)) {
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
      queueVersion++;
      notifyListeners();
    }
  }

  /// Imports picked files by copying them into the app's documents directory.
  /// On Android the picker grants temporary access to the source path, so a raw
  /// path reference breaks playback. Copying guarantees a permanent, readable
  /// local path.
  Future<int> importPickedFiles(List<dynamic> files) async {
    var added = 0;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/library');
    await dir.create(recursive: true);
    final existing = library.map((t) => t.path).whereType<String>().toSet();
    for (final file in files) {
      try {
        final bytes = await file.readAsBytes() as Uint8List?;
        if (bytes == null || bytes.isEmpty) {
          continue;
        }
        final name =
            file.name as String? ??
            'track_${DateTime.now().microsecondsSinceEpoch}';
        final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '_');
        var dest = File('${dir.path}/$safe');
        var counter = 1;
        while (await dest.exists()) {
          final base = safe.contains('.')
              ? safe.substring(0, safe.lastIndexOf('.'))
              : safe;
          final ext = safe.contains('.')
              ? safe.substring(safe.lastIndexOf('.'))
              : '';
          dest = File('${dir.path}/${base}_$counter$ext');
          counter++;
        }
        await dest.writeAsBytes(bytes, flush: true);
        final track = Track.fromPath(dest.path);
        if (existing.contains(track.path)) {
          continue;
        }
        library.add(track);
        _libraryIndex[track.id] = library.length - 1;
        _lowerTitles[track.id] = track.title.toLowerCase();
        existing.add(track.path!);
        added++;
      } catch (_) {
        // Skip unreadable files, keep importing the rest.
      }
    }
    if (added > 0) {
      await _saveLibrary();
      queue = List<Track>.of(library);
      queueVersion++;
      notifyListeners();
    }
    return added;
  }

  Future<void> playAt(int index) async {
    if (index < 0 || index >= queue.length) {
      return;
    }
    queueVersion++;
    queueIndex = index;
    final track = queue[index];
    historyIds.remove(track.id);
    historyIds.insert(0, track.id);
    _recordPlay(track);
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
      if (!await File(path).exists()) {
        lastError = 'file_not_found';
        notifyListeners();
        return;
      }
      try {
        await player.setFilePath(path);
        await _applySessionPrefs();
        await _applyStartOptions(track);
        await player.play();
        _sourceLoaded = true;
        unawaited(_ensureEqualizerApplied());
        lastError = null;
      } catch (e) {
        debugPrint('playback failed: $e');
        lastError = 'playback_failed';
        notifyListeners();
      }
      return;
    }
    if (track.isDownloaded) {
      final path = track.downloadPath!;
      if (!await File(path).exists()) {
        lastError = 'file_not_found';
        notifyListeners();
        return;
      }
      try {
        await player.setFilePath(path);
        await _applySessionPrefs();
        await _applyStartOptions(track);
        await player.play();
        _sourceLoaded = true;
        unawaited(_ensureEqualizerApplied());
        lastError = null;
      } catch (e) {
        debugPrint('playback failed: $e');
        lastError = 'playback_failed';
        notifyListeners();
      }
      return;
    }
    // Remote: resolve a fresh audio URL (cache lives in StreamService).
    final videoId = track.videoId;
    if (videoId == null) {
      lastError = 'missing_video_id';
      notifyListeners();
      return;
    }
    if (videoId.startsWith('radio:')) {
      // Live radio: the stream URL is stored on the track, no resolution.
      final url = track.url;
      if (url == null || url.isEmpty) {
        lastError = 'stream_failed';
        notifyListeners();
        return;
      }
      try {
        await player.setUrl(url);
        await _applySessionPrefs();
        await _applyStartOptions(track);
        await player.play();
        _sourceLoaded = true;
        unawaited(_ensureEqualizerApplied());
        lastError = null;
      } catch (e) {
        debugPrint('radio failed: $e');
        lastError = 'stream_failed';
        notifyListeners();
      }
      return;
    }
    try {
      final url = await streamService.resolveAudioUrl(videoId);
      if (queueIndex >= 0 && queueIndex < queue.length) {
        queue[queueIndex] = queue[queueIndex].copyWithUrl(url);
      }
      try {
        if (cacheOnlineAudio) {
          // ignore: experimental_member_use
          await player.setAudioSource(LockCachingAudioSource(Uri.parse(url)));
        } else {
          await player.setUrl(url);
        }
      } catch (_) {
        // Cache proxy unavailable (for example on Windows). Play directly.
        await player.setUrl(url);
      }
      await _applySessionPrefs();
      await _applyStartOptions(track);
      await player.play();
      _sourceLoaded = true;
      unawaited(_ensureEqualizerApplied());
      lastError = null;
    } catch (e) {
      debugPrint('stream failed: $e');
      lastError = 'stream_failed';
      notifyListeners();
    }
  }

  /// Applies volume and speed to the player. Called after the source is set,
  /// when the platform exists. The calls are safe no-ops if the platform is
  /// not ready yet.
  Future<void> _applyStartOptions(Track track) async {
    if (track.videoId?.startsWith('radio:') ?? false) return;
    var target = resumePositions[track.id] ?? 0;
    if (skipIntroSeconds > 0 && target < skipIntroSeconds * 1000) {
      target = skipIntroSeconds * 1000;
    }
    if (target <= 0) return;
    try {
      await player.seek(Duration(milliseconds: target));
    } catch (_) {
      // Source not seekable.
    }
  }

  Future<void> _applySessionPrefs() async {
    try {
      await player.setVolume(effectiveGain);
      await player.setSpeed(playbackRate);
      await player.setPitch(pitch);
      await player.setSkipSilenceEnabled(skipSilence);
    } catch (_) {
      // Platform not ready yet. Defaults are used until the next play.
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
    queueVersion++;
    unawaited(_saveLibrary());
    unawaited(playAt(queue.length - 1));
  }

  /// Plays a live radio station. The station is queued and tracked like any
  /// stream. The stream URL is stored on the track so restarts can replay it.
  void playRadioStation(RadioStation station) {
    final detail = <String?>[
      station.country,
      if (station.codec != null && station.codec!.isNotEmpty)
        station.codec!.toUpperCase(),
      if (station.bitrate != null && station.bitrate! > 0)
        '${station.bitrate} kbps',
    ].where((e) => e != null && e.isNotEmpty).join(' · ');
    final track = Track.remote(
      videoId: 'radio:${station.stationUuid}',
      title: station.name,
      author: detail.isEmpty ? null : detail,
      thumbnailUrl: station.favicon,
      url: station.streamUrl,
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
    queueVersion++;
    unawaited(_saveLibrary());
    unawaited(playAt(queue.length - 1));
  }

  /// The Favorites playlist is managed by the app under a fixed id and is
  /// pinned in the Playlists screen.
  Playlist? get favoritesPlaylist {
    for (final playlist in playlists) {
      if (playlist.id == 'favorites') {
        return playlist;
      }
    }
    return null;
  }

  bool isFavoriteId(String id) => favoritesPlaylist?.contains(id) ?? false;

  Future<void> toggleFavorite(Track track) async {
    var favorite = favoritesPlaylist;
    if (favorite == null) {
      favorite = Playlist(id: 'favorites', name: 'Favorites');
      playlists.insert(0, favorite);
    }
    if (favorite.contains(track.id)) {
      favorite.removeId(track.id);
    } else {
      favorite.add(track);
    }
    await _savePlaylists();
    notifyListeners();
  }

  /// Adds several tracks to the queue without duplicating ids.
  Future<void> addTracksToQueue(List<Track> tracks) async {
    var changed = false;
    for (final track in tracks) {
      if (queue.any((t) => t.id == track.id)) {
        continue;
      }
      queue.add(track);
      if (!library.any((t) => t.id == track.id)) {
        library.add(track);
        _libraryIndex[track.id] = library.length - 1;
        _lowerTitles[track.id] = track.title.toLowerCase();
      }
      changed = true;
    }
    if (!changed) {
      return;
    }
    queueVersion++;
    unawaited(_saveLibrary());
    await _saveQueue();
    notifyListeners();
  }

  /// Groups local tracks by artist name for the Artists screen.
  Map<String, List<Track>> artists() {
    final out = <String, List<Track>>{};
    for (final track in library) {
      final key = (track.author ?? 'Unknown').trim().isEmpty
          ? 'Unknown'
          : track.author!.trim();
      out.putIfAbsent(key, () => <Track>[]).add(track);
    }
    final keys = out.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return <String, List<Track>>{for (final key in keys) key: out[key]!};
  }

  /// Groups local tracks by album name for the Albums screen.
  Map<String, List<Track>> albums() {
    final out = <String, List<Track>>{};
    for (final track in library) {
      final key = (track.album ?? 'Unknown album').trim().isEmpty
          ? 'Unknown album'
          : track.album!.trim();
      out.putIfAbsent(key, () => <Track>[]).add(track);
    }
    final keys = out.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return <String, List<Track>>{for (final key in keys) key: out[key]!};
  }

  /// Finds groups of tracks with the same title, artist, and duration.
  List<List<Track>> duplicates() {
    final groups = <String, List<Track>>{};
    for (final track in library) {
      final key =
          '${track.title.toLowerCase()}|'
          '${(track.author ?? '').toLowerCase()}|${track.durationSeconds ?? 0}';
      groups.putIfAbsent(key, () => <Track>[]).add(track);
    }
    return groups.values.where((group) => group.length > 1).toList();
  }

  /// Removes a track from library, queue, and playlists.
  Future<void> removeTrack(Track track) async {
    library.removeWhere((t) => t.id == track.id);
    queue = queue.where((t) => t.id != track.id).toList();
    queueIndex = queue.isEmpty
        ? -1
        : (queueIndex >= queue.length ? queue.length - 1 : queueIndex);
    queueVersion++;
    for (final playlist in playlists) {
      playlist.removeId(track.id);
    }
    _rebuildIndexes();
    unawaited(_saveLibrary());
    unawaited(_savePlaylists());
    await _saveQueue();
    notifyListeners();
  }

  /// Merges a backup into the current library without duplicates.
  Future<int> importBackup(List<Track> tracks, List<Playlist> imported) async {
    var added = 0;
    final ids = library.map((t) => t.id).toSet();
    for (final track in tracks) {
      if (ids.contains(track.id)) continue;
      library.add(track);
      ids.add(track.id);
      added++;
    }
    final playlistIds = playlists.map((p) => p.id).toSet();
    for (final playlist in imported) {
      if (playlistIds.contains(playlist.id)) continue;
      playlists.add(playlist);
      playlistIds.add(playlist.id);
    }
    _rebuildIndexes();
    await _saveLibrary();
    await _savePlaylists();
    notifyListeners();
    return added;
  }

  /// Total bytes used by downloaded audio and cached waveforms.
  Future<int> storageBytes() async {
    var total = 0;
    for (final track in library) {
      if (track.isDownloaded) {
        total += await downloadService.sizeOf(track.downloadPath);
      }
    }
    try {
      final temp = await getTemporaryDirectory();
      final dir = Directory(temp.path);
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.wave')) {
          total += await entity.length();
        }
      }
    } catch (_) {
      // Temporary directory not readable.
    }
    return total;
  }

  Future<void> clearWaveformCache() async {
    try {
      final temp = await getTemporaryDirectory();
      final dir = Directory(temp.path);
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.wave')) {
          await entity.delete();
        }
      }
    } catch (_) {
      // Nothing to clear.
    }
    notifyListeners();
  }

  /// Inserts a track right after the current one.
  Future<void> playNext(Track track) async {
    var insertAt = queueIndex + 1;
    if (insertAt <= 0 || insertAt > queue.length) {
      insertAt = queue.isEmpty ? 0 : queue.length;
    }
    queue.insert(insertAt, track);
    if (!library.any((t) => t.id == track.id)) {
      library.add(track);
      _libraryIndex[track.id] = library.length - 1;
      _lowerTitles[track.id] = track.title.toLowerCase();
    }
    queueVersion++;
    unawaited(_saveLibrary());
    await _saveQueue();
    notifyListeners();
  }

  /// Adds several tracks to Favorites in one write.
  Future<void> addManyToFavorites(List<Track> tracks) async {
    var favorite = favoritesPlaylist;
    if (favorite == null) {
      favorite = Playlist(id: 'favorites', name: 'Favorites');
      playlists.insert(0, favorite);
    }
    for (final track in tracks) {
      favorite.add(track);
    }
    await _savePlaylists();
    notifyListeners();
  }

  /// Adds several tracks to any playlist in one write.
  Future<void> addTracksToPlaylist(
    Playlist playlist,
    List<Track> tracks,
  ) async {
    for (final track in tracks) {
      playlist.add(track);
    }
    await _savePlaylists();
    notifyListeners();
  }

  /// Saves the current queue as a new playlist.
  Future<void> saveQueueAsPlaylist(String name) async {
    final playlist = await createPlaylist(name);
    for (final track in queue) {
      playlist.add(track);
    }
    await _savePlaylists();
    notifyListeners();
  }

  /// Stops playback and empties the queue.
  Future<void> clearQueue() async {
    await player.stop();
    _sourceLoaded = false;
    queue = <Track>[];
    queueVersion++;
    queueIndex = -1;
    _cachedItems.clear();
    _lastSyncKey = '';
    unawaited(_saveQueue());
    notifyListeners();
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
    if (!library.any((t) => t.id == track.id)) {
      library.add(track);
      _libraryIndex[track.id] = library.length - 1;
      _lowerTitles[track.id] = track.title.toLowerCase();
      unawaited(_saveLibrary());
    }
    queue.add(track);
    queueVersion++;
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
    queueVersion++;
    unawaited(_saveQueue());
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
    queueVersion++;
    unawaited(_saveQueue());
    notifyListeners();
  }

  void setSleepTimer(int? minutes) {
    _sleepTimer?.cancel();
    _fadeTimer?.cancel();
    sleepMinutes = minutes;
    if (minutes != null && minutes > 0) {
      sleepDeadline = DateTime.now().add(Duration(minutes: minutes));
      if (sleepFade && minutes > 1) {
        _fadeTimer = Timer(
          Duration(seconds: minutes * 60 - 10),
          _startSleepFade,
        );
      }
      _sleepTimer = Timer(Duration(minutes: minutes), () {
        if (isPlaying) {
          unawaited(player.pause());
        }
        sleepMinutes = null;
        sleepDeadline = null;
        // Restore the user's volume after the fade out.
        unawaited(player.setVolume(volume));
        notifyListeners();
      });
    } else {
      sleepDeadline = null;
      unawaited(player.setVolume(volume));
    }
    notifyListeners();
  }

  void _startSleepFade() {
    var tick = 0;
    _fadeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      tick++;
      unawaited(player.setVolume((volume * (1 - tick / 10)).clamp(0.0, 1.0)));
      if (tick >= 10) {
        timer.cancel();
      }
    });
  }

  Future<void> setSleepFade(bool value) async {
    sleepFade = value;
    final prefs = await _getPrefs();
    await prefs.setBool(_keySleepFade, value);
    notifyListeners();
  }

  Future<void> playRadioFor(Track track) async {
    final videoId = track.videoId;
    List<VideoResult> candidates = <VideoResult>[];
    if (videoId != null) {
      try {
        candidates = await streamService.related(videoId);
      } catch (_) {
        candidates = <VideoResult>[];
      }
    }
    if (candidates.isEmpty) {
      candidates = await streamService.search(
        '${track.title} ${track.author ?? ''}'.trim(),
      );
    }
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

  Future<void> setSkipSilence(bool value) async {
    skipSilence = value;
    try {
      await player.setSkipSilenceEnabled(value);
    } catch (_) {
      // Not supported on this platform.
    }
    final prefs = await _getPrefs();
    await prefs.setBool(_keySkipSilence, value);
    notifyListeners();
  }

  Future<void> setPitch(double value) async {
    pitch = value.clamp(0.5, 2.0).toDouble();
    try {
      await player.setPitch(pitch);
    } catch (_) {
      // Not supported on this platform.
    }
    final prefs = await _getPrefs();
    await prefs.setDouble(_keyPitch, pitch);
    notifyListeners();
  }

  Future<void> setCacheOnlineAudio(bool value) async {
    cacheOnlineAudio = value;
    final prefs = await _getPrefs();
    await prefs.setBool(_keyCacheOnline, value);
    notifyListeners();
  }

  Future<void> setImmersivePlayer(bool value) async {
    immersivePlayer = value;
    final prefs = await _getPrefs();
    await prefs.setBool(_keyImmersive, value);
    notifyListeners();
  }

  Future<void> setLibraryGrid(bool value) async {
    libraryGrid = value;
    final prefs = await _getPrefs();
    await prefs.setBool(_keyLibraryGrid, value);
    notifyListeners();
  }

  Future<void> setPlaylistCover(Playlist playlist, String trackId) async {
    playlist.coverTrackId = trackId;
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> setThemeFromArt(bool value) async {
    themeFromArt = value;
    final prefs = await _getPrefs();
    await prefs.setBool(_keyThemeFromArt, value);
    notifyListeners();
  }

  Future<void> setSleepUntilEnd(bool value) async {
    sleepUntilEnd = value;
    final prefs = await _getPrefs();
    await prefs.setBool(_keySleepUntilEnd, value);
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    textScale = value.clamp(0.85, 1.5).toDouble();
    final prefs = await _getPrefs();
    await prefs.setDouble(_keyTextScale, textScale);
    notifyListeners();
  }

  Future<void> setReduceMotion(bool value) async {
    reduceMotion = value;
    final prefs = await _getPrefs();
    await prefs.setBool(_keyReduceMotion, value);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    onboardingDone = true;
    final prefs = await _getPrefs();
    await prefs.setBool(_keyOnboardingDone, true);
    notifyListeners();
  }

  /// A locally generated mix from play counts and listening history.
  List<Track> dailyMix({int limit = 20}) {
    final seen = <String>{};
    final out = <Track>[];
    for (final track in [
      ...topPlayed(limit: limit),
      ...recentTracks(),
      ...library,
    ]) {
      if (seen.add(track.id)) {
        out.add(track);
      }
      if (out.length >= limit) break;
    }
    return out;
  }

  /// Replaces the queue and starts the first track.
  Future<void> playTracksNow(List<Track> tracks) async {
    if (tracks.isEmpty) return;
    queue = List<Track>.of(tracks);
    queueIndex = 0;
    queueVersion++;
    await _saveQueue();
    await playAt(0);
  }

  Future<void> setTrackMood(String id, String mood) async {
    trackMoods[id] = mood;
    final prefs = await _getPrefs();
    await prefs.setString(_keyMoods, jsonEncode(trackMoods));
    notifyListeners();
  }

  Map<String, dynamic>? cachedLyrics(String title, String artist) {
    return lyricsCache['$title|$artist'];
  }

  Future<void> cacheLyrics(
    String title,
    String artist,
    Map<String, dynamic> data,
  ) async {
    lyricsCache['$title|$artist'] = data;
    final prefs = await _getPrefs();
    await prefs.setString(_keyLyricsCache, jsonEncode(lyricsCache));
  }

  Future<void> saveQueuePreset(String name) async {
    queuePresets.add(
      QueuePreset(
        name: name.trim().isEmpty ? 'Preset' : name.trim(),
        ids: queue.map((track) => track.id).toList(),
      ),
    );
    final prefs = await _getPrefs();
    await prefs.setString(
      _keyQueuePresets,
      jsonEncode(queuePresets.map((preset) => preset.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> loadQueuePreset(int index) async {
    if (index < 0 || index >= queuePresets.length) return;
    final byId = <String, Track>{for (final track in library) track.id: track};
    final ids = queuePresets[index].ids;
    final restored = ids.map((id) => byId[id]).whereType<Track>().toList();
    if (restored.isEmpty) return;
    queue = restored;
    queueIndex = 0;
    queueVersion++;
    await _saveQueue();
    await playAt(0);
  }

  Future<void> deleteQueuePreset(int index) async {
    if (index < 0 || index >= queuePresets.length) return;
    queuePresets.removeAt(index);
    final prefs = await _getPrefs();
    await prefs.setString(
      _keyQueuePresets,
      jsonEncode(queuePresets.map((preset) => preset.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> setSkipIntro(int seconds) async {
    skipIntroSeconds = seconds.clamp(0, 120);
    final prefs = await _getPrefs();
    await prefs.setInt(_keySkipIntro, skipIntroSeconds);
    notifyListeners();
  }

  Future<void> setSkipOutro(int seconds) async {
    skipOutroSeconds = seconds.clamp(0, 120);
    final prefs = await _getPrefs();
    await prefs.setInt(_keySkipOutro, skipOutroSeconds);
    notifyListeners();
  }

  Future<void> setBufferPreset(int value) async {
    bufferPreset = value.clamp(0, 2);
    final prefs = await _getPrefs();
    await prefs.setInt(_keyBufferPreset, bufferPreset);
    notifyListeners();
  }

  Future<void> setFocusMode(bool value) async {
    focusMode = value;
    final prefs = await _getPrefs();
    await prefs.setBool(_keyFocusMode, value);
    notifyListeners();
  }

  Future<void> setEndAction(String value) async {
    endAction = value;
    final prefs = await _getPrefs();
    await prefs.setString(_keyEndAction, value);
    notifyListeners();
  }

  Future<void> setTrackGain(Track track, double dB) async {
    replayGains[track.id] = dB;
    final prefs = await _getPrefs();
    await prefs.setString(_keyReplayGain, jsonEncode(replayGains));
    _applySessionPrefs();
    notifyListeners();
  }

  double get effectiveGain {
    final cur = current;
    if (cur == null) return 1;
    final db = replayGains[cur.id] ?? 0;
    // Convert dB to linear gain, clamp to avoid clipping.
    return (volume * pow(10, db / 20).toDouble()).clamp(0.0, 1.0);
  }

  void markAbLoopA() {
    final cur = current;
    if (cur == null) return;
    if (abLoopTrackId != cur.id) {
      abLoopA = null;
      abLoopB = null;
    }
    abLoopTrackId = cur.id;
    abLoopA = position.inSeconds;
    if (abLoopB != null && abLoopB! <= abLoopA!) abLoopB = null;
    _saveAbLoop();
    notifyListeners();
  }

  void markAbLoopB() {
    final cur = current;
    if (cur == null || abLoopTrackId != cur.id || abLoopA == null) return;
    abLoopB = position.inSeconds;
    if (abLoopB! <= abLoopA!) abLoopB = null;
    _saveAbLoop();
    notifyListeners();
  }

  void clearAbLoop() {
    abLoopTrackId = null;
    abLoopA = null;
    abLoopB = null;
    _saveAbLoop();
    notifyListeners();
  }

  Future<void> _saveAbLoop() async {
    final prefs = await _getPrefs();
    await prefs.setString(
      _keyAbLoop,
      jsonEncode(<String, dynamic>{
        'id': abLoopTrackId,
        'a': abLoopA,
        'b': abLoopB,
      }),
    );
  }

  bool get abLoopActive =>
      abLoopTrackId != null &&
      abLoopA != null &&
      abLoopB != null &&
      abLoopTrackId == current?.id;

  Future<void> setEqPreset(String preset) async {
    eqPreset = preset;
    final prefs = await _getPrefs();
    await prefs.setString(_keyEqPreset, preset);
    await _applyEqPreset(preset);
    notifyListeners();
  }

  Future<void> _applyEqPreset(String preset) async {
    if (!Platform.isAndroid) return;
    try {
      final params = await equalizer.parameters;
      final flat = <double>[for (final band in params.bands) band.gain];
      final presets = <String, List<double>>{
        'flat': List<double>.filled(flat.length, 0),
        'bass': [for (final v in flat) v + 6],
        'vocal': [for (final v in flat) v + 3],
        'rock': [for (final v in flat) v + 4],
        'jazz': [for (final v in flat) v + 2],
      };
      final target = presets[preset] ?? presets['flat']!;
      for (var i = 0; i < params.bands.length; i++) {
        final gain = target[i].clamp(params.minDecibels, params.maxDecibels);
        equalizerGains[i] = gain;
        await params.bands[i].setGain(gain);
      }
      await _saveEqualizerGains();
    } catch (_) {
      // Effects not ready yet.
    }
  }

  Future<void> setOfflineMode(bool value) async {
    offlineMode = value;
    final prefs = await _getPrefs();
    await prefs.setBool(_keyOfflineMode, value);
    notifyListeners();
  }

  bool isFavoriteStation(String uuid) =>
      favoriteStations.any((t) => t.videoId == 'radio:$uuid');

  Future<void> toggleFavoriteStation(RadioStation station) async {
    final id = 'radio:${station.stationUuid}';
    final existing = favoriteStations.where((t) => t.videoId == id).toList();
    if (existing.isNotEmpty) {
      for (final track in existing) {
        favoriteStations.remove(track);
      }
    } else {
      favoriteStations.add(
        Track.remote(
          videoId: id,
          title: station.name,
          author: station.country ?? station.codec,
          thumbnailUrl: station.favicon,
          url: station.streamUrl,
        ),
      );
    }
    final prefs = await _getPrefs();
    await prefs.setString(
      _keyFavoriteStations,
      jsonEncode(favoriteStations.map((t) => t.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> setPlaybackRate(double value) async {
    playbackRate = value.clamp(0.5, 2.0);
    await player.setSpeed(playbackRate);
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
      return;
    }
    // After a restart the queue is restored but no source is loaded. Load
    // the restored current track instead of playing nothing.
    if (!_sourceLoaded) {
      if (queue.isEmpty) {
        return;
      }
      var target = queueIndex;
      if (target < 0 || target >= queue.length) {
        target = 0;
      }
      await playAt(target);
      return;
    }
    await player.play();
  }

  Future<void> seek(Duration d) async {
    await player.seek(d);
  }

  Future<void> seekRelative(int seconds) async {
    final target = position + Duration(seconds: seconds);
    if (target < Duration.zero) {
      await seek(Duration.zero);
      return;
    }
    await seek(target);
  }

  Future<void> adjustVolume(double delta) async {
    await setVolume(volume + delta);
  }

  Future<void> next({bool auto = false}) async {
    if (queue.isEmpty) {
      return;
    }
    if (auto && endAction == 'pause') {
      await player.pause();
      return;
    }
    if (auto && endAction == 'repeat') {
      await player.seek(Duration.zero);
      await player.play();
      return;
    }
    if (repeat == NiRepeatMode.one && auto) {
      await player.seek(Duration.zero);
      await player.play();
      return;
    }
    int nextIndex;
    if (shuffle && queue.length > 1) {
      // Avoid picking the same track we just ended on.
      do {
        nextIndex = _random.nextInt(queue.length);
      } while (nextIndex == queueIndex);
    } else if (shuffle) {
      nextIndex = 0;
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

  /// Reorders playlists. [oldIndex] and [newIndex] are relative to the
  /// reorderable list, which excludes the pinned Favorites playlist.
  void reorderPlaylists(int oldIndex, int newIndex) {
    final favorite = favoritesPlaylist;
    final normal = playlists.where((p) => p.id != 'favorites').toList();
    if (oldIndex < 0 ||
        oldIndex >= normal.length ||
        newIndex < 0 ||
        newIndex >= normal.length) {
      return;
    }
    var target = newIndex;
    if (oldIndex < newIndex) {
      target = newIndex - 1;
    }
    final item = normal.removeAt(oldIndex);
    normal.insert(target, item);
    playlists
      ..clear()
      ..addAll([?favorite, ...normal]);
    unawaited(_savePlaylists());
    notifyListeners();
  }

  /// Replaces the queue with the playlist's tracks and starts playback.
  Future<void> playAllFromPlaylist(
    Playlist playlist, {
    bool shuffleAll = false,
  }) async {
    final byId = <String, Track>{for (final track in library) track.id: track};
    final tracks = playlist.trackIds
        .map((id) => byId[id])
        .whereType<Track>()
        .toList();
    if (tracks.isEmpty) {
      return;
    }
    queue = tracks;
    queueIndex = 0;
    queueVersion++;
    if (shuffleAll) {
      shuffle = true;
    }
    await _saveQueue();
    await playAt(0);
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
    _sourceLoaded = false;
    // Free downloaded audio files on disk before wiping metadata.
    for (final track in downloadedTracks()) {
      await downloadService.deleteFile(track.downloadPath);
    }
    library.clear();
    _libraryIndex.clear();
    _lowerTitles.clear();
    queue = <Track>[];
    queueVersion++;
    playlists.clear();
    historyIds.clear();
    queueIndex = -1;
    _cachedItems.clear();
    _lastSyncKey = '';
    _widgetTitle = null;
    _widgetArtist = null;
    _widgetPlaying = null;
    _volumeTimer?.cancel();
    _equalizerTimer?.cancel();
    sleepDeadline = null;
    sleepMinutes = null;
    _sleepTimer?.cancel();
    _fadeTimer?.cancel();
    unawaited(player.setVolume(volume));
    playCounts.clear();
    final prefs = await _getPrefs();
    await prefs.remove(_keyPlayCounts);
    await _saveLibrary();
    await _savePlaylists();
    await _saveHistory();
    await _saveQueue();
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
      _keyLibraryV2,
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
    await prefs.setString(_keyHistoryV2, jsonEncode(historyIds));
  }

  @override
  void dispose() {
    _volumeTimer?.cancel();
    _equalizerTimer?.cancel();
    _scanDebounce?.cancel();
    _scanRetryTimer?.cancel();
    unawaited(_scanSub?.cancel());
    unawaited(_playerStateSub?.cancel());
    unawaited(_positionSub?.cancel());
    unawaited(_durationSub?.cancel());
    unawaited(_errorSub?.cancel());
    unawaited(_icySub?.cancel());
    unawaited(player.dispose());
    streamService.dispose();
    downloadService.dispose();
    lyricsService.dispose();
    chartService.dispose();
    suggestionsService.dispose();
    radioService.dispose();
    _sleepTimer?.cancel();
    _fadeTimer?.cancel();
    _statsTimer?.cancel();
    _resumeTimer?.cancel();
    super.dispose();
  }

  void _rebuildIndexes() {
    _libraryIndex.clear();
    _lowerTitles.clear();
    for (var i = 0; i < library.length; i++) {
      _libraryIndex[library[i].id] = i;
      _lowerTitles[library[i].id] = library[i].title.toLowerCase();
    }
  }
}
