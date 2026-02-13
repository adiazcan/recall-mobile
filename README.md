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

### Environment Configuration

Create environment-specific `.env` files for easier configuration management:

```bash
# Copy the example and fill in your values
cp .env.example .env.dev

# Edit with your Entra ID credentials and API endpoints
nano .env.dev
```

See [.env.example](.env.example) for all available configuration options.

**📖 For detailed setup instructions**, including how to get Entra ID credentials from Azure Portal, see [ENVIRONMENT.md](ENVIRONMENT.md).

## Run

### Using .env files (Recommended)

```bash
./run.sh dev      # Development
./run.sh staging  # Staging
./run.sh prod     # Production
```

The script reads from `.env.dev`, `.env.staging`, or `.env.prod` respectively.

### Manual --dart-define (Alternative)

```bash
fvm flutter run -t lib/main_dev.dart
```

With optional overrides:

```bash
fvm flutter run -t lib/main_dev.dart \
  --dart-define=API_BASE_URL=https://your-api-host \
  --dart-define=OPENAPI_SPEC_URL=https://your-api-host/openapi/v1.json \
  --dart-define=ENTRA_CLIENT_ID=your-client-id \
  --dart-define=ENTRA_TENANT_ID=your-tenant-id \
  --dart-define=ENTRA_SCOPES="api://recall/Items.ReadWrite User.Read offline_access" \
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
