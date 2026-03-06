# Snyk Authentication & Configuration

## Authentication Methods

| Method | Best For | Token Lifetime |
|--------|----------|----------------|
| `snyk auth` (OAuth 2.0) | Local development | Auto-refreshing, short-lived |
| `SNYK_TOKEN` env var | CI/CD, automation | Depends on token type |
| API token (legacy) | Simple CI/CD | Long-lived, static |
| Personal Access Token (PAT) | Enterprise per-user audit | Configurable expiry |
| Service Account | Enterprise CI/CD | OAuth short-lived |

### Local Development

```bash
snyk auth
# Opens browser → log in to Snyk → token stored locally
```

### CI/CD

```bash
export SNYK_TOKEN=<your-token>
snyk test --json
```

### Verifying Auth

```bash
snyk whoami --experimental  # Shows authenticated user + org
```

## Organization Configuration

### Current Org

The neb Snyk org is `chirotouch-cloud`.

### Setting the Org

Three methods, in precedence order:
1. **CLI flag:** `snyk test --org=chirotouch-cloud`
2. **Config:** `snyk config set org=chirotouch-cloud`
3. **Env var:** `SNYK_CFG_ORG=chirotouch-cloud`

Pin the org explicitly in CI/CD to avoid results landing in the wrong org.

## Permission Model

| Action | Org Admin | Org Collaborator |
|--------|-----------|-----------------|
| `snyk test` | Yes | Yes |
| `snyk code test` | Yes | Yes |
| `snyk container test` | Yes | Yes |
| `snyk monitor` | Yes | Yes |
| `snyk ignore` | Yes | Yes |
| `snyk monitor --project-environment` | Yes | **No** |
| Manage org settings | Yes | No |
| Manage users/roles | Yes | No |

Key insight: all scan and remediation commands work for Org Collaborators. The only restriction is `--project-environment` on monitor.

## `.snyk` Policy File

The `.snyk` file in a project root defines vulnerability ignore policies.

### Structure

```yaml
# Ignore a vulnerability
ignore:
  SNYK-JS-LODASH-567746:
    - '*':
        reason: "No user input reaches this code path"
        expires: 2026-06-06T00:00:00.000Z

# Ignore for a specific dependency path
  SNYK-JS-AXIOS-123456:
    - 'my-app > express > axios':
        reason: "Mitigated by WAF"
        expires: 2026-09-06T00:00:00.000Z

# Exclude files from SAST scanning
exclude:
  code:
    - tests/**
    - legacy/**
```

### `.snyk` vs Dashboard Ignores

| Feature | `.snyk` File | Dashboard |
|---------|-------------|-----------|
| Version controlled | Yes (git) | No |
| Branch-aware | Yes | No (global) |
| Centralized visibility | No (per-repo) | Yes |
| Works for SAST | No | Yes |
| Merge conflicts | Possible | No |
| Code review of ignore decisions | Yes (in PRs) | No |

The neb team currently uses dashboard ignores. Both approaches work — dashboard is better for centralized audit, `.snyk` is better for code-review visibility.

## Rate Limits

| API | Limit |
|-----|-------|
| REST API (v3) | 1,620 requests/min per key |
| V1 API (legacy) | 2,000 requests/min |
| CLI commands | No separate limit (bounded by API limits) |

A single `snyk test` may make multiple API calls depending on project complexity. Parallel CI pipelines sharing one token can hit limits.

## Enterprise Features

| Feature | Available |
|---------|-----------|
| Unlimited scans | Yes |
| Service accounts | Yes (org-level and group-level) |
| Custom roles (RBAC) | Yes |
| SSO/SAML | Yes |
| Audit logs | Yes (90-day retention) |
| Custom IaC rules (OPA) | Yes |
| Org/group-level policies | Yes |
| Snyk Agent Fix (AI) | Yes (IDE only, Early Access) |
| Custom Base Image Recommendations | Yes |
| Data residency | EU, APAC, or Private Cloud |

## Token Security

- Never hardcode `SNYK_TOKEN` in source code or config files
- Use CI/CD secret management (GitHub Actions secrets, etc.)
- For local dev, rely on `snyk auth` OAuth (tokens managed automatically)
- Rotate API tokens periodically
- If a token is leaked: revoke immediately in Snyk UI, generate new token, update all services
