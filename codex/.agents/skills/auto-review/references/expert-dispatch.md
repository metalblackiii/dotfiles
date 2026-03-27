# Expert Panel Dispatch

Domain-expert subagents are dispatched in parallel during Phase 1 (initial review only). Each expert brings specialized knowledge from an existing skill to catch issues that the standard `pr-analysis` pass might miss.

## Dispatch Cap

**Maximum 4 experts per review cycle.** When more than 4 experts match, select the top 4 by priority tier. Within a tier, prefer experts with more matched files. If still tied, use table order (earlier row wins).

| Tier | Experts | Rationale |
|---|---|---|
| 4 (highest) | Security | Highest-risk domain; hardest to catch in standard pass |
| 3 | Database, Neb Conventions, TypeScript | Deep domain knowledge standard analysis lacks |
| 2 | API Design, Platform, Frontend (neb-www), Dependencies, Refactoring | Specialized but partially covered by standard analysis |
| 1 | CI/CD, Infrastructure, Bash | Contextual; lower frequency |

Frontend (non-neb-www) uses `pr-analysis` inline and does not dispatch a subagent — it never counts toward the cap. Frontend (neb-www) dispatches `www-design` and counts toward the cap.

## Expert Heuristic Table

Match changed file paths (and repo metadata) against these patterns. Multiple experts may match for a single PR.

| Pattern | Expert | Skill to Load | Match Logic |
|---|---|---|---|
| `*.sql`, `migrations/**`, `models/**`, files containing Sequelize imports | Database | `../database-expert/SKILL.md` | Path glob or content grep for `sequelize`, `DataTypes`, `QueryInterface` |
| Auth middleware, Cognito config, `**/permissions/**`, files referencing `userSecurity` | Security | `../secure-code-guardian/SKILL.md` + `../security-review/SKILL.md` | Path contains `auth`, `cognito`, `permission`, `security`; or diff contains `userSecurity`, `SECURITY_SCHEMA_KEYS` |
| `Dockerfile*`, `docker-compose*`, `.dockerignore` | Infrastructure | `../dockerfile-expert/SKILL.md` | Path glob |
| `.github/workflows/**`, `action.yml`, `action.yaml` | CI/CD | `../gha-expert/SKILL.md` | Path glob |
| `routes/**`, `controllers/**`, files with route definitions or API contracts | API Design | `../api-designer/SKILL.md` | Path contains `route`, `controller`; or diff contains `router.get`, `router.post`, `app.use`. **Suppressed when Neb Conventions is dispatched** — see Conflict Resolution. |
| `**/charts/**`, `**/helm/**`, k8s manifests, `values*.yaml` | Platform | `../helm-expert/SKILL.md` + `../k8s-expert/SKILL.md`. When `values.yaml` or `values-*.yaml` are in scope, additionally load `../neb-helm-env/SKILL.md`. | Path contains `chart`, `helm`; path glob matches `values.yaml` or `values-*.yaml`; or YAML content has `apiVersion:` + `kind:` |
| Frontend in neb-www: new components, pages, significant template/layout changes | Frontend | `../www-design/SKILL.md` | Repo is `*/neb-www` AND diff adds new component files, page routes, or substantial template changes (>50 lines of HTML/Lit template). For non-neb-www repos or trivial frontend changes, use `pr-analysis` frontend category inline (no subagent). |
| Frontend (other repos): `*.tsx`, `*.jsx`, `*.css`, `*.scss`, component directories | Frontend (inline) | Use `pr-analysis` frontend category (no separate skill) | Path glob for frontend extensions. Does not dispatch a subagent — never counts toward cap. |
| Large structural changes: >500 lines changed AND >5 files renamed/moved | Refactoring | `../code-renovator/SKILL.md` | Computed from PR metadata: `additions + deletions > 500` and rename count > 5 |
| `*.ts`, `*.tsx` where diff contains type-level constructs | TypeScript | `../typescript-expert/SKILL.md` | Path glob for TS extensions AND diff contains `interface `, `type `, `<T`, ` as `, `: any`, `extends `, `implements `, `Partial<`, `Omit<`, `Pick<`, `Record<` |
| Repo name matches `*/neb-ms-*` or `*/neb-microservice` | Neb Conventions | `../neb-ms-conventions/SKILL.md` + relevant categories from `../api-designer/SKILL.md` | Repo-level match on `org/repo` name. **Subsumes API Design** — see Conflict Resolution. |
| `*.sh`, `*.bash`, shebang `#!/bin/bash` or `#!/bin/sh` | Bash | `../bash-expert/SKILL.md` | Path glob or first-line shebang detection |
| `package.json`, `package-lock.json`, `Cargo.toml`, `Cargo.lock`, `requirements.txt`, `Brewfile` | Dependencies | `../snyk-expert/SKILL.md` | Path glob for dependency manifests and lockfiles |

### Conflict Resolution

**Neb Conventions subsumes API Design.** When the repo matches `*/neb-ms-*` or `*/neb-microservice`, Neb Conventions is dispatched instead of API Design for route/controller files. The Neb Conventions expert's prompt includes relevant API design criteria from `api-designer/SKILL.md` so REST design coverage isn't lost — it's reviewed through a neb-aware lens. API Design is only dispatched independently if it matched files outside routes/controllers that Neb Conventions doesn't cover.

### Pattern Matching Implementation

```
matched_experts = {}

# Path-based matching (skip inline-only rows — they don't dispatch subagents)
for each file in changed_files:
  for each expert in heuristic_table:
    if expert is inline-only (e.g., Frontend other repos):
      continue
    if file.path matches expert.pattern:
      mark expert as needed
      add file to expert's scope

# Content-based matching (Sequelize, userSecurity, type constructs, etc.)
for each content trigger in diff output:
  mark matching expert as needed
  add triggering file to expert's scope

# Repo-level matching (Neb Conventions)
if repo name matches neb-ms-* or neb-microservice:
  mark Neb Conventions as needed with all changed files in scope

# Repo-level matching (Frontend / neb-www)
if repo name matches */neb-www:
  if diff adds new component files, page routes, or >50 lines of template:
    mark Frontend (neb-www) as needed with frontend files in scope

# Shebang detection (Bash)
for each file without .sh/.bash extension:
  if first line matches #!/bin/(ba)?sh:
    mark Bash expert as needed
    add file to Bash expert scope

# Platform enrichment (neb-helm-env)
if Platform expert matched AND scope contains values.yaml or values-*.yaml:
  add neb-helm-env/SKILL.md to Platform expert's domain knowledge

# Conflict resolution
if Neb Conventions dispatched AND API Design dispatched:
  merge API Design's route/controller files into Neb Conventions scope
  remove API Design unless it has non-route/controller files remaining

# Cap enforcement (max 4)
if len(matched_experts) > 4:
  sort by priority tier (descending), then by matched file count (descending),
    then by heuristic table order (ascending, earlier row wins)
  keep top 4, discard rest
```

If no experts match, skip dispatch entirely — the standard `pr-analysis` analysis is sufficient.

## Subagent Prompt Template

Each expert subagent receives a focused prompt. Use the `Agent` tool to dispatch.

```
You are a {expert_domain} expert reviewing a pull request.

## Your Domain Knowledge
{content of the domain skill's SKILL.md}

## Review Criteria
{relevant categories from pr-analysis for this domain}

## PR Context
- Title: {title}
- Author: {author}
- Files in your scope: {list of files this expert should focus on}

## Diff (Your Scope Only)
{filtered diff — only files relevant to this expert}

## Full File Context
{full content of files in scope, for surrounding context}

## Instructions
1. Review the diff through the lens of your domain expertise
2. Read full files when the diff alone is insufficient
3. Apply the review criteria and your domain knowledge
4. Focus on issues the standard review might miss — your value is depth, not breadth

Return findings as JSON:

{
  "expert": "{expert_domain}",
  "findings": [
    {
      "severity": "Critical|Important|Minor",
      "title": "short descriptive title",
      "repo": "org/repo",
      "location": "path/to/file.ext:line",
      "evidence": "what you observed in the code",
      "recommendation": "specific fix or improvement"
    }
  ],
  "looks_good": ["positive observations specific to your domain"]
}

For single-PR reviews, `repo` may be omitted. For multi-PR reviews, `repo` is required — experts receive files from multiple repos and must attribute findings accurately.

Rules:
- Only report findings within your domain expertise
- Provide evidence from the actual code — no speculation
- Read full file context before flagging patterns
- If unsure, flag as a question, not a finding
```

## Dispatch Mechanics

Dispatch is platform-specific. Both paths use the same subagent prompt template above and target a cost-effective model for review work.

### Claude Code

Use the `Agent` tool. Dispatch all matched experts in a single message for parallel execution.

```
Agent(
  description: "{expert_domain} expert review",
  prompt: <filled template above>,
  subagent_type: "general-purpose",
  model: "sonnet",
  run_in_background: true
)
```

Wait for all background agents to complete before proceeding to synthesis.

### Codex

Use `spawn_agent` / `wait` to dispatch each expert. Send the prompt template as `message`.

```
agent_id = spawn_agent(
  agent_type: "worker",
  message: <filled template above>
)
```

Valid `agent_type` values: `default`, `explorer`, `worker`. Use `worker` for expert review subagents.

Dispatch all matched experts, then `wait` for all to return results.

### Notes

- Sonnet (Claude Code) is specified explicitly to avoid inheriting an expensive parent model. Codex model selection is environment-level.
- Both platforms: dispatch all matched experts before waiting. Parallel fan-out, then synthesize.

## Merge and Deduplication Algorithm

After all subagents return:

1. **Collect**: Gather findings from standard analysis + all expert subagents into a single list
2. **Normalize**: Ensure every finding has severity, title, location (file:line), evidence, recommendation. For multi-PR reviews, also require `repo` (org/repo).
3. **Dedup**:
   - Group findings by `repo + file path` (for multi-PR) or `file path` alone (single-PR)
   - Within each group, compare findings with overlapping line ranges (within 3 lines)
   - If two findings overlap AND share the same issue category, keep the more specific one:
     - Prefer the finding with longer evidence (more detail)
     - Prefer the finding from the domain expert over standard analysis (expert has deeper context)
     - If tied, keep both (different angles on the same issue are valuable)
4. **Sort**: Critical first, then Important, then Minor. Within each tier, sort by file path then line number
5. **Assign IDs**: Sequential `f-1`, `f-2`, ... for metrics tracking

### Dedup Examples

| Finding A | Finding B | Decision |
|---|---|---|
| Standard: "Missing error handling" at `auth.js:42` | Security expert: "Auth middleware silently swallows invalid tokens" at `auth.js:41` | Keep Security expert version (more specific, within 3 lines, same category) |
| Standard: "Empty catch block" at `api.js:100` | API expert: "Missing request validation" at `api.js:105` | Keep both (different categories despite proximity) |
| Database: "Missing index on user_id" at `migration.sql:15` | Standard: "Missing index on user_id" at `migration.sql:15` | Keep Database version (expert has deeper context, same issue) |
| Neb Conventions: "Business logic in controller" at `routes/patient.js:30` | API Design: "Controller too thick" at `routes/patient.js:28` | Neb Conventions wins (subsumes API Design in neb repos; if both findings survived dedup, keep the neb-specific framing) |
