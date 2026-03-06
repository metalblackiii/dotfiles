# SAST Interpretation Guide

## What SAST Finds

Snyk Code (SAST) analyzes your source code for security anti-patterns — places where untrusted input reaches a dangerous operation without proper validation.

### Common Finding Categories

| Category | CWE | Example | Typical Severity |
|----------|-----|---------|-----------------|
| SQL Injection | CWE-89 | Unsanitized input in raw SQL query | High |
| Cross-Site Scripting (XSS) | CWE-79 | User input rendered without encoding | High |
| Command Injection | CWE-78 | User input in `exec()` / `execSync()` | High |
| Path Traversal | CWE-22 | User input in file path operations | Medium |
| Open Redirect | CWE-601 | User input in redirect URL | Medium |
| Hardcoded Secrets | CWE-798 | API keys, passwords in source | High |
| Insecure Deserialization | CWE-502 | Untrusted data in `JSON.parse()` to eval | Medium |
| Information Exposure | CWE-200 | Error messages leaking stack traces | Medium |
| Server-Side Request Forgery | CWE-918 | User input in outbound HTTP requests | High |

## Reading SAST Output

### The Data Flow

Each SAST finding includes a data flow trace showing how untrusted data reaches a dangerous sink:

```
SOURCE: HTTP request parameter (req.query.id)
  → THROUGH: variable assignment (const userId = req.query.id)
  → THROUGH: string concatenation (`SELECT * FROM users WHERE id = ${userId}`)
  → SINK: database query (db.query(...))
```

Understanding the flow is critical for determining if a finding is a true positive or false positive.

### True Positive Indicators

- Source is genuinely untrusted (HTTP params, user input, external API response)
- No validation/sanitization between source and sink
- Sink is genuinely dangerous (SQL query, shell command, file path, redirect)

### False Positive Indicators

- Source is internal/trusted (config file, environment variable, hardcoded constant)
- Input is validated between source and sink (but Snyk doesn't see it across files)
- CLI tool where command-line args are the expected input (not "untrusted" in context)
- The "dangerous" operation is intentional and safe in context

## Common False Positives in Neb Services

### Path Traversal from CLI Arguments

```
Finding: Unsanitized input from a command line argument flows into fs.readFileSync
```

For CLI tools (like platform-ops), command-line arguments ARE the expected input. This is a false positive for internal-only tools. It's a true positive for user-facing services.

**Decision framework:**
- Internal CLI tool → accept/ignore with reason
- User-facing API endpoint → fix it

### Command Injection from Exception Messages

```
Finding: Unsanitized input from an exception flows into child_process.execSync
```

Check: is the exception message actually user-controlled? If it comes from a caught error in your own code, it's likely a false positive. If it comes from user input that triggers the error, it may be real.

### SQL "Injection" in Sequelize

Sequelize parameterizes queries by default. Findings on Sequelize model methods (`.findAll()`, `.findOne()`) are usually false positives — the ORM handles escaping. True positives are:
- `sequelize.query()` with string interpolation (raw query)
- `Sequelize.literal()` with user input

## SAST vs SCA Priority

| Dimension | SAST | SCA |
|-----------|------|-----|
| Fix effort | High (code rewrite) | Low (version bump) |
| Fix reliability | Uncertain (requires understanding logic) | High (deterministic upgrade) |
| AI fix success rate | ~5-11% survive verification | High (mechanical change) |
| False positive rate | Higher | Lower |
| Impact if real | Direct exploitation of your code | Depends on reachability |

**Rule of thumb:** Fix SCA first (faster, more reliable), then review SAST findings with human judgment. Don't auto-fix SAST findings — present them for manual review.

## Snyk Code Limitations

- **Single-file analysis only** — cannot trace data flow across file boundaries (inter-file analysis is limited)
- **No `critical` severity** — highest is `high`
- **`.snyk` ignores don't work** — must use dashboard ignores or `--file-path` exclusions
- **No fix suggestions via CLI** — Snyk Agent Fix (AI-powered code fixes) is IDE-only, not CLI
- **No output file when clean** — `--json-file-output` doesn't create the file if no issues found

## Handling SAST Results

### For the Skill Workflow

1. Run `snyk code test --json` and capture results
2. Group findings by file and severity
3. Present to human with data flow summary
4. Human decides: fix now, accept, or investigate further
5. Do NOT auto-fix — SAST fixes require understanding business logic

### For Individual Findings

Ask these questions:
1. Is the source genuinely untrusted? (HTTP input, user data, external API)
2. Is there validation between source and sink that Snyk can't see?
3. Is the sink genuinely dangerous in this context?
4. Is this an internal tool or user-facing service?
5. Could this expose PHI or enable unauthorized access? (HIPAA elevation)
