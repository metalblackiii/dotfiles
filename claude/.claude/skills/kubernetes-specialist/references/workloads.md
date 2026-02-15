# Workloads & Scheduling

## Workload Types

| Type | Use When | Example |
|------|----------|---------|
| **Deployment** | Stateless services, most web apps | API services, frontend |
| **StatefulSet** | Ordered startup, stable network IDs, persistent storage | Databases, Kafka, Redis |
| **DaemonSet** | One pod per node | Log collectors, monitoring agents |
| **Job** | Run-to-completion tasks | Database migrations, batch imports |
| **CronJob** | Scheduled tasks | Nightly reports, cleanup jobs |

## Deployment Configuration

### Rolling Update Strategy

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max pods above desired during update
      maxUnavailable: 0   # Zero downtime — always N pods running
  template:
    spec:
      containers:
      - name: app
        image: registry/service:v1.2.3
        ports:
        - containerPort: 8080
          name: http
```

**`maxUnavailable: 0`** ensures zero-downtime deploys but requires enough cluster capacity for surge pods.

### Resource Management

```yaml
resources:
  requests:
    memory: "256Mi"   # Scheduler uses this to place pods
    cpu: "100m"       # 100 millicores = 0.1 CPU
  limits:
    memory: "512Mi"   # OOMKilled if exceeded
    cpu: "500m"       # Throttled if exceeded (not killed)
```

**Guidelines**:
- `requests` = typical usage (what the scheduler plans for)
- `limits.memory` = 1.5-2x requests (OOM is worse than throttle)
- `limits.cpu` = 2-5x requests (CPU throttling is recoverable)
- Never set memory limit < request (guarantees OOM under load)

### Sizing Cheat Sheet

| Workload Type | Memory Request | CPU Request | Notes |
|---------------|---------------|-------------|-------|
| Node.js API service | 256Mi-512Mi | 100m-250m | V8 heap + overhead |
| Worker/consumer | 128Mi-256Mi | 50m-100m | Depends on processing |
| Database migration job | 256Mi | 100m | Short-lived |
| Frontend (nginx) | 64Mi-128Mi | 50m | Static file serving |

## Health Probes

### Three Probe Types

```yaml
# Liveness: Is the container alive? Restart if not.
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30    # Give app time to start
  periodSeconds: 10
  failureThreshold: 3        # 3 failures = restart

# Readiness: Can it handle traffic? Remove from service if not.
readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3        # 3 failures = stop sending traffic

# Startup: Is it still starting? Don't check liveness until started.
startupProbe:
  httpGet:
    path: /health
    port: 8080
  failureThreshold: 30       # 30 * 10s = 5 min max startup
  periodSeconds: 10
```

**Key distinction**: Liveness failure → restart. Readiness failure → stop traffic (no restart). Use startup probe for slow-starting apps to prevent premature liveness kills.

### Common Probe Mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| No `initialDelaySeconds` | Pod killed during startup | Set based on actual startup time |
| Liveness checks DB | DB outage restarts all pods | Liveness = process health only |
| Same path for liveness and readiness | Can't distinguish "crashed" from "overloaded" | Liveness = `/health`, readiness = `/health/ready` (checks dependencies) |

## Horizontal Pod Autoscaler (HPA)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5 min before scaling down
```

## Pod Disruption Budgets

Protect service availability during voluntary disruptions (node drains, cluster upgrades):

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
spec:
  minAvailable: 1          # Or use maxUnavailable: 1
  selector:
    matchLabels:
      app: my-service
```

**Always set PDBs for production services** — without them, a node drain can kill all pods simultaneously.

## Node Affinity and Topology

```yaml
# Spread pods across availability zones
topologySpreadConstraints:
- maxSkew: 1
  topologyKey: topology.kubernetes.io/zone
  whenUnsatisfiable: DoNotSchedule
  labelSelector:
    matchLabels:
      app: my-service
```
