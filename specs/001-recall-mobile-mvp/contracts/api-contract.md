# API Contract: Recall Mobile MVP

**Phase 1 Output** | **Date**: 2026-02-10

This documents the expected backend API contract at `/api/v1` that the mobile app will consume. Based on the spec's assumption that the backend already provides these endpoints for the React web app.

## Authentication

All endpoints below require `Authorization: Bearer {access_token}` header.
Scopes are configured in Entra ID app registration and requested during MSAL sign-in.

## Endpoints

### Items

#### List Items
```
GET /api/v1/items
```

**Query Parameters**:

| Parameter    | Type   | Required | Description                              |
|-------------|--------|----------|------------------------------------------|
| status      | string | No       | Filter: `unread` or `archived`           |
| favorite    | bool   | No       | Filter: `true` for favorites only        |
| collectionId| string | No       | Filter: items in specific collection     |
| tags        | string | No       | Filter: comma-separated tag IDs (AND logic) |
| cursor      | string | No       | Pagination cursor from previous response |
| limit       | int    | No       | Page size (default: 20)                  |
| sort        | string | No       | Sort field (default: `createdAt`)        |
| order       | string | No       | Sort direction (default: `desc`)         |

**Response** `200 OK`:
```json
{
  "items": [
    {
      "id": "string",
      "url": "string",
      "title": "string",
      "excerpt": "string | null",
      "domain": "string",
      "previewImageUrl": "string | null",
      "status": "unread | archived",
      "isFavorite": false,
      "collectionId": "string | null",
      "tags": [{ "id": "string", "name": "string" }],
      "createdAt": "2026-02-10T12:00:00Z",
      "updatedAt": "2026-02-10T12:00:00Z"
    }
  ],
  "nextCursor": "string | null",
  "totalCount": 42
}
```

#### Create Item (Save URL)
```
POST /api/v1/items
```

**Request Body**:
```json
{
  "url": "https://example.com/article",
  "collectionId": "string | null",
  "tagIds": ["string"]
}
```

**Response** `201 Created`:
```json
{
  "id": "string",
  "url": "string",
  "title": "string",
  ...
}
```

**Response** `409 Conflict` (duplicate URL):
```json
{
  "error": "duplicate",
  "existingItemId": "string",
  "message": "This URL has already been saved"
}
```

#### Get Item Detail
```
GET /api/v1/items/{id}
```

**Response** `200 OK`: Single item object (same shape as list item).

#### Update Item
```
PATCH /api/v1/items/{id}
```

**Request Body** (partial update):
```json
{
  "status": "archived | unread",
  "isFavorite": true,
  "collectionId": "string | null",
  "tagIds": ["string"]
}
```

**Response** `200 OK`: Updated item object.

#### Delete Item
```
DELETE /api/v1/items/{id}
```

**Response** `204 No Content`.

### Collections

#### List Collections
```
GET /api/v1/collections
```

**Response** `200 OK`:
```json
{
  "collections": [
    {
      "id": "string",
      "name": "string",
      "itemCount": 5,
      "createdAt": "2026-02-10T12:00:00Z",
      "updatedAt": "2026-02-10T12:00:00Z"
    }
  ]
}
```

#### Create Collection
```
POST /api/v1/collections
```

**Request Body**:
```json
{
  "name": "string"
}
```

**Response** `201 Created`: Collection object.

**Response** `409 Conflict` (duplicate name):
```json
{
  "error": "duplicate",
  "message": "A collection with this name already exists"
}
```

#### Update Collection (Rename)
```
PATCH /api/v1/collections/{id}
```

**Request Body**:
```json
{
  "name": "string"
}
```

**Response** `200 OK`: Updated collection object.

#### Delete Collection
```
DELETE /api/v1/collections/{id}
```

**Response** `204 No Content`.

Items in the deleted collection are moved to inbox (collectionId set to null) by the backend.

### Tags

#### List Tags
```
GET /api/v1/tags
```

**Response** `200 OK`:
```json
{
  "tags": [
    { "id": "string", "name": "string" }
  ]
}
```

#### Create Tag
```
POST /api/v1/tags
```

**Request Body**:
```json
{
  "name": "string"
}
```

**Response** `201 Created`: Tag object.

## Error Responses

All error responses follow a consistent shape:

```json
{
  "error": "error_code",
  "message": "Human-readable description"
}
```

| Status | Code               | Description                          |
|--------|--------------------|--------------------------------------|
| 400    | `validation_error` | Invalid request body or parameters   |
| 401    | `unauthorized`     | Missing or expired token             |
| 403    | `forbidden`        | Insufficient scopes                  |
| 404    | `not_found`        | Resource does not exist              |
| 409    | `duplicate`        | Conflict (duplicate URL or name)     |
| 500    | `internal_error`   | Server error                         |

## Notes

- This contract is inferred from the spec's functional requirements and the assumption that the backend serves the React web app with the same endpoints.
- Actual endpoint paths, field names, and pagination style should be verified against the backend's OpenAPI spec at `/openapi/v1.json`.
- The app already has an `OpenApiRepository` that can fetch and display the spec for verification.
