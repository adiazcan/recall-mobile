# Implementation Plan: Recall Mobile MVP

**Branch**: `001-recall-mobile-mvp` | **Date**: 2026-02-10 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-recall-mobile-mvp/spec.md`

## Summary

Build the core Recall mobile experience on the existing Flutter scaffold: Entra ID authentication with silent token refresh, inbox with filtering and infinite scroll, item detail management, collections CRUD, in-app and share sheet URL saving, and a minimal offline cache. The existing Riverpod + GoRouter + Dio architecture is extended with new providers, screens, models, and platform-specific share extension configuration.

## Technical Context

**Language/Version**: Dart 3.10.8+ / Flutter stable (pinned via FVM)
**Primary Dependencies**: flutter_riverpod 2.6.1, go_router 16.2.1, dio 5.9.0, flutter_secure_storage 9.2.4 (existing); adding: msal_flutter (Entra ID auth), receive_sharing_intent or share_handler (share sheet), cached_network_image (image thumbnails)
**Storage**: Flutter Secure Storage (tokens), SharedPreferences (local cache for items/collections/tags JSON)
**Testing**: flutter_test (widget), mocktail (mocking), integration_test (E2E)
**Target Platform**: iOS 15+ and Android API 24+ (phones)
**Project Type**: Mobile
**Performance Goals**: 60 fps list scrolling, <2s action feedback, <5s share-to-save flow, <30s first sign-in
**Constraints**: Tokens only in secure storage, no token logging, graceful offline fallback with cached data
**Scale/Scope**: ~6 screens, ~15 providers, ~32 functional requirements, single-user mobile app against existing backend

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution is a blank template (no project-specific principles defined). No gates to enforce. Proceeding.

**Post-Phase 1 re-check**: No violations. Architecture follows existing codebase conventions (Riverpod providers, GoRouter, Dio interceptors, feature-folder structure).

## Project Structure

### Documentation (this feature)

```text
specs/001-recall-mobile-mvp/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── api-contract.md  # Backend API contract mapping
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── main.dart                          # Delegates to main_dev.dart
├── main_dev.dart                      # Dev entrypoint (existing)
├── main_staging.dart                  # Staging entrypoint (existing)
├── main_prod.dart                     # Production entrypoint (existing)
└── src/
    ├── app/
    │   ├── app.dart                   # RecallApp widget (extend with auth guard)
    │   ├── router.dart                # GoRouter config (add auth redirect, new routes)
    │   └── providers.dart             # Root providers (add auth, items, collections, tags)
    ├── config/
    │   └── app_config.dart            # AppConfig (add Entra ID client ID, scopes, redirect URI)
    ├── auth/
    │   ├── token_store.dart           # TokenStore interface + impls (existing)
    │   ├── auth_service.dart          # NEW: Entra ID sign-in/sign-out/refresh orchestration
    │   └── auth_state.dart            # NEW: Auth state notifier (authenticated/unauthenticated/loading)
    ├── network/
    │   ├── dio_provider.dart          # Dio client (update: add token refresh interceptor)
    │   └── api_client.dart            # NEW: Typed API client wrapping Dio for /api/v1 endpoints
    ├── models/
    │   ├── item.dart                  # NEW: Item model
    │   ├── collection.dart            # NEW: Collection model
    │   ├── tag.dart                   # NEW: Tag model
    │   └── paginated_response.dart    # NEW: Generic paginated list wrapper
    ├── features/
    │   ├── onboarding/
    │   │   └── onboarding_screen.dart # NEW: Sign-in screen
    │   ├── inbox/
    │   │   ├── inbox_screen.dart      # NEW: Items list with filters + infinite scroll
    │   │   ├── inbox_providers.dart   # NEW: Items list state, filters, pagination
    │   │   └── item_card.dart         # NEW: List item widget
    │   ├── item_detail/
    │   │   ├── item_detail_screen.dart # NEW: Item details + actions
    │   │   └── item_detail_providers.dart # NEW: Single item state + mutations
    │   ├── save_url/
    │   │   └── save_url_screen.dart   # NEW: Save URL form (used by in-app + share sheet)
    │   ├── collections/
    │   │   ├── collections_screen.dart # NEW: Collections list
    │   │   └── collections_providers.dart # NEW: Collections state + CRUD
    │   ├── home/
    │   │   └── home_screen.dart       # Update: add inbox, collections tabs + FAB
    │   ├── settings/
    │   │   └── settings_screen.dart   # Update: add sign-out action
    │   ├── api/
    │   │   └── api_screen.dart        # Existing (may be removed or moved to dev-only)
    │   └── shared/
    │       ├── error_view.dart        # NEW: Reusable error + retry widget
    │       ├── empty_state.dart       # NEW: Reusable empty state widget
    │       └── tag_picker.dart        # NEW: Tag selection + inline creation widget
    ├── openapi/
    │   └── openapi_repository.dart    # Existing
    └── cache/
        └── cache_service.dart         # NEW: SharedPreferences-based JSON cache

test/
├── auth/
│   ├── token_store_test.dart          # Existing
│   ├── auth_service_test.dart         # NEW
│   └── auth_state_test.dart           # NEW
├── models/
│   ├── item_test.dart                 # NEW
│   ├── collection_test.dart           # NEW
│   └── tag_test.dart                  # NEW
├── features/
│   ├── inbox/
│   │   └── inbox_screen_test.dart     # NEW
│   ├── item_detail/
│   │   └── item_detail_screen_test.dart # NEW
│   ├── save_url/
│   │   └── save_url_screen_test.dart  # NEW
│   └── collections/
│       └── collections_screen_test.dart # NEW
├── network/
│   └── api_client_test.dart           # NEW
├── cache/
│   └── cache_service_test.dart        # NEW
├── config/
│   └── app_config_test.dart           # Existing
├── openapi/
│   └── openapi_repository_test.dart   # Existing
└── widget_test.dart                   # Update with new app structure

ios/
├── Runner/
│   └── Info.plist                     # Update: add URL scheme for Entra redirect
└── ShareExtension/                    # NEW: iOS Share Extension target
    ├── ShareViewController.swift      # Share extension entry point
    └── Info.plist                      # Extension config with URL UTType filter

android/
└── app/
    └── src/
        └── main/
            └── AndroidManifest.xml    # Update: add intent filter for URL sharing + Entra redirect
```

**Structure Decision**: Extends the existing Flutter mobile project structure. No new top-level projects needed. New code follows the established `lib/src/` convention with feature folders. Platform-specific share extension code lives in `ios/ShareExtension/` and Android manifest intent filters.

## Complexity Tracking

No constitution violations to justify.
