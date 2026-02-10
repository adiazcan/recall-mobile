# Data Model: Recall Mobile MVP

**Phase 1 Output** | **Date**: 2026-02-10

## Entities

### Item

Represents a saved URL with its metadata. Corresponds to the backend `/api/v1/items` resource.

| Field          | Type              | Required | Notes                                           |
|----------------|-------------------|----------|-------------------------------------------------|
| id             | String            | Yes      | Unique identifier from backend                  |
| url            | String            | Yes      | Original saved URL                              |
| title          | String            | Yes      | Page title (from backend parsing)               |
| excerpt        | String?           | No       | Short text snippet                              |
| domain         | String            | Yes      | Source domain extracted from URL                 |
| previewImageUrl| String?           | No       | Preview/thumbnail image URL                     |
| status         | ItemStatus        | Yes      | `unread` or `archived`                          |
| isFavorite     | bool              | Yes      | Favorite flag, defaults to false                |
| collectionId   | String?           | No       | Assigned collection (null = inbox)              |
| tags           | List\<Tag\>       | Yes      | Associated tags (can be empty)                  |
| createdAt      | DateTime          | Yes      | Save timestamp (used for sort order)            |
| updatedAt      | DateTime          | Yes      | Last modification timestamp                     |

**State transitions**:
- `unread` → `archived` (via archive action)
- `archived` → `unread` (via unarchive action)
- Any state → deleted (permanent, with confirmation)

**Validation**:
- `url` must be a valid absolute URL
- `status` must be one of the defined enum values
- `tags` can be empty list but not null

### Collection

A named group for organizing items.

| Field      | Type     | Required | Notes                                    |
|------------|----------|----------|------------------------------------------|
| id         | String   | Yes      | Unique identifier from backend           |
| name       | String   | Yes      | Unique display name                      |
| itemCount  | int      | Yes      | Number of items in the collection        |
| createdAt  | DateTime | Yes      | Creation timestamp                       |
| updatedAt  | DateTime | Yes      | Last modification timestamp              |

**Validation**:
- `name` must be non-empty and unique across all user collections
- `itemCount` is read-only (computed by backend)

**Lifecycle**:
- Create → Rename → Delete
- On delete: all items in collection have `collectionId` set to null (moved to inbox)

### Tag

A label for filtering and categorization.

| Field | Type   | Required | Notes                           |
|-------|--------|----------|---------------------------------|
| id    | String | Yes      | Unique identifier from backend  |
| name  | String | Yes      | Display name                    |

**Validation**:
- `name` must be non-empty
- Tags can be created inline during item tag editing

### ItemStatus (Enum)

| Value     | Description                        |
|-----------|------------------------------------|
| unread    | Default status for newly saved items |
| archived  | Item has been archived by the user |

### AuthState (Enum/Union)

| State            | Description                                      |
|------------------|--------------------------------------------------|
| unauthenticated  | No valid session, show onboarding                |
| loading          | Auth operation in progress (sign-in, refresh)    |
| authenticated    | Valid session with access token                  |

### PaginatedResponse\<T\>

Generic wrapper for paginated API responses.

| Field    | Type      | Required | Notes                                      |
|----------|-----------|----------|--------------------------------------------|
| items    | List\<T\> | Yes      | Current page of results                    |
| nextCursor | String? | No       | Cursor for next page (null = last page)    |
| totalCount | int?    | No       | Total items matching query (if provided)   |

## Relationships

```text
User Session (1) ──── owns ────> (many) Items
User Session (1) ──── owns ────> (many) Collections
User Session (1) ──── owns ────> (many) Tags

Collection (1) ──── contains ──> (many) Items  [Item.collectionId]
Item (many) <──── tagged with ──> (many) Tags   [Item.tags]
```

## Cache Schema

Cached as JSON strings in SharedPreferences:

| Key                    | Value                              | Updated On              |
|------------------------|------------------------------------|-------------------------|
| `cache_items_json`     | Serialized first page of items     | Every successful items fetch |
| `cache_collections_json` | Serialized collections list      | Every successful collections fetch |
| `cache_tags_json`      | Serialized tags list               | Every successful tags fetch |
