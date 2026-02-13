# Quickstart: Recall Mobile MVP

**Phase 1 Output** | **Date**: 2026-02-10

## Prerequisites

- Flutter SDK via FVM (`fvm install`)
- Xcode 15+ (for iOS)
- Android Studio / Android SDK API 24+ (for Android)
- Entra ID app registration with mobile redirect URIs configured
- Access to recall-core backend (dev environment URL already hardcoded in `main_dev.dart`)

## Setup

```bash
# Clone and install
git checkout 001-recall-mobile-mvp
fvm install
fvm flutter pub get

# iOS: install CocoaPods dependencies
cd ios && pod install && cd ..
```

## Configuration

### Entra ID Setup

The app requires Entra ID configuration. You have two options:

#### Option 1: Using .env Files (Recommended)

1. Copy the example environment file:
   ```bash
   cp .env.example .env.dev
   ```

2. Edit `.env.dev` with your Azure app registration values:
   ```bash
   ENTRA_CLIENT_ID=your-client-id-here
   ENTRA_TENANT_ID=your-tenant-id-here
   ENTRA_SCOPES=api://recall-dev/Items.ReadWrite User.Read offline_access
   ENTRA_REDIRECT_URI=msauth://com.recall.mobile/callback
   ```

3. Run the app using the helper script:
   ```bash
   ./run.sh dev     # uses .env.dev
   ./run.sh staging # uses .env.staging
   ./run.sh prod    # uses .env.prod
   ```

#### Option 2: Manual --dart-define (Alternative)

If you prefer not to use .env files, pass configuration directly:

| Define             | Description                          | Example                               |
|--------------------|--------------------------------------|---------------------------------------|
| `ENTRA_CLIENT_ID`  | Entra app registration client ID     | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`|
| `ENTRA_TENANT_ID`  | Entra tenant ID                      | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`|
| `ENTRA_SCOPES`     | Space-separated API scopes           | `api://recall/Items.ReadWrite`        |
| `ENTRA_REDIRECT_URI`| Mobile redirect URI                 | `msauth://com.recall.mobile/callback` |

```bash
fvm flutter run -t lib/main_dev.dart \
  --dart-define=ENTRA_CLIENT_ID=your-client-id \
  --dart-define=ENTRA_TENANT_ID=your-tenant-id \
  --dart-define=ENTRA_SCOPES="api://recall/Items.ReadWrite User.Read offline_access" \
  --dart-define=ENTRA_REDIRECT_URI="msauth://com.recall.mobile/callback"
```

### iOS Share Extension

After implementing the share extension:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the ShareExtension target
3. Ensure the App Group is configured for shared storage between the main app and extension
4. The extension Info.plist filters for URL content via `NSExtensionActivationSupportsWebURLWithMaxCount`

### Android Share Intent

The AndroidManifest.xml intent filter is configured to receive `text/plain` intents. URL validation happens in Dart code after receiving the shared text.

## Quality Checks

```bash
# Format, analyze, test (same as CI)
dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test

# Run single test file
fvm flutter test test/auth/auth_service_test.dart

# Run tests with coverage
fvm flutter test --coverage
```

## Architecture Quick Reference

| Layer          | Location                        | Pattern                              |
|----------------|--------------------------------|--------------------------------------|
| Models         | `lib/src/models/`              | Immutable Dart classes, manual JSON  |
| Auth           | `lib/src/auth/`                | AuthService + AuthState notifier     |
| Network        | `lib/src/network/`             | Dio + typed ApiClient                |
| Cache          | `lib/src/cache/`               | SharedPreferences JSON cache         |
| Providers      | `lib/src/app/providers.dart`   | Riverpod Provider/AsyncNotifier      |
| Feature providers | `lib/src/features/*/`       | Co-located with feature screens      |
| Routing        | `lib/src/app/router.dart`      | GoRouter with auth redirect          |
| Screens        | `lib/src/features/*/`          | ConsumerWidget / ConsumerStatefulWidget |
| Shared widgets | `lib/src/features/shared/`     | Error, empty state, tag picker       |

## New Dependencies (to add)

```yaml
# pubspec.yaml additions
dependencies:
  msal_flutter: ^latest          # Entra ID authentication
  receive_sharing_intent: ^latest # Share sheet URL receiving
  cached_network_image: ^latest   # Image loading + caching
  url_launcher: ^latest           # Open URLs in browser
```
