# EcoAction

A local-first, offline-friendly Flutter Android app for personal climate action:

**UNDERSTAND → TAKE ACTION → RECORD → ESTIMATE IMPACT → BUILD HABITS → CREATE CHANGE**

Discover small real-world actions, log the ones you actually do, and see an
**estimated** CO2e impact - plus streaks, challenges, badges, and a
college/community leaderboard (currently labeled DEMO MODE).

## Status

- Phases 0-1 foundation and data/domain layer are in place (models, SQLite schema,
  repositories, content catalog).
- CO2e estimation engine and streak engine are in place.
- All emission factors are **PROVISIONAL** until the India-verification pass (Phase 2b).
- UI screens are built in subsequent phases.

## Local commands (require the Flutter SDK - builds happen in GitHub Actions)

```sh
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

> Do **not** build the APK on this device. The release APK is produced and uploaded
> as an artifact by GitHub Actions (`.github/workflows/build.yml`).

## Adding content without code changes

| File | Contains |
|------|----------|
| `assets/content/actions.json` | Action catalog (each action carries a provisional impact spec) |
| `assets/content/factors.json` | Emission factors (every factor carries source, version, uncertainty, status) |
| `assets/content/badges.json` | Badge definitions |
| `assets/content/challenges.json` | Challenge definitions |

## Scientific credibility

The phone cannot measure carbon. All figures are **estimates** built from
user-provided activity + documented emission factors. Every factor tracks its
source, version, uncertainty, and `provisional`/`verified` status. Values are
provisional until the India factor-verification research pass, and the UI will
always label estimates as estimates.