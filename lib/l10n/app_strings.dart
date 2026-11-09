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
  String get nowPlaying => isId ? 'Sedang diputar' : 'Now Playing';
  String get addMusic => isId ? 'Tambah musik' : 'Add music';
  String get emptyLibrary => isId
      ? 'Belum ada musik. Tambahkan file audio dari perangkat ini.'
      : 'No music yet. Add audio files from this device.';
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
}
