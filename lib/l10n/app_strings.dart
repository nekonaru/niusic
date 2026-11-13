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
}
