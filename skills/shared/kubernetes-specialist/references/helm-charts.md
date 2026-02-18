# Helm Charts

## Chart Structure

Standard Helm chart layout for service deployments:

```
helm/
├── Chart.yaml              # Chart metadata (name, version, appVersion)
├── values.yaml             # Default values
├── values-dev.yaml         # Environment overrides
├── values-staging.yaml
├── values-prod.yaml
├── templates/
│   ├── _helpers.tpl        # Template helpers (labels, names, selectors)
│   ├── deployment.yaml     # Deployment spec
│   ├── service.yaml        # Service (ClusterIP, NodePort, LoadBalancer)
│   ├── ingress.yaml        # Ingress rules
│   ├── configmap.yaml      # Non-sensitive configuration
│   ├── secret.yaml         # Sensitive configuration (or external-secrets)
│   ├── hpa.yaml            # Horizontal Pod Autoscaler
│   ├── serviceaccount.yaml # Dedicated service account
│   ├── networkpolicy.yaml  # Network segmentation
│   └── tests/
│       └── test-connection.yaml
└── .helmignore
```

## values.yaml Patterns

### Core Values

```yaml
replicaCount: 2

image:
  repository: your-registry/service-name
  tag: ""  # Set by CI/CD
  pullPolicy: IfNotPresent

resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"

env:
  NODE_ENV: production
  LOG_LEVEL: info

# Service-specific env vars (cross-service URLs, feature flags)
serviceEnv:
  NEB_REGISTRY_API_URL: ""
  NEB_BILLING_API_URL: ""
```

### Health Checks

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /health/ready
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3
```

### Autoscaling

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

## Template Patterns

### Labels (_helpers.tpl)

```yaml
{{- define "service.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
environment: {{ .Values.environment | default "dev" }}
{{- end }}

{{- define "service.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

### Environment Variables from Multiple Sources

```yaml
# In deployment.yaml
env:
  {{- range $key, $val := .Values.env }}
  - name: {{ $key }}
    value: {{ $val | quote }}
  {{- end }}
  {{- range $key, $val := .Values.serviceEnv }}
  - name: {{ $key }}
    value: {{ $val | quote }}
  {{- end }}
envFrom:
  - secretRef:
      name: {{ include "service.fullname" . }}-secrets
  - configMapRef:
      name: {{ include "service.fullname" . }}-config
```

### Conditional Resources

```yaml
# Only create HPA if autoscaling is enabled
{{- if .Values.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
...
{{- end }}
```

## Environment Overrides

Use environment-specific values files for differences between environments:

```yaml
# values-prod.yaml — only overrides, not full copy
replicaCount: 3

resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "1000m"

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
```

Deploy with: `helm upgrade --install service-name ./helm -f helm/values.yaml -f helm/values-prod.yaml`

## Common Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| No resource limits | Pod consumes entire node | Always set requests AND limits |
| `latest` image tag | Non-deterministic deployments | Pin to specific tag/SHA |
| Secrets in values.yaml | Credentials in git | Use external-secrets or sealed-secrets |
| No readiness probe | Traffic sent to starting pods | Always define readiness probe |
| Hardcoded replicas in prod | Can't scale with load | Use HPA for production |
| No PDB (PodDisruptionBudget) | All pods killed during node drain | Set `minAvailable` for critical services |
