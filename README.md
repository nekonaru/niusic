<div align="center">

<img src="assets/niusic-mark.png" alt="Niusic logo" width="120" />

<h1>Niusic: Local and Online Music Player</h1>
<p><b>Play local and online music on Android and Windows (Flutter) with library, queue, playlists, YouTube search, downloads, lyrics, and radio. No account.</b></p>

<a href="https://github.com/nekonaru/niusic/releases"><img src="https://img.shields.io/github/v/nekonaru/niusic?style=flat-square" alt="Release" /></a>
<a href="https://github.com/nekonaru/niusic/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/nekonaru/niusic/ci.yml?style=flat-square" alt="CI" /></a>
<img src="https://img.shields.io/badge/language-Flutter-02569B?style=flat-square" alt="Flutter" />
<img src="https://img.shields.io/badge/platform-Android%20%7C%20Windows-000000?style=flat-square" alt="Platform" />
<a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License" /></a>

</div>

<br />

**English** | [Bahasa Indonesia](README.id.md)

> [!NOTE]
> Niusic plays your local files offline and streams YouTube videos online when you use the Stream tab. On Android 13+ it asks for notification permission only from Settings, not at first launch.

---

## Table of Contents

- [About](#about)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Display Language](#display-language)
- [Project Structure](#project-structure)
- [Development](#development)
- [Testing](#testing)
- [Security](#security)
- [Continuous Integration](#continuous-integration)
- [FAQ](#faq)
- [Author](#author)
- [Disclaimer](#disclaimer)
- [License](#license)

---

## About

Niusic is a local-first music player for Android and Windows. One Flutter codebase builds both apps. The app reads audio files from your device, keeps the library on the device, and plays them offline. Release builds use minified APKs and a zipped Windows exe.

> _"Your music stays on your device."_

---

## Features

### Playback

| Feature | Description |
|---------|-------------|
| **Play and pause** | Play a track, pause, resume, skip next or previous. |
| **Seek and volume** | Seek within a track and adjust volume. |
| **Shuffle and repeat** | Toggle shuffle and repeat off, all, or one. |
| **Queue** | Play the full library as a queue, in order. |

### Library

| Feature | Description |
|---------|-------------|
| **Import audio** | Pick multiple audio files with the system file picker. |
| **Search** | Filter the library by title text. |
| **History** | Keep the last 100 played tracks on the device. |

### Streaming

| Feature | Description |
|---------|-------------|
| **YouTube search** | Search YouTube videos from Piped instances with titles, channels, and thumbnails. |
| **Online playback** | Stream audio from YouTube, mixed in the same queue as local tracks. |
| **Queue and playlists** | Add online tracks to the queue or to any playlist. |
| **Background playback** | Android media notification: play/pause, skip, and seek while the app is closed. |
| **Android widget** | Home screen widget shows title and artist with play/pause, previous, and next. |
| **Keyboard control** | Play/pause with Space, seek and volume with arrows, skip tracks with Ctrl+arrows. Desktop only. |
| **Offline downloads** | Download audio to the device and play it without internet. |
| **Audio quality** | Pick low or high bitrate in Settings. |
| **Lyrics** | View plain lyrics from LRCLIB. When timed lyrics exist, the current line is highlighted and scrolls with the song. |
| **Daily chart** | See Deezer top tracks on Home and play them on YouTube. |
| **Radio** | Add related tracks for the current song to the queue. |
| **Sleep timer** | Pause after 15, 30, or 60 minutes. |
| **Adaptive UI** | Sidebar and two-pane player on desktop, bottom bar on mobile. |
| **Clean UI** | Rounded Material 3 cards, calm typography, and a clear accent seed across the app. |
| **Channel browse** | Open any channel from search and play its uploads. |
| **Suggestions** | See YouTube search suggestions as chips. |
| **Playback speed** | Set 0.5x to 2.0x in Settings. |
| **Accent themes** | Pick indigo, teal, purple, or orange accent. |
| **Online playlists** | Browse YouTube playlists, play them, or save them locally. |

### Organization

| Feature | Description |
|---------|-------------|
| **Playlists** | Create, rename in code, delete, add, and remove tracks locally. |
| **Settings** | Switch language, theme, volume, and clear local data. |

---

## Requirements

| Dependency | Minimum Version | Notes |
|------------|-----------------|-------|
| **Android** | 8.0 (API 26) | For the APK build. |
| **Windows** | 10 | For the Windows build. |
| **Flutter** | 3.47.0 | For building from source. |
| **Dart** | 3.13.0 | Included with Flutter. |

> [!TIP]
> Most users only need the ready install files from the latest Release. You do not need a terminal, Flutter, or Android Studio.

### Never used a terminal? Start here

<details><summary><b>Open a terminal on Windows or Android</b></summary>

1. On Windows, open the Start menu, type `powershell`, press Enter.
2. On Android, you do not need a terminal to install the APK.
3. Download the APK, open it, and follow the Android prompts.

</details>

---

## Installation

### Option A: Download the app (easiest)

1. Open the latest Release on GitHub.
2. Download `niusic-android-arm64-v8a-release.apk` for most modern phones, `niusic-android-armeabi-v7a-release.apk` for older 32-bit phones, or `niusic-windows-x64.zip` for Windows.
3. On Android, open the APK and allow installs from your browser if asked.
4. On Windows, extract the zip and open `niusic.exe`.
5. Open Niusic and pick your music files.

> [!IMPORTANT]
> On Android, allow the file picker to read the audio files you choose. Niusic needs no other permission.

### Option B: Build from source (for development / to read or change the code)

#### 1. Get the code

<details><summary><b>I have Git installed</b></summary>

```bash
git clone https://github.com/nekonaru/niusic.git
cd niusic
```

</details>

<details><summary><b>I don't have Git</b></summary>

1. Open `https://github.com/nekonaru/niusic`.
2. Click Code, then Download ZIP.
3. Extract the zip, then open the extracted folder in a terminal.

</details>

#### 2. Install dependencies and verify

```bash
flutter pub get
```

> [!IMPORTANT]
> The command above must finish with no errors.

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

## Usage

### First launch

1. Open Niusic.
2. Tap Add music on the Home tab.
3. Pick audio files in the file picker.
4. Tap a track in the Library to play it.

> [!NOTE]
> Niusic stores file paths, playlists, history, and settings on this device only.

### Everyday use

- **Home:** See recent tracks and add more music.
- **Library:** Search and play the full library.
- **Stream:** Search online, tap to play, or add to queue or a playlist.
- **Playlists:** Create a playlist, then add tracks from the Library menu.
- **Settings:** Change language, theme, volume, or clear local data.
- **Mini player:** Tap the bottom track bar to open the full player.

---

## Display Language

1. Open the Settings tab.
2. Under Language, pick English or Bahasa Indonesia.
3. The UI switches right away and stays after restart.

---

## Project Structure

```
niusic
├── assets     # Niusic mark (SVG master and PNG header)
├── lib
│   ├── l10n     # English and Indonesian UI strings
│   ├── models   # Track and Playlist models
│   ├── screens  # Home, Library, Playlists, Settings, Now Playing
│   └── services # Playback and on-device storage
├── test         # Unit and widget tests
├── android      # Android app shell
├── windows      # Windows app shell
├── README.md    # English documentation
└── README.id.md # Indonesian documentation
```

---

## Development

### Adding a new user-facing string

1. Add the English text and the Indonesian text in `lib/l10n/app_strings.dart`.
2. Use the new getter in the screen that shows it.
3. Run `flutter analyze` and `flutter test`.

> [!WARNING]
> Do not edit files under `build/` or generated platform files by hand. Change Dart code and rerun Flutter commands.

---

## Testing

Run these commands before every push:

```bash
flutter analyze
flutter test
flutter build windows --release
```

| Check | Requirement |
|-------|-------------|
| **Analyze** | Zero issues. |
| **Tests** | All tests pass. |
| **Windows build** | Release build succeeds. |
| **Smoke test** | `flutter run -d windows` opens the app. |

Lint config lives in `analysis_options.yaml` with `prefer_single_quotes` and `sort_child_properties_last`.

---

## Security

Niusic stores only local data on the device: file paths, playlist entries, history, language, theme, and volume. It has no backend, no account, and no analytics. Online search talks only to public Piped instances over HTTPS and online playback streams from Googlevideo over HTTPS. No API keys or tokens are stored.

> [!NOTE]
> Report a vulnerability through GitHub Issues. See [`SECURITY.md`](SECURITY.md). Do not include secrets or personal data.

---

## Continuous Integration

| Workflow | Purpose |
|----------|---------|
| `.github/workflows/ci.yml` | Analyze, test, and build Windows and Android. |
| `.github/workflows/release.yml` | Build artifacts and publish a draft release on `v*` tags. |

CI runs on push to `main` and on `v*` tags. A release is created only after CI is green.

---

## FAQ

<details><summary><b>Does Niusic need internet?</b></summary>

Local playback works offline. Online search and playback need internet.

</details>

<details><summary><b>Where is my data stored?</b></summary>

On your device, with SharedPreferences. There is no sync and no account.

</details>

<details><summary><b>Can I stream music?</b></summary>

Yes. Open the Stream tab, search, and tap a result to play it online.

</details>

<details><summary><b>Which files are supported?</b></summary>

Formats your device playback engine supports, such as MP3, M4A, WAV, and OGG. Use the system file picker filter for audio.

</details>

---

## Author

<div align="center">

| [![Nicolas Dwi Dharma](https://github.com/nekonaru.png?size=100)](https://github.com/nekonaru) |
|:---:|
| **Nicolas Dwi Dharma** |
| [github.com/nekonaru](https://github.com/nekonaru) |

</div>

---

## Disclaimer

Niusic plays files you already own or have on your device. You are responsible for the music files you add and play. Niusic does not provide, host, or redistribute music.

---

## License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more information.
