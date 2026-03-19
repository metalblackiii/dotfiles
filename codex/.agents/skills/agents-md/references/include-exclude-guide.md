# Include/Exclude Guide

## The Non-Inferable Details Litmus Test

The single most useful heuristic: **before adding any line, ask "Could the agent discover this by reading the repository?"**

```
Candidate line
    │
    ▼
Could the agent discover this
by reading the repo?
    │
   YES ──→ EXCLUDE (wastes tokens, may increase agent steps)
    │
    NO
    │
    ▼
Would removing this line cause
the agent to make mistakes?
    │
    NO ──→ EXCLUDE (no behavioral impact = pure cost)
    │
   YES
    │
    ▼
Is this already enforced by a
linter, hook, or CI check?
    │
   YES ──→ EXCLUDE (duplicate enforcement; note the tool instead)
    │
    NO
    │
    ▼
INCLUDE — this line earns its place
```

## What to Include (High Confidence)

| Category | Examples | Why It Belongs |
|---|---|---|
| **Non-obvious build/test commands** | `make db-reset` before tests, `pnpm --filter` syntax | Agent can't guess custom commands. Point to discovery mechanisms (`npm run`, `make help`) and favor existing scripts rather than line-iteming them |
| **Tool choices not in config** | "Use `uv` not `pip`", "use `pnpm` not `npm`" | Config doesn't always make this explicit |
| **Operational landmines** | "Don't run migrations on prod replica", "Feature X requires env var Y" | Non-inferable traps save costly mistakes |
| **Architectural decisions** | Why we chose X over Y, deprecated modules still in prod | The "why" isn't in the code |
| **Workflow conventions** | Branch naming, PR format, commit conventions, review expectations | Repo etiquette the agent needs |
| **Hard constraints (3-tier)** | Always / Ask first / Never boundaries | Clear behavioral boundaries |
| **Dev environment quirks** | Required env vars, setup prerequisites, OS-specific gotchas | Not discoverable from code alone |
| **Security/compliance** | HIPAA handling, auth patterns, data classification rules | Regulatory consequences if violated |

## What to Exclude (High Confidence)

| Category | Examples | Why It Doesn't Belong |
|---|---|---|
| **Directory structure** | "src/ contains source code", "tests/ has tests" | Agent can `ls` and read these |
| **Tech stack descriptions** | "Built with React and Node.js" | In package.json/go.mod/Cargo.toml |
| **Standard language conventions** | "Use camelCase in JavaScript" | Model already knows these |
| **Linter-enforced style** | "2-space indentation", "trailing commas" | "Never send an LLM to do a linter's job" |
| **Tutorials or explanations** | Multi-paragraph architecture walkthroughs | Wrong medium; link to docs instead |
| **Self-evident practices** | "Write clean code", "Follow best practices" | Zero signal; dilutes attention on real rules |
| **Auto-generated content** | Output from `/init` or similar tools | Net-negative: -3% success, +20% cost |
| **Redundant emphasis** | Restating the same rule in 3 places | Wastes tokens; creates contradiction risk |
| **Script/command inventories** | Listing all npm scripts, Make targets, or CLI subcommands | Discoverable via `npm run`, `make help`, `package.json scripts`. Instead, add one line pointing to the discovery mechanism and favor those scripts. Only document commands with non-obvious prerequisites, execution order, or required flags |

## Edge Cases: Seems Inferable But Isn't

These are tricky — they look discoverable but often aren't:

| Item | Why It Seems Inferable | Why It Isn't |
|---|---|---|
| Test execution order | "Just run `npm test`" | Some suites need DB reset first, or specific env vars |
| Monorepo package boundaries | "Agent can see the folders" | Cross-package import rules aren't in the code |
| Feature flag requirements | "It's in the config" | Which flags are required for local dev isn't obvious |
| API versioning strategy | "Just follow the existing pattern" | Multiple patterns may coexist; agent needs the current standard |
| Deploy-blocked paths | "CI will catch it" | If the agent doesn't know, it wastes time on doomed approaches |

## Edge Cases: Seems Non-Inferable But Is

| Item | Why It Seems Non-Inferable | Why It Actually Is |
|---|---|---|
| Framework conventions | "Agent might not know our patterns" | Standard framework conventions are in training data |
| File naming patterns | "Our convention is specific" | Agent infers from existing files in 2 seconds |
| Import ordering | "We have a specific order" | Usually enforced by ESLint/isort already |
| Error handling patterns | "Our pattern is custom" | Agent reads 2-3 existing files and gets it |

## Anthropic's Pruning Test

For each line in the instruction file, ask:

> "Would removing this cause Claude to make mistakes?"

If the answer is "no" — cut it. Run this test:
- After initial drafting (before committing)
- Quarterly as a maintenance pass
- When the file exceeds 150 lines
- After any major refactor that may have invalidated rules

## Sources

- Claude Code Best Practices: code.claude.com/docs/en/best-practices
- Addy Osmani: addyosmani.com/blog/agents-md
- HumanLayer: humanlayer.dev/blog/writing-a-good-claude-md
- ETH Zurich: arxiv.org/abs/2602.11988
- GitHub Blog (2,500 repo analysis): github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md
