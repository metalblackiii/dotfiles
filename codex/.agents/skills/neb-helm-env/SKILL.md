---
name: neb-helm-env
description: ALWAYS invoke when adding, modifying, or deploying environment variables for neb microservices via Helm charts. Triggers on "add env var", "new environment variable", "deploy config", "helm values", "configmap change", or any task requiring a value to flow from neb-deploy into a running neb-ms-* pod. Not for generic Helm chart creation (use helm-expert) or application code conventions (use neb-ms-conventions).
---

# Neb Helm Environment Variables

## Overview

Adding an environment variable to a neb service touches up to **three repos**: the service repo declares it, neb-deploy overrides it per deployed environment, and neb-local-dev can override it for local Kubernetes development. This skill covers the end-to-end flow.

## Architecture

```
neb-ms-{service}/helm/{service}/          neb-deploy/helm/values/
  values.yaml        (defaults)             base/{service}/values.yaml    (shared overrides)
  templates/                                dev/{service}/values.yaml     (dev overrides)
    configmap.yaml   (non-sensitive)        staging/{service}/values.yaml
    secret.yaml      (sensitive)            production/{service}/values.yaml
  Chart.yaml         (version)              canary/{service}/values.yaml

neb-local-dev/src/nebula/
  services.yaml      (local-dev overrides per service, under `values:` key)
  dependencies.yaml  (local-dev overrides for infra: mysql, kafka, redis, etc.)
```

**Deployed merge order** (later wins): service defaults -> base/values.yaml -> {env}/values.yaml -> base/{service}/values.yaml -> {env}/{service}/values.yaml

**Local-dev merge order**: service defaults (from chart repo or local chart) -> `services.yaml` values (converted to `--set`/`--set-string` args, which override everything)

## Template Helpers

Use these in configmap.yaml or secret.yaml depending on sensitivity:

| Helper | Use for | Example |
|--------|---------|---------|
| `common.prop.value` | Local plaintext value | `{{ include "common.prop.value" .Values.MY_VAR }}` |
| `common.global.prop.value` | Global-first with local fallback | `{{ include "common.global.prop.value" (list . "MY_VAR") }}` |
| `common.secretProp.value` | Local sensitive value | `{{ include "common.secretProp.value" (list . "MY_VAR") }}` |
| `common.global.secretProp.value` | Global-first sensitive value | `{{ include "common.global.secretProp.value" (list . "MY_VAR") }}` |
| `common.url` | Service URL from `urls` map | `{{ include "common.url" (list . "billing") }}` |
| `common.host` | host:port from `hosts` map | `{{ include "common.host" (list . "kafka") }}` |
| `common.hostname` | hostname only from `hosts` | `{{ include "common.hostname" (list . "mysql") }}` |
| `common.hostport` | port only from `hosts` | `{{ include "common.hostport" (list . "mysql") }}` |

## Adding a Non-Sensitive Env Var (Step by Step)

### 1. Service repo: Add default value

In `helm/{service}/values.yaml`, add the key alphabetically among peers:

```yaml
PRACTICE_USER_POOL_CLIENT_ID: ''
```

Use empty string `''` for values that must be overridden per environment. Use a real default for values that work across environments.

### 2. Service repo: Add to configmap template

In `helm/{service}/templates/configmap.yaml`, add a line inside the `data:` block (alphabetical):

```yaml
PRACTICE_USER_POOL_CLIENT_ID: {{ include "common.prop.value" .Values.PRACTICE_USER_POOL_CLIENT_ID }}
```

Use `common.global.prop.value` instead if the value should be settable globally for all services.

### 3. Service repo: Bump chart version

In `helm/{service}/Chart.yaml`, increment the patch version:

```yaml
version: 0.1.45  # was 0.1.44
```

Bump patch for any values.yaml or template change. This publishes a new chart version.

### 4. Service repo: Update application code

Read the env var via `process.env.PRACTICE_USER_POOL_CLIENT_ID`. Add tests covering the new behavior.

### 5. Service repo: Commit and PR

Commit all helm + code changes together. The chart is republished on merge.

### 6. neb-deploy: Add per-environment overrides

In `helm/values/{env}/{service}/values.yaml` for each environment that needs a non-default value:

```yaml
# dev
PRACTICE_USER_POOL_CLIENT_ID: ar5mfqmrap4s7s1o8aitdf1dl

# staging
PRACTICE_USER_POOL_CLIENT_ID: 609ikof67b3tl7o8uajdesbeoq

# production
PRACTICE_USER_POOL_CLIENT_ID: 5hs3lgsl3gcclepriq0i6fkt9b

# canary (usually matches production)
PRACTICE_USER_POOL_CLIENT_ID: 5hs3lgsl3gcclepriq0i6fkt9b
```

Add alphabetically among peers. Each environment file is independent.

### 7. neb-deploy: Commit and PR

This PR is the companion to the service repo PR. Reference the service PR in the body.

### 8. Deploy order

Merge the **service repo PR first** (so the chart with the new template is published), then merge the **neb-deploy PR** (so the override values are available). Deployment picks up both.

## Adding a Sensitive Env Var

For credentials, keys, passwords — use the secret template instead.

### Service repo differences

1. In `values.yaml`, add with a local dev placeholder: `MY_SECRET: localdevvalue`
2. In `templates/secret.yaml` (not configmap.yaml):
   ```yaml
   MY_SECRET: {{ include "common.secretProp.value" (list . "MY_SECRET") }}
   ```
   Use `common.global.secretProp.value` for shared secrets (e.g., `MS_SECRET_KEY`).
3. Bump chart version as usual.

### neb-deploy differences

Instead of adding values to `helm/values/{env}/{service}/values.yaml`, add the key mapping to `helm/env-value-keys.yaml`:

```yaml
MY_SECRET:
  dev: MY_SECRET              # shell env var name for dev
  staging: MY_SECRET
  canary: PROD_MY_SECRET      # prod uses PROD_ prefix
  production: PROD_MY_SECRET
```

The deploy script resolves these from CI/CD environment variables (sourced from AWS Secrets Manager) and injects them via `helm upgrade --set`.

## How Pods Receive Env Vars

The deployment template mounts both ConfigMap and Secret via `envFrom`:

```yaml
envFrom:
  - configMapRef:
      name: {{ template "common.fullname" . }}
  - secretRef:
      name: {{ template "common.fullname" . }}
```

All keys from both sources become environment variables in the pod automatically.

## Local Development (neb-local-dev)

The service's `values.yaml` defaults also apply in local-dev (the chart is deployed to a local Kubernetes cluster). To override a value for local-dev only, edit `neb-local-dev/src/nebula/services.yaml`.

Each service has a section with an optional `values:` block:

```yaml
# neb-local-dev/src/nebula/services.yaml
registry:
  deploymentPhase: initial
  repository: http://helm-charts.nebula.care:8080
  values:
    SKIP_LOGI_PROVISIONING: "true"   # true only in local-dev
    resources:
      limits:
        cpu: 500m
        memory: 500Mi
```

These values are converted to `--set-string` (strings) or `--set` (numbers/booleans) args by `load-dependency-config.js`, which override the chart defaults at deploy time.

**When to add a local-dev override:**
- The deployed default doesn't work locally (e.g., external service URLs, feature flags that need different behavior)
- Resource limits need to be smaller for local clusters
- A variable should be explicitly different in local dev (e.g., `SKIP_LOGI_PROVISIONING`)

**When NOT to override:** If the service `values.yaml` default already works for local dev (most cases), no entry in `services.yaml` is needed.

**Testing local chart changes:** Uncomment the local repository path to use a sibling repo's chart instead of the published one:

```yaml
permissions:
  # repository: http://helm-charts.nebula.care:8080
  repository: "../neb-ms-permissions/helm/permissions"
  # version: '*'
```

Infrastructure dependencies (MySQL, Kafka, Redis, Elasticsearch) use the same pattern in `dependencies.yaml`.

## Environments

| Environment | Purpose | Overrides location |
|-------------|---------|-------------------|
| local-dev | Local Kubernetes | `neb-local-dev/src/nebula/services.yaml` |
| dev | Development/QA | `neb-deploy/helm/values/dev/{service}/values.yaml` |
| staging | Pre-production | `neb-deploy/helm/values/staging/{service}/values.yaml` |
| production | Live traffic | `neb-deploy/helm/values/production/{service}/values.yaml` |
| canary | Prod canary | `neb-deploy/helm/values/canary/{service}/values.yaml` |

## Common Patterns

- **Canary matches production**: Copy the same value to both files.
- **Global values**: Set in `helm/values/base/values.yaml` or `helm/values/{env}/values.yaml` (not service-specific). Access via `common.global.prop.value`.
- **Worker-specific overrides**: Add to `templates/configmap-worker.yaml` if the worker needs different values than the web pod.
- **Hosts/URLs**: Use the `hosts` and `urls` maps in values.yaml with the host/url helpers, not raw strings.
- **Local-dev only flags**: Add to `services.yaml` when a feature must behave differently locally (e.g., skip external provisioning).

## Checklist

- [ ] Default added to service `values.yaml` (alphabetical)
- [ ] Template line added to `configmap.yaml` or `secret.yaml` (alphabetical)
- [ ] Chart version bumped in `Chart.yaml`
- [ ] Application code reads the env var and has tests
- [ ] neb-deploy overrides added for all 4 environments (or `env-value-keys.yaml` for secrets)
- [ ] Local-dev override added to `services.yaml` if the default doesn't work locally
- [ ] Service repo PR merged before neb-deploy PR
- [ ] Deploy verified in dev before promoting to staging/production
