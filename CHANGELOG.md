# Changelog

## v1.5.0

Redesigns the app UI for a cleaner, more consistent feel on Android and Windows.

### New features

- **Refreshed theme.** Material 3 theme with rounded cards, calmer navigation, and a clearer accent seed.

### Improvements

- **Home screen.** Added a now playing hero card, section headers with icons, horizontal chart row, and grouped recent/downloads in cards.
- **Now Playing.** Large artwork with drop shadow, centered gradient backdrop, calmer typography, accent-aware controls.
- **Settings.** Clear section labels, same grouped layout as the rest of the app.
- **Mini player.** Rounded floating mini player with tinted progress affordance feel.

## v1.4.0

Implements the Android runtime fixes and hardens app startup.

### New features

- **Notification permission request.** MainActivity now asks for POST_NOTIFICATIONS on Android 13+, so media notifications show up.
- **Audio service activity.** MainActivity now extends AudioServiceActivity, the base audio_service recommends.

### Improvements

- **Startup resilience.** If loading local data throws, Niusic opens anyway and shows the error on the home screen instead of hanging on the progress spinner. The home tabs are always usable.

## v1.3.0

Adds desktop keyboard control and image decode memory tuning.

### New features

- **Desktop keyboard control.** Space toggles play/pause, arrows seek and change volume, Ctrl+arrows skip tracks.

### Improvements

- **Image cache.** Network images use decode cacheWidth so thumbnails and banners use less memory.
- **Optimization pass.** Analyzed and removed an unused import. Tests and analyze are clean.

## v1.2.1

Lyrics screen now follows the song when timed lyrics are available.

### New features

- **Synced lyrics.** When LRCLIB has timed lyrics, the screen highlights the current line and scrolls to it automatically. Plain lyrics still show as before.

## v1.2.0

Adds an Android home screen widget for now playing.

### New features

- **Home screen widget.** Shows the current title and artist with previous, play/pause, and next buttons. Tapping the cover art or title opens Niusic.
- **Widget updates.** Niusic writes the widget state to SharedPreferences on every playback change and notifies the widget to rebind.

### Improvements

- **Android manifest.** Registers the widget receiver and keeps the media service and button receiver from v1.1.0.

## v1.1.0

Adds OS media notification controls on Android so Niusic can keep playing in the background.

### New features

- **Media notification.** Android shows title, artist, play/pause, skip next, skip previous, stop, and seek in the notification while music plays.

### Improvements

- **Notification state.** App pushes queue, play state, position, and media item to the OS notification on every state change.
- **Windows unaffected.** On Windows the notification handler is not registered; the app runs as before.
- **Android manifest.** Foreground service and media button receiver are declared with the mediaPlayback foreground type.

## v1.0.0

Stable first release. Local and online playback, downloads, lyrics, radio, chart, and adaptive desktop and mobile UI.

### Improvements

- **Queue persistence.** The queue order and play position survive restarts.
- **Storage management.** Settings shows download size and clears all downloads.
- **Release artifacts.** CI verifies APK and zip assets exist before publishing.
- **Safety.** Remote playback resolves a fresh audio URL per track and falls back when one source fails.

## v0.8.0

Adds online playlists, queue persistence, and storage management.

### New features

- **Online playlists.** Search now shows online playlists. Open one, play it, or save it as a local playlist.
- **Queue persistence.** The queue order and play position survive app restarts.
- **Storage overview.** Download sizes are available through `totalDownloadBytes` and `clearDownloads`.

## v0.7.0

Adds channel browse, search suggestions, playback speed, and accent themes. Also fixes related radio and documents remaining gaps.

### New features

- **Channel browse.** Open any channel from search and see banner, avatar, subscribers, and uploads.
- **Search suggestions.** Tap a suggestion chip to search again instantly.
- **Playback speed.** Adjust 0.5x to 2.0x in Settings. The rate is saved.
- **Accent themes.** Pick indigo, teal, purple, or orange accent in Settings.
- **True radio.** Radio now prefers related streams for the current video, then falls back to search.

### Improvements

- **Gap analysis.** `docs/GAPS.md` lists which Auralys features are implemented and which need accounts or native code.

## v0.6.0

Makes the UI native to each device: a sidebar and two-pane now playing on desktop, and a bottom bar on mobile. Also fixes a queue lookup bug and tightens audio focus.

### New features

- **Desktop sidebar.** On tablet and desktop widths the app shows a NavigationRail with labels instead of a bottom bar.
- **Two-pane now playing.** On desktop, artwork sits beside the controls. On mobile they stack vertically.
- **Adaptive grids.** Library, search results, and Home chart switch from 1 column on mobile to 2 or 3 columns on wide screens.

### Improvements

- **Queue bug fix.** Tapping a library item now plays the track at its queue position, even after the queue is reordered.
- **Audio focus.** Android requests music audio focus before playback.
- **Responsive tests.** Added widget tests for narrow bottom-bar and wide rail layouts.

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
