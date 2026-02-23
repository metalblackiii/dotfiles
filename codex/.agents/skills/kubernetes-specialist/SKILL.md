---
name: kubernetes-specialist
description: Use when deploying or managing Kubernetes workloads, writing or modifying Helm charts, troubleshooting pod issues, configuring RBAC or NetworkPolicies, or optimizing cluster resource usage
---

# Kubernetes Specialist

Production Kubernetes specialist for deploying and managing containerized services. Focuses on Helm charts, workload configuration, security hardening, and troubleshooting.

## When to Use

- Writing or modifying Helm charts for service deployments
- Configuring workloads (Deployments, StatefulSets, Jobs, CronJobs)
- Troubleshooting pod failures, CrashLoopBackOffs, or networking issues
- Setting up or reviewing RBAC, NetworkPolicies, or Pod Security
- Configuring persistent storage, ConfigMaps, or Secrets
- Optimizing resource requests/limits and scaling behavior

## Core Workflow

1. **Analyze** — Understand workload characteristics: stateless/stateful, scaling needs, storage, networking, security requirements
2. **Design** — Choose workload types, define resource requests/limits, plan health checks
3. **Implement** — Write declarative YAML manifests or Helm templates with proper structure
4. **Secure** — Apply RBAC, NetworkPolicies, Pod Security Standards, least privilege
5. **Validate** — Test deployments, verify health checks, confirm resource limits, check security posture

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Helm Charts | `references/helm-charts.md` | Writing or modifying Helm charts, values files, template patterns |
| Workloads & Scheduling | `references/workloads.md` | Deployments, StatefulSets, Jobs, resource limits, probes, scaling |
| Troubleshooting | `references/troubleshooting.md` | Pod failures, networking issues, storage problems, debugging |

## Constraints

### MUST DO
- Use declarative YAML manifests (avoid imperative kubectl commands for production)
- Set resource requests AND limits on all containers
- Include liveness and readiness probes for all services
- Use Secrets for sensitive data (never hardcode credentials in manifests)
- Apply least privilege RBAC — dedicated ServiceAccounts per workload
- Label resources consistently (app, version, component, environment)
- Pin image tags to specific versions (never use `latest` in production)

### MUST NOT DO
- Deploy without resource limits (risks node-level resource starvation)
- Store secrets in ConfigMaps or plain environment variables
- Use the default ServiceAccount for application pods
- Run containers as root without documented justification
- Skip health checks on any long-running service
- Allow unrestricted network access (default allow-all NetworkPolicy)
- Expose internal services without ingress/gateway configuration

## Related Skills

- **docker-infrastructure** — for container builds and local Docker development
- **neb-ms-conventions** — for neb service structure (helm/ directory, deployment patterns)
