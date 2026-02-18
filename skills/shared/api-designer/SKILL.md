---
name: api-designer
description: Use when designing new REST API endpoints, planning API versioning strategy, defining request/response contracts, or evolving existing APIs with breaking changes
disable-model-invocation: true
---

# API Designer

REST API design specialist for Express/Node.js services. Focuses on resource modeling, versioning strategy, error contracts, and evolving APIs in a multi-service ecosystem.

## When to Use

- Designing new API endpoints or resources
- Planning how to version a breaking change
- Defining request/response contracts for a new feature
- Reviewing API design for consistency with existing patterns
- Adding entitlement or authorization gates to API endpoints
- Designing cross-service API contracts (service-to-service)

## Core Workflow

1. **Model Resources** — Identify the domain resources. Name endpoints as nouns, use HTTP methods for verbs. Map relationships.
2. **Design Contract** — Define request schema (validation rules), response shape (formatter), status codes, and error responses.
3. **Version Strategy** — Determine if the change is additive (no version bump) or breaking (new version path). Follow existing version conventions.
4. **Gate Access** — Define security schema, feature flags, and entitlement checks. Document who can call this endpoint and under what conditions.
5. **Document** — Specify the contract clearly enough that another service can integrate without reading the implementation.

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| REST Patterns | `references/rest-patterns.md` | Resource naming, HTTP methods, status codes, pagination |
| Versioning & Evolution | `references/versioning-evolution.md` | Breaking vs additive changes, version bumping, deprecation |
| Error Handling | `references/error-handling.md` | Error response format, validation errors, status code selection |

## Constraints

### MUST DO
- Use nouns for resources, HTTP methods for actions
- Return consistent error response shapes across all endpoints
- Validate all input with request schemas (express-validator)
- Use appropriate HTTP status codes (don't 200-everything)
- Version breaking changes — additive changes go in the current version
- Define security schemas for every endpoint
- Support pagination for list endpoints (offset/limit or cursor)

### MUST NOT DO
- Design RPC-style endpoints (verbs in URLs like `/getUser` or `/createCharge`)
- Return different error shapes from different endpoints
- Make breaking changes to existing version paths without a migration plan
- Skip request validation — even for service-to-service calls
- Expose internal IDs or implementation details in response shapes
- Design endpoints that require callers to make N+1 requests for common use cases

## Related Skills

- **neb-ms-conventions** — for implementation patterns (filesystem routing, controllerWrapper, `req.db`)
- **microservices-architect** — for cross-service communication design and data ownership
- **refactoring-guide** — for refactoring service-layer code behind the API
