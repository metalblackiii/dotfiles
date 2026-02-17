---
name: docker-infrastructure
description: Use when troubleshooting Docker containers, debugging compose services, fixing Dockerfile build failures, investigating networking or volume issues, or working with container orchestration in local development environments.
user-invocable: false
disable-model-invocation: true
---

# Docker Infrastructure

## Overview

Container issues have predictable root causes. Check the layers systematically: image build, container runtime, networking, volumes, then orchestration.

## When to Use

- Container won't start or exits immediately
- Services can't communicate with each other
- Volume mounts missing or stale data
- Port conflicts or connection refused
- Compose dependency ordering issues
- Health check failures
- Image build failures or cache problems

## Diagnostic Order

Always check in this order — each layer depends on the previous:

| Order | Layer | Check | Command |
|-------|-------|-------|---------|
| 1 | Image | Does it exist and build? | `docker images`, `docker compose build` |
| 2 | Container | Is it running? Exit code? | `docker ps -a`, `docker logs <container>` |
| 3 | Health | Passing health checks? | `docker inspect --format='{{.State.Health}}'` |
| 4 | Network | Can services reach each other? | `docker network inspect`, `docker compose exec <svc> ping <other>` |
| 5 | Volumes | Mounted correctly? Permissions? | `docker inspect -f '{{.Mounts}}'` |
| 6 | Compose | Dependency order correct? | Check `depends_on` and health conditions |

## Common Patterns

### Container Exits Immediately
```
docker logs <container>    # Check exit reason
docker inspect <container> --format='{{.State.ExitCode}}'
```
- Exit 0: Process completed (missing CMD/entrypoint, or foreground process ended)
- Exit 1: Application error (check logs)
- Exit 137: OOM killed (increase memory limit)
- Exit 139: Segfault

### Connection Refused Between Services
1. Verify both containers on same network: `docker network inspect <network>`
2. Use service name as hostname, not localhost
3. Use container port, not host-mapped port
4. Check if target service is healthy before connecting

### Compose Dependency Ordering
```yaml
# depends_on alone only waits for container start, not readiness
depends_on:
  db:
    condition: service_healthy  # Wait for health check to pass
```

### Volume Mount Issues
- Host path doesn't exist: Docker creates it as root-owned directory
- File vs directory: Mounting a file requires the file to exist on host first
- Permissions: Container user may differ from host user

### Build Cache Problems
```bash
docker compose build --no-cache <service>  # Force rebuild
docker system prune --filter "until=24h"   # Clean old layers
```

## Quick Reference

| Symptom | Likely Cause | First Check |
|---------|-------------|-------------|
| "connection refused" | Service not ready or wrong network | `docker ps` + `docker network inspect` |
| "no such file or directory" | Volume mount path wrong | `docker inspect -f '{{.Mounts}}'` |
| Container restart loop | App crash or health check fail | `docker logs --tail 50` |
| Port already in use | Another container or host process | `docker ps` + `lsof -i :<port>` |
| Stale code in container | Build cache or old image | `docker compose build --no-cache` |
| Compose up hangs | Waiting on unhealthy dependency | Check `depends_on` conditions |
