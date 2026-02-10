# Feature Specification: Recall Mobile MVP

**Feature Branch**: `001-recall-mobile-mvp`
**Created**: 2026-02-10
**Status**: Draft
**Input**: User description: "Mobile application (iOS + Android) for Recall - core MVP with authentication, inbox browsing, item management, collections, and OS share sheet integration"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sign In with Entra ID (Priority: P1)

A user opens the Recall mobile app for the first time and is presented with an onboarding screen. They tap "Sign in" and are directed through the Entra ID authentication flow. Upon successful authentication, they are redirected to their inbox. The app securely stores their session tokens so they remain signed in across app restarts until the session expires or they sign out.

**Why this priority**: Authentication is the gateway to all other functionality. Without sign-in, no other features are accessible since the backend requires authenticated requests with scopes.

**Independent Test**: Can be fully tested by launching the app, completing sign-in, and verifying the user lands on the inbox screen with their data loaded. Delivers value as the foundation for all API interactions.

**Acceptance Scenarios**:

1. **Given** the user is not signed in, **When** they open the app, **Then** they see the onboarding/sign-in screen with an option to sign in via Entra ID.
2. **Given** the user taps "Sign in", **When** they complete the Entra ID authentication flow, **Then** they are redirected to the inbox screen and their session tokens are stored securely.
3. **Given** the user has a valid stored session, **When** they reopen the app, **Then** they are taken directly to the inbox without re-authenticating.
4. **Given** the user's access token has expired, **When** they attempt any action, **Then** the system silently refreshes the token and completes the action without interruption.
5. **Given** the refresh token has also expired or been revoked, **When** silent refresh fails, **Then** the user is prompted to re-authenticate and returned to their previous context afterward.
6. **Given** the user wants to sign out, **When** they tap "Sign out" in settings, **Then** all stored tokens are cleared and they are returned to the sign-in screen.

---

### User Story 2 - Browse Inbox and Filter Items (Priority: P1)

A user views their saved items in a scrollable inbox list. Each item displays its title, source domain, a short excerpt, and a preview image thumbnail when available. Visual indicators show whether an item is favorited or archived. The user can filter the list by status (unread/archived), favorites, collection, or tags. The list loads more items automatically as the user scrolls down.

**Why this priority**: The inbox is the primary screen users interact with after signing in. Browsing saved items is the core value proposition of Recall.

**Independent Test**: Can be tested by signing in and verifying that saved items appear in the list with correct metadata, and that filtering narrows results as expected. Delivers value as the main content consumption interface.

**Acceptance Scenarios**:

1. **Given** the user is signed in and has saved items, **When** they navigate to the inbox, **Then** they see a list of items showing title, domain, excerpt snippet, and preview image (if available).
2. **Given** items exist with different statuses, **When** the user applies the "unread" filter, **Then** only unread items are displayed.
3. **Given** items exist with different statuses, **When** the user applies the "archived" filter, **Then** only archived items are displayed.
4. **Given** some items are favorited, **When** the user toggles the favorites filter, **Then** only favorited items are shown.
5. **Given** items belong to different collections, **When** the user selects a collection filter, **Then** only items in that collection are shown.
6. **Given** items have various tags, **When** the user selects one or more tags to filter by, **Then** only items matching all selected tags are shown.
7. **Given** more items exist than fit on one screen, **When** the user scrolls to the bottom of the list, **Then** additional items load automatically (infinite scroll).
8. **Given** the user has no saved items, **When** they view the inbox, **Then** they see a helpful empty state message encouraging them to save their first item.

---

### User Story 3 - View and Manage Item Details (Priority: P1)

A user taps on an item in the inbox to see its full details: title, excerpt, preview image, tags, and collection. From the detail view, they can open the original link in their device browser, toggle the favorite status, archive or unarchive the item, edit tags, move the item to a different collection, or delete the item (with a confirmation prompt).

**Why this priority**: Item detail management is essential for the core "read later" workflow. Users need to act on their saved items beyond just browsing.

**Independent Test**: Can be tested by tapping an item, verifying all detail fields display correctly, and performing each action (favorite, archive, edit tags, move collection, delete) to confirm state changes persist.

**Acceptance Scenarios**:

1. **Given** the user taps an item in the inbox, **When** the detail screen loads, **Then** they see the item's title, excerpt, preview image, tags, and collection.
2. **Given** the user is viewing item details, **When** they tap "Open in browser", **Then** the original URL opens in the device's default browser.
3. **Given** an unfavorited item, **When** the user taps the favorite toggle, **Then** the item is marked as favorited and the indicator updates immediately.
4. **Given** an unread item, **When** the user taps "Archive", **Then** the item status changes to archived and this is reflected in the inbox.
5. **Given** an archived item, **When** the user taps "Unarchive", **Then** the item status reverts to unread.
6. **Given** the user wants to change tags, **When** they tap "Edit tags", **Then** they can add or remove tags from the item and save changes.
7. **Given** the user wants to reorganize, **When** they tap "Move to collection", **Then** they can select a different collection and the item moves accordingly.
8. **Given** the user taps "Delete", **When** a confirmation dialog appears and they confirm, **Then** the item is permanently removed and they return to the inbox.
9. **Given** the user taps "Delete", **When** a confirmation dialog appears and they cancel, **Then** the item remains unchanged.

---

### User Story 4 - Save a URL from Inside the App (Priority: P2)

A user wants to save a new URL directly within the Recall app. They tap an "Add" or "Save URL" action, enter or paste a URL, optionally assign a collection and tags, and save. The item appears in their inbox after saving.

**Why this priority**: In-app saving is a key way users add content. It complements the share sheet but serves users who are already in the app.

**Independent Test**: Can be tested by opening the save URL flow, entering a valid URL, optionally tagging it, saving, and verifying it appears in the inbox.

**Acceptance Scenarios**:

1. **Given** the user is on the inbox screen, **When** they tap the "Add" action, **Then** a save URL screen appears with a URL input field.
2. **Given** the save URL screen is open, **When** the user enters a valid URL and taps "Save", **Then** the item is created and appears in their inbox.
3. **Given** the save URL screen is open, **When** the user enters a valid URL, selects a collection and adds tags, then taps "Save", **Then** the item is created with the selected collection and tags.
4. **Given** the user enters an invalid URL, **When** they tap "Save", **Then** they see a validation error and the item is not created.
5. **Given** a network error occurs during save, **When** the save fails, **Then** the user sees a clear error message with an option to retry.

---

### User Story 5 - Save a URL via OS Share Sheet (Priority: P2)

A user is browsing content in another app (browser, social media, etc.) and wants to save a URL to Recall. They use the OS share action and select Recall from the share targets. A compact save screen appears pre-filled with the shared URL. The user can optionally choose a collection and tags, then save. The item is saved to their Recall inbox without leaving the source app.

**Why this priority**: Share sheet integration is a critical mobile-specific feature that makes saving content frictionless. It differentiates the mobile experience from the web app.

**Independent Test**: Can be tested by sharing a URL from a browser to Recall, verifying the save screen appears pre-filled, saving with optional metadata, and confirming the item appears in the Recall inbox.

**Acceptance Scenarios**:

1. **Given** the user is in another app with a shareable URL, **When** they invoke the OS share sheet and select Recall, **Then** the Recall save screen opens with the URL pre-filled.
2. **Given** the Recall save screen is open via share sheet, **When** the user taps "Save" without modifying options, **Then** the item is saved to the default inbox.
3. **Given** the Recall save screen is open via share sheet, **When** the user selects a collection and adds tags before saving, **Then** the item is saved with the chosen metadata.
4. **Given** the user is not currently signed in to Recall, **When** they share a URL to Recall, **Then** they are prompted to sign in before saving, and the shared URL is preserved through the auth flow.
5. **Given** the share sheet is active on iOS, **When** the user interacts with the Recall share extension, **Then** it behaves consistently with iOS share extension conventions.
6. **Given** the share sheet is active on Android, **When** the user interacts with the Recall share intent, **Then** it behaves consistently with Android share intent conventions.

---

### User Story 6 - Manage Collections (Priority: P2)

A user wants to organize their saved items into collections. They can view a list of all collections with item counts, create new collections, rename existing ones, and delete collections. When a collection is deleted, its items are moved back to the inbox rather than being lost.

**Why this priority**: Collections are a primary organizational tool. Without them, users cannot categorize their saved content meaningfully.

**Independent Test**: Can be tested by navigating to collections, creating a new collection, renaming it, moving items into it, deleting it, and verifying items return to the inbox.

**Acceptance Scenarios**:

1. **Given** the user navigates to the collections screen, **When** collections exist, **Then** they see a list of collections with the number of items in each.
2. **Given** the user taps "Create collection", **When** they enter a name and confirm, **Then** a new empty collection is created and appears in the list.
3. **Given** the user selects an existing collection, **When** they choose "Rename" and enter a new name, **Then** the collection name is updated everywhere it appears.
4. **Given** the user selects a collection with items, **When** they choose "Delete" and confirm, **Then** the collection is removed and all its items are moved to the inbox.
5. **Given** the user tries to create a collection with a duplicate name, **When** they submit, **Then** they see a validation message indicating the name is already in use.
6. **Given** the user selects a collection, **When** they tap it, **Then** they see the items belonging to that collection.

---

### User Story 7 - Cached Browsing and Error Handling (Priority: P3)

A user opens the app with poor or no network connectivity. They can still view previously loaded items, collections, and tags from a local cache. When network-dependent actions fail, the user sees clear error messages with retry options. The app recovers gracefully when connectivity is restored.

**Why this priority**: While full offline editing is out of scope, basic caching and graceful error handling are essential for a reliable mobile experience where connectivity varies.

**Independent Test**: Can be tested by loading items with connectivity, then disabling the network and verifying cached content is still viewable, and that network actions show appropriate error messages with retry options.

**Acceptance Scenarios**:

1. **Given** the user has previously loaded their inbox, **When** they open the app without network connectivity, **Then** they see the last cached items list.
2. **Given** the user has previously loaded collections and tags, **When** they open the app without network, **Then** cached collections and tags are available for browsing.
3. **Given** a network request fails, **When** the user sees an error, **Then** the error message is clear and includes a "Retry" option.
4. **Given** the user is performing an action that requires network (save, delete, etc.), **When** it fails, **Then** the user is informed and the app does not lose their input or context.
5. **Given** the network was unavailable, **When** connectivity is restored, **Then** the app can resume normal operations without requiring a restart.

---

### Edge Cases

- When the user saves a duplicate URL, the system displays an "already saved" message and offers to navigate to the existing item. No duplicate is created.
- How does the app handle a URL that cannot be fetched or parsed by the backend (e.g., paywalled content, dead link)?
- When the user's token expires mid-action, the system silently refreshes the token and retries the request. If refresh fails, the user is prompted to re-authenticate and the in-progress action is preserved for retry after sign-in.
- The share sheet uses platform-level content type filtering (iOS UTType / Android intent filter) so that Recall only appears as a share target for URL content. Non-URL content (plain text, images) will not show Recall as an option.
- How does the app handle very long item titles or excerpts in list and detail views?
- What happens when the user rapidly taps favorite/archive toggles (debounce/throttle)?
- What happens when a collection is deleted while another user (on web) is simultaneously adding items to it?
- How does the app handle the case where the backend returns a paginated list with zero results after a filter change?

## Requirements *(mandatory)*

### Functional Requirements

**Authentication**
- **FR-001**: System MUST allow users to sign in using Entra ID with appropriate scopes for the backend.
- **FR-002**: System MUST securely store authentication tokens in the device's secure storage mechanism.
- **FR-003**: System MUST NOT log or expose authentication tokens in any output.
- **FR-004**: System MUST attempt silent token refresh using the stored refresh token when the access token expires. Only if the refresh fails MUST the system prompt the user to re-authenticate.
- **FR-005**: System MUST provide a sign-out option that clears all stored tokens and returns to the sign-in screen.

**Inbox / Items List**
- **FR-006**: System MUST display saved items in a scrollable list with title, source domain, excerpt snippet, and preview image thumbnail (when available), sorted by save date descending (newest first).
- **FR-007**: System MUST show visual indicators for favorite status and item status (unread/archived) on each list item.
- **FR-008**: System MUST support filtering items by status (unread/archived), favorites, collection, and tag(s).
- **FR-009**: System MUST support infinite scroll pagination for the items list.
- **FR-010**: System MUST display an empty state when no items match the current filters.

**Item Details**
- **FR-011**: System MUST display item details including title, excerpt, preview image, tags, and collection.
- **FR-012**: System MUST allow the user to open the original URL in the device's default browser.
- **FR-013**: System MUST allow the user to toggle the favorite status of an item.
- **FR-014**: System MUST allow the user to archive or unarchive an item.
- **FR-015**: System MUST allow the user to add and remove tags from an item by selecting from existing tags or creating new tags inline.
- **FR-016**: System MUST allow the user to move an item to a different collection.
- **FR-017**: System MUST allow the user to delete an item, with a confirmation prompt before deletion.

**Save URL**
- **FR-018**: System MUST allow the user to save a new URL from within the app with optional collection and tag assignment.
- **FR-019**: System MUST validate that the entered URL is a well-formed URL before attempting to save.
- **FR-019a**: When saving a URL that already exists, the system MUST display an "already saved" notification and offer navigation to the existing item without creating a duplicate.

**Share Sheet**
- **FR-020**: System MUST register as a share target on both iOS and Android for URL content types only, using platform-level content filtering so Recall does not appear for non-URL shares.
- **FR-021**: System MUST present a save screen pre-filled with the shared URL when invoked via share sheet.
- **FR-022**: System MUST allow the user to optionally select a collection and tags before saving via share sheet.
- **FR-023**: System MUST handle the case where the user is not signed in when a share is received by prompting authentication and preserving the shared URL.

**Collections**
- **FR-024**: System MUST display a list of collections with item counts.
- **FR-025**: System MUST allow the user to create a new collection with a unique name.
- **FR-026**: System MUST allow the user to rename an existing collection.
- **FR-027**: System MUST allow the user to delete a collection, moving all its items to the inbox.
- **FR-028**: System MUST prevent creating collections with duplicate names.

**Caching and Error Handling**
- **FR-029**: System MUST cache the most recently loaded items list, collections, and tags for display when offline.
- **FR-030**: System MUST display clear error messages with retry options when network requests fail.
- **FR-031**: System MUST not lose user input or context when a network action fails.

**Configuration**
- **FR-032**: System MUST support multiple environment configurations (development, production) with separate backend endpoints and authentication settings.

### Key Entities

- **Item**: A saved URL with associated metadata — title, excerpt, preview image URL, source domain, status (unread/archived), favorite flag, tags, and collection assignment.
- **Collection**: A named group for organizing items. Has a unique name and an item count. Deleting a collection returns its items to the inbox.
- **Tag**: A label that can be applied to items for filtering and categorization. Items can have multiple tags.
- **User Session**: Represents the authenticated user's state including identity tokens and access scopes. Stored securely on device.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete sign-in and reach the inbox in under 30 seconds on first launch.
- **SC-002**: Users can save a URL via share sheet in under 5 seconds (from share action to confirmed save).
- **SC-003**: The items list scrolls smoothly at 60 frames per second with image thumbnails loading progressively.
- **SC-004**: 100% of item management actions (favorite, archive, delete, tag edit, collection move) are reflected in the UI within 2 seconds of user action.
- **SC-005**: Cached content is viewable within 1 second of app launch when no network is available.
- **SC-006**: All network errors present a user-friendly message with a retry option — no raw error codes or blank screens.
- **SC-007**: The share sheet integration is available as a share target on both iOS and Android after app installation.
- **SC-008**: Users can browse, filter, and manage items across all defined filters (status, favorites, collection, tags) without needing to reload the app.

## Clarifications

### Session 2026-02-10

- Q: What should the user experience be when saving a duplicate URL? → A: Show "already saved" message with link to existing item — no duplicate created.
- Q: What should happen when the share sheet receives non-URL content? → A: Hide Recall from the share sheet entirely for non-URL content types via platform filtering.
- Q: Should the app attempt silent token refresh before prompting re-authentication? → A: Yes — use refresh token automatically; only prompt sign-in if refresh fails.
- Q: What is the default sort order for the inbox items list? → A: Newest first — most recently saved items at the top.
- Q: How should tag editing work — select existing only, or also create new tags inline? → A: Select from existing tags plus create new tags inline.

## Assumptions

- The backend API at `/api/v1` is stable and provides all endpoints needed for items, tags, collections, and authentication as described.
- Entra ID authentication supports mobile redirect URIs and the required scopes are pre-configured on the backend.
- The backend handles duplicate URL detection and returns appropriate responses when a duplicate is saved.
- Preview image URLs returned by the backend are publicly accessible and suitable for mobile image loading.
- Pagination is cursor-based or offset-based as provided by the existing backend API.
- Tag filtering uses AND logic (items must match all selected tags) consistent with the web app behavior.
- The web app (React) serves as the reference implementation for UI behavior and API contract.
- The app skeleton, navigation structure, and state management baseline already exist in this repository and will be extended.

## Dependencies

- **recall-core Backend API**: All data operations depend on the existing `/api/v1` endpoints being available and documented.
- **Entra ID Service**: Authentication depends on Entra ID availability and correct tenant/app registration configuration.
- **App Store / Play Store**: Share sheet registration requires proper platform configuration in iOS Info.plist and Android manifest.

## Out of Scope

- Full offline editing (creating/modifying items while offline with sync on reconnect).
- Search functionality (text search across items).
- Push notifications.
- Item content reader view (reading articles within the app).
- Bulk operations (multi-select delete, archive, tag).
- User profile management or account settings beyond sign-in/sign-out.
- Analytics or usage tracking.
- Dark mode / theme customization.
- Tablet-optimized layouts.
