# Tasks: Recall Mobile MVP

**Input**: Design documents from `/specs/001-recall-mobile-mvp/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Not explicitly requested in the feature specification. Test tasks are omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add new dependencies and create shared models/utilities needed across multiple user stories

- [X] T001 Add new dependencies to pubspec.yaml: msal_flutter, receive_sharing_intent, cached_network_image, url_launcher
- [X] T002 [P] Create Item model with ItemStatus enum and JSON serialization in lib/src/models/item.dart
- [X] T003 [P] Create Collection model with JSON serialization in lib/src/models/collection.dart
- [X] T004 [P] Create Tag model with JSON serialization in lib/src/models/tag.dart
- [X] T005 [P] Create PaginatedResponse generic wrapper with JSON parsing in lib/src/models/paginated_response.dart
- [X] T006 [P] Create reusable ErrorView widget with retry callback in lib/src/features/shared/error_view.dart
- [X] T007 [P] Create reusable EmptyState widget in lib/src/features/shared/empty_state.dart

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Auth service, API client, cache layer, and router — MUST be complete before ANY user story can be implemented

**Warning**: No user story work can begin until this phase is complete

- [X] T008 Extend AppConfig with Entra ID fields (entraClientId, entraTenantId, entraScopes, entraRedirectUri) and update fromDartDefines() in lib/src/config/app_config.dart
- [X] T009 Update main_dev.dart, main_staging.dart, main_prod.dart to pass new Entra ID dart-define defaults/requirements
- [X] T010 Create AuthService class wrapping msal_flutter with signIn(), signOut(), refreshToken(), and acquireTokenSilent() in lib/src/auth/auth_service.dart
- [X] T011 Create AuthState notifier (unauthenticated/loading/authenticated) as Riverpod AsyncNotifier in lib/src/auth/auth_state.dart
- [X] T012 Register authServiceProvider and authStateProvider in lib/src/app/providers.dart
- [X] T013 Update Dio interceptor in lib/src/network/dio_provider.dart to implement QueuedInterceptor with silent token refresh on 401 and retry
- [X] T014 Create typed ApiClient class wrapping Dio with methods for all /api/v1 endpoints (items CRUD, collections CRUD, tags list/create) in lib/src/network/api_client.dart
- [X] T015 Register apiClientProvider in lib/src/app/providers.dart
- [X] T016 Create CacheService using SharedPreferences for stale-while-revalidate caching of items, collections, and tags JSON in lib/src/cache/cache_service.dart
- [X] T017 Register cacheServiceProvider in lib/src/app/providers.dart
- [X] T018 Update GoRouter in lib/src/app/router.dart: add auth redirect guard (unauthenticated → /onboarding, authenticated → /inbox), add refreshListenable watching authState, add new routes (/onboarding, /inbox, /item/:id, /save, /collections, /settings)
- [X] T019 Update HomeScreen in lib/src/features/home/home_screen.dart: replace API/Settings tabs with Inbox/Collections/Settings tabs and add FAB for save URL action
- [X] T020 Update iOS Info.plist in ios/Runner/Info.plist: add URL scheme for MSAL redirect (msauth)
- [X] T021 Update Android AndroidManifest.xml in android/app/src/main/AndroidManifest.xml: add MSAL redirect activity and URL share intent filter

**Checkpoint**: Foundation ready — auth, API client, cache, routing, and platform config in place. User story implementation can now begin.

---

## Phase 3: User Story 1 — Sign In with Entra ID (Priority: P1) MVP

**Goal**: User can sign in via Entra ID, see the onboarding screen when unauthenticated, and be redirected to inbox after successful authentication. Session persists across app restarts. Sign out clears tokens.

**Independent Test**: Launch app → see onboarding → sign in → land on inbox with data. Restart app → skip sign-in. Sign out → return to onboarding.

### Implementation for User Story 1

- [X] T022 [US1] Create OnboardingScreen with Entra ID sign-in button that triggers authService.signIn() in lib/src/features/onboarding/onboarding_screen.dart
- [X] T023 [US1] Update SettingsScreen to add sign-out button that calls authService.signOut() and clears tokens in lib/src/features/settings/settings_screen.dart
- [X] T024 [US1] Wire OnboardingScreen into router at /onboarding route in lib/src/app/router.dart
- [X] T025 [US1] Verify auth redirect guard: unauthenticated users → /onboarding, authenticated users → /inbox, sign-out → /onboarding

**Checkpoint**: User Story 1 is fully functional — users can sign in, persist session, and sign out.

---

## Phase 4: User Story 2 — Browse Inbox and Filter Items (Priority: P1)

**Goal**: User sees a scrollable list of saved items with title, domain, excerpt, preview image, and status indicators. Filters by status/favorites/collection/tags work. Infinite scroll loads more items.

**Independent Test**: Sign in → inbox shows items sorted newest first → apply each filter → verify results narrow → scroll to bottom → more items load → empty state when no results.

### Implementation for User Story 2

- [X] T026 [P] [US2] Create InboxProviders with AsyncNotifier managing items list state, active filters, pagination cursor, and hasMore flag in lib/src/features/inbox/inbox_providers.dart
- [X] T027 [P] [US2] Create ItemCard widget displaying title, domain, excerpt, CachedNetworkImage thumbnail, favorite icon, and status indicator in lib/src/features/inbox/item_card.dart
- [X] T028 [US2] Create InboxScreen with ListView.builder, scroll controller for infinite scroll, filter bar (status/favorites/collection/tags dropdowns), and empty state in lib/src/features/inbox/inbox_screen.dart
- [X] T029 [US2] Wire InboxScreen into router at /inbox route and set as initial authenticated route in lib/src/app/router.dart
- [X] T030 [US2] Integrate CacheService into inbox providers: load cached items on startup, update cache on each successful fetch in lib/src/features/inbox/inbox_providers.dart

**Checkpoint**: User Story 2 is fully functional — inbox displays items with all filters and infinite scroll working.

---

## Phase 5: User Story 3 — View and Manage Item Details (Priority: P1)

**Goal**: User taps an item to see full details and can perform all actions: open in browser, favorite/unfavorite, archive/unarchive, edit tags, move to collection, delete with confirmation.

**Independent Test**: Tap item → see details → toggle favorite → archive → edit tags → move collection → delete with confirm → return to inbox with changes reflected.

### Implementation for User Story 3

- [X] T031 [P] [US3] Create TagPicker widget with existing tag selection and inline new tag creation in lib/src/features/shared/tag_picker.dart
- [X] T032 [P] [US3] Create ItemDetailProviders with single-item state, mutation methods (toggleFavorite, updateStatus, updateTags, moveCollection, delete) calling ApiClient in lib/src/features/item_detail/item_detail_providers.dart
- [X] T033 [US3] Create ItemDetailScreen displaying all item fields, open-in-browser via url_launcher, action buttons for favorite/archive/tags/collection/delete with confirmation dialog in lib/src/features/item_detail/item_detail_screen.dart
- [X] T034 [US3] Wire ItemDetailScreen into router at /item/:id route with item ID parameter in lib/src/app/router.dart
- [X] T035 [US3] Ensure item mutations in detail screen refresh the inbox list state (invalidate inbox provider or update item in-place) in lib/src/features/item_detail/item_detail_providers.dart

**Checkpoint**: User Story 3 is fully functional — all item detail actions work and reflect in the inbox.

---

## Phase 6: User Story 4 — Save a URL from Inside the App (Priority: P2)

**Goal**: User taps FAB/Add button to open a save URL form, enters a URL with optional collection/tags, saves, and sees it in inbox. Duplicate URLs show "already saved" with navigation to existing item. Validation prevents malformed URLs.

**Independent Test**: Tap Add → enter URL → save → item appears in inbox. Enter duplicate → see "already saved" message. Enter invalid URL → see validation error.

### Implementation for User Story 4

- [X] T036 [US4] Create SaveUrlScreen with URL text field, collection picker, TagPicker, save button, URL validation, duplicate handling (409 → show existing item link), and loading/error states in lib/src/features/save_url/save_url_screen.dart
- [X] T037 [US4] Wire SaveUrlScreen into router at /save route, triggered from HomeScreen FAB in lib/src/app/router.dart
- [X] T038 [US4] After successful save, refresh inbox items list and navigate back to inbox in lib/src/features/save_url/save_url_screen.dart

**Checkpoint**: User Story 4 is fully functional — in-app URL saving with validation and duplicate detection works.

---

## Phase 7: User Story 5 — Save a URL via OS Share Sheet (Priority: P2)

**Goal**: User shares a URL from any app to Recall via OS share sheet. Recall opens pre-filled save screen. If not signed in, auth flow preserves the shared URL.

**Independent Test**: From browser, share URL → Recall share target appears → save screen pre-filled → save → item in inbox. Test while signed out → auth then save.

### Implementation for User Story 5

- [X] T039 [US5] Create iOS Share Extension target with ShareViewController.swift and Info.plist configured for URL UTType only in ios/ShareExtension/
- [X] T040 [US5] Configure receive_sharing_intent plugin: add listener for incoming shared URLs on app startup and foreground resume in lib/src/app/app.dart
- [X] T041 [US5] Route shared URL to SaveUrlScreen with pre-filled URL parameter, handling both app-running and cold-start scenarios in lib/src/app/router.dart
- [X] T042 [US5] Handle unauthenticated share: store pending shared URL, complete auth flow, then navigate to SaveUrlScreen with preserved URL in lib/src/auth/auth_state.dart
- [X] T043 [US5] Update SaveUrlScreen to accept optional pre-filled URL parameter from share intent in lib/src/features/save_url/save_url_screen.dart

**Checkpoint**: User Story 5 is fully functional — share sheet integration works on both iOS and Android.

---

## Phase 8: User Story 6 — Manage Collections (Priority: P2)

**Goal**: User can view collections with item counts, create new collections, rename, and delete (items move to inbox on delete). Duplicate names are prevented.

**Independent Test**: Navigate to collections → see list with counts → create new → rename → delete with items → verify items moved to inbox.

### Implementation for User Story 6

- [X] T044 [P] [US6] Create CollectionsProviders with collections list state, create/rename/delete methods calling ApiClient in lib/src/features/collections/collections_providers.dart
- [X] T045 [US6] Create CollectionsScreen with list of collections showing name and item count, create/rename/delete actions with dialogs, duplicate name validation, and tap-to-view-items navigation in lib/src/features/collections/collections_screen.dart
- [X] T046 [US6] Wire CollectionsScreen into router at /collections route and into HomeScreen bottom nav tab in lib/src/app/router.dart
- [X] T047 [US6] Integrate CacheService into collections providers: cache collections list, load from cache on startup in lib/src/features/collections/collections_providers.dart

**Checkpoint**: User Story 6 is fully functional — full collections CRUD with cache works.

---

## Phase 9: User Story 7 — Cached Browsing and Error Handling (Priority: P3)

**Goal**: App shows cached items/collections/tags when offline. Network errors show clear messages with retry. No user input is lost on failure. App resumes normally when connectivity returns.

**Independent Test**: Load items online → go offline → reopen app → see cached items → attempt action → see error with retry → go online → retry succeeds.

### Implementation for User Story 7

- [X] T048 [US7] Integrate CacheService into tags provider: cache tags list on fetch, load from cache on startup in lib/src/app/providers.dart
- [X] T049 [US7] Add stale-while-revalidate pattern to all list providers: show cached data immediately, fetch fresh data in background, update UI on arrival in lib/src/features/inbox/inbox_providers.dart and lib/src/features/collections/collections_providers.dart
- [X] T050 [US7] Add consistent error handling to all mutation actions (save, delete, favorite, archive, tag edit, collection CRUD): show ErrorView with retry, preserve user input on failure in lib/src/features/item_detail/item_detail_screen.dart and lib/src/features/save_url/save_url_screen.dart
- [X] T051 [US7] Add network connectivity awareness: detect offline state and show a non-blocking indicator bar in lib/src/app/app.dart

**Checkpoint**: User Story 7 is fully functional — offline cache, error handling, and retry work across all screens.

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Final integration, cleanup, and validation

- [X] T052 Update existing widget_test.dart to work with new app structure (auth guard, new routes, new home tabs) in test/widget_test.dart
- [X] T053 Update existing app_config_test.dart to cover new Entra ID config fields in test/config/app_config_test.dart
- [X] T054 Remove or gate existing ApiScreen behind dev-only flag (not part of production nav) in lib/src/features/api/api_screen.dart and lib/src/app/router.dart
- [X] T055 Run dart format, flutter analyze, flutter test and fix any issues
- [X] T056 Validate full user journey: sign in → browse inbox → filter → view detail → favorite → archive → edit tags → move collection → save URL → share sheet → collections CRUD → sign out

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (T001 must complete first for new deps; T002-T007 can overlap with Phase 2)
- **User Stories (Phase 3-9)**: All depend on Phase 2 completion
  - US1 (Sign In): Can start immediately after Phase 2
  - US2 (Inbox): Can start after Phase 2; benefits from US1 for auth but testable with mock auth
  - US3 (Item Detail): Can start after Phase 2; benefits from US2 for navigation from inbox
  - US4 (Save URL): Can start after Phase 2; independent
  - US5 (Share Sheet): Depends on US4 (reuses SaveUrlScreen)
  - US6 (Collections): Can start after Phase 2; independent
  - US7 (Cache/Errors): Depends on US2 and US6 (adds caching to their providers)
- **Polish (Phase 10)**: Depends on all user stories being complete

### User Story Dependencies

```
Phase 2 (Foundational)
  ├── US1 (Sign In) ─────────────────────────────────┐
  ├── US2 (Inbox) ──────────── US3 (Item Detail)     │
  ├── US4 (Save URL) ────────── US5 (Share Sheet)    ├── Phase 10 (Polish)
  ├── US6 (Collections) ────────────────────────────  │
  └── US2 + US6 ─────────────── US7 (Cache/Errors) ──┘
```

### Parallel Opportunities

- **Phase 1**: T002, T003, T004, T005, T006, T007 can all run in parallel (different files)
- **Phase 2**: T020 and T021 can run in parallel (different platform files)
- **After Phase 2**: US1, US2, US4, US6 can all start in parallel (independent stories)
- **Within US2**: T026 and T027 can run in parallel
- **Within US3**: T031 and T032 can run in parallel
- **Within US6**: T044 can start before T045

---

## Parallel Example: Phase 1

```bash
# Launch all model and shared widget tasks together:
Task: "Create Item model in lib/src/models/item.dart"
Task: "Create Collection model in lib/src/models/collection.dart"
Task: "Create Tag model in lib/src/models/tag.dart"
Task: "Create PaginatedResponse in lib/src/models/paginated_response.dart"
Task: "Create ErrorView widget in lib/src/features/shared/error_view.dart"
Task: "Create EmptyState widget in lib/src/features/shared/empty_state.dart"
```

## Parallel Example: User Stories after Phase 2

```bash
# Launch independent user stories in parallel:
Task: US1 "Create OnboardingScreen" + US2 "Create InboxProviders" + US4 "Create SaveUrlScreen" + US6 "Create CollectionsProviders"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 + 3)

1. Complete Phase 1: Setup (models, deps, shared widgets)
2. Complete Phase 2: Foundational (auth, API client, cache, router, platform config)
3. Complete Phase 3: US1 — Sign In
4. Complete Phase 4: US2 — Browse Inbox
5. Complete Phase 5: US3 — Item Details
6. **STOP and VALIDATE**: Core read-later experience works end-to-end
7. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 (Sign In) → Auth works → Deploy/Demo (skeleton MVP)
3. Add US2 (Inbox) + US3 (Details) → Core browsing works → Deploy/Demo (functional MVP)
4. Add US4 (Save URL) + US5 (Share Sheet) → Content saving works → Deploy/Demo
5. Add US6 (Collections) → Organization works → Deploy/Demo
6. Add US7 (Cache/Errors) → Reliability improved → Deploy/Demo
7. Polish → Production-ready

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- The API contract (contracts/api-contract.md) is inferred — verify against actual backend OpenAPI spec before implementing ApiClient methods
