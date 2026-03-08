You are decomposing a PRD into implementation phases. Do NOT implement anything.

## Input

Read the PRD at `{{PRD_PATH}}`.

## Task

Analyze the PRD and break it into sequential implementation phases. Each phase must be:

- **Small**: ≤12 files changed, ≤400 lines of new/modified code
- **Self-contained**: clear inputs, outputs, and acceptance criteria
- **Ordered**: later phases build on earlier ones — no circular dependencies
- **Testable**: each phase has a verification command (test suite, build, lint)

Explore the codebase to understand existing structure before decomposing.

## Output

Write two files:

### 1. `{{STATE_FILE}}`

```json
{
  "version": "1",
  "prd_path": "{{PRD_PATH}}",
  "created_at": "<current ISO timestamp>",
  "updated_at": "<current ISO timestamp>",
  "consecutive_failures": 0,
  "phases": [
    {
      "id": "phase-1",
      "title": "<short title>",
      "description": "<1-2 sentences: what this phase accomplishes and why it comes in this order>",
      "status": "pending",
      "failed_count": 0,
      "started_at": null,
      "completed_at": null,
      "error": null
    }
  ]
}
```

Use `phase-1`, `phase-2`, etc. for IDs. Include as many phases as the PRD requires.

### 2. `{{PROGRESS_FILE}}`

```
# PRD Loop Progress
PRD: {{PRD_PATH}}
Started: <current timestamp>

---
```

## Constraints

- Do NOT write any implementation code
- Do NOT create specs or plans — only the state file and progress log
- Do NOT modify any project files
