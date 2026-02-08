# Recall Mobile

Flutter mobile app bootstrap for Recall.

## Prerequisites

- Flutter SDK managed with FVM
- iOS/Android toolchains for local simulator/emulator runs

## Setup

```bash
fvm install
fvm flutter pub get
```

## Run (dev)

```bash
fvm flutter run -t lib/main_dev.dart
```

With optional overrides:

```bash
fvm flutter run -t lib/main_dev.dart \
  --dart-define=API_BASE_URL=https://your-api-host \
  --dart-define=OPENAPI_SPEC_URL=https://your-api-host/openapi/v1.json \
  --dart-define=LOG_HTTP=true
```

## Other entrypoints

```bash
fvm flutter run -t lib/main_staging.dart \
  --dart-define=API_BASE_URL=https://staging-host \
  --dart-define=OPENAPI_SPEC_URL=https://staging-host/openapi/v1.json

fvm flutter run -t lib/main_prod.dart \
  --dart-define=API_BASE_URL=https://prod-host \
  --dart-define=OPENAPI_SPEC_URL=https://prod-host/openapi/v1.json
```

## Local quality checks

```bash
fvm flutter analyze
fvm flutter test
dart format --set-exit-if-changed .
```
