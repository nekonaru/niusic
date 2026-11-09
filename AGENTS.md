# Project

| Variable | Value |
|----------|-------|
| `PROJECT_NAME` | `Niusic` |
| `REPO` | `nekonaru/niusic` |
| `AUTHOR_NAME` | `Nicolas Dwi Dharma` |
| `AUTHOR_GITHUB` | `nekonaru` |
| `PROJECT_KIND` | `app` |
| `STACK` | `Flutter (Dart)` |
| `PLATFORMS` | `Android, Windows` |
| `MIN_OS` | `Android 8.0 (API 26), Windows 10` |
| `DEFAULT_BRANCH` | `main` |
| `LICENSE` | `MIT` |
| `UI_LANGUAGES` | `English, Bahasa Indonesia` |
| `VERIFICATION` | `local-and-ci` |

## Rules

All work is done by AI. The owner gives ideas and confirms the project runs.

Keep English as the source. Indonesian is a translation. Update `README.md` first, then `README.id.md`, in the same commit. Update `CHANGELOG.md` and `CHANGELOG.id.md` together for releases.

No em dash and no en dash anywhere. No emoji in docs, README, changelog, or release notes. Never invent facts. Never commit secrets, keystores, `.env` files, or generated binaries.

Commit and push every change. Use `type: short description` under 72 characters. Verify with `git log origin/main --oneline -1` after each push.

Before every release, run the app security toolkit checks for `PROJECT_KIND` `app`. Keep `SECURITY_MAP.md`, `SECURITY_REVIEW.md`, and `SECURITY_REPORT.md` out of git with `.git/info/exclude`. Commit only `SECURITY.md`.

## Commands

- `flutter analyze`: must report zero issues.
- `flutter test`: all tests must pass.
- `flutter run -d windows`: one-command smoke test on Windows.
- `flutter run -d <android-device>`: one-command smoke test on Android.

## Layout

- `lib/models/`: data models only.
- `lib/services/`: playback and storage.
- `lib/screens/`: UI screens.
- `lib/l10n/app_strings.dart`: English and Indonesian UI strings.
- `test/`: unit and widget tests.
