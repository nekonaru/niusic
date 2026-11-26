# Feature Gap Analysis

Date: 2026-11-26. Comparison: Niusic v7.0.0 against Auralys (Android Kotlin/Metrolist fork and Windows JavaFX).

## Implemented

- **Background media notification.** Android shows play/pause, skip, seek, and stop in the media notification. Windows runs without it.
- **Android home screen widget.** Shows title, artist, and previous/play/next buttons. Tapping artwork opens the app.
- **Local library.** Import local audio files, search, play. Android additionally auto-scans the device media database for music and picks up new files in real time via a content observer.
- **Online search and playback.** YouTube search via Piped, audio via Googlevideo manifest.
- **Queue, playlists, history.** Queue persists across restarts.
- **Downloads.** Save YouTube audio to disk, play offline, delete, clear all.
- **Lyrics.** LRCLIB lyrics, plain and timed. Timed lyrics highlight the active line and scroll with the song.
- **Radio.** Related streams from Piped, fallback to search.
- **Chart.** Deezer daily chart on Home.
- **Sleep timer, volume, quality, speed, shuffle, repeat.**
- **Channel browse.** Open a channel from search, see banner, avatar, subscribers, uploads.
- **Online playlists.** Search, open, play, or save as a local playlist.
- **Search suggestions.** YouTube suggest endpoint.
- **Themes.** Light, dark, system, plus 4 accent colors.
- **Equalizer.** Five-band equalizer and loudness enhancer via the AudioPipeline of just_audio (Android only). Set gains in dB, persisted, restored on next launch, applied live during playback.
- **Live internet radio.** Community radio from radio-browser.info. Search or browse top voted stations, tap to play. Streamed live via just_audio, stored in the queue and library, replays after restart.
- **Favorites.** The Favorites playlist is pinned at the top of Playlists. Heart buttons appear in the Library, in playlists, and in the Now Playing screen. Kept on the device.
- **Queue improvements.** Drag to reorder, save the queue as a playlist, and clear the queue. Duplicate queue keys cannot happen anymore (even with duplicate tracks).
- **Adaptive UI.** Sidebar desktop, bottom bar mobile, two-pane now playing.
- **Share.** Share the current track from Now Playing.
- **Most played.** On-device play counts, shown on Home.
- **Waveform seek bar.** Android local tracks show a real waveform bar in Now Playing. Tap or drag to seek. Falls back to the slider when extraction is not possible.
- **Library multi-select.** Long press to select multiple tracks, then add to queue, Favorites, or a playlist.
- **Full history and track details.** See all recently played tracks and inspect details (source, duration, play count, path) with play-next, favorite, and share actions.
- **Playlist management.** Rename, delete with confirmation, drag to reorder, play all or shuffle, with total duration shown.
- **Sleep timer fade out.** Volume drops gently in the last 10 seconds of the timer.

## Not implemented

- **Discord presence and Listen Together.** Needs a Discord app registration and OAuth. Owner gives ideas only, no account walkthrough is allowed. Recorded as Open: needs account access. Code is safe without it: no tokens stored.
- **Song recognition.** Needs a recognition API key or microphone plus model. No public key-free endpoint was verified. Not implemented.
- **YouTube Music library sync, subscriptions, likes, and comments.** Needs Google account OAuth and YouTube Data API key. Not implemented.

## Roadmap

1. Recognition provider behind an optional API key store.
2. EQ presets via native effects.
3. Discord presence behind an optional app registration.
