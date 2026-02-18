# Troubleshooting

## Diagnostic Flowchart

```
Pod not running?
├── Pending → Check: resources, node selector, taints, PVC
├── CrashLoopBackOff → Check: logs, liveness probe, OOM, config
├── ImagePullBackOff → Check: image name, tag, registry auth
├── Init:Error → Check: init container logs
└── Running but not ready → Check: readiness probe, dependencies
```

## kubectl Commands

### Pod Status

```bash
# Overview of all pods in namespace
kubectl get pods -n <namespace> -o wide

# Detailed pod info (events, conditions, volumes)
kubectl describe pod <pod-name> -n <namespace>

# Recent events (sorted by time)
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

### Logs

```bash
# Current container logs
kubectl logs <pod-name> -n <namespace>

# Previous container logs (after crash)
kubectl logs <pod-name> -n <namespace> --previous

# Follow logs in real time
kubectl logs -f <pod-name> -n <namespace>

# Logs from specific container in multi-container pod
kubectl logs <pod-name> -c <container-name> -n <namespace>

# Last N lines
kubectl logs <pod-name> -n <namespace> --tail=100
```

### Exec into Pods

```bash
# Interactive shell
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Run a single command
kubectl exec <pod-name> -n <namespace> -- env | grep NEB_

# Check DNS resolution
kubectl exec <pod-name> -n <namespace> -- nslookup <service-name>

# Check connectivity to another service
kubectl exec <pod-name> -n <namespace> -- curl -s http://<service>:<port>/health
```

### Resource Usage

```bash
# Pod resource consumption (requires metrics-server)
kubectl top pods -n <namespace>

# Node resource consumption
kubectl top nodes

# Sort by memory usage
kubectl top pods -n <namespace> --sort-by=memory
```

## Common Issues

### CrashLoopBackOff

**Symptom**: Pod starts, crashes, restarts, crashes again with increasing backoff.

**Diagnostic steps**:
1. `kubectl logs <pod> --previous` — check the crash logs
2. `kubectl describe pod <pod>` — check Last State exit code
3. Common exit codes:
   - **Exit 1**: Application error (check logs)
   - **Exit 137**: OOMKilled (increase memory limit)
   - **Exit 143**: SIGTERM (graceful shutdown issue)

**Common causes**:
| Cause | Signal | Fix |
|-------|--------|-----|
| Missing env var | Error in logs about undefined config | Check ConfigMap/Secret mounting |
| Database unreachable | Connection timeout in logs | Check network policy, DNS, credentials |
| Port conflict | "Address already in use" | Check containerPort matches app config |
| OOM | Exit code 137, `OOMKilled` in describe | Increase memory limit |
| Failed health check | Liveness probe failing in events | Fix probe path/port, increase initialDelaySeconds |

### ImagePullBackOff

```bash
# Check the exact error
kubectl describe pod <pod> | grep -A 5 "Events"

# Common fixes:
# 1. Wrong image name/tag
# 2. Private registry — need imagePullSecrets
# 3. Image doesn't exist (typo in tag)
```

### Pending Pods

```bash
kubectl describe pod <pod> | grep -A 10 "Events"
```

| Event Message | Cause | Fix |
|--------------|-------|-----|
| `Insufficient cpu` | No node has enough CPU | Reduce requests or add nodes |
| `Insufficient memory` | No node has enough memory | Reduce requests or add nodes |
| `node(s) had taints` | Node taints don't match tolerations | Add toleration or use different nodes |
| `no persistent volumes available` | PVC can't be bound | Check StorageClass, PV availability |
| `0/N nodes are available` | Scheduling constraints too strict | Check nodeSelector, affinity rules |

### Networking Issues

```bash
# Check service endpoints
kubectl get endpoints <service-name> -n <namespace>

# Verify DNS resolution from inside cluster
kubectl run dns-test --image=busybox --rm -it -- nslookup <service-name>.<namespace>.svc.cluster.local

# Check NetworkPolicy (if pods can't communicate)
kubectl get networkpolicy -n <namespace>
kubectl describe networkpolicy <policy-name> -n <namespace>
```

| Symptom | Likely Cause | Check |
|---------|-------------|-------|
| Connection refused | Service not running or wrong port | `kubectl get endpoints` |
| Connection timeout | NetworkPolicy blocking traffic | `kubectl get networkpolicy` |
| DNS resolution fails | Service doesn't exist or wrong namespace | `kubectl get svc -A` |
| Intermittent failures | Pod not ready but in service | Check readiness probe |

### OOM (Out of Memory)

```bash
# Check if pod was OOMKilled
kubectl describe pod <pod> | grep -A 3 "Last State"

# Check current memory usage vs limits
kubectl top pod <pod> -n <namespace>
```

**Fix**: Increase `resources.limits.memory`. If the app genuinely needs more memory, also increase `resources.requests.memory` so the scheduler places it on nodes with enough capacity.

## Helm-Specific Debugging

```bash
# See what Helm would deploy (dry run)
helm template ./helm -f helm/values.yaml -f helm/values-prod.yaml

# Check deployed release status
helm status <release-name> -n <namespace>

# See deployed values
helm get values <release-name> -n <namespace>

# See full manifest of deployed release
helm get manifest <release-name> -n <namespace>

# Rollback to previous release
helm rollback <release-name> <revision> -n <namespace>

# List release history
helm history <release-name> -n <namespace>
```
