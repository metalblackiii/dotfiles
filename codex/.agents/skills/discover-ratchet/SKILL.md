---
name: discover-ratchet
description: ALWAYS invoke for finding ratchetable optimization targets in a codebase — measurable metrics that can be improved iteratively. Triggers on "what can I ratchet", "find ratchet candidates", "discover metrics", "what's worth optimizing", or scanning a repo for iterative improvement opportunities. Do not start a ratchet loop directly. Not for qualitative code review (use quick-wins).
---

# Discover-Ratchet

Scan a codebase for quantitatively improvable targets — things with a number a command can measure. Output ranked candidates ready for `/ratchet`.

## The Iron Law

**Probe and report only. Never modify files, never start iterating.** This skill identifies targets; `/ratchet` does the work.

## Workflow

### 1. Detect Stack

Read the repo root to determine what probes apply:

| Indicator | Stack signal |
|---|---|
| `package.json` | Node/TypeScript — coverage, lint, bundle, deps |
| `tsconfig.json` | TypeScript — `any` count, strict errors |
| `.eslintrc*` / `eslint.config.*` | ESLint — warning/error count |
| `Cargo.toml` | Rust — clippy warnings, unsafe blocks, compile time |
| `pyproject.toml` / `setup.py` | Python — coverage, mypy errors, ruff warnings |
| `go.mod` | Go — vet warnings, staticcheck |
| `Dockerfile` | Container — image size, layer count |

Skip categories where the tooling isn't configured. Don't suggest installing tools.

### 2. Run Probes

For each detected category, run a fast measurement command. Every probe must complete in under 10 seconds — if it would take longer (e.g., full build for bundle size), note it as "needs build" and skip the live measurement.

Run probes in parallel where possible.

#### Probe Catalog

**TypeScript / JavaScript:**

| Candidate | Probe | Direction |
|---|---|---|
| `any` type count | `rg ":\s*any\b" --type ts -c <src>` | lower |
| ESLint errors | `npx eslint <src> --format json 2>/dev/null \| jq 'map(.errorCount) \| add // 0'` | lower |
| ESLint warnings | `npx eslint <src> --format json 2>/dev/null \| jq 'map(.warningCount) \| add // 0'` | lower |
| TypeScript strict errors | `npx tsc --noEmit 2>&1 \| grep -c "error TS"` | lower |
| Test coverage | `npm test -- --coverage 2>&1 \| grep "All files"` (parse %) | higher |
| Production dep count | `npm ls --prod --parseable 2>/dev/null \| wc -l` | lower |
| TODO/FIXME count | `rg "TODO\|FIXME" --type ts -c <src>` | lower |
| Bundle size | Requires build — note if `build` script exists, don't run | lower |

**Rust:**

| Candidate | Probe | Direction |
|---|---|---|
| Clippy warnings | `cargo clippy --message-format=short 2>&1 \| grep -c "warning"` (may need warm cache — skip on timeout) | lower |
| Unsafe blocks | `rg "unsafe\s*\{" --type rust -c` | lower |
| TODO/FIXME count | `rg "TODO\|FIXME" --type rust -c` | lower |

**Python:**

| Candidate | Probe | Direction |
|---|---|---|
| Mypy errors | `mypy <src> 2>&1 \| grep -c "error:"` | lower |
| Ruff warnings | `ruff check <src> 2>&1 \| tail -1` (parse count) | lower |
| Test coverage | `pytest --cov=<src> --cov-report=term 2>&1 \| grep "TOTAL"` (parse %) | higher |
| TODO/FIXME count | `rg "TODO\|FIXME" --type py -c` | lower |

**General (any stack):**

| Candidate | Probe | Direction |
|---|---|---|
| Longest function | Line-count heuristic or ast-grep if available | lower |

**Optional discovery (not directly ratchetable):**

If the codebase contains scoring, ranking, or weighting logic, note hardcoded tunables as a separate callout — these are autoresearch candidates, not ratchet candidates:

```
rg "\b(weight|threshold|score|boost|decay|multiplier|factor)\b.*=\s*[0-9]" --type-not test <src>
```

List the files and tunable names but don't generate a verify command or include them in the ranked output. Mention: "These may benefit from autoresearch-style parameter tuning rather than ratchet iteration."

Adapt probes to the actual project structure. If `src/` doesn't exist, find the real source root.

### 3. Score and Rank

Rate each candidate on two axes:

| Axis | Rating | Criteria |
|---|---|---|
| **Impact** | HIGH | Core metric (coverage, type safety, lint errors), large absolute count |
| | MED | Useful but secondary (TODOs, dep count), moderate count |
| | LOW | Marginal improvement, small absolute count |
| **Ease** | HIGH | Clear verify command, bounded scope, fast eval |
| | MED | Needs a helper script or scoped test run |
| | LOW | Requires build step, external service, or complex setup |

Rank by impact first, ease as tiebreaker. Drop candidates where the count is already near zero (fewer than 3 instances) — there's nothing to ratchet.

### 4. Report

Output a numbered list, highest-priority first:

```
=== Discover-Ratchet: <N> candidates in <repo> ===

1. [HIGH/HIGH]  TypeScript `any` count — src/services/ (47 instances)
   Verify:  rg ":\s*any\b" src/services/ --type ts -c | awk -F: '{s+=$2} END {print "SCORE:", s+0}'
   Scope:   src/services/**/*.ts
   Est:     10-15 iterations

2. [HIGH/MED]   Test coverage — src/auth/ (62%)
   Verify:  npm test -- --coverage 2>&1 | grep "src/auth" | awk '{print "SCORE:", $4}'
   Scope:   src/auth/**/*.ts, src/auth/**/*.test.ts
   Est:     15-20 iterations

3. [MED/HIGH]   ESLint warnings (38 remaining)
   Verify:  npx eslint src/ --format json 2>/dev/null | jq 'map(.warningCount) | add // 0' | xargs -I{} echo "SCORE: {}"
   Scope:   src/**/*.ts
   Est:     10 iterations

---
Pick a candidate and run: /ratchet
```

Each entry must include:
- **Priority tag** — `[impact/ease]`
- **What** — metric name, location, current value
- **Verify** — exact command producing `SCORE: <number>` (ratchet's output contract)
- **Scope** — file globs for the ratchet loop
- **Est** — suggested iteration count based on the count and verify speed

### 5. Suggest Next Step

End with: "Pick a candidate and run `/ratchet`" — nothing more. Don't start iterating, don't ask follow-up questions about which one to pick.

## Verify Command Contract

Every verify command in the output MUST produce `SCORE: <number>` — this is ratchet's input contract. If a raw probe doesn't naturally produce this format, pipe through `awk` or `xargs` to add the prefix. Always test the verify command before including it in the report.

## Boundaries

- **Not quick-wins** — quick-wins reports qualitative findings (dead code, code smells). Discover-ratchet reports quantitative metrics with exact commands.
- **Not ratchet** — discover-ratchet identifies targets. Ratchet iterates on them.
- **Not autoresearch** — autoresearch targets tunable parameters (weights, thresholds). Discover-ratchet targets any measurable metric.

## Constraints

### MUST DO
- Run probes against the actual codebase — never estimate counts
- Verify that probe commands work before including in the report
- Adapt source paths to the repo's actual structure
- Drop near-zero candidates (< 3 instances)

### MUST NOT DO
- Modify any files
- Start a ratchet loop
- Install tools or suggest installing tools
- Run probes that take longer than 10 seconds
- Include candidates without a working verify command
