# Cross-PR Analysis

Heuristics for analyzing a set of related PRs that implement a single feature across multiple repositories. Applied in Phase 1 Step 5 — skip for single-PR reviews.

## When to Apply

Cross-PR analysis triggers when 2+ PRs are provided (URLs, numbers, or a mix). The set title (if provided) establishes feature intent — use it to judge completeness and coherence.

## Analysis Categories

### 1. Contract Consistency

**What:** Provider and consumer PRs must agree on API shapes — endpoint paths, methods, request/response fields, types, and error codes.

**How:**
1. Identify provider PRs (changes to routes, controllers, API definitions)
2. Identify consumer PRs (changes to API calls, service clients, fetch/axios usage)
3. For each provider endpoint changed:
   - Extract the contract: path, method, request params/body shape, response shape, status codes
   - Find all consumers of that endpoint across the PR set
   - Verify: field names match (camelCase vs snake_case is a common miss), types align, required fields are sent, error responses are handled
4. Flag mismatches as Important or Critical (Critical if it would cause runtime failure)

**Common patterns in neb:**
- Backend exposes Sequelize model attributes → frontend expects specific JSON field names
- New query parameters added to API but not sent by frontend
- Response shape changes (wrapping in `{ data: ... }`) not reflected in consumer

### 2. Deployment Ordering

**What:** Some PRs must deploy before others to avoid runtime failures during rollout.

**How:**
1. Identify dependencies:
   - Schema migration PRs → code PRs that reference new columns/tables
   - Provider endpoint PRs → consumer PRs that call new endpoints
   - Permission/entitlement PRs → feature PRs gated by those permissions
   - Shared library PRs (neb-microservice) → service PRs that depend on new exports
2. Build a dependency graph
3. Flag:
   - **Critical**: Circular dependencies (impossible to deploy safely)
   - **Important**: Missing ordering annotation (PRs should document deploy order)
   - **Minor**: Order exists but isn't documented

**Output:** Include a suggested merge/deploy order in the cross-cutting section:
```
Deploy order:
1. neb-microservice#45 (shared utility)
2. neb-ms-permissions#135 (permission definitions)
3. neb-ms-core#326, neb-ms-core#327 (parallel — independent)
4. neb-www#1646, neb-www#1645 (frontend — consumes above)
```

### 3. Shared Model Drift

**What:** The same business entity (Patient, Appointment, User, Practice, etc.) may be represented in multiple services. Changes in one PR should be reflected (or at least acknowledged) in others.

**How:**
1. From each PR's diff, extract entity/model changes (Sequelize model definitions, TypeScript interfaces, API response shapes)
2. Group by entity name
3. For each entity changed in >1 PR:
   - Compare field additions/removals/renames
   - Check for type mismatches (e.g., `string` in one service, `number` in another)
   - Check for naming inconsistencies (`userId` vs `user_id` vs `userID`)
4. Flag divergence as Important (unless intentional — some services legitimately project different views of the same entity)

### 4. Feature Completeness

**What:** Given the stated feature intent (set title), does the PR set cover all necessary layers?

**How:**
1. Identify the feature's architecture layers from the PR set:
   - Backend service logic
   - Database migrations
   - API endpoints (new or modified)
   - Frontend UI
   - Permissions/entitlements
   - Tests
   - Documentation
2. Check for gaps:
   - Backend changes without corresponding frontend? (May be intentional for API-only features)
   - New endpoints without permission checks?
   - New data without migration?
   - Feature flag referenced but not defined?
3. Flag gaps as questions (Minor) rather than findings — the user knows the feature better than the reviewer

**Note:** This is advisory. Missing layers may be in separate PRs not included in this set, or planned for a follow-up. Don't assume gaps are bugs.

### 5. Cross-Service Error Handling

**What:** When service A calls service B's new/changed endpoint, does A handle failure gracefully?

**How:**
1. From consumer PRs, identify new or changed inter-service calls
2. Check:
   - Is there error handling (try/catch, .catch(), error callback)?
   - Does it cover likely failure modes (timeout, 404, 500, network error)?
   - Is there a fallback or degraded UX, or does the whole feature break?
3. Flag missing error handling as Important

### 6. Configuration Consistency

**What:** Environment variables, feature flags, and config values that must be consistent across services.

**How:**
1. From each PR's diff, extract new environment variables, feature flag references, config constants
2. Check for:
   - Same env var name with different defaults across services
   - Feature flag referenced in code but not defined in config
   - Config values that should match (e.g., timeout values for a circuit breaker pattern)
3. Flag inconsistencies as Important

## Cross-PR Finding Format

Cross-PR findings use the `xpr:` ID namespace and reference multiple PRs:

```json
{
  "id": "xpr:f-1",
  "severity": "Important",
  "category": "Contract Consistency",
  "title": "Response field name mismatch: `patientName` vs `patient_name`",
  "prs": ["org/neb-ms-core#324", "org/neb-www#1646"],
  "evidence": "neb-ms-core returns `patient_name` (snake_case from Sequelize) but neb-www expects `patientName` (camelCase)",
  "recommendation": "Align on one convention. If the API contract is snake_case, update the frontend mapping."
}
```

## Severity Guidelines

| Category | Critical | Important | Minor |
|----------|----------|-----------|-------|
| Contract Consistency | Runtime failure (field missing entirely) | Naming mismatch (may work but fragile) | Style inconsistency (both work) |
| Deployment Ordering | Circular dependency | Missing ordering documentation | Order is obvious but not annotated |
| Shared Model Drift | Type mismatch causing data corruption | Field naming divergence | Representation differences (intentional projections) |
| Feature Completeness | — (never critical, always advisory) | — | Missing layer (flagged as question) |
| Cross-Service Error Handling | No error handling on critical path | Partial error handling (misses some cases) | Error handling exists but could be more specific |
| Configuration Consistency | Contradictory config causing runtime error | Different defaults for shared config | Config present but not documented |
