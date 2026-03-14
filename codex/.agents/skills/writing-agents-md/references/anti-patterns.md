# Anti-Patterns in Instruction Files

## The 11 Anti-Patterns

| # | Anti-Pattern | Mechanism (Why It Hurts) | Detection | Fix |
|---|---|---|---|---|
| 1 | **File > 200-300 lines** | Uniform compliance degradation across all rules; wastes context budget | `wc -l` | Prune ruthlessly; move domain knowledge to `rules/` or skills |
| 2 | **LLM-generated content** (`/init`) | Describes rather than constrains; ETH Zurich: -3% success, +20% cost | Check git blame for bulk additions; look for generic phrasing | Write by hand from observed failures; use `/init` only as skeleton then gut it |
| 3 | **Rules the model already follows** | Pure token cost; zero behavioral change | Ask: "Would Claude do this without the rule?" If yes, it's waste | Delete |
| 4 | **Generic rules** ("write clean code") | No measurable behavioral effect; impossible to verify compliance | Grep for vague language: "clean", "best practices", "high quality" | Delete or replace with specific, testable constraint |
| 5 | **Architecture descriptions** | Don't reduce file navigation; go stale quickly; agent can read the code | Look for sections describing directory structure, component relationships | Link to actual docs or use `@imports`; let agent explore |
| 6 | **Code style in instruction files** | Expensive, slow, unreliable vs. linters; duplicate enforcement | Grep for indentation rules, naming conventions, formatting instructions | Use hooks/linters; document only: "Style enforced by Biome" |
| 7 | **Emphasis on >10% of rules** | Emphasis fatigue; IMPORTANT becomes background noise | Count IMPORTANT/CRITICAL/MUST/NEVER markers vs total directive lines | Reserve for 3-5 truly critical constraints |
| 8 | **Conflicting directives** across levels | Arbitrary resolution; undefined behavior; agent picks randomly | Diff root vs nested files; search for contradicting instructions on same topic | One source of truth per concern; audit for contradictions |
| 9 | **No maintenance process** | Accumulates contradictions, dead rules, stale descriptions over time | Check git log for instruction file edits — if none in 3+ months, it's rotting | Add to PR workflow: "did this rule earn its place?" |
| 10 | **Prose for hard constraints** | Advisory, not mandatory; compliance degrades with session length | Look for absolute rules ("NEVER", "ALWAYS") without corresponding hook enforcement | Use hooks for anything that must always fire |
| 11 | **Sensitive content** (URLs, credentials, internal patterns) | Supply chain attack surface (CVE-2025-59536, CVE-2026-21852) | Grep for URLs, API keys, internal hostnames, IP addresses | Remove; these files are read every session by every agent |

## Session Compliance Decay

Compliance with instruction file rules follows a predictable decay curve:

| Session Phase | Messages | Compliance Rate |
|---|---|---|
| Initial | 1-2 | ~95% |
| Early | 3-5 | 60-80% |
| Mid | 6-10 | 20-60% |
| Late | 10+ | Original instructions mostly disregarded |

**Implications for instruction file design:**
- Put the most critical rules first AND last (Lost in the Middle effect — rules at positions 15-40 receive less attention)
- Keep total rule count low — frontier models reliably follow ~150-200 instructions; Claude Code's system prompt already uses ~50 slots
- Hard constraints that must survive late-session degradation belong in hooks, not prose
- CLAUDE.md is NOT exempt from context compaction — it re-injects on the next fresh session, not mid-session

## The Lost in the Middle Effect

Stanford/UNC (TACL 2024): LLMs attend more strongly to information at the beginning and end of context, with a performance valley in the middle. For instruction files, this means:

- **Position 1-5**: High compliance — put non-negotiables here
- **Position 6-15**: Good compliance — build/test commands, key conventions
- **Position 15-40**: Compliance valley — avoid putting critical rules here
- **Last 5 rules**: Compliance recovery — repeat or reinforce critical constraints

This is why the structural taxonomy puts Non-Negotiables first and References last (structural bookends around the compliance valley).

## Sources

- ETH Zurich study (arXiv 2602.11988): LLM-generated files decrease success by 3%, increase cost 20%+
- Lost in the Middle (TACL 2024): aclanthology.org/2024.tacl-1.9
- GitHub #7777: Rules in prompts are requests; hooks in code are laws
- CVE-2025-59536 / CVE-2026-21852: Supply chain attacks via instruction files
- Practitioner reports: HumanLayer, alexop.dev, tessl.io
