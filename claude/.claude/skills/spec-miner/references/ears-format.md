# EARS Format

Easy Approach to Requirements Syntax for clear, unambiguous observed requirements.

## EARS Syntax Patterns

**Ubiquitous (Always)**
```
The system shall [action].
```

**Event-Driven**
```
When [trigger], the system shall [action].
```

**State-Driven**
```
While [state], the system shall [action].
```

**Conditional**
```
While [state], when [trigger], the system shall [action].
```

**Optional / Feature-Gated**
```
Where [feature/entitlement enabled], the system shall [action].
```

## Examples

### Authentication

**OBS-AUTH-001: Token Authentication**
```
When a request includes a valid JWT in the Authorization header,
the system shall authenticate the user and attach user context to the request.
```

**OBS-AUTH-002: Expired Token**
```
When an expired or invalid token is provided,
the system shall return 401 Unauthorized.
```

### Feature Gating

**OBS-ENTL-001: Entitlement Check**
```
Where PHX_GBB_ENTITLEMENTS is enabled for the tenant,
when hasEntitlement() is called, the system shall check entl: records in FeatureOptIn.
```

**OBS-ENTL-002: Entitlement Passthrough**
```
Where PHX_GBB_ENTITLEMENTS is not enabled for the tenant,
when hasEntitlement() is called, the system shall return true (passthrough).
```

### Tenant-Scoped Operations

**OBS-DATA-001: Multi-Tenant Isolation**
```
The system shall scope all database queries to the authenticated tenant's connection (req.db).
```

**OBS-DATA-002: Cross-Tenant Prevention**
```
When a request references a resource belonging to a different tenant,
the system shall return 404 Not Found (not 403, to avoid information leakage).
```

### Business Logic

**OBS-BIZ-001: Add-On Gated Feature**
```
Where tenant has the ct-verify add-on,
the system shall display real-time eligibility verification options.
```

**OBS-BIZ-002: Tier-Based Feature**
```
While tenant tier is Advanced,
the system shall enable multi-location support in practice settings.
```

## Quick Reference

| Type | Pattern | Use For |
|------|---------|---------|
| Ubiquitous | shall [action] | Always-true behaviors |
| Event | When [X], shall | Triggered behaviors |
| State | While [X], shall | State-dependent behaviors |
| Conditional | While [X], when [Y], shall | State + trigger combined |
| Optional | Where [X enabled], shall | Feature-gated behaviors |

## Naming Convention

```
OBS-{MODULE}-{NNN}: {Short Description}
```

Modules: AUTH, DATA, BIZ, ENTL, API, UI, SEC, INT (integration), MSG (messaging)
