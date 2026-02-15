# REST Patterns

## Resource Naming

### URL Structure

```
/api/v{N}/tenants/:tenantId/{resource}
/api/v{N}/tenants/:tenantId/{resource}/:id
/api/v{N}/tenants/:tenantId/{resource}/:id/{sub-resource}
```

### Naming Rules

| Rule | Good | Bad |
|------|------|-----|
| Plural nouns | `/patients` | `/patient` |
| Lowercase with hyphens | `/insurance-claims` | `/insuranceClaims`, `/insurance_claims` |
| No verbs in URLs | `POST /charges` | `POST /createCharge` |
| No trailing slashes | `/patients/123` | `/patients/123/` |
| Nested for ownership | `/tenants/:id/patients` | `/patients?tenantId=:id` |

### When to Nest vs Flatten

**Nest** when the child doesn't exist without the parent:
```
GET /tenants/:tenantId/patients/:patientId/appointments
```

**Flatten** when the resource is independently identifiable:
```
GET /appointments/:appointmentId   (if globally unique IDs)
```

**Don't over-nest** — max 2-3 levels deep:
```
# Too deep
GET /tenants/:tid/patients/:pid/appointments/:aid/charges/:cid/adjustments

# Better — access charge directly
GET /tenants/:tid/charges/:cid/adjustments
```

## HTTP Methods

| Method | Purpose | Idempotent | Request Body | Response |
|--------|---------|:----------:|:------------:|---------|
| GET | Read | Yes | No | Resource or collection |
| POST | Create | No | Yes | Created resource + 201 |
| PUT | Full replace | Yes | Yes | Updated resource |
| PATCH | Partial update | No* | Yes | Updated resource |
| DELETE | Remove | Yes | No | 204 or confirmation |

*PATCH can be made idempotent if the patch document is absolute (set fields) rather than relative (increment fields).

### Method Selection

- **POST vs PUT for create**: POST when server assigns ID, PUT when client specifies ID
- **PUT vs PATCH for update**: PUT replaces entire resource, PATCH updates specific fields. In practice, most updates are PATCH.
- **DELETE with soft-delete**: Return 200 with the soft-deleted resource, not 204

## Status Codes

### Success

| Code | When to Use |
|------|-------------|
| 200 | Successful GET, PUT, PATCH, DELETE (with body) |
| 201 | Successful POST (resource created) |
| 204 | Successful DELETE (no body) |

### Client Errors

| Code | When to Use |
|------|-------------|
| 400 | Malformed request, validation error |
| 401 | Not authenticated (no/invalid token) |
| 403 | Authenticated but not authorized |
| 404 | Resource not found |
| 409 | Conflict (duplicate, state conflict) |
| 422 | Semantic validation error (well-formed but invalid) |

### Server Errors

| Code | When to Use |
|------|-------------|
| 500 | Unexpected server error |
| 502 | Upstream service error |
| 503 | Service unavailable (overloaded, maintenance) |

**400 vs 422**: Use 400 for syntax errors (malformed JSON, missing required field). Use 422 for business rule violations (date in past, amount exceeds limit). In practice, 400 for both is acceptable if the error body is clear.

## Pagination

### Offset-Based (Simple)

```
GET /tenants/:id/appointments?offset=0&limit=25

Response:
{
  "data": [...],
  "pagination": {
    "offset": 0,
    "limit": 25,
    "total": 342
  }
}
```

**Pros**: Simple, supports jumping to page N
**Cons**: Inconsistent results when data changes during paging, slow for large offsets

### Cursor-Based (Scalable)

```
GET /tenants/:id/appointments?limit=25&cursor=eyJpZCI6MTAwfQ==

Response:
{
  "data": [...],
  "pagination": {
    "limit": 25,
    "nextCursor": "eyJpZCI6MTI1fQ==",
    "hasMore": true
  }
}
```

**Pros**: Consistent results, performant at any depth
**Cons**: Can't jump to page N, harder to implement

**Recommendation**: Use offset-based for admin/backoffice UIs (need page jumping). Use cursor-based for patient-facing lists and infinite scroll.

## Filtering and Sorting

```
GET /tenants/:id/appointments?status=scheduled&date_gte=2025-01-01&sort=-date
```

Conventions:
- Filter by field name: `?status=scheduled`
- Range filters: `_gte`, `_lte`, `_gt`, `_lt` suffixes
- Sorting: `sort=field` (ascending), `sort=-field` (descending)
- Multiple sort: `sort=-date,lastName`

## Bulk Operations

When a client needs to create or update multiple resources:

```
POST /tenants/:id/charges/bulk
Body: { "items": [...] }
Response: { "results": [{ "id": 1, "status": "created" }, { "id": 2, "status": "error", "error": "..." }] }
```

Return per-item results so the client knows which succeeded and which failed.
