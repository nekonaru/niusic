<div align="center">

<h1>Niusic: Local Music Player</h1>
<p><b>Play local music on Android and Windows (Flutter) with library, queue, playlists, and history. Fully offline, no account.</b></p>

<a href="https://github.com/nekonaru/niusic/releases"><img src="https://img.shields.io/github/v/nekonaru/niusic?style=flat-square" alt="Release" /></a>
<a href="https://github.com/nekonaru/niusic/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/nekonaru/niusic/ci.yml?style=flat-square" alt="CI" /></a>
<img src="https://img.shields.io/badge/language-Flutter-02569B?style=flat-square" alt="Flutter" />
<img src="https://img.shields.io/badge/platform-Android%20%7C%20Windows-000000?style=flat-square" alt="Platform" />
<a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License" /></a>

</div>

<br />

**English** | [Bahasa Indonesia](README.id.md)

> [!NOTE]
> Niusic plays audio files that already exist on your device. It does not stream or download music.

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

Niusic stores only local data on the device: file paths, playlists, history, language, theme, and volume. It has no backend, no account, no analytics, and no network calls. Keep dependencies updated in `pubspec.yaml` and `pubspec.lock`.

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

No. v0.1.0 plays local files only. It makes no network calls.

</details>

<details><summary><b>Where is my data stored?</b></summary>

On your device, with SharedPreferences. There is no sync and no account.

</details>

<details><summary><b>Can I stream music yet?</b></summary>

No. Streaming is not in v0.1.0. It is planned for a later release.

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
