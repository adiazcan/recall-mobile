# Research: Recall Mobile MVP

**Phase 0 Output** | **Date**: 2026-02-10

## R1: Entra ID Authentication on Flutter

**Decision**: Use `msal_flutter` (Microsoft Authentication Library wrapper) for Entra ID sign-in, token acquisition, and silent token refresh.

**Rationale**: `msal_flutter` is the official community wrapper around MSAL iOS/Android SDKs. It handles the OAuth2/OIDC flow natively on each platform, including PKCE, redirect URI handling, token caching, and silent refresh. This is the standard approach for Entra ID on mobile.

**Alternatives considered**:
- `flutter_appauth` (generic OAuth2): Would work but lacks MSAL-specific features like Entra ID tenant discovery, B2C support, and Microsoft's built-in token cache. Requires more manual configuration.
- Custom WebView-based OAuth2: Not recommended — violates platform security guidelines and lacks silent refresh.

**Key integration notes**:
- Requires Entra app registration with mobile redirect URIs (`msauth://` scheme)
- iOS: Add URL scheme to Info.plist, configure broker support
- Android: Add redirect activity to AndroidManifest.xml, configure signature hash
- AppConfig needs: `entraClientId`, `entraTenantId`, `entraScopes`, `entraRedirectUri`
- Silent refresh via `acquireTokenSilent()` — falls back to interactive on failure

## R2: Share Sheet Integration (iOS + Android)

**Decision**: Use `receive_sharing_intent` package for receiving shared URLs from other apps, combined with platform-native share extension configuration.

**Rationale**: `receive_sharing_intent` is the most maintained Flutter plugin for handling incoming shared content. It supports both iOS Share Extensions and Android intent filters with a unified Dart API. The package handles app-started-from-share and app-already-running cases.

**Alternatives considered**:
- `share_handler`: Similar functionality but less community adoption.
- Manual platform channels: Maximum control but significant native code for both platforms. Overkill for URL-only sharing.

**Key integration notes**:
- iOS: Requires a Share Extension target in Xcode with `NSExtensionActivationSupportsWebURLWithMaxCount = 1` to filter for URLs only
- Android: Intent filter with `android.intent.action.SEND` and `text/plain` MIME type, with URL validation in Dart
- Listen to share stream on app startup and when app is in foreground
- Share sheet save screen reuses the same `SaveUrlScreen` widget with pre-filled URL

## R3: Image Thumbnail Loading and Caching

**Decision**: Use `cached_network_image` for loading and caching preview image thumbnails in the items list.

**Rationale**: Industry standard for Flutter image loading. Provides disk + memory caching, placeholder/error widgets, and fade-in animations. Handles concurrent loads efficiently for scrolling lists.

**Alternatives considered**:
- Manual Dio + `Image.memory`: No caching, poor scroll performance.
- `fast_cached_image`: Less mature, smaller community.

**Key integration notes**:
- Use with `CachedNetworkImageProvider` in list items for automatic cache management
- Configure max cache size appropriate for mobile (100MB default is fine)
- Provide placeholder and error widgets for missing/broken images

## R4: Local Caching Strategy

**Decision**: Use `SharedPreferences` (already a dependency) to cache last-loaded JSON responses for items list, collections, and tags.

**Rationale**: The spec requires minimal caching — only the last loaded state for offline viewing. SharedPreferences is already in the project and sufficient for storing serialized JSON strings. No need for a full database (Hive, Isar, SQLite) for this scope.

**Alternatives considered**:
- `hive` / `isar`: Full local database — overkill for caching last-loaded JSON. Adds complexity and dependencies.
- `sqflite`: SQL database — unnecessary for simple key-value JSON cache.
- Plain file storage: Works but SharedPreferences is simpler and already available.

**Key integration notes**:
- Cache keys: `cache_items_json`, `cache_collections_json`, `cache_tags_json`
- Write-through: Update cache on every successful API fetch
- Read on startup: Load cache first, then fetch fresh data (stale-while-revalidate pattern)
- No cache invalidation timer needed — always show cached, always fetch fresh

## R5: Infinite Scroll Pagination

**Decision**: Implement cursor/offset-based pagination in the items list provider using Riverpod `AsyncNotifier` with a scroll controller listener.

**Rationale**: The existing codebase uses simple `Provider` but pagination requires mutable state (current page, loading more flag, accumulated items). `AsyncNotifier` (or `StateNotifier`) fits this pattern while staying within Riverpod conventions.

**Alternatives considered**:
- `infinite_scroll_pagination` package: Adds a dependency for something achievable with a scroll controller and provider state.
- Manual scroll listener with `setState`: Doesn't integrate well with Riverpod's reactive model.

**Key integration notes**:
- Scroll controller detects when user is near bottom (e.g., 200px threshold)
- Provider maintains: items list, current page/cursor, hasMore flag, isLoadingMore flag
- Append new items to existing list on successful fetch
- Handle filter changes: reset pagination and reload from page 1

## R6: Dio Token Refresh Interceptor

**Decision**: Implement a `QueuedInterceptor` in Dio that intercepts 401 responses, performs silent token refresh via `AuthService`, and retries the original request.

**Rationale**: `QueuedInterceptor` serializes interceptor handling so that multiple concurrent 401s trigger only one refresh, then all queued requests retry with the new token. This prevents token refresh races.

**Alternatives considered**:
- Simple `Interceptor` with manual locking: More error-prone, doesn't handle concurrent requests cleanly.
- Dio retry packages (`dio_smart_retry`): Generic retry, doesn't handle auth-specific token refresh logic.

**Key integration notes**:
- On 401: Call `authService.refreshToken()` (which calls MSAL silent acquire)
- On refresh success: Update stored tokens, retry original request with new token
- On refresh failure: Clear tokens, emit unauthenticated state, reject request
- Use `QueuedInterceptorsWrapper` to serialize concurrent 401 handling

## R7: Navigation with Auth Guards

**Decision**: Use GoRouter's `redirect` mechanism to guard authenticated routes and redirect unauthenticated users to the onboarding screen.

**Rationale**: GoRouter already supports redirect guards natively. The router can watch the auth state provider and redirect accordingly. This is the established pattern in the Flutter/GoRouter ecosystem.

**Alternatives considered**:
- Wrapper widgets that check auth state: Scattered auth checks, harder to maintain.
- Navigator 2.0 manual guards: GoRouter already abstracts this.

**Key integration notes**:
- `refreshListenable` on the router watches auth state changes
- Redirect logic: if unauthenticated and not on `/onboarding`, redirect to `/onboarding`
- If authenticated and on `/onboarding`, redirect to `/inbox`
- Deep link preservation for share sheet: store pending URL before auth redirect
