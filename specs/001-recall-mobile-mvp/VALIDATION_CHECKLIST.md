# Validation Checklist: Recall Mobile MVP

**Purpose**: Manual testing checklist to validate all user stories work end-to-end.

**Prerequisites**:
- Dev backend running with valid API endpoints
- Entra ID tenant configured with valid client ID
- iOS Simulator or Android Emulator ready
- App built in dev mode: `fvm flutter run -t lib/main_dev.dart`

---

## ✅ Phase 10 Validation: Full User Journey

### US1: Sign In with Entra ID

- [ ] **Cold Start → Onboarding**
  - Launch app from scratch
  - Verify onboarding screen appears
  - See "Sign in with Microsoft" button
  
- [ ] **Sign In Flow**
  - Tap sign-in button
  - Entra ID web view loads
  - Enter credentials
  - Complete MFA if required
  - App redirects to inbox after success
  
- [ ] **Session Persistence**
  - Force quit app
  - Relaunch app
  - Verify app goes directly to inbox (no re-auth)
  
- [ ] **Sign Out**
  - Navigate to Settings tab
  - Tap "Sign Out" button
  - Verify return to onboarding screen
  - Verify tokens cleared (can't access API without re-auth)

---

### US2: Browse Inbox and Filter Items

- [ ] **Initial Load**
  - Inbox screen shows loading indicator
  - Items appear in reverse chronological order (newest first)
  - Each item card shows:
    - Title
    - Domain/source
    - Excerpt preview
    - Thumbnail image (if available)
    - Favorite icon (filled or outlined)
    - Status indicator (unread/read/archived)
  
- [ ] **Empty State**
  - If no items, see friendly empty state message
  - Message prompts to save first URL
  
- [ ] **Infinite Scroll**
  - Scroll to bottom of list
  - Loading indicator appears
  - Next page of items loads
  - Verify no duplicate items
  - Test until reaching end (no more items message)
  
- [ ] **Filter by Status**
  - Apply "Unread" filter → see only unread items
  - Apply "Read" filter → see only read items
  - Apply "Archived" filter → see only archived items
  - Clear filter → see all items
  
- [ ] **Filter by Favorites**
  - Toggle "Favorites only" → see only favorited items
  - Clear filter → see all items
  
- [ ] **Filter by Collection**
  - Select collection from dropdown
  - Verify only items from that collection appear
  - Clear filter → see all items
  
- [ ] **Filter by Tags**
  - Select one or more tags
  - Verify only items with those tags appear
  - Clear filters → see all items
  
- [ ] **Offline Cache**
  - Load inbox with network on
  - Turn off network (airplane mode)
  - Force quit and relaunch app
  - Verify cached items still display
  - Turn network back on
  - Verify fresh data loads in background

---

### US3: View and Manage Item Details

- [ ] **Navigate to Detail**
  - Tap any item card in inbox
  - Detail screen loads showing:
    - Full title
    - Source URL
    - Full content/excerpt
    - Large preview image
    - Tags list
    - Collection name
    - Favorite status
    - Read/archive status
    - Created/updated timestamps
  
- [ ] **Open in Browser**
  - Tap "Open in Browser" button
  - External browser launches with URL
  
- [ ] **Toggle Favorite**
  - Tap favorite icon → becomes favorited
  - Tap again → unfavorites
  - Return to inbox → verify favorite status reflected
  
- [ ] **Archive/Unarchive**
  - Tap "Archive" button → item archived
  - Return to inbox → item disappears (if not filtering archived)
  - Apply "Archived" filter → item appears
  - Tap item → tap "Unarchive" → returns to inbox
  
- [ ] **Edit Tags**
  - Tap "Edit Tags"
  - Tag picker modal opens
  - Select existing tags
  - Type new tag name → creates new tag
  - Save changes
  - Verify tags updated in detail view
  - Return to inbox → item shows new tags
  
- [ ] **Move to Collection**
  - Tap "Move to Collection"
  - Collection picker modal opens
  - Select different collection
  - Save
  - Verify collection updated in detail view
  - Navigate to Collections tab → verify item count updated
  
- [ ] **Delete Item**
  - Tap "Delete" button
  - Confirmation dialog appears
  - Cancel → nothing happens
  - Tap "Delete" again → confirm
  - Item deleted, return to inbox
  - Verify item no longer appears in inbox
  
- [ ] **Error Handling**
  - Turn off network
  - Try to favorite/archive/edit tags
  - Verify error message appears with retry button
  - Turn network back on
  - Tap retry → action succeeds

---

### US4: Save a URL from Inside the App

- [ ] **Open Save Screen**
  - From inbox or collections, tap FAB (+)
  - Save URL screen appears
  
- [ ] **Save New URL**
  - Enter valid URL (e.g., https://example.com)
  - Optionally select collection
  - Optionally add tags
  - Tap "Save"
  - Loading indicator appears
  - Success → return to inbox
  - New item appears at top of inbox
  
- [ ] **URL Validation**
  - Enter invalid URL (e.g., "not a url")
  - Tap "Save"
  - Verify validation error appears
  - Fix URL → save succeeds
  
- [ ] **Duplicate Detection**
  - Enter URL that already exists
  - Tap "Save"
  - See "Already saved" message
  - Link to existing item shown
  - Tap link → navigate to existing item detail
  
- [ ] **Offline Handling**
  - Turn off network
  - Try to save URL
  - Error message appears with retry
  - Turn network on
  - Tap retry → save succeeds

---

### US5: Save a URL via OS Share Sheet

**iOS**:
- [ ] **Share from Safari**
  - Open Safari, navigate to any webpage
  - Tap share button
  - Verify "Recall" appears in share sheet
  - Tap Recall → app opens with save screen pre-filled
  - Optionally edit collection/tags
  - Tap "Save" → item saved
  - Navigate to inbox → verify item appears

- [ ] **Share When Not Signed In**
  - Sign out from Recall
  - Share URL from Safari
  - App opens to onboarding
  - Complete sign-in
  - Save screen appears with pre-filled URL preserved
  - Save → item appears in inbox

- [ ] **Share When App Closed**
  - Force quit Recall
  - Share URL from Safari
  - App cold starts with save screen
  - Save → item appears in inbox

**Android**:
- [ ] **Share from Browser**
  - Open Chrome/Firefox, navigate to webpage
  - Tap share icon
  - Select "Recall" from share targets
  - App opens with save screen pre-filled
  - Save → item appears in inbox

- [ ] **Share When Not Signed In**
  - Sign out from Recall
  - Share URL from browser
  - App opens to onboarding
  - Complete sign-in
  - Save screen appears with preserved URL
  - Save → item appears in inbox

---

### US6: Manage Collections

- [ ] **View Collections List**
  - Navigate to Collections tab
  - See list of all collections
  - Each collection shows:
    - Collection name
    - Item count
  
- [ ] **Empty State**
  - If no collections, see empty state
  - Prompt to create first collection
  
- [ ] **Create Collection**
  - Tap "Create Collection" button
  - Dialog appears with text field
  - Enter collection name
  - Tap "Create"
  - New collection appears in list with 0 items
  
- [ ] **Duplicate Name Prevention**
  - Try to create collection with existing name
  - Verify error message appears
  - Change name → creation succeeds
  
- [ ] **Rename Collection**
  - Long-press or tap edit on collection
  - Rename dialog appears
  - Enter new name
  - Save
  - Verify collection name updated
  
- [ ] **Delete Collection**
  - Tap delete on collection
  - Confirmation dialog appears
  - Confirm deletion
  - Collection removed from list
  - Navigate to inbox
  - Verify items from deleted collection moved to inbox (no collection)
  
- [ ] **View Collection Items**
  - Tap on collection
  - Navigate to inbox with collection filter applied
  - See only items from that collection
  
- [ ] **Collection Cache**
  - Load collections
  - Turn off network
  - Force quit and relaunch
  - Verify cached collections display
  - Turn network on
  - Verify fresh data loads

---

### US7: Cached Browsing and Error Handling

- [ ] **Stale-While-Revalidate Pattern**
  - Load inbox with network on
  - Turn off network
  - Pull to refresh
  - Verify cached items still show (not blank screen)
  - See subtle "loading in background" indicator
  - Turn network back on
  - Fresh data loads without jarring UI change
  
- [ ] **Network Error Recovery**
  - Turn off network
  - Try any create/update/delete action
  - Error view appears with clear message
  - Retry button available
  - Turn network back on
  - Tap retry → action succeeds
  
- [ ] **User Input Preservation**
  - Fill out save URL form
  - Turn off network
  - Tap save → error appears
  - Verify form data NOT cleared
  - Turn network on
  - Tap retry → save succeeds without re-entering data
  
- [ ] **Connectivity Indicator**
  - Turn off network
  - Verify non-blocking offline indicator bar appears at top
  - Turn network on
  - Indicator disappears

---

## 🔧 Edge Cases & Polish

- [ ] **Deep Links**
  - Share URL to app while closed
  - Cold start with saved state
  - Verify no crashes or data loss
  
- [ ] **Background/Foreground Transitions**
  - Perform action (e.g., saving URL)
  - Background app mid-operation
  - Return to foreground
  - Verify operation completes or shows appropriate state
  
- [ ] **Token Refresh on 401**
  - Let access token expire (wait 1 hour or mock short expiry)
  - Perform any API action
  - Verify silent token refresh happens
  - Action succeeds without user intervention
  - If refresh fails, redirect to onboarding
  
- [ ] **Large Data Sets**
  - Test with 100+ items in inbox
  - Verify scroll performance smooth
  - Infinite scroll still works
  
- [ ] **Image Loading**
  - Test items with missing images
  - Verify placeholder shows
  - Test items with slow-loading images
  - Verify cached images load fast on revisit
  
- [ ] **Form Validation**
  - Test all text inputs with empty strings
  - Test with very long inputs
  - Test with special characters
  - Verify appropriate validation messages

---

## ✅ Final Approval Criteria

All checkboxes above must be ✅ before considering Phase 10 complete.

**Sign-off**:
- [ ] All user stories validated end-to-end
- [ ] No critical bugs found
- [ ] No crashes or hangs
- [ ] Performance acceptable (smooth scrolling, fast navigation)
- [ ] Error messages helpful and actionable
- [ ] Offline mode works as expected
- [ ] Share sheet integration works on both platforms
- [ ] Ready for internal demo/pilot

**Blockers** (if any):
- _None identified_

---

## 📝 Testing Notes

**Date**: _[To be filled during testing]_  
**Tester**: _[Name]_  
**Device/Simulator**: _[iOS/Android version, device model]_  
**Backend**: _[Dev/Staging/Prod]_  
**Issues Found**: _[Link to bug tracker or list issues here]_
