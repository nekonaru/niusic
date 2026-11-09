# Changelog

## v0.5.0

Adds lyrics, daily chart, radio, and a sleep timer.

### New features

- **Lyrics.** A lyrics button in Now Playing loads plain lyrics from LRCLIB for the current track.
- **Daily chart.** Home shows the Deezer top tracks. Tap a tile to play it on YouTube.
- **Radio.** A radio button adds related YouTube tracks for the current song to the queue.
- **Sleep timer.** Pause playback after 15, 30, or 60 minutes, or turn it off.

## v0.4.0

Adds offline downloads, an audio quality choice, and a queue screen you can reorder and trim.

### New features

- **Offline downloads.** Download YouTube audio to the device and play it without internet. Manage downloads from Home.
- **Downloaded list and delete.** Home shows downloaded tracks. Tap to play or use the delete icon to free space.
- **Audio quality.** Choose low or high bitrate in Settings. The choice is saved on the device.
- **Queue screen.** A queue button in Now Playing opens a list you can drag to reorder and tap to remove.

### Improvements

- **Offline playback priority.** Downloaded tracks play from disk instead of the network.

## v0.3.0

Adds online search and playback, so Niusic now streams YouTube music like Auralys in addition to local files.

### New features

- **Online search.** Search YouTube videos from the Stream tab and see title, channel, and thumbnail.
- **Online playback.** Tap a result to stream its audio. Remote tracks join the queue, history, and playlists like local tracks.
- **Thumbnail display.** The Now Playing screen shows the video thumbnail when available.

### Improvements

- **Resilient search.** Search tries two public Piped instances in order, so one outage does not break the tab.
- **Cached audio URLs.** Resolved Googlevideo URLs are cached in memory for 1 hour.
- **Better errors.** Search and playback failures show a friendly message and keep existing playback intact.

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
