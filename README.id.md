<div align="center">

<h1>Niusic: Pemutar Musik Lokal</h1>
<p><b>Putar musik lokal di Android dan Windows (Flutter) dengan perpustakaan, antrian, playlist, dan riwayat. Sepenuhnya offline, tanpa akun.</b></p>

<a href="https://github.com/nekonaru/niusic/releases"><img src="https://img.shields.io/github/v/nekonaru/niusic?style=flat-square" alt="Rilis" /></a>
<a href="https://github.com/nekonaru/niusic/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/nekonaru/niusic/ci.yml?style=flat-square" alt="CI" /></a>
<img src="https://img.shields.io/badge/language-Flutter-02569B?style=flat-square" alt="Flutter" />
<img src="https://img.shields.io/badge/platform-Android%20%7C%20Windows-000000?style=flat-square" alt="Platform" />
<a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="Lisensi" /></a>

</div>

<br />

[English](README.md) | **Bahasa Indonesia**

> [!NOTE]
> Niusic memutar file audio yang sudah ada di perangkat kamu. Aplikasi ini tidak melakukan streaming atau mengunduh musik.

---

## Daftar Isi

- [Tentang](#tentang)
- [Fitur](#fitur)
- [Kebutuhan](#kebutuhan)
- [Instalasi](#instalasi)
- [Pemakaian](#pemakaian)
- [Bahasa Tampilan](#bahasa-tampilan)
- [Struktur Proyek](#struktur-proyek)
- [Pengembangan](#pengembangan)
- [Pengujian](#pengujian)
- [Keamanan](#keamanan)
- [Integrasi Berkelanjutan](#integrasi-berkelanjutan)
- [FAQ](#faq)
- [Penulis](#penulis)
- [Penanggung Jawaban](#penanggung-jawaban)
- [Lisensi](#lisensi)

---

## Tentang

Niusic adalah pemutar musik local-first untuk Android dan Windows. Satu codebase Flutter membangun kedua aplikasi. Aplikasi membaca file audio dari perangkat kamu, menyimpan perpustakaan di perangkat, dan memutarnya secara offline.

> _"Musik kamu tetap ada di perangkat kamu."_

---

## Fitur

### Pemutaran

| Fitur | Deskripsi |
|-------|-----------|
| **Putar dan jeda** | Putar lagu, jeda, lanjutkan, lewati berikutnya atau sebelumnya. |
| **Lompat dan volume** | Lompat di dalam lagu dan atur volume. |
| **Acak dan ulangi** | Aktifkan acak dan ulangi mati, semua, atau satu. |
| **Antrian** | Putar seluruh perpustakaan sebagai antrian, berurutan. |

### Perpustakaan

| Fitur | Deskripsi |
|-------|-----------|
| **Impor audio** | Pilih banyak file audio lewat pemilih file sistem. |
| **Cari** | Saring perpustakaan berdasarkan teks judul. |
| **Riwayat** | Simpan 100 lagu terakhir yang diputar di perangkat. |

### Organisasi

| Fitur | Deskripsi |
|-------|-----------|
| **Playlist** | Buat, ganti nama lewat kode, hapus, tambah, dan hapus lagu secara lokal. |
| **Pengaturan** | Ganti bahasa, tema, volume, dan hapus data lokal. |

---

## Kebutuhan

| Dependensi | Versi Minimum | Catatan |
|------------|----------------|---------|
| **Android** | 8.0 (API 26) | Untuk build APK. |
| **Windows** | 10 | Untuk build Windows. |
| **Flutter** | 3.47.0 | Untuk build dari sumber. |
| **Dart** | 3.13.0 | Termasuk dalam Flutter. |

> [!TIP]
> Kebanyakan pengguna hanya membutuhkan file instalasi siap pakai dari Release terbaru. Kamu tidak butuh terminal, Flutter, atau Android Studio.

### Belum pernah memakai terminal? Mulai dari sini

<details><summary><b>Buka terminal di Windows atau Android</b></summary>

1. Pada Windows, buka menu Start, ketik `powershell`, tekan Enter.
2. Pada Android, kamu tidak butuh terminal untuk memasang APK.
3. Unduh APK, buka, dan ikuti petunjuk Android.

</details>

---

## Instalasi

### Opsi A: Unduh APK (paling mudah)

1. Buka Release terbaru di GitHub.
2. Unduh `niusic-android-arm64-v8a-release.apk` atau `niusic-windows.zip`.
3. Pada Android, buka APK dan izinkan pemasangan dari browser jika diminta.
4. Pada Windows, ekstrak zip dan buka `niusic.exe`.
5. Buka Niusic dan pilih folder atau file musik kamu.

> [!IMPORTANT]
> Pada Android, izinkan pemilih file membaca file audio yang kamu pilih. Niusic tidak butuh izin lain untuk v0.1.0.

### Opsi B: Build dari sumber (untuk pengembangan / membaca atau mengubah kode)

#### 1. Ambil kode

<details><summary><b>Saya sudah memasang Git</b></summary>

```bash
git clone https://github.com/nekonaru/niusic.git
cd niusic
```

</details>

<details><summary><b>Saya belum memasang Git</b></summary>

1. Buka `https://github.com/nekonaru/niusic`.
2. Klik Code, lalu Download ZIP.
3. Ekstrak zip, lalu buka folder hasil ekstrak di terminal.

</details>

#### 2. Pasang dependensi dan verifikasi

```bash
flutter pub get
```

> [!IMPORTANT]
> Perintah di atas harus selesai tanpa error.

```bash
flutter analyze
flutter test
```

#### 3. Build

```bash
flutter build windows --release
flutter build apk --release --split-per-abi
```

---

## Pemakaian

### Peluncuran pertama

1. Buka Niusic.
2. Ketuk Tambah musik pada tab Beranda.
3. Pilih file audio di pemilih file.
4. Ketuk lagu pada Perpustakaan untuk memutarnya.

> [!NOTE]
> Niusic menyimpan path file, playlist, riwayat, dan pengaturan di perangkat ini saja.

### Pemakaian harian

- **Beranda:** Lihat lagu baru diputar dan tambah musik.
- **Perpustakaan:** Cari dan putar seluruh perpustakaan.
- **Playlist:** Buat playlist, lalu tambah lagu dari menu Perpustakaan.
- **Pengaturan:** Ubah bahasa, tema, volume, atau hapus data lokal.
- **Pemutar mini:** Ketuk bar lagu di bawah untuk membuka pemutar penuh.

---

## Bahasa Tampilan

1. Buka tab Pengaturan.
2. Pada bagian Bahasa, pilih English atau Bahasa Indonesia.
3. UI langsung berubah dan tetap sama setelah restart.

---

## Struktur Proyek

```
niusic
├── lib
│   ├── l10n     # String UI English dan Indonesia
│   ├── models   # Model Track dan Playlist
│   ├── screens  # Home, Library, Playlists, Settings, Now Playing
│   └── services # Pemutaran dan penyimpanan di perangkat
├── test         # Tes unit dan widget
├── android      # Shell aplikasi Android
├── windows      # Shell aplikasi Windows
├── README.md    # Dokumentasi English
└── README.id.md # Dokumentasi Indonesia
```

---

## Pengembangan

### Menambah string baru yang ditampilkan ke pengguna

1. Tambahkan teks English dan teks Indonesia di `lib/l10n/app_strings.dart`.
2. Pakai getter baru pada layar yang menampilkannya.
3. Jalankan `flutter analyze` dan `flutter test`.

> [!WARNING]
> Jangan ubah file di bawah `build/` atau file platform hasil generate secara manual. Ubah kode Dart dan jalankan ulang perintah Flutter.

---

## Pengujian

Jalankan perintah ini sebelum setiap push:

```bash
flutter analyze
flutter test
flutter build windows --release
```

| Pemeriksaan | Kebutuhan |
|-------------|-----------|
| **Analyze** | Nol isu. |
| **Tes** | Semua tes lulus. |
| **Build Windows** | Build rilis berhasil. |
| **Smoke test** | `flutter run -d windows` membuka aplikasi. |

Konfigurasi lint ada di `analysis_options.yaml` dengan `prefer_single_quotes` dan `sort_child_properties_last`.

---

## Keamanan

Niusic hanya menyimpan data lokal di perangkat: path file, playlist, riwayat, bahasa, tema, dan volume. Aplikasi ini tidak punya backend, akun, analitik, dan panggilan jaringan pada v0.1.0. Jaga dependensi tetap terbaru di `pubspec.yaml` dan `pubspec.lock`.

> [!NOTE]
> Laporkan kerentanan lewat GitHub Issues. Lihat [`SECURITY.md`](SECURITY.md). Jangan sertakan secret atau data pribadi.

---

## Integrasi Berkelanjutan

| Workflow | Tujuan |
|----------|---------|
| `.github/workflows/ci.yml` | Analyze, tes, dan build Windows serta Android. |
| `.github/workflows/release.yml` | Build artefak dan terbitkan release draft pada tag `v*`. |

CI berjalan pada push ke `main` dan pada tag `v*`. Release dibuat hanya setelah CI hijau.

---

## FAQ

<details><summary><b>Apakah Niusic butuh internet?</b></summary>

Tidak. v0.1.0 hanya memutar file lokal. Aplikasi ini tidak melakukan panggilan jaringan.

</details>

<details><summary><b>Di mana data saya disimpan?</b></summary>

Di perangkat kamu, memakai SharedPreferences. Tidak ada sinkronisasi dan tidak ada akun.

</details>

<details><summary><b>Bisakah saya streaming musik sekarang?</b></summary>

Tidak. Streaming belum ada pada v0.1.0. Fitur ini direncanakan untuk rilis berikutnya.

</details>

<details><summary><b>File apa saja yang didukung?</b></summary>

Format yang didukung mesin pemutar perangkat kamu, seperti MP3, M4A, WAV, dan OGG. Pakai filter audio pada pemilih file sistem.

</details>

---

## Penulis

<div align="center">

| [![Nicolas Dwi Dharma](https://github.com/nekonaru.png?size=100)](https://github.com/nekonaru) |
|:---:|
| **Nicolas Dwi Dharma** |
| [github.com/nekonaru](https://github.com/nekonaru) |

</div>

---

## Penanggung Jawaban

Niusic memutar file yang sudah kamu miliki atau sudah ada di perangkat kamu. Kamu bertanggung jawab atas file musik yang kamu tambah dan putar. Niusic tidak menyediakan, menghost, atau mendistribusikan musik.

---

## Lisensi

Didistribusikan di bawah **Lisensi MIT**. Lihat [`LICENSE`](LICENSE) untuk informasi lebih lanjut.
