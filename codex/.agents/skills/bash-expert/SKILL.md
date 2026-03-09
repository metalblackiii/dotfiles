---
name: bash-expert
description: Create, generate, validate, lint, audit, or fix bash/shell scripts (.sh). Covers script generation, ShellCheck analysis, POSIX compliance, and shell automation. Triggers on "create bash script", "validate shell script", "lint .sh file", "ShellCheck", "POSIX compliance", or any bash/shell scripting request.
---

# Bash Expert

Generate and validate production-ready bash/shell scripts with deterministic workflows, ShellCheck analysis, and iterative fix loops.

## When to Use

- Creating, generating, writing, or scaffolding bash/shell scripts
- Validating, linting, auditing, or fixing existing scripts
- Converting manual CLI steps into automation scripts
- Building text-processing scripts (grep, awk, sed)
- Making scripts POSIX-compliant or ShellCheck-clean

## Generation Workflow

### Stages (run in order)

1. **Preflight** — confirm scope, shell target (bash default, POSIX sh if portability needed).
2. **Capture requirements** — input source/format, output destination, error handling (fail-fast/retry/continue), security, performance, portability. Produce `Captured Requirements` table with `REQ-*` IDs.
3. **Choose generation path**:
   - Standard CLI skeleton (usage/logging/arg parsing/cleanup) → **Template-first** (default)
   - Multi-command architecture or unusual control flow → **Custom generation**
4. **Load only relevant references** (progressive disclosure):

   | Need | Reference |
   |------|-----------|
   | Tool choice (grep/awk/sed) | `docs/text-processing-guide.md` |
   | Script structure, arg patterns | `docs/script-patterns.md` |
   | Strict mode, shell differences | `docs/bash-scripting-guide.md` |
   | Naming, organization, quality | `docs/generation-best-practices.md` |

5. **Generate script**:
   - **Template-first**: `bash scripts/generate_script_template.sh standard output-script.sh`, then add business logic.
   - **Custom**: shebang + strict mode, `usage()`, `parse_args()`, input validation, dependency checks, main workflow, predictable exit codes.
6. **Validate and iterate** — use validation workflow below. Repeat until clean.
7. **Final response** — script path, requirements traceability (`REQ-*` → implementation), validation results, citations, assumptions.

### Citation Format (required)

`[Ref: docs/<file>.md -> <section>]`

## Validation Workflow

### Execution Flow

1. **Preflight** — confirm target exists, bash available, determine write access.
2. **Run baseline validation**:
   ```bash
   bash scripts/validate.sh <script-path>
   ```
   Optional: `VALIDATOR_SHELLCHECK_MODE=system|wrapper|disabled` for explicit control.
3. **Record**: detected shell type, exit code (`0` clean, `1` warnings, `2` errors), all issue lines and ShellCheck codes.
4. **Load only needed references**:

   | Issue Type | Reference |
   |-----------|-----------|
   | ShellCheck code explanations | `docs/shellcheck-reference.md` |
   | Fix patterns, security mistakes | `docs/common-mistakes.md` |
   | Bash-only behavior | `docs/bash-reference.md` |
   | POSIX portability / bashism fixes | `docs/shell-reference.md` |
   | Text-processing issues | `docs/grep-reference.md`, `docs/awk-reference.md`, `docs/sed-reference.md` |

5. **Provide or apply fixes** — for each issue: exact location, root cause, corrected code, why, citation.
6. **Mandatory post-fix rerun**: `bash scripts/validate.sh <script-path>`. Continue until stable.

### Fix Citation Format

```
Reference: docs/<file>.md -> <Section> -> <Subsection>
```

## Fallback Behavior

| Constraint | Action |
|-----------|--------|
| shellcheck missing, wrapper available | `scripts/validate.sh` uses `scripts/shellcheck_wrapper.sh --cache` automatically |
| shellcheck and wrapper unavailable | Syntax + custom checks only, state reduced coverage |
| Python unavailable for wrapper | Skip wrapper, keep syntax + custom checks |
| Read-only target | Advisory-only suggestions |
| CI gate mode | `bash scripts/run_generator_ci.sh` or `bash scripts/run_validator_ci.sh` |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/generate_script_template.sh` | Scaffold new scripts from templates |
| `scripts/validate.sh` | Primary validator entrypoint |
| `scripts/shellcheck_wrapper.sh` | ShellCheck fallback via cached Python venv |
| `scripts/run_generator_ci.sh` | CI gate for generator scripts (syntax + shellcheck + regression) |
| `scripts/run_validator_ci.sh` | CI gate for validator (requires system shellcheck) |
| `scripts/test_generator.sh` | Generator regression tests |
| `scripts/test_validate.sh` | Validator regression tests |

## References

| File | Content |
|------|---------|
| `docs/bash-scripting-guide.md` | Strict mode, shell differences, safety |
| `docs/script-patterns.md` | Script structure and argument patterns |
| `docs/generation-best-practices.md` | Naming, organization, quality baseline |
| `docs/text-processing-guide.md` | grep vs awk vs sed tool choice |
| `docs/shellcheck-reference.md` | ShellCheck code explanations |
| `docs/common-mistakes.md` | Fix patterns and security mistakes |
| `docs/bash-reference.md` | Bash-only behavior |
| `docs/shell-reference.md` | POSIX portability, bashism fixes |
| `docs/grep-reference.md` | grep patterns |
| `docs/awk-reference.md` | awk patterns |
| `docs/sed-reference.md` | sed patterns |
| `docs/regex-reference.md` | Regular expression reference |

## Done Criteria

### Generation
- `Captured Requirements` table with `REQ-*` IDs exists.
- Template-first vs custom decision documented.
- Script generated with deterministic structure.
- Validation executed, rerun policy applied.
- Skipped checks include reason and risk.
- Final response has traceability, citations, assumptions.

### Validation
- Target file verified.
- Validation command (or fallback) executed.
- Findings with subsection-level citations.
- Post-fix rerun mandatory, exit code and remaining count reported.
