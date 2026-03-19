# Output Templates

## Simplify Output Template

For simplify mode (checks 1-2 + bloat ratio only):

```markdown
# Simplify: <filename>

## Summary
<1-2 sentences: current state and reduction potential>

| Metric | Value |
|---|---|
| Lines | <count> |
| Bloat ratio | <directive:descriptive> |

## Lines to Remove
<numbered list with reason for each>

## Recommended Actions
1. ...
```

## Full Audit Output Template

For full audit mode (all 7 checks):

```markdown
# Instruction File Audit: <filename>

## Summary
<1-2 sentences: overall assessment>

## Dimension Scores

| Dimension | Score | Notes |
|---|---|---|
| Non-inferable content | STRONG/NEEDS WORK/WEAK | |
| Size | STRONG/NEEDS WORK/WEAK | <line count> |
| Emphasis discipline | STRONG/NEEDS WORK/WEAK | <marker count> |
| Structure | STRONG/NEEDS WORK/WEAK | |
| Boundary format | STRONG/NEEDS WORK/WEAK | |
| Hook opportunities | STRONG/NEEDS WORK/WEAK | |
| Cross-platform | STRONG/NEEDS WORK/WEAK | |

**Overall: STRONG / NEEDS WORK / WEAK**

## Lines to Remove
<numbered list with reason for each>

## Lines to Add
<numbered list with rationale — tag each as LOCAL (project file) or GLOBAL (user-wide config)>

## Potentially Outdated
<rules that were never triggered across sampled sessions, or that the agent consistently followed without needing the rule — candidates for removal. Only populated when Phase 2c was run.>

## Hook Candidates
<rules that should become hooks>

## Anti-Patterns Detected
<from the 11-pattern checklist>

## Recommended Actions (Priority Order)
1. ...
2. ...
```

## Write Output Template

```markdown
# Draft: <filename>

<the drafted instruction file>

---

## Decisions Made
- File strategy: <chosen pattern and why>
- Sections included/omitted: <rationale>
- Lines excluded by litmus test: <count>

## Post-Creation Checklist
- [ ] Verify all referenced files/paths exist
- [ ] Run any mentioned commands to confirm they work
- [ ] If AGENTS.md + CLAUDE.md, verify relationship is clean
- [ ] If using @imports, verify Claude Code resolves them
- [ ] Review emphasis markers — are they all protecting against real failures?
- [ ] Schedule first maintenance review (suggest: 30 days or next major refactor)
```

## Grading Rubric

### Per Dimension

| Grade | Meaning |
|---|---|
| **STRONG** | No issues found; follows best practices |
| **NEEDS WORK** | Minor issues; file works but could be improved |
| **WEAK** | Significant issues; file likely hurts more than it helps |

### Overall Grade

| Overall | Criteria |
|---|---|
| **STRONG** | No dimensions rated WEAK |
| **NEEDS WORK** | 1-3 dimensions rated WEAK |
| **WEAK** | 4+ dimensions rated WEAK, OR any critical anti-pattern (LLM-generated content, >300 lines, emphasis on >10% of rules) |
