# Changelog

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
