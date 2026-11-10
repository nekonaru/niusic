# Feature Gap Analysis

Date: 2026-11-10. Comparison: Niusic v1.1.0 against Auralys (Android Kotlin/Metrolist fork and Windows JavaFX).

## Implemented

- **Background media notification.** Android shows play/pause, skip, seek, and stop in the media notification. Windows runs without it.
- **Local library.** Import local audio files, search, play.
- **Online search and playback.** YouTube search via Piped, audio via Googlevideo manifest.
- **Queue, playlists, history.** Queue persists across restarts.
- **Downloads.** Save YouTube audio to disk, play offline, delete, clear all.
- **Lyrics.** LRCLIB plain lyrics.
- **Radio.** Related streams from Piped, fallback to search.
- **Chart.** Deezer daily chart on Home.
- **Sleep timer, volume, quality, speed, shuffle, repeat.**
- **Channel browse.** Open a channel from search, see banner, avatar, subscribers, uploads.
- **Online playlists.** Search, open, play, or save as a local playlist.
- **Search suggestions.** YouTube suggest endpoint.
- **Themes.** Light, dark, system, plus 4 accent colors.
- **Adaptive UI.** Sidebar desktop, bottom bar mobile, two-pane now playing.

## Not implemented

- **Discord presence and Listen Together.** Needs a Discord app registration and OAuth. Owner gives ideas only, no account walkthrough is allowed. Recorded as Open: needs account access. Code is safe without it: no tokens stored.
- **Song recognition.** Needs a recognition API key or microphone plus model. No public key-free endpoint was verified. Not implemented.
- **Android widgets.** Needs Kotlin AppWidget providers and native layout resources. Not implemented in Flutter-only build.
- **Equalizer and audio effects.** audioplayers has no EQ API. Needs native audio effects or a different engine. Not implemented.
- **YouTube Music library sync, subscriptions, likes, and comments.** Needs Google account OAuth and YouTube Data API key. Not implemented.

## Roadmap

1. Widgets via native Android providers.
2. Recognition provider behind an optional API key store.
3. EQ presets via native effects.
4. Discord presence behind an optional app registration.
