# Security Policy

## Reporting a Vulnerability

Report security issues through GitHub Issues in this repository. Include a short description, the affected version, and steps to reproduce or observe the issue. Do not include secrets or personal data.

Niusic is a local-first app. It stores library paths, playlists, history, and settings on the device with SharedPreferences. It has no backend, no account, and no analytics.

## Scope

In scope: app code, build configuration, dependencies, and release pipeline.
Out of scope: third-party services, the user's own media files, and social engineering.

## Supported Versions

Only the latest stable release is supported. Fixes ship as a new release.

## Known limitations at v1.3.0

- Release APK and Windows zip are not code-signed with a private key. They install from a direct download on Android and as a portable exe on Windows.
- Online search uses public Piped instances and online playback uses Googlevideo URLs. Both can change or rate-limit.
- EQ/effects, Discord presence, YouTube Music sync, and song recognition are not implemented. See `docs/GAPS.md`.
- Media notification and home screen widget are Android-only. On Windows, the app runs without OS media controls or widget.
