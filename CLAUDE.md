# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter mobile app for the Recall API. Targets iOS and Android. Package ID: `com.recall.mobile`.

## Commands

All Flutter commands must use FVM (`fvm flutter ...`).

```bash
# Setup
fvm install && fvm flutter pub get

# Run (dev has hardcoded defaults; staging/prod require --dart-define URLs)
fvm flutter run -t lib/main_dev.dart
fvm flutter run -t lib/main_staging.dart --dart-define=API_BASE_URL=... --dart-define=OPENAPI_SPEC_URL=...

# Quality checks (CI runs all three on every PR)
dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test

# Run a single test file
fvm flutter test test/config/app_config_test.dart
```

## Architecture

**Stack**: Riverpod (state) + GoRouter (navigation) + Dio (HTTP) — no code generation.

**Entrypoints**: `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart`. Each calls `AppConfig.fromDartDefines()` with environment-specific `--dart-define` values (`APP_ENV`, `API_BASE_URL`, `OPENAPI_SPEC_URL`, `LOG_HTTP`). Dev has defaults; staging/prod throw `AppConfigException` if URLs are missing.

**Providers** (`lib/src/app/providers.dart`): All dependency injection flows through Riverpod. `appConfigProvider` is overridden at startup in `ProviderScope`. Other providers (`dioProvider`, `tokenStoreProvider`, `openApiRepositoryProvider`) derive from it. Tests override providers via `ProviderScope.overrides`.

**Routing** (`lib/src/app/router.dart`): GoRouter with a `ShellRoute` wrapping all screens in `HomeScreen` (bottom nav). Routes: `/api` (API spec viewer), `/settings` (config display + token management).

**Network** (`lib/src/network/dio_provider.dart`): Dio client with auth interceptor (Bearer token from `TokenStore`) and optional HTTP logging. 15-second timeouts.

**Auth** (`lib/src/auth/token_store.dart`): `SecureTokenStore` (FlutterSecureStorage) for production, `InMemoryTokenStore` for tests.

**Features**: Each feature lives in `lib/src/features/<name>/` with its screen widget. Screens use `ConsumerWidget` or `ConsumerStatefulWidget`.

## Conventions

- Wire new features through Riverpod providers in `lib/src/app/providers.dart`.
- Add new routes to `lib/src/app/router.dart` and navigation items to `HomeScreen`.
- Place tests mirroring `lib/src/` structure under `test/`.
- No codegen (build_runner, freezed, json_serializable) — manual JSON parsing and const constructors.
- Keep staging/prod configuration strict; never add implicit placeholder URLs.
