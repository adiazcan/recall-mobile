# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter mobile app for the Recall API. Targets iOS and Android. Package ID: `com.recall.mobile`.

## Commands

All Flutter commands must use FVM (`fvm flutter ...`).

```bash
# Setup
fvm install && fvm flutter pub get

# Run using .env files (recommended - see ENVIRONMENT.md)
./run.sh dev      # uses .env.dev
./run.sh staging  # uses .env.staging
./run.sh prod     # uses .env.prod

# Run manually with --dart-define (alternative)
fvm flutter run -t lib/main_dev.dart
fvm flutter run -t lib/main_staging.dart --dart-define=API_BASE_URL=... --dart-define=OPENAPI_SPEC_URL=... --dart-define=ENTRA_CLIENT_ID=... --dart-define=ENTRA_TENANT_ID=...

# Quality checks (CI runs all three on every PR)
dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test

# Run a single test file
fvm flutter test test/config/app_config_test.dart
```

## Configuration

**Environment files** (`.env.dev`, `.env.staging`, `.env.prod`): Store configuration including Entra ID credentials, API URLs, and feature flags. These files are gitignored. Use `.env.example` as a template. See [ENVIRONMENT.md](ENVIRONMENT.md) for detailed setup instructions.

**Runtime configuration**: `AppConfig.fromDartDefines()` reads `--dart-define` values (automatically populated from .env files by `run.sh` script). Required values: `ENTRA_CLIENT_ID`, `ENTRA_TENANT_ID`, `ENTRA_SCOPES`, `ENTRA_REDIRECT_URI`, `API_BASE_URL`, `OPENAPI_SPEC_URL`. Optional: `LOG_HTTP` (boolean).

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

## Active Technologies
- Dart 3.10.8+ / Flutter stable (pinned via FVM) + flutter_riverpod 2.6.1, go_router 16.2.1, dio 5.9.0, flutter_secure_storage 9.2.4 (existing); adding: msal_flutter (Entra ID auth), receive_sharing_intent or share_handler (share sheet), cached_network_image (image thumbnails) (001-recall-mobile-mvp)
- Flutter Secure Storage (tokens), SharedPreferences (local cache for items/collections/tags JSON) (001-recall-mobile-mvp)

## Recent Changes
- 001-recall-mobile-mvp: Added Dart 3.10.8+ / Flutter stable (pinned via FVM) + flutter_riverpod 2.6.1, go_router 16.2.1, dio 5.9.0, flutter_secure_storage 9.2.4 (existing); adding: msal_flutter (Entra ID auth), receive_sharing_intent or share_handler (share sheet), cached_network_image (image thumbnails)
