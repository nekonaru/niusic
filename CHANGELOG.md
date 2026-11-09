# Changelog

## v0.2.1

Adds the Niusic Bars app icon on Android and Windows and shows it in the README header.

### New features

- **App icon.** Android launcher icons and Windows `app_icon.ico` now use the new Bars mark.
- **README logo.** The README header shows the new mark in both languages.

### Improvements

- **Brand asset.** The SVG master lives in `assets/niusic-mark.svg` with a PNG header image in `assets/niusic-mark.png`.

## v0.2.0

Adds a Windows exe package to the release and trims rebuild work, APK size, and disk writes during playback.

### New features

- **Windows exe package.** The release now ships `niusic-windows-x64.zip` with `niusic.exe` plus DLLs, alongside the Android APKs.
- **Two Android APKs.** The release now includes arm64-v8a and armeabi-v7a builds.

### Improvements

- **Faster playback UI.** Position updates notify the UI once per second instead of several times per second.
- **Faster library.** Library search and queue lookup use precomputed indexes instead of repeated linear scans.
- **Smaller APK.** Release builds enable minification and resource shrinking.
- **Fewer disk writes.** Settings are cached and volume changes are debounced for 300 ms.
- **Stable tabs.** Tabs use IndexedStack so switching tabs does not rebuild progress.

## v0.1.0

Local-first release with one Flutter codebase for Android and Windows. Plays music files on your device with library, queue, playlists, and history.

### New features

- **Local library.** Import audio files with the system file picker and search by title.
- **Playback controls.** Play, pause, skip, seek, volume, shuffle, and repeat.
- **Playlists.** Create, delete, add, and remove tracks on the device.
- **Home and mini player.** See recent tracks and open the full player from the bottom bar.
- **Bilingual UI.** Switch between English and Bahasa Indonesia in Settings.
- **Themes.** Use system, light, or dark theme.

### Improvements

- **Single codebase.** One Flutter project builds Android APK and Windows exe.
- **On-device storage.** Library paths, playlists, history, and settings stay on the device.
