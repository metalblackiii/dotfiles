# Container Scanning

## How It Works

`snyk container test` scans a container image at two layers:

1. **OS packages** — vulnerabilities in the base image's package manager (apt, apk, yum)
2. **Application dependencies** — packages installed inside the image (node_modules, pip packages, etc.)

When you provide `--file=Dockerfile`, Snyk also analyzes which base image you're using and recommends upgrades.

## Scanning Approaches

### Local Image

```bash
# Build the image first
docker build -t neb-ms-core:local .

# Scan with Dockerfile context for base image advice
snyk container test neb-ms-core:local --json --file=Dockerfile || true
```

### Remote Registry Image

```bash
# Scan directly from ECR (requires docker login or registry auth)
snyk container test 082673049991.dkr.ecr.us-east-1.amazonaws.com/neb-ms-core:latest \
  --json --file=Dockerfile || true
```

### Without Docker Running

Snyk can scan Dockerfiles without building, but results are limited to base image analysis only — no OS package or app dependency scanning.

## Base Image Selection

### Current State (neb repos)

From the codebase survey, neb services use:
- `node:24-trixie-slim` (neb-ms-core) — Debian Trixie slim variant
- Similar patterns across other neb-ms-* repos

### Base Image Tiers

| Image Type | Example | Size | Vulns | Use When |
|------------|---------|------|-------|----------|
| **Alpine** | `node:24-alpine` | ~50MB | Fewest | No native compilation needs, no glibc dependency |
| **Slim** | `node:24-slim` | ~200MB | Moderate | Need glibc, minimal native deps |
| **Full** | `node:24` | ~900MB | Most | Need build tools in the runtime image |
| **Distroless** | `gcr.io/distroless/nodejs24` | ~130MB | Fewest | Maximum security, no shell access |

### Neb Consideration

neb-ms-core needs `ghostscript` and `graphicsmagick` (native packages), which rules out Alpine and Distroless. Slim is the right choice — but verify the specific Debian release for vuln counts.

### Multi-Stage Builds

The neb repos already use multi-stage builds (builder stage installs native deps, final stage copies built artifacts). This is the right pattern — keep build tools out of the runtime image.

```dockerfile
# Builder: has build-essential, node-gyp, python3
FROM node:24-trixie-slim as builder
RUN apt-get update && apt-get install -y build-essential ...
COPY package*.json ./
RUN npm ci

# Runtime: minimal
FROM node:24-trixie-slim
COPY --from=builder /app/node_modules ./node_modules
COPY . .
```

## Interpreting Container Scan Results

### Base Image Remediation

When `--file=Dockerfile` is provided, the JSON includes `docker.baseImageRemediation`:

```json
{
  "docker": {
    "baseImage": "node:24-trixie-slim",
    "baseImageRemediation": {
      "advice": [
        {
          "message": "Minor image version upgrade",
          "bold": true
        },
        {
          "message": "Upgrade to node:24.1-trixie-slim to fix 12 vulnerabilities"
        }
      ]
    }
  }
}
```

### What to Fix

1. **Base image upgrade** — usually the highest-impact single change (fixes dozens of OS vulns at once)
2. **Application dependencies** — same as SCA, but inside the container
3. **Unnecessary packages** — remove build tools from runtime image via multi-stage

### What to Accept

- OS-level vulns with no upstream fix (wait for next Debian/Alpine release)
- Vulns in packages your app doesn't use (common in full/non-slim images)
- Low-severity kernel-related CVEs in userspace containers

## `--exclude-base-image-vulns`

Use this flag to focus on vulns your team can actually fix (application layer) vs vulns that require upstream base image maintainers:

```bash
# Only show vulns YOU introduced (not inherited from base image)
snyk container test myimage:latest --json --exclude-base-image-vulns || true
```

## Platform Targeting

For multi-arch images (common with M1/M2 Macs building for Linux deployment):

```bash
# Scan the deployment architecture, not your local arch
snyk container test myimage:latest --platform=linux/amd64 --json || true
```

## Monitoring

```bash
# Upload container snapshot for continuous monitoring
snyk container monitor myimage:latest --file=Dockerfile --org=chirotouch-cloud
```

This alerts when new CVEs are disclosed against packages in your image, even if you haven't rebuilt.
