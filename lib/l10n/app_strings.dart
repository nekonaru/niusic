class AppStrings {
  const AppStrings(this.lang);

  final String lang;

  bool get isId => lang == 'id';

  String get appName => 'Niusic';
  String get library => isId ? 'Perpustakaan' : 'Library';
  String get playlists => isId ? 'Playlist' : 'Playlists';
  String get settings => isId ? 'Pengaturan' : 'Settings';
  String get home => isId ? 'Beranda' : 'Home';
  String get stream => isId ? 'Streaming' : 'Stream';
  String get searchOnlineHint =>
      isId ? 'Cari lagu online (YouTube)' : 'Search online (YouTube)';
  String get searching => isId ? 'Mencari...' : 'Searching...';
  String get noResults => isId ? 'Tidak ada hasil.' : 'No results.';
  String get searchError => isId
      ? 'Pencarian gagal. Periksa koneksi dan coba lagi.'
      : 'Search failed. Check your connection and try again.';
  String get playNow => isId ? 'Putar sekarang' : 'Play now';
  String get enqueue => isId ? 'Tambah ke antrian' : 'Add to queue';
  String get needsInternet =>
      isId ? 'Streaming butuh internet.' : 'Streaming needs internet.';
  String get downloads => isId ? 'Unduhan' : 'Downloads';
  String get download => isId ? 'Unduh untuk offline' : 'Download for offline';
  String get downloading => isId ? 'Mengunduh...' : 'Downloading...';
  String get downloaded => isId ? 'Terunduh' : 'Downloaded';
  String get deleteDownload => isId ? 'Hapus unduhan' : 'Delete download';
  String get noDownloads => isId
      ? 'Belum ada unduhan. Unduh lagu dari tab Streaming.'
      : 'No downloads yet. Download songs from the Stream tab.';
  String get audioQuality => isId ? 'Kualitas audio' : 'Audio quality';
  String get qualityHigh => isId ? 'Tinggi' : 'High';
  String get qualityLow => isId ? 'Rendah' : 'Low';
  String get lyrics => isId ? 'Lirik' : 'Lyrics';
  String get videos => isId ? 'Video' : 'Videos';
  String get channels => isId ? 'Kanal' : 'Channels';
  String get noLyrics => isId
      ? 'Lirik tidak ditemukan untuk lagu ini.'
      : 'No lyrics found for this track.';
  String get lyricsError => isId
      ? 'Lirik gagal dimuat. Periksa koneksi.'
      : 'Failed to load lyrics. Check your connection.';
  String get dailyChart => isId ? 'Chart harian' : 'Daily Chart';
  String get topToday => isId ? 'Top hari ini' : 'Top today';
  String get radio => isId ? 'Radio' : 'Radio';
  String get playRadio => isId ? 'Putar radio' : 'Play radio';
  String get sleepTimer => isId ? 'Timer tidur' : 'Sleep timer';
  String get sleepOff => isId ? 'Mati' : 'Off';
  String get minutes15 => '15 min';
  String get minutes30 => '30 min';
  String get minutes60 => '60 min';
  String get lyricsTitle => isId ? 'Lirik' : 'Lyrics';
  String get channel => isId ? 'Kanal' : 'Channel';
  String get subscribers => isId ? 'pelanggan' : 'subscribers';
  String get uploads => isId ? 'Unggahan' : 'Uploads';
  String get playbackSpeed => isId ? 'Kecepatan putar' : 'Playback speed';
  String get accent => isId ? 'Warna aksen' : 'Accent color';
  String get suggestions => isId ? 'Saran pencarian' : 'Search suggestions';
  String get storage => isId ? 'Penyimpanan' : 'Storage';
  String get downloadsSize => isId ? 'Ukuran unduhan' : 'Download size';
  String get clearDownloads =>
      isId ? 'Hapus semua unduhan' : 'Clear all downloads';
  String get nowPlaying => isId ? 'Sedang diputar' : 'Now Playing';
  String get addMusic => isId ? 'Tambah musik' : 'Add music';
  String get emptyLibrary => isId
      ? 'Belum ada musik. Tambahkan file audio dari perangkat ini.'
      : 'No music yet. Add audio files from this device.';
  String get emptyLibraryHint => isId
      ? 'Import file lokal di sini, atau gunakan tab Streaming untuk mencari lagu online dari YouTube.'
      : 'Import local files here, or open the Stream tab to search YouTube for tracks online.';
  String get searchHint => isId ? 'Cari di perpustakaan' : 'Search library';
  String get queue => isId ? 'Antrian' : 'Queue';
  String get recent => isId ? 'Baru diputar' : 'Recently played';
  String get newPlaylist => isId ? 'Playlist baru' : 'New playlist';
  String get playlistName => isId ? 'Nama playlist' : 'Playlist name';
  String get create => isId ? 'Buat' : 'Create';
  String get cancel => isId ? 'Batal' : 'Cancel';
  String get delete => isId ? 'Hapus' : 'Delete';
  String get rename => isId ? 'Ganti nama' : 'Rename';
  String get addToPlaylist => isId ? 'Tambah ke playlist' : 'Add to playlist';
  String get removeFromPlaylist =>
      isId ? 'Hapus dari playlist' : 'Remove from playlist';
  String get emptyPlaylist =>
      isId ? 'Playlist ini kosong.' : 'This playlist is empty.';
  String get language => isId ? 'Bahasa' : 'Language';
  String get english => 'English';
  String get indonesian => 'Bahasa Indonesia';
  String get theme => isId ? 'Tema' : 'Theme';
  String get themeSystem => isId ? 'Sistem' : 'System';
  String get themeLight => isId ? 'Terang' : 'Light';
  String get themeDark => isId ? 'Gelap' : 'Dark';
  String get volume => isId ? 'Volume' : 'Volume';
  String get clearData => isId ? 'Hapus semua data' : 'Clear all data';
  String get clearDataConfirm => isId
      ? 'Hapus perpustakaan, playlist, dan riwayat?'
      : 'Clear library, playlists, and history?';
  String get shuffle => isId ? 'Acak' : 'Shuffle';
  String get repeat => isId ? 'Ulangi' : 'Repeat';
  String get repeatOff => isId ? 'Mati' : 'Off';
  String get repeatAll => isId ? 'Semua' : 'All';
  String get repeatOne => isId ? 'Satu' : 'One';
  String get previous => isId ? 'Sebelumnya' : 'Previous';
  String get next => isId ? 'Berikutnya' : 'Next';
  String get play => isId ? 'Putar' : 'Play';
  String get pause => isId ? 'Jeda' : 'Pause';
  String get noTrack =>
      isId ? 'Pilih lagu untuk mulai.' : 'Pick a track to start.';
  String get tracksCount => isId ? 'lagu' : 'tracks';
  String get added => isId ? 'Ditambahkan.' : 'Added.';
  String get removed => isId ? 'Dihapus.' : 'Removed.';
  String get save => isId ? 'Simpan' : 'Save';
  String get openNowPlaying => isId ? 'Buka pemutar' : 'Open now playing';
  String get notifications => isId ? 'Notifikasi' : 'Notifications';
  String get enableNotifications =>
      isId ? 'Izinkan notifikasi media' : 'Allow media notifications';
  String get enableNotificationsDesc => isId
      ? 'Tampilkan notifikasi media dengan kontrol putar.'
      : 'Show a media notification with playback controls.';
  String get allow => isId ? 'Izinkan' : 'Allow';

  String get appearance => isId ? 'Tampilan' : 'Appearance';
  String get playback => isId ? 'Pemutaran' : 'Playback';
  String get about => isId ? 'Tentang' : 'About';
  String get version => isId ? 'Versi' : 'Version';

  String get scanDeviceMusic =>
      isId ? 'Pindai musik perangkat' : 'Scan device music';
  String get scanDeviceMusicDesc => isId
      ? 'Mencari file audio di perangkat secara otomatis. Lagu baru muncul dengan sendirinya.'
      : 'Finds audio files on this device automatically. New songs appear on their own.';
  String get scanNow => isId ? 'Pindai sekarang' : 'Scan now';
  String get scanning => isId ? 'Memindai...' : 'Scanning...';
  String get scanPermissionNeeded =>
      isId ? 'Izinkan akses ke file musik' : 'Allow access to music files';
  String get scanUnavailable => isId
      ? 'Pindai otomatis hanya tersedia di Android.'
      : 'Auto scan is available on Android only.';
  String get noMusicFound => isId
      ? 'Belum ada file musik di perangkat ini.'
      : 'No music files found on this device yet.';
  String get lastScanPrefix => isId ? 'Terakhir dipindai' : 'Last scan';
  String scanResult(int added, int total) {
    final newSongs = added == 0
        ? (isId ? 'tidak ada lagu baru' : 'no new songs')
        : '+$added ${isId ? "lagu baru" : "new"}';
    return isId
        ? 'Ditemukan $total lagu, $newSongs.'
        : 'Found $total tracks, $newSongs.';
  }

  String get errorMissingPath => isId
      ? 'Lagu ini tidak punya lokasi file.'
      : 'This track has no file path.';
  String get errorFileNotFound => isId
      ? 'File tidak ditemukan di perangkat.'
      : 'File not found on this device.';
  String get errorMissingVideoId => isId
      ? 'Lagu online ini hilang pengenal.'
      : 'This online track is missing its id.';
  String get errorStreamFailed => isId
      ? 'Streaming gagal. Periksa koneksi lalu coba lagi.'
      : 'Stream failed. Check your connection and try again.';
  String get errorPlaybackFailed =>
      isId ? 'Gagal memutar audio.' : 'Could not play audio.';
  String errorText(String? code) {
    switch (code) {
      case 'missing_path':
        return errorMissingPath;
      case 'file_not_found':
        return errorFileNotFound;
      case 'missing_video_id':
        return errorMissingVideoId;
      case 'stream_failed':
        return errorStreamFailed;
      case 'playback_failed':
        return errorPlaybackFailed;
      default:
        return code ?? '';
    }
  }

  String get equalizer => 'Equalizer';
  String get equalizerDesc => isId
      ? 'Ubah karakter suara. Hanya di Android.'
      : 'Tune the sound. Android only.';
  String get loudnessEnhancer => isId ? 'Penguat volume' : 'Loudness enhancer';
  String get reset => isId ? 'Atur ulang' : 'Reset';
  String get mostPlayed => isId ? 'Paling sering diputar' : 'Most played';
  String get sortBy => isId ? 'Urutkan' : 'Sort by';
  String get sortByName => isId ? 'Nama' : 'Name';
  String get sortByArtist => isId ? 'Artis' : 'Artist';
  String get sortByDuration => isId ? 'Durasi' : 'Duration';
  String get sortByRecent => isId ? 'Terakhir diputar' : 'Recently played';
  String get share => isId ? 'Bagikan' : 'Share';
  String get playsCountSuffix => isId ? 'kali diputar' : 'plays';
  String get cancelSleep =>
      isId ? 'Batalkan timer tidur' : 'Cancel sleep timer';

  String get favorites => isId ? 'Favorit' : 'Favorites';
  String get addToFavorites => isId ? 'Tambah ke favorit' : 'Add to favorites';
  String get removeFromFavorites =>
      isId ? 'Hapus dari favorit' : 'Remove from favorites';
  String get radioSearchHint =>
      isId ? 'Cari stasiun radio...' : 'Search radio stations...';
  String get noStations =>
      isId ? 'Tidak ada stasiun ditemukan.' : 'No stations found.';
  String get clearQueue => isId ? 'Bersihkan antrian' : 'Clear queue';
  String get clearQueueConfirm =>
      isId ? 'Bersihkan seluruh antrian?' : 'Clear the entire queue?';
  String get saveAsPlaylist =>
      isId ? 'Simpan sebagai playlist' : 'Save as playlist';
  String get live => 'LIVE';
  String get seeAll => isId ? 'Lihat semua' : 'See all';
  String get selectedCount => isId ? 'dipilih' : 'selected';
  String get clearSelection => isId ? 'Batal pilih' : 'Cancel selection';
  String get trackDetails => isId ? 'Detail lagu' : 'Track details';
  String get sourceKind => isId ? 'Sumber' : 'Source';
  String get sourceLocal => isId ? 'File lokal' : 'Local file';
  String get sourceDownloaded => isId ? 'Unduhan' : 'Downloaded';
  String get sourceOnline => isId ? 'Online' : 'Online';
  String get sourceRadio => isId ? 'Radio' : 'Radio';
  String get playNext => isId ? 'Putar berikutnya' : 'Play next';
  String get emptyHistory =>
      isId ? 'Belum ada riwayat putar.' : 'No playback history yet.';
  String get renamePlaylist => isId ? 'Ganti nama playlist' : 'Rename playlist';
  String get deletePlaylist => isId ? 'Hapus playlist' : 'Delete playlist';
  String get deletePlaylistConfirm => isId
      ? 'Hapus playlist ini? Lagu tetap ada di perpustakaan.'
      : 'Delete this playlist? Tracks stay in the library.';
  String get playAll => isId ? 'Putar semua' : 'Play all';
  String get shuffleAll => isId ? 'Acak semua' : 'Shuffle all';
  String get fadeOutSleep =>
      isId ? 'Pelankan sebelum tidur' : 'Fade out before sleep';
  String get fadeOutSleepDesc => isId
      ? 'Volume turun perlahan 10 detik sebelum timer berhenti.'
      : 'Volume drops slowly in the last 10 seconds of the timer.';

  String get artists => isId ? 'Artis' : 'Artists';
  String get albums => isId ? 'Album' : 'Albums';
  String get songs => isId ? 'Lagu' : 'Songs';
  String get sortByRecentAdded => isId ? 'Baru ditambahkan' : 'Recently added';
  String get smartPlaylists => isId ? 'Playlist pintar' : 'Smart playlists';
  String get recentlyAdded => isId ? 'Baru ditambahkan' : 'Recently added';
  String get neverPlayed => isId ? 'Belum diputar' : 'Never played';
  String get duplicates => isId ? 'Lagu duplikat' : 'Duplicate tracks';
  String get noDuplicates =>
      isId ? 'Tidak ada duplikat.' : 'No duplicate tracks found.';
  String get mergeDuplicates => isId ? 'Hapus duplikat' : 'Remove duplicates';
  String get editMetadata => isId ? 'Ubah info lagu' : 'Edit track info';
  String get backupRestore =>
      isId ? 'Cadangkan / Pulihkan' : 'Backup / Restore';
  String get exportBackup => isId ? 'Ekspor cadangan' : 'Export backup';
  String get importBackup => isId ? 'Pulihkan cadangan' : 'Restore backup';
  String get backupDone => isId ? 'Cadangan dibagikan.' : 'Backup shared.';
  String restoreDone(int added) =>
      isId ? '$added lagu dipulihkan.' : '$added tracks restored.';
  String get cacheSize => isId ? 'Ukuran cache' : 'Cache size';
  String get clearCache => isId ? 'Hapus cache' : 'Clear cache';
  String get statsTitle => isId ? 'Statistik dengar' : 'Listening stats';
  String get totalListening => isId ? 'Total mendengar' : 'Total listening';
  String get thisWeek => isId ? 'Minggu ini' : 'This week';
  String get exportCsv => isId ? 'Ekspor CSV' : 'Export CSV';
  String get offlineMode => isId ? 'Mode offline' : 'Offline mode';
  String get offlineModeDesc => isId
      ? 'Matikan semua permintaan jaringan.'
      : 'Disable all network requests.';
  String get all => isId ? 'Semua' : 'All';
  String get editInfoSaved => isId ? 'Info disimpan.' : 'Info saved.';

  String get skipSilence => isId ? 'Lewati hening' : 'Skip silence';
  String get skipSilenceDesc => isId
      ? 'Potong bagian senyap pada audio lokal.'
      : 'Cut silent parts in local audio.';
  String get pitch => isId ? 'Nada dasar' : 'Pitch';
  String get cacheOnline => isId ? 'Cache audio online' : 'Cache online audio';
  String get cacheOnlineDesc => isId
      ? 'Simpan audio streaming saat diputar untuk putar ulang offline.'
      : 'Cache streaming audio while playing for offline replay.';
  String get topStations => isId ? 'Terpopuler' : 'Top stations';
  String get stationFavorites => isId ? 'Stasiun favorit' : 'Favorite stations';
  String get nowOnRadio => isId ? 'Sedang diputar' : 'Now playing';
  String get immersivePlayer =>
      isId ? 'Pemutar layar penuh' : 'Immersive player';
  String get gridView => isId ? 'Tampilan grid' : 'Grid view';
  String get offlineActive => isId
      ? 'Mode offline aktif. Fitur online dimatikan.'
      : 'Offline mode is on. Online features are disabled.';

  String get advancedPlayback =>
      isId ? 'Pemutaran lanjutan' : 'Advanced playback';
  String get resumePosition =>
      isId ? 'Lanjutkan posisi lagu' : 'Resume track position';
  String get skipIntro => isId ? 'Lewati intro' : 'Skip intro';
  String get skipOutro => isId ? 'Lewati akhir' : 'Skip outro';
  String get seconds => isId ? 'detik' : 'seconds';
  String get bufferPreset => isId ? 'Ukuran buffer' : 'Buffer size';
  String get bufferLight => isId ? 'Hemat' : 'Light';
  String get bufferNormal => isId ? 'Normal' : 'Normal';
  String get bufferLarge => isId ? 'Besar' : 'Large';
  String get endAction => isId ? 'Saat lagu usai' : 'When a track ends';
  String get endNext => isId ? 'Lanjut' : 'Next';
  String get endPause => isId ? 'Jeda' : 'Pause';
  String get endRepeat => isId ? 'Ulang' : 'Repeat';
  String get focusMode => isId ? 'Mode fokus' : 'Focus mode';
  String get focusHint =>
      isId ? 'Ketuk untuk menampilkan kontrol' : 'Tap to show controls';
  String get abLoop => isId ? 'Ulang A-B' : 'A-B loop';
  String get markA => 'A';
  String get markB => 'B';
  String get clearLoop => isId ? 'Hapus loop' : 'Clear loop';
  String get replayGain => isId ? 'Gain lagu' : 'Track gain';
  String get eqFlat => isId ? 'Rata' : 'Flat';
  String get eqBass => isId ? 'Bass' : 'Bass';
  String get eqVocal => isId ? 'Vokal' : 'Vocal';
  String get eqRock => isId ? 'Rock' : 'Rock';
  String get eqJazz => isId ? 'Jazz' : 'Jazz';

  String get themeFromArt => isId ? 'Warna dari sampul' : 'Theme from artwork';
  String get themeFromArtDesc => isId
      ? 'Warna pemutar mengikuti sampul lagu online.'
      : 'Player colors follow online track artwork.';
  String get textSize => isId ? 'Ukuran teks' : 'Text size';
  String get sleepUntilEnd =>
      isId ? 'Jeda di akhir lagu' : 'Pause at track end';
  String get queuePresets => isId ? 'Preset antrian' : 'Queue presets';
  String get savePreset => isId ? 'Simpan preset' : 'Save preset';
  String get loadPreset => isId ? 'Muat preset' : 'Load preset';
  String get playlistCover => isId ? 'Atur sampul' : 'Set cover';
  String get karaokeMode => isId ? 'Mode karaoke' : 'Karaoke mode';

  String get onboardingTitle1 =>
      isId ? 'Musikmu, otomatis' : 'Your music, automatically';
  String get onboardingDesc1 => isId
      ? 'Niusic memindai lagu di perangkat dan menambahkannya tanpa impor manual.'
      : 'Niusic scans songs on your device and adds them without manual import.';
  String get onboardingTitle2 =>
      isId ? 'Putar dengan nyaman' : 'Play in comfort';
  String get onboardingDesc2 => isId
      ? 'Kontrol media, equalizer, dan lirik tersedia di satu pemutar.'
      : 'Media controls, equalizer, and lyrics live in one player.';
  String get onboardingTitle3 => isId ? 'Siap mendengar' : 'Ready to listen';
  String get onboardingDesc3 => isId
      ? 'Izinkan notifikasi media dari Pengaturan kapan saja.'
      : 'Allow media notifications from Settings at any time.';
  String get getStarted => isId ? 'Mulai' : 'Get started';
  String get onboardingNext => isId ? 'Lanjut' : 'Next';
  String get skip => isId ? 'Lewati' : 'Skip';
  String get continueListening =>
      isId ? 'Lanjutkan mendengar' : 'Continue listening';
  String get reduceMotion => isId ? 'Kurangi animasi' : 'Reduce motion';

  String get dailyMix => isId ? 'Campuran harian' : 'Daily mix';
  String get mood => isId ? 'Suasana' : 'Mood';
  String get moodCalm => isId ? 'Tenang' : 'Calm';
  String get moodFocus => isId ? 'Fokus' : 'Focus';
  String get moodEnergy => isId ? 'Berenergi' : 'Energy';
  String get quickActions => isId ? 'Aksi cepat' : 'Quick actions';
  String get shareSelected => isId ? 'Bagikan pilihan' : 'Share selected';
  String get minutes45 => '45 min';
}
