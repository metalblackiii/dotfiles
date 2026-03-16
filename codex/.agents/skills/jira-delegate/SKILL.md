---
name: jira-delegate
description: ALWAYS invoke when the user wants to interact with Jira — checking tickets, searching issues, adding comments, updating fields, exploring relationships, or reading attachments. Triggers on ticket keys (NEB-1234), "check Jira", "what's the status of", "search for tickets", "comment on", "update the summary", "what's blocking", "show me the attachments", or any Jira-related request. Do not answer Jira questions from memory. Not for Jira admin, workflow configuration, or board management.
---

# Jira Delegate

Translate natural language into `ptjira` CLI commands, execute them, and present results conversationally. The user talks to you about Jira; you talk to Jira on their behalf.

## Principle

Act as a knowledgeable delegate, not a command proxy. Interpret intent, choose the right command and flags, and synthesize results into what the user actually wants to know — don't just dump raw output.

## Prerequisites

- `ptjira` is installed and on PATH
- Auth is configured via env vars (`JIRA_EMAIL`, `JIRA_API_TOKEN`, `JIRA_HOST`) or `~/.config/ptjira/config.toml`
- If a command fails with auth errors, tell the user to check their config — don't guess credentials

## Command Reference

### Get a ticket

```bash
ptjira get <KEY>
```

Returns full JSON with all fields and available transitions. Use when the user asks about a specific ticket's details, status, description, assignee, or transitions.

### Search issues

```bash
ptjira search "<JQL>" [--max-results N] [--json]
```

Pipe output or use `--json` to get structured results. Construct JQL from natural language:

| User says | JQL |
|-----------|-----|
| "my open tickets" | `assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC` |
| "my in-progress items" | `assignee = currentUser() AND statusCategory = "In Progress" ORDER BY updated DESC` |
| "open bugs in NEB" | `project = NEB AND issuetype = Bug AND statusCategory != Done ORDER BY priority DESC` |
| "tickets updated this week" | `project = NEB AND updated >= startOfWeek() ORDER BY updated DESC` |
| "what's in the current sprint" | `project = NEB AND sprint in openSprints() ORDER BY rank ASC` |
| "unassigned high priority" | `project = NEB AND assignee is EMPTY AND priority in (High, Highest) ORDER BY created DESC` |

**Use `statusCategory` instead of `status` for filtering.** This Jira instance uses custom status names (e.g., "In DEV", "PR", "Implemented" instead of "In Progress"; "Completed" instead of "Done"). The three status categories — `"To Do"`, `"In Progress"`, `"Done"` — are reliable across all workflows.

Default to `ORDER BY updated DESC` unless the user implies a different sort. Default `--max-results 25` unless the user asks for more.

### Explore relationships

```bash
ptjira context <KEY> [--depth N] [--include parent,subtasks,linked,children,epicSiblings]
```

Use when the user asks about what's related, what's blocking, parent/child structure, or sibling work. Choose `--include` based on intent:

| User asks about | Include |
|-----------------|---------|
| "what's blocking this" | `linked` (then filter for blocking relations) |
| "show me the subtasks" | `subtasks` |
| "what else is in this epic" | `epicSiblings` |
| "full picture of this ticket" | `parent,subtasks,linked` (default) |
| "deep dive" | `parent,subtasks,linked,children,epicSiblings` with `--depth 2` |

After fetching, interpret the graph — summarize relationships, highlight blockers, show status of related work.

### Add a comment

```bash
ptjira comment <KEY> "<TEXT>"
```

Supports markdown — use it for formatting. When the user says "tell them..." or "add a note about...", compose the comment in markdown, show the user what you'll post, and confirm before executing.

### Update a field

```bash
ptjira update <KEY> --field <FIELD> --value "<VALUE>"
```

`description` and `environment` fields support markdown (auto-converted to ADF). Always confirm the change with the user before executing — field updates are not easily reversible.

### List/download attachments

```bash
ptjira attachments <KEY> [--download] [--max-size BYTES] [--json]
```

Use `--download --json` when the user wants to read attachment content (text files only, 1MB default limit). Without `--download`, shows metadata only.

## Interaction Patterns

### Single-ticket lookup

User: "What's the status of NEB-1234?"
→ `ptjira get NEB-1234` → Extract and present status, assignee, summary, and any recent context.

### Multi-step investigation

User: "What's blocking NEB-1234 and can you summarize?"
→ `ptjira context NEB-1234 --include linked` → Identify blocking links → `ptjira get <blocker-key>` for each blocker → Synthesize a summary.

### Search and triage

User: "Show me all open bugs assigned to me"
→ `ptjira search "assignee = currentUser() AND issuetype = Bug AND statusCategory != Done ORDER BY priority DESC" --json` → Present as a prioritized list.

### Compose and confirm

User: "Comment on NEB-1234 that the fix is deployed to staging"
→ Draft: "Fix has been deployed to staging environment. Ready for QA verification."
→ Show user the draft → On approval: `ptjira comment NEB-1234 "<text>"`

### Batch context gathering

User: "Give me a status update on NEB-1234, NEB-1235, and NEB-1236"
→ Run `ptjira get` for each in parallel → Synthesize into a combined status summary.

## Presenting Results

- **Summarize, don't dump.** Extract what the user asked about. Full JSON is for you to parse, not the user to read.
- **Highlight actionable info.** Status, assignee, blockers, next steps.
- **Link to tickets.** Format as `[NEB-1234](https://practicetek.atlassian.net/browse/NEB-1234)` when useful.
- **For search results**, present as a concise list: key, summary, status, assignee — one line each.
- **For context/relationships**, describe the graph in plain language: "NEB-1234 has 3 subtasks (2 done, 1 in progress). It's blocked by NEB-1200 which is assigned to Jane."

## Guardrails

- **Confirm before writing.** Always show the user what you'll comment or update before executing write operations.
- **No credential guessing.** If auth fails, surface the error — don't retry with different credentials.
- **No PII in examples.** Use placeholder data in any example output.
- **Respect rate limits.** If running multiple commands, execute sequentially unless you're confident parallel execution is safe (read-only commands).
- **Admit gaps.** If the CLI can't do what the user wants (transitions, creating tickets, bulk updates, sprint management), say so clearly — that's valuable signal for identifying gaps.

## Known Gaps

These are things `ptjira` cannot do yet. When a user asks for one of these, tell them it's a gap and note it for future development:

- **Transition tickets** (move status) — the `get` command returns available transitions but there's no `transition` command
- **Create tickets** — no `create` command
- **Bulk updates** — no batch operations
- **Sprint/board management** — no sprint commands
- **Watchers/notifications** — no watcher management
- **Work logs** — no time tracking
- **Custom field updates by name** — `update` works with field IDs; custom field name resolution isn't built in
- **Delete comments/attachments** — no delete operations
- **Link/unlink issues** — no link management command

When you hit a gap, format it clearly: "ptjira doesn't support [action] yet. This would need a new `[command]` subcommand."
