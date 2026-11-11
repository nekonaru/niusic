# Changelog

## v1.7.0

Audit rilis: memperbaiki kebocoran penyimpanan dan memperkuat startup aplikasi serta alur pembersihan.

### Peningkatan

- **Bersihkan penyimpanan.** "Hapus semua data" kini juga menghapus file audio unduhan di disk, bukan hanya mengubah metadata.
- **State startup.** Cache widget dan notifikasi diatur ulang dengan benar setelah data dihapus, sehingga UI langsung menampilkan perpustakaan kosong.

## v1.6.0

Mengurangi alokasi berlebih pada notifikasi pemutaran dan pembaruan widget, serta mengaudit jalur panas untuk stabilitas Android.

### Peningkatan

- **Sinkron notifikasi.** Item media disimpan dalam cache per antrean, dan panggilan sinkron ganda ditekan saat tidak ada yang berubah di lagu saat ini.
- **Stabilitas Android.** Startup kini memuat secara tangguh dan layar Beranda selalu terbuka.

## v1.5.0

Mendesain ulang UI aplikasi agar lebih rapi dan konsisten di Android dan Windows.

### Fitur baru

- **Tema baru.** Tema Material 3 dengan kartu membulat, navigasi lebih tenang, dan warna aksen yang lebih jelas.

### Peningkatan

- **Layar Beranda.** Kartu hero sedang diputar, header bagian dengan ikon, baris chart horizontal, dan daftar terakhir/terunduh dalam kartu.
- **Sedang diputar.** Artwork besar dengan bayangan, latar gradien, tipografi tenang, dan kontrol mengikuti aksen.
- **Pengaturan.** Label bagian jelas, tata letak sama seperti sisa aplikasi.
- **Pemutar mini.** Pemutar mini membulat mengambang dengan nuansa progres.

## v1.4.0

Menambahkan perbaikan runtime Android dan memperkuat startup aplikasi.

### Fitur baru

- **Permintaan izin notifikasi.** MainActivity kini meminta POST_NOTIFICATIONS di Android 13+, agar notifikasi media muncul.
- **Audio service activity.** MainActivity kini turunan AudioServiceActivity, base yang direkomendasikan audio_service.

### Peningkatan

- **Ketahanan startup.** Jika memuat data lokal melempar error, Niusic tetap terbuka dan menampilkan error di layar Beranda alih-alih berhenti di spinner. Tab tetap bisa dipakai.

## v1.3.0

Menambahkan kontrol keyboard desktop dan penyesuaian memori decode gambar.

### Fitur baru

- **Kontrol keyboard desktop.** Space putar/jeda, panah lompat dan ubah volume, Ctrl+panah lewati lagu.

### Peningkatan

- **Cache gambar.** Gambar jaringan memakai parameter cacheWidth sehingga thumbnail dan banner memakai memori lebih sedikit.
- **Optimalkan.** Import tidak terpakai dihapus. Analisis dan tes bersih.

## v1.2.1

Layar lirik kini mengikuti lagu saat lirik bertanda waktu tersedia.

### Fitur baru

- **Lirik sinkron.** Jika LRCLIB memiliki lirik bertanda waktu, layar menyorot baris aktif dan menggulir otomatis ke baris itu. Lirik polos tetap tampil seperti biasa.

## v1.2.0

Menambahkan widget home screen Android untuk sedang diputar.

### Fitur baru

- **Widget home screen.** Menampilkan judul dan artis saat ini dengan tombol sebelumnya, putar/jeda, dan berikutnya. Ketuk cover art atau judul untuk membuka Niusic.
- **Pembaruan widget.** Niusic menulis status widget ke SharedPreferences pada setiap perubahan pemutaran dan memberi tahu widget untuk mengikat ulang.

### Peningkatan

- **Manifest Android.** Mendaftarkan receiver widget dan mempertahankan media service dari v1.1.0.

## v1.1.0

Menambahkan kontrol notifikasi media OS di Android sehingga Niusic bisa terus memutar di latar belakang.

### Fitur baru

- **Notifikasi media.** Android menampilkan judul, artis, putar/jeda, lewati berikutnya, lewati sebelumnya, berhenti, dan lompat di notifikasi saat musik diputar.

### Peningkatan

- **Status notifikasi.** Aplikasi mengirim antrean, status putar, posisi, dan item media ke notifikasi OS pada setiap perubahan status.
- **Windows tidak terganggu.** Di Windows, handler notifikasi tidak didaftarkan; aplikasi berjalan seperti sebelumnya.
- **Manifest Android.** Foreground service dan media button receiver dideklarasikan dengan foreground type mediaPlayback.

## v1.0.0

Rilis stabil pertama. Pemutaran lokal dan online, unduhan, lirik, radio, chart, dan UI adaptif desktop dan mobile.

### Peningkatan

- **Persistensi antrean.** Urutan antrean dan posisi putar bertahan setelah restart.
- **Manajemen penyimpanan.** Pengaturan menampilkan ukuran unduhan dan menghapus semua unduhan.
- **Artefak rilis.** CI memverifikasi aset APK dan zip ada sebelum terbit.
- **Keamanan.** Pemutaran online meng-resolve URL audio baru per lagu dan fallback saat satu sumber gagal.

## v0.8.0

Menambahkan playlist online, persistensi antrean, dan manajemen penyimpanan.

### Fitur baru

- **Playlist online.** Pencarian kini menampilkan playlist online. Buka satu, putar, atau simpan sebagai playlist lokal.
- **Persistensi antrean.** Urutan antrean dan posisi putar tetap ada setelah aplikasi restart.
- **Ringkasan penyimpanan.** Ukuran unduhan tersedia lewat `totalDownloadBytes` dan `clearDownloads`.

## v0.7.0

Menambahkan browse kanal, saran pencarian, kecepatan putar, dan tema aksen. Juga memperbaiki radio terkait dan mendokumentasikan kesenjangan yang tersisa.

### Fitur baru

- **Browse kanal.** Buka kanal mana pun dari pencarian dan lihat banner, avatar, pelanggan, dan unggahan.
- **Saran pencarian.** Ketuk chip saran untuk mencari lagi secara instan.
- **Kecepatan putar.** Atur 0,5x hingga 2,0x di Pengaturan. Kecepatan tersimpan.
- **Tema aksen.** Pilih aksen indigo, teal, ungu, atau oranye di Pengaturan.
- **Radio asli.** Radio kini mengutamakan stream terkait untuk video saat ini, lalu fallback ke pencarian.

### Peningkatan

- **Analisis kesenjangan.** `docs/GAPS.md` mencantumkan fitur Auralys mana yang sudah dibuat dan mana yang butuh akun atau kode native.

## v0.6.0

Membuat UI native untuk setiap perangkat: sidebar dan sekarang diputar dua pane di desktop, dan bar bawah di mobile. Juga memperbaiki bug pencarian antrean dan memperketat fokus audio.

### Fitur baru

- **Sidebar desktop.** Pada lebar tablet dan desktop, aplikasi menampilkan NavigationRail dengan label, bukan bar bawah.
- **Sedang diputar dua pane.** Di desktop, artwork ada di samping kontrol. Di mobile, mereka ditumpuk vertikal.
- **Grid adaptif.** Perpustakaan, hasil pencarian, dan chart Beranda beralih dari 1 kolom di mobile ke 2 atau 3 kolom di layar lebar.

### Peningkatan

- **Perbaikan bug antrean.** Ketuk item perpustakaan kini memutar lagu pada posisi antreannya, bahkan setelah antrean diurut ulang.
- **Fokus audio.** Android meminta fokus audio musik sebelum pemutaran.
- **Tes responsif.** Tes widget ditambah untuk tata letak bar bawah sempit dan rail lebar.

## v0.5.0

Menambahkan lirik, chart harian, radio, dan timer tidur.

### Fitur baru

- **Lirik.** Tombol lirik di Sedang diputar memuat lirik polos dari LRCLIB untuk lagu saat ini.
- **Chart harian.** Beranda menampilkan lagu teratas Deezer. Ketuk tile untuk memutarnya di YouTube.
- **Radio.** Tombol radio menambahkan lagu YouTube terkait untuk lagu saat ini ke antrian.
- **Timer tidur.** Jeda pemutaran setelah 15, 30, atau 60 menit, atau matikan.

## v0.4.0

Menambahkan unduhan offline, pilihan kualitas audio, dan layar antrean yang bisa diatur ulang dan dipangkas.

### Fitur baru

- **Unduhan offline.** Unduh audio YouTube ke perangkat dan putar tanpa internet. Kelola unduhan dari Beranda.
- **Daftar terunduh dan hapus.** Beranda menampilkan lagu terunduh. Ketuk untuk putar atau pakai ikon hapus untuk bebas ruang.
- **Kualitas audio.** Pilih bitrate rendah atau tinggi di Pengaturan. Pilihan tersimpan di perangkat.
- **Layar antrean.** Tombol antrean di Sedang diputar membuka daftar yang bisa digeser untuk diurutkan ulang dan diketuk untuk dihapus.

### Peningkatan

- **Prioritas offline.** Lagu terunduh diputar dari disk, bukan dari jaringan.

## v0.3.0

Menambahkan pencarian dan pemutaran online, sehingga Niusic kini memutar musik YouTube seperti Auralys selain file lokal.

### Fitur baru

- **Pencarian online.** Cari video YouTube dari tab Streaming dan lihat judul, kanal, dan thumbnail.
- **Pemutaran online.** Ketuk hasil untuk memutar audio streaming. Lagu remote masuk antrian, riwayat, dan playlist seperti lagu lokal.
- **Tampilan thumbnail.** Layar Sedang diputar menampilkan thumbnail video bila tersedia.

### Peningkatan

- **Pencarian tangguh.** Pencarian mencoba dua instance Piped publik berurutan, sehingga satu gangguan tidak merusak tab.
- **URL audio ter-cache.** URL Googlevideo yang di-resolve disimpan di memori selama 1 jam.
- **Error lebih baik.** Kegagalan pencarian dan pemutaran menampilkan pesan ramah dan menjaga pemutaran yang ada tetap utuh.

## v0.2.1

Menambahkan icon aplikasi Niusic Bars di Android dan Windows dan menampilkannya di header README.

### Fitur baru

- **Icon aplikasi.** Icon launcher Android dan `app_icon.ico` Windows kini memakai mark Bars baru.
- **Logo README.** Header README menampilkan mark baru dalam kedua bahasa.

### Peningkatan

- **Aset brand.** Master SVG ada di `assets/niusic-mark.svg` dengan gambar PNG header di `assets/niusic-mark.png`.

## v0.2.0

Menambahkan paket exe Windows ke rilis dan memangkas kerja rebuild, ukuran APK, dan penulisan disk saat pemutaran.

### Fitur baru

- **Paket exe Windows.** Rilis kini menyertakan `niusic-windows-x64.zip` berisi `niusic.exe` dan DLL, bersama APK Android.
- **Dua APK Android.** Rilis kini menyertakan build arm64-v8a dan armeabi-v7a.

### Peningkatan

- **UI pemutaran lebih cepat.** Pembaruan posisi memberi tahu UI satu kali per detik, bukan beberapa kali per detik.
- **Perpustakaan lebih cepat.** Pencarian perpustakaan dan pencarian antrian memakai indeks yang dihitung di awal, bukan pemindaian linear berulang.
- **APK lebih kecil.** Build rilis mengaktifkan minifikasi dan penyusutan sumber daya.
- **Penulisan disk lebih sedikit.** Pengaturan disimpan di cache dan perubahan volume diberi debounce 300 ms.
- **Tab stabil.** Tab memakai IndexedStack sehingga berpindah tab tidak membangun ulang progres.

## v0.1.0

Rilis local-first dengan satu codebase Flutter untuk Android dan Windows. Memutar file musik di perangkat kamu dengan perpustakaan, antrian, playlist, dan riwayat.

### Fitur baru

- **Perpustakaan lokal.** Impor file audio dengan pemilih file sistem dan cari berdasarkan judul.
- **Kontrol pemutaran.** Putar, jeda, lewati, lompat, volume, acak, dan ulangi.
- **Playlist.** Buat, hapus, tambah, dan hapus lagu di perangkat.
- **Beranda dan pemutar mini.** Lihat lagu baru diputar dan buka pemutar penuh dari bar bawah.
- **UI dwibahasa.** Beralih antara English dan Bahasa Indonesia di Pengaturan.
- **Tema.** Pakai tema sistem, terang, atau gelap.

### Peningkatan

- **Satu codebase.** Satu proyek Flutter membangun APK Android dan exe Windows.
- **Penyimpanan di perangkat.** Path perpustakaan, playlist, riwayat, dan pengaturan tetap di perangkat.
