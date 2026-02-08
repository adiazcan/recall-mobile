# AGENTS.md

## Project Overview
- Name: `recall-mobile`
- App: Flutter mobile app for Recall
- Targets: iOS and Android
- Package/bundle id: `com.recall.mobile`
- Architecture: Riverpod + GoRouter + Dio

## Tooling
- Flutter SDK is pinned via FVM (`.fvm/fvm_config.json` -> `stable`)
- Use `fvm flutter ...` for all Flutter commands
- CI runs on GitHub Actions (`.github/workflows/flutter-ci.yml`)

## Common Commands
- Install SDK + deps:
  - `fvm install`
  - `fvm flutter pub get`
- Run app (dev):
  - `fvm flutter run -t lib/main_dev.dart`
- Run app (staging/prod with defines):
  - `fvm flutter run -t lib/main_staging.dart --dart-define=API_BASE_URL=... --dart-define=OPENAPI_SPEC_URL=...`
  - `fvm flutter run -t lib/main_prod.dart --dart-define=API_BASE_URL=... --dart-define=OPENAPI_SPEC_URL=...`
- Quality checks:
  - `dart format --set-exit-if-changed .`
  - `fvm flutter analyze`
  - `fvm flutter test`

## Runtime Configuration
`AppConfig.fromDartDefines()` reads:
- `APP_ENV` (`dev|staging|prod`)
- `API_BASE_URL`
- `OPENAPI_SPEC_URL`
- `LOG_HTTP` (`true|false`)

Defaults:
- `lib/main_dev.dart` sets dev defaults for API/OpenAPI URLs and `LOG_HTTP=true`
- `lib/main_staging.dart` and `lib/main_prod.dart` require explicit URLs

## Source Layout
- Entrypoints:
  - `lib/main.dart` (delegates to dev)
  - `lib/main_dev.dart`
  - `lib/main_staging.dart`
  - `lib/main_prod.dart`
- App shell/router/providers:
  - `lib/src/app/app.dart`
  - `lib/src/app/router.dart`
  - `lib/src/app/providers.dart`
- Config/network/auth:
  - `lib/src/config/app_config.dart`
  - `lib/src/network/dio_provider.dart`
  - `lib/src/auth/token_store.dart`
- Features:
  - `lib/src/features/api/api_screen.dart`
  - `lib/src/features/settings/settings_screen.dart`
  - `lib/src/features/home/home_screen.dart`
- OpenAPI access:
  - `lib/src/openapi/openapi_repository.dart`
- Tests:
  - `test/config/app_config_test.dart`
  - `test/auth/token_store_test.dart`
  - `test/openapi/openapi_repository_test.dart`
  - `test/widget_test.dart`

## Current Functional Scope
- Displays API and settings tabs
- Fetches OpenAPI spec JSON from configured URL
- Shows HTTP status and key OpenAPI fields (`openapi`, `info.title`, `info.version`)
- Provides token clear action via secure token store

## Notes for Future Agents
- Keep changes minimal and consistent with existing structure.
- Prefer wiring new features through Riverpod providers.
- Do not introduce codegen-based state/routing unless explicitly requested.
- Keep staging/prod configuration strict (no implicit placeholders in prod paths).
