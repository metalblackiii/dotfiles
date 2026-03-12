# Codebase Indexing for AI Coding Assistants: Research Summary

> Researched 2026-03-11. Based on web research (Claude + Codex, 11 parallel streams) and codebase analysis of [codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp).

## Executive Summary

The codebase indexing space for AI coding assistants has exploded since mid-2025, with 20+ MCP servers competing to be the "memory layer" for AI agents. The tools cluster into five architectural camps: knowledge graphs (tree-sitter + graph DB), embedding/vector search, hybrid BM25+vector, symbol-only indexing, and LSP-based navigation. **No single approach dominates** -- the industry is converging on hybrid architectures that combine structural parsing with semantic search, augmented by agentic exploration. Notably, Anthropic deliberately abandoned RAG for Claude Code after finding agentic search outperforms it, and Amazon Science research (Feb 2026) validated that keyword search via tools achieves 90%+ of RAG performance. For your use case, the strongest alternatives to codebase-memory-mcp are **CodeGraphContext** (closest structural competitor, 1.8K stars, graph DB), **Serena** (LSP-based, 21K stars, highest accuracy), and **cocoindex-code** (lightweight hybrid, 680 stars, local embeddings). However, the community consensus is to start minimal (CLAUDE.md + skills) and add indexing only when hitting concrete pain points at scale.

## Key Concepts

**Codebase indexing** pre-processes source code into a searchable representation (graph, embeddings, or symbol index) so AI assistants can answer questions about code structure without reading every file. This reduces token consumption by 50-99% compared to naive file-by-file exploration.

**MCP (Model Context Protocol)** is the emerging standard for exposing these indexes to AI agents. An MCP server runs alongside the agent and responds to tool calls like `search_graph` or `search_code`.

**Token efficiency** measures how few tokens an assistant needs to understand a codebase. Aider's repo-map achieves ~1K tokens for an entire repo; codebase-memory-mcp claims 3.4K tokens for five structural queries vs 412K via exploration (99.2% reduction).

**The stale index problem** is the most dangerous failure mode: indexes frozen in time cause agents to generate syntactically correct but functionally broken code using phantom APIs and deleted functions.

## Ecosystem Landscape

### MCP-Based Codebase Tools

| Tool | Stars | Approach | Languages | Key Strength | Key Weakness | Status |
|------|-------|----------|-----------|--------------|--------------|--------|
| **[Serena](https://github.com/oraios/serena)** | 21.4K | LSP via solid-lsp | 30+ | IDE-grade accuracy, semantic editing | No persistent graph or memory | Active |
| **[claude-context](https://github.com/zilliztech/claude-context)** | 5.6K | BM25 + dense vector (Milvus) | Broad | ~40% token reduction, hybrid search | Requires cloud (Zilliz + OpenAI) | Active |
| **[CodeGraphContext](https://github.com/CodeGraphContext/CodeGraphContext)** | 1.8K | Tree-sitter + graph DB (KuzuDB/Neo4j) | 14 | Graph visualization, live file watching | Fewer languages than cbm-mcp | Active |
| **[jCodeMunch-MCP](https://github.com/jgravelle/jcodemunch-mcp)** | 1K | Tree-sitter, O(1) byte-offset | 13 | ~80% token reduction, cost tracking | No graph queries, commercial license | Active |
| **[code-index-mcp](https://github.com/johnhuang316/code-index-mcp)** | 821 | Tree-sitter + fallback parsing | 7 (TS) / 50+ (fallback) | Dual strategy, real-time monitoring | Narrow tree-sitter support | Active |
| **[cocoindex-code](https://github.com/cocoindex-io/cocoindex-code)** | 680 | Tree-sitter + local embeddings (MiniLM) | 9 | 70% savings, no API keys, lightweight | Small embedding model | Active |
| **[codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp)** | 596 | Tree-sitter + SQLite graph, Louvain | 64 | Broadest language support, sub-ms queries | No .gitignore, no semantic search | Active |
| **[Probe](https://github.com/probelabs/probe)** | 493 | ripgrep + tree-sitter, zero-indexing | 12+ | Zero setup, deterministic | No persistent index, repeated scans | Active |
| **[lsmcp](https://github.com/mizchi/lsmcp)** | 440 | LSP-first MCP | Broad (LSP) | Workspace symbols, definitions, references | Not persistent memory | Quiet |
| **[codemogger](https://github.com/glommer/codemogger)** | 257 | Tree-sitter + MiniLM embeddings (int8) | 13 | Keyword 25-370x faster than ripgrep | Slow initial embedding | Active |
| **[SymDex](https://github.com/husnainpk/SymDex)** | 82 | Tree-sitter + sqlite-vec + embeddings | 14+ | 97% token reduction, HTTP routes, offline | Less mature | Active |
| **[code-graph-mcp](https://github.com/entrepeneur4lyf/code-graph-mcp)** | 81 | ast-grep + rustworkx | 25+ | Framework detection, code smell analysis | Slow (10-60s queries) | Active |

### Non-MCP Context Tools

| Tool | Approach | Open Source | Token Efficiency | Multi-Repo |
|------|----------|------------|------------------|------------|
| **Aider** | Tree-sitter + PageRank repo-map | Yes (Apache 2.0) | ~1K tokens for full repo map | No |
| **Cursor** | AST chunking + Turbopuffer cloud embeddings | No | Cache-optimized incremental | No |
| **Sourcegraph Cody** | SCIP code graph + embeddings + agentic | Open core | Multi-layer context | Yes |
| **GitHub Copilot** | Hybrid remote/local + proprietary embeddings | No | Seconds-level indexing | Limited |
| **Roo Code** | Tree-sitter + Qdrant embeddings | Yes (Apache 2.0) | Configurable threshold | No |
| **Augment Code** | Semantic indexing + multi-repo graph (MCP) | No | 200K compressed context | Yes |
| **Continue.dev** | Was hybrid RAG; deprecated @Codebase for agentic | Yes (Apache 2.0) | In transition | No |
| **Cline** | No indexing -- file-by-file exploration | Yes (Apache 2.0) | High token cost | No |
| **Windsurf** | AST embeddings + Cascade behavioral engine | No | Real-time tracking | Yes |

## Best Practices

### What Works

1. **Start minimal, add complexity only when needed.** Community consensus: "CLAUDE.md gives you 90% of what you need." Skills and structured instructions outperform indexing for most medium codebases. ([HN](https://news.ycombinator.com/item?id=46426624))

2. **Hybrid retrieval beats any single approach.** Combining BM25 keyword search with semantic embeddings reduces retrieval failure by 35% (Sourcegraph Cody data). Graph queries add structural understanding that neither can provide. ([arXiv](https://arxiv.org/html/2408.05344v1))

3. **Function-level chunking outperforms file-level by ~7%.** Greptile's data shows function-only chunks score 0.768 similarity vs 0.718 for full files. AST-based chunking (cAST) improved SWE-bench Pass@1 by 2.67 points. ([Greptile](https://www.greptile.com/blog/semantic-codebase-search), [arXiv](https://arxiv.org/html/2506.15655v1))

4. **Agentic exploration often beats pre-indexed retrieval.** Anthropic found "agentic search generally works better" and is "simpler." Amazon Science (Feb 2026) confirmed keyword search via tools achieves 90%+ of RAG performance. ([vadim.blog](https://vadim.blog/claude-code-no-indexing))

5. **Observation masking beats LLM summarization for context management.** JetBrains research: masking old observations wins in 4/5 configurations while being 52% cheaper than summarization. ([JetBrains](https://blog.jetbrains.com/research/2025/12/efficient-context-management/))

### Common Pitfalls

1. **Stale indexes are worse than no indexes.** ForgeCode benchmarks: indexed agents using stale embeddings generated syntactically correct but functionally broken code, negating speed gains. ([ForgeCode](https://forgecode.dev/blog/index-vs-no-index-ai-code-agents/))

2. **More context is not always better.** Stanford's "Lost in the Middle" research shows 20-25% accuracy variance based on information position in context. Models attend primarily to first and last tokens. ([local-ai-zone](https://local-ai-zone.github.io/guides/context-length-optimization-ultimate-guide-2025.html))

3. **Ignoring .gitignore creates noise and security risk.** codebase-memory-mcp's lack of .gitignore support means it indexes build artifacts, dependencies, and potentially sensitive files. This was your primary reason for uninstalling.

4. **Cloud-dependent indexing creates vendor lock-in.** claude-context requires Zilliz + OpenAI; Cursor requires Turbopuffer. Local-first tools (CodeGraphContext, cocoindex-code, codebase-memory-mcp) avoid this.

## Current State (codebase-memory-mcp)

Based on the Codex source survey:

**Architecture:** 14 MCP tools (not 12 as documented). Go binary with CGO tree-sitter bridge. Per-project SQLite databases at `~/.cache/codebase-memory-mcp/`. Multi-pass pipeline: discover -> parse -> structure -> calls -> HTTP links -> community detection -> git coupling.

**Strengths:**
- Broadest language support (64 languages) -- unmatched in the space
- Sub-ms Cypher queries on SQLite with WAL mode
- Louvain community detection (unique feature)
- Cross-service HTTP call linking with confidence scoring
- Git diff impact mapping with risk classification (CRITICAL/HIGH/MEDIUM/LOW)
- Single Go binary, zero external dependencies
- Serious performance engineering: mmap, prefetch, adaptive concurrency, in-memory graph buffer

**Issues that drove uninstall:**
- **No .gitignore support** -- uses custom .cgrignore with `filepath.Match` globs
- **Incomplete .cgrignore** -- file-level patterns like `*.pb.go` documented but not applied during `classifyFile()` (only `shouldSkipDir()`)
- **OOM kills** (GitHub issue #49) and **very high CPU usage** (issue #45)
- **No git worktree support** (issue #48)
- Documentation drift: README says 12 tools, source has 14; README says single DB, source uses per-project DBs

## Gap Analysis

| Recommendation | codebase-memory-mcp | Gap | Effort to Fix |
|----------------|---------------------|-----|---------------|
| Respect .gitignore | Uses .cgrignore only | Major -- indexes build artifacts, deps, sensitive files | Medium (Go gitignore libs exist) |
| Semantic/embedding search | Graph-only, no embeddings | Cannot answer "find code that does X" when names don't match | High (needs embedding model + vector storage) |
| Hybrid retrieval (BM25 + semantic) | Neither BM25 nor embeddings | Misses the approach with best evidence | High |
| Graph visualization | No visualization | CodeGraphContext offers interactive graph vis | Medium |
| License clarity | Not stated | Barrier to adoption; competitors are MIT | Trivial |
| Resource management | OOM/CPU issues reported | Unusable on large monorepos without fixes | Unknown |
| Incremental context loading | Returns full query results | No token budgeting or progressive disclosure | Medium |

## Trade-offs & Decision Points

### 1. Graph-based vs Embedding-based vs Hybrid

**Graph-based (codebase-memory-mcp, CodeGraphContext):** Best for structural queries ("what calls this?", "blast radius of this change"). Worst for semantic queries ("find the authentication handler"). Lean this way if your workflow is dominated by impact analysis and refactoring.

**Embedding-based (claude-context, cocoindex-code, Roo Code):** Best for semantic discovery ("find code that validates emails"). Worst for structural traversal. Lean this way if you're exploring unfamiliar codebases.

**Hybrid (SymDex, codemogger, Augment Code):** Best overall quality but highest complexity. Lean this way for production workflows at scale.

**Our lean:** For your use case (Claude Code CLI, multiple repos, skills-driven workflow), a lightweight hybrid that respects .gitignore would be ideal. cocoindex-code or SymDex are the closest existing options.

### 2. Pre-indexing vs Agentic Exploration

**Pre-indexing saves tokens** on repeated queries about the same codebase. ForgeCode measured 22% faster, 35% fewer API calls.

**Agentic exploration provides fresher results** and avoids the stale index problem entirely. Anthropic and Amazon Science both validate this approach.

**Our lean:** Pre-indexing as a fast-pass supplement to agentic exploration, not a replacement. This is the emerging production consensus.

### 3. Local-only vs Cloud-dependent

**Local-only (codebase-memory-mcp, CodeGraphContext, cocoindex-code):** No data leaves the machine. Critical for HIPAA-adjacent environments.

**Cloud-dependent (claude-context, Cursor, Augment Code):** Better embedding models, managed infrastructure, team-level index sharing.

**Our lean:** Local-only is non-negotiable given your security requirements.

### 4. Invest in indexing vs Invest in better instructions

The "CLAUDE.md camp" argues that well-structured project instructions, skills, and conventions eliminate 90% of the need for codebase indexing. Your existing skills infrastructure (skills/, CLAUDE.md, GUARD.md) already provides significant context compression.

**When indexing pays off:** 1000+ file projects, inconsistent naming, legacy codebases, cost-sensitive high-volume workflows.

**When instructions are enough:** Well-structured projects with clear naming conventions, moderate size, experienced developer directing the agent.

## Recommended Approach

Given your setup (Claude Code CLI, skills-driven workflow, HIPAA-adjacent, recently uninstalled codebase-memory-mcp):

### Short-term: Don't reinstall anything yet

Your existing skills infrastructure (CLAUDE.md, skills, hooks, subagents) provides strong context management. The research validates that agentic exploration + well-structured instructions is competitive with indexing for well-named medium codebases.

### If you hit a concrete indexing need, evaluate these three:

1. **[CodeGraphContext](https://github.com/CodeGraphContext/CodeGraphContext)** (1.8K stars, MIT, Python) -- Closest to what you had but better maintained. Graph DB options (KuzuDB default), live file watching, interactive visualization. Fewer languages (14 vs 64) but covers your likely stack. Check if it respects .gitignore.

2. **[cocoindex-code](https://github.com/cocoindex-io/cocoindex-code)** (680 stars, Apache 2.0, Rust+Python) -- Lightweight hybrid: tree-sitter chunking + local MiniLM embeddings. No API keys, no external services. Claims 70% token savings. Worth evaluating if you want semantic search without cloud dependencies.

3. **[Serena](https://github.com/oraios/serena)** (21.4K stars, MIT, Python) -- LSP-based, highest accuracy for supported languages. Not a "memory" server but provides IDE-grade navigation (find-references, go-to-definition) that Claude Code's native LSP doesn't fully cover yet. Different niche but high value.

### If you want to build something custom:

The community's convergent DIY stack is **tree-sitter + SQLite + optional embeddings**. Multiple independent projects (CodeGraph, code-review-graph, codebase-memory-mcp) arrived at this same architecture. Adding .gitignore support and optional local embeddings (MiniLM or nomic-embed-code) to this pattern would create a strong tool.

## References & Sources

### MCP Tools
- [Serena](https://github.com/oraios/serena) -- LSP-based MCP server
- [claude-context (Zilliz)](https://github.com/zilliztech/claude-context) -- Hybrid BM25 + vector
- [CodeGraphContext](https://github.com/CodeGraphContext/CodeGraphContext) -- Tree-sitter + graph DB
- [jCodeMunch-MCP](https://github.com/jgravelle/jcodemunch-mcp) -- Symbol retrieval
- [code-index-mcp](https://github.com/johnhuang316/code-index-mcp) -- Dual strategy indexer
- [cocoindex-code](https://github.com/cocoindex-io/cocoindex-code) -- Lightweight hybrid
- [codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp) -- Reference implementation
- [Probe](https://github.com/probelabs/probe) -- Zero-indexing search
- [lsmcp](https://github.com/mizchi/lsmcp) -- LSP-first MCP
- [codemogger](https://github.com/glommer/codemogger) -- Tree-sitter + embeddings
- [SymDex](https://github.com/husnainpk/SymDex) -- Hybrid symbol + vector
- [code-graph-mcp](https://github.com/entrepeneur4lyf/code-graph-mcp) -- ast-grep + code smells
- [codegraph-rust](https://github.com/Jakedismo/codegraph-rust) -- GraphRAG in Rust
- [know-cli](https://github.com/sushilk1991/know-cli) -- 3-tier BM25 + graph + semantic

### Non-MCP Tools
- [Aider repo-map](https://aider.chat/docs/repomap.html) -- Gold standard for token-efficient structural context
- [Sourcegraph Cody](https://sourcegraph.com/docs/cody) -- Enterprise multi-repo context
- [Augment Code Context Engine](https://www.augmentcode.com/context-engine) -- 500K file indexing + MCP
- [Roo Code](https://docs.roocode.com/features/codebase-indexing) -- Open source embeddings + Qdrant

### Research & Analysis
- [Anthropic: Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) -- First-party guidance
- [Claude Code no-indexing rationale](https://vadim.blog/claude-code-no-indexing) -- Boris Cherny's HN disclosure
- [Greptile: Semantic codebase search](https://www.greptile.com/blog/semantic-codebase-search) -- NL translation insight
- [cAST: AST-based chunking](https://arxiv.org/html/2506.15655v1) -- SWE-bench improvement
- [LongCodeZip](https://arxiv.org/html/2510.00446v1) -- 5.6x code compression
- [Codified Context](https://arxiv.org/html/2602.20478v1) -- Tiered knowledge architecture
- [SWE-ContextBench](https://arxiv.org/html/2602.08316) -- Experience reuse benchmark
- [JetBrains: Context Management](https://blog.jetbrains.com/research/2025/12/efficient-context-management/) -- Observation masking
- [Factory.ai: Compressing Context](https://factory.ai/news/compressing-context) -- Production compression
- [ForgeCode: Index vs No-Index](https://forgecode.dev/blog/index-vs-no-index-ai-code-agents/) -- Benchmark comparison
- [Continue: Accuracy Limits of Retrieval](https://blog.continue.dev/accuracy-limits-of-codebase-retrieval/) -- Retrieval evaluation
- [Cursor: Secure Codebase Indexing](https://cursor.com/blog/secure-codebase-indexing) -- Architecture details
- [How Cursor indexes codebases fast](https://read.engineerscodex.com/p/how-cursor-indexes-codebases-fast)

### Community Discussions
- [HN: codebase-memory-mcp discussion](https://news.ycombinator.com/item?id=47193064)
- [HN: Claude Code memory systems](https://news.ycombinator.com/item?id=46426624)
- [r/cursor: Context retrieval degraded](https://forum.cursor.com/t/cursor-context-retrieval-degraded/79196)
- [r/cursor: Apollo test comparison](https://www.reddit.com/r/cursor/comments/1l5x0de/every_ai_coding_agent_claims_they_understand_your/)

## Open Questions

1. **Does CodeGraphContext respect .gitignore?** This was the primary pain point with codebase-memory-mcp. Needs hands-on verification before adopting.

2. **How do embedding-based tools perform on your specific stack?** Token savings claims (40-70%) are general -- actual savings depend on codebase size, naming conventions, and query patterns.

3. **Is the token cost of agentic exploration actually a problem for you?** If your current Claude Code sessions stay well within budget, indexing may be solving a problem you don't have.

4. **Would Aider's repo-map approach work as an MCP?** RepoMapper (126 stars) implements this, but it's read-only and early-stage. The PageRank approach is elegant and proven.

5. **What's the right trigger for "I need indexing now"?** Community suggests: when you consistently see the agent reading 10+ files to answer structural questions, or when token costs exceed your comfort threshold on repeated similar queries.
