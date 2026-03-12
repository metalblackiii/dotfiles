---
name: dockerfile-expert
description: ALWAYS invoke to create, generate, validate, lint, scan, audit, or optimize Dockerfiles, container images, multi-stage builds, and .dockerignore files. Triggers on "create Dockerfile", "validate Dockerfile", "containerize", "Docker best practices", "optimize Docker image", or any Dockerfile request.
---

# Dockerfile Expert

Generate and validate production-ready Dockerfiles with multi-stage builds, security hardening, layer optimization, and iterative validation loops.

## When to Use

- Creating new Dockerfiles from scratch or containerizing applications
- Implementing multi-stage builds for size optimization
- Validating, linting, scanning, or auditing existing Dockerfiles
- Optimizing Docker builds for security and performance
- Generating .dockerignore files

## Generation Workflow

### Stages (run in order)

1. **Gather requirements** — language, runtime version, entrypoint, exposed port, package manager, health endpoint.
2. **Load references** — local reference files first; external docs only when insufficient.
   - `references/security_best_practices.md`
   - `references/optimization_patterns.md`
   - `references/language_specific_guides.md`
   - `references/multistage_builds.md`
3. **Generate Dockerfile and `.dockerignore`**.
4. **Validate** with validation workflow below.
5. **Iterate fixes** until zero errors or 3 iterations max.
6. **Publish** final artifacts plus validation/audit report.

### Core Principles (all REQUIRED)

- **Multi-stage builds** — separate build from runtime; copy only necessary artifacts (50-85% size reduction).
- **Security hardening** — specific version tags (never `:latest`), non-root user, minimal base images (alpine/distroless), no hardcoded secrets.
- **Layer optimization** — least-to-most-frequently-changing order, dependency files before app code, combine RUN commands, clean caches in same layer.
- **Production readiness** — HEALTHCHECK for services, exec form for ENTRYPOINT/CMD, absolute WORKDIR, EXPOSE for ports.

### Node.js Build-Stage Rule

If the app has a build step (TypeScript, Vite, Webpack), install **all** dependencies in builder (omit `--only=production`), then `npm prune --production` after build.

### Language-Specific Size Targets

| Language | With optimization | Without |
|----------|------------------|---------|
| Node.js | ~50-150MB (Alpine) | ~1GB |
| Python | ~150-250MB (slim) | ~900MB |
| Go | ~5-20MB (distroless) | ~800MB |
| Java | ~200-350MB (JRE) | ~500MB+ |

### Generation Scripts (optional CLI tools)

```bash
scripts/generate_nodejs.sh --version 20 --port 3000 --output Dockerfile
scripts/generate_python.sh
scripts/generate_golang.sh
scripts/generate_java.sh
scripts/generate_dockerignore.sh
```

## Validation Workflow

### Execution Flow

1. **Preflight** — verify target Dockerfile exists.
2. **Read target Dockerfile**.
3. **Run validation script**:
   ```bash
   bash scripts/dockerfile-validate.sh <Dockerfile>
   ```
4. **Classify findings** by severity:

   | Severity | Examples |
   |----------|----------|
   | Critical | Hardcoded secrets, explicit root with high-risk context |
   | High | Checkov failures, missing USER directive |
   | Medium | `:latest` tags, cache-cleanup misses |
   | Low | Style/info, non-blocking optimization |

5. **No-issue fast path** — if clean, return pass summary, skip references.
6. **Load references only when findings exist**:

   | Issue Category | Reference |
   |----------------|-----------|
   | Secrets, root user, hardening | `references/security_checklist.md` |
   | Image size, layers, multi-stage | `references/optimization_guide.md` |
   | Tag pinning, COPY vs ADD, conventions | `references/docker_best_practices.md` |

7. **Produce report** with severity buckets and recommended fixes.
8. **Offer fix application** — patch and rerun if user approves.

### Validate-Iterate Loop

- Run at least one validation pass.
- If any `error`, apply fixes and re-run (max 3 iterations).
- For `warning`, fix or document as intentional deviation with justification.

### Fallback Behavior

| Condition | Action |
|-----------|--------|
| Script fails (Python/tool install) | Manual grep checks for `:latest`, hardcoded secrets, root USER, missing HEALTHCHECK |
| hadolint missing, Docker available | `docker run --rm -i hadolint/hadolint < Dockerfile` |
| No Docker, no hadolint/checkov | Regex-based checks only, mark as PARTIAL |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/generate_nodejs.sh` | Generate Node.js Dockerfiles |
| `scripts/generate_python.sh` | Generate Python Dockerfiles |
| `scripts/generate_golang.sh` | Generate Go Dockerfiles |
| `scripts/generate_java.sh` | Generate Java Dockerfiles |
| `scripts/generate_dockerignore.sh` | Generate .dockerignore |
| `scripts/dockerfile-validate.sh` | Primary validation script (hadolint + Checkov + best practices + optimization) |
| `scripts/test_generator.sh` | Generator regression tests |
| `scripts/test_validate.sh` | Validator regression tests |

## References

| File | Content |
|------|---------|
| `references/security_best_practices.md` | Non-root users, secret handling, base image hardening |
| `references/optimization_patterns.md` | Multi-stage strategy, cache optimization, BuildKit mounts |
| `references/language_specific_guides.md` | Language/framework runtime patterns |
| `references/multistage_builds.md` | Advanced stage-splitting and artifact-copy |
| `references/security_checklist.md` | Validation security checklist |
| `references/optimization_guide.md` | Validation optimization guide |
| `references/docker_best_practices.md` | Tag pinning, instruction usage, conventions |

## Done Criteria

### Generation
- Dockerfile and `.dockerignore` generated.
- Validation executed (primary or documented fallback).
- Iteration log present with command path, counts, fixes.
- No remaining `error` findings.
- Every remaining `warning` has fix or intentional-deviation report.
- Output includes optimization metrics and next steps.

### Validation
- Target Dockerfile path verified.
- Validation command (or fallback) executed.
- Findings reported using severity buckets.
- If fixes applied, validation rerun and final status reported.
