---
name: helm-expert
description: Create, scaffold, generate, validate, lint, audit, or check Helm charts, Chart.yaml, values.yaml, templates, CRDs, and schemas. Triggers on "create Helm chart", "validate Helm chart", "lint chart", "scaffold chart", "Helm templates", or any Helm request.
---

# Helm Expert

Generate and validate production-ready Helm charts with deterministic scaffolding, standard helpers, reusable templates, security checks, and multi-stage validation loops.

## When to Use

- Creating, scaffolding, or generating new Helm charts
- Generating Helm templates (Deployment, Service, Ingress, HPA, etc.)
- Converting K8s manifests to Helm charts
- Validating, linting, auditing, or checking existing charts
- Troubleshooting template rendering failures
- Pre-deployment quality gates (schema, dry-run, security)

## Generation Workflow

### Stages (run in order)

1. **Gather requirements** — scope, workload type (deployment/statefulset/daemonset), image, ports (service + target), probes, autoscaling, ingress, storage, security.
2. **CRD doc lookup** (only if CRDs in scope) — try Context7 first, then operator docs. Also: `references/crd_patterns.md`.
3. **Scaffold chart structure**:
   ```bash
   bash scripts/generate_chart_structure.sh <chart-name> <output-dir> [options]
   ```
   Options: `--image`, `--port`, `--target-port`, `--type`, `--with-templates`, `--with-ingress`, `--with-hpa`, `--force`
4. **Generate standard helpers**:
   ```bash
   bash scripts/generate_standard_helpers.sh <chart-name> <chart-dir>
   ```
   Required helpers: `name`, `fullname`, `chart`, `labels`, `selectorLabels`, `serviceAccountName`.
5. **Consult references and generate templates**:
   - `references/resource_templates.md` for resource patterns
   - `references/helm_template_functions.md` for templating functions
6. **Create values.yaml** — group logically, `# --` comments, sensible defaults, separate `service.port`/`service.targetPort`.
7. **Validate** — use validation workflow below.

### Key Template Patterns

```yaml
metadata:
  name: {{ include "mychart.fullname" . }}
  labels: {{- include "mychart.labels" . | nindent 4 }}

{{- with .Values.nodeSelector }}
nodeSelector: {{- toYaml . | nindent 2 }}
{{- end }}

annotations:
  {{- if and .Values.configMap .Values.configMap.enabled }}
  checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
  {{- end }}
```

### Template Functions Quick Reference

| Function | Purpose | Example |
|----------|---------|---------|
| `required` | Enforce required values | `{{ required "msg" .Values.x }}` |
| `default` | Fallback value | `{{ .Values.x \| default 1 }}` |
| `quote` | Quote strings | `{{ .Values.x \| quote }}` |
| `include` | Use helpers | `{{ include "name" . \| nindent 4 }}` |
| `toYaml` | Convert to YAML | `{{ toYaml .Values.x \| nindent 2 }}` |
| `tpl` | Render as template | `{{ tpl .Values.config . }}` |

## Validation Workflow

### Stages (1-10, run in order)

1. **Tool check** — `bash scripts/setup_tools.sh`. Required: helm, yamllint, kubeconform. Optional: kubectl.
2. **Structure validation** — `bash scripts/validate_chart_structure.sh <chart-dir>`
3. **Helm lint** — `helm lint <chart-dir> --strict`
4. **Template rendering** — `helm template <release> <chart-dir> --values <values> --debug --output-dir ./rendered`
5. **YAML syntax** — `yamllint -c assets/.yamllint` on rendered files
6. **CRD detection** — `bash scripts/detect_crd_wrapper.sh` on rendered files. Look up docs via Context7 or web search.
7. **Schema validation** — `kubeconform -summary -verbose` with CRD catalog schema location
8. **Cluster dry-run** (optional, needs kubectl) — `helm install --dry-run=server` and `helm upgrade --dry-run=server`
9. **Security check** (MANDATORY) — verify in rendered templates:
   - Pod securityContext: `runAsNonRoot`, `runAsUser`, `fsGroup`
   - Container securityContext: `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, `capabilities.drop: [ALL]`
   - Resource limits/requests
   - No `:latest` image tags
   - Liveness/readiness probes
10. **Final report** (MANDATORY) — Stage 1-9 status table, severity-grouped findings, proposed changes

### Execution Model

- Keep going after stage-level failures to collect complete findings.
- If Stage 4 produces no manifests, mark Stages 5-9 as blocked.
- Stage 8 is environment-dependent optional; Stages 9-10 are mandatory.
- Default is **read-only** — do not modify files unless user explicitly asks.

### Fallback Behavior

| Condition | Action |
|-----------|--------|
| `helm` missing | Run Stage 2 only, Stages 3-9 blocked |
| `yamllint` missing | Use `yq` or skip Stage 5 |
| `kubeconform` missing | Skip Stage 7 |
| `kubectl` missing / no context | Skip Stage 8 |
| macOS extended attributes blocking helm | `xattr -cr <chart-dir>/` |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/generate_chart_structure.sh` | Scaffold chart with templates, ingress, HPA |
| `scripts/generate_standard_helpers.sh` | Generate standard `_helpers.tpl` |
| `scripts/generate_helpers.sh` | Generate helpers for existing charts |
| `scripts/setup_tools.sh` | Check/install validation tools |
| `scripts/validate_chart_structure.sh` | Validate chart directory structure |
| `scripts/detect_crd_wrapper.sh` | Detect CRDs in rendered output |
| `scripts/detect_crd.py` | CRD detection (Python, called by wrapper) |

## References

| File | Content |
|------|---------|
| `references/resource_templates.md` | All K8s resource templates (Deployment, Service, Ingress, etc.) |
| `references/helm_template_functions.md` | Template function guide |
| `references/crd_patterns.md` | CRD patterns (cert-manager, Prometheus, Istio, ArgoCD) |
| `references/helm_best_practices.md` | Chart best practices |
| `references/k8s_best_practices.md` | Kubernetes YAML best practices |
| `references/template_functions.md` | Extended function reference |

## Assets

| File | Purpose |
|------|---------|
| `assets/_helpers-template.tpl` | Standard helpers template |
| `assets/values-schema-template.json` | JSON Schema for values validation |
| `assets/values.schema.json` | Example values schema |
| `assets/.helmignore` | Standard .helmignore |
| `assets/.yamllint` | yamllint rules for K8s YAML |

## Done Criteria

### Generation
- `Chart.yaml`, `values.yaml`, `.helmignore`, `NOTES.txt`, `_helpers.tpl` exist.
- `values.yaml` has explicit `service.port` and `service.targetPort`.
- Workload template uses conditional checksum annotations.
- Image rendering supports tag and digest modes.
- Validation completed and outcomes reported.

### Validation
- Stage 1-10 status table present.
- Every skipped stage has concrete reason.
- Severity totals reported with remediation actions.
- No file edits unless explicitly requested.
