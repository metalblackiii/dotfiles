# TypeScript CLI Best Practices: Research Summary

> Researched 2026-03-09. Based on web research and codebase analysis of `prd-loop` (~/repos/prd-loop).

## Executive Summary

The TypeScript CLI ecosystem has matured significantly, with a clear split between traditional Node.js-era tools (commander, yargs, chalk, ora) and a new generation of TypeScript-native tools that leverage the type system as a first-class concern (citty, cleye, ansis, yocto-spinner). prd-loop's current CLI implementation is functional but hand-rolled, with no signal handling, no progress indicators, no `--help`/`--version`, and Zod used only for state — not CLI args or config. The research identifies concrete upgrades across five areas, with signal handling and child process lifecycle as the highest-severity gaps. The TypeScript-specific delta is large enough to warrant a new `references/typescript-cli.md` file in the cli-developer skill.

## Key Concepts

**Three-layer CLI architecture**: prd-loop is an orchestrator that spawns long-running child processes (`claude -p`, `codex exec`, `gh pr create`). This makes it fundamentally different from a simple CRUD CLI — process lifecycle management, signal propagation, and state persistence under interruption are critical concerns.

**TypeScript-native vs bolted-on types**: The arg parsing ecosystem has split. Libraries like citty, cleye, and cmd-ts infer types from definitions (one source of truth). Traditional libraries like commander require a separate `@commander-js/extra-typings` package or manual interfaces that can drift.

**ESM is settled**: With `"type": "module"` and `"moduleResolution": "nodenext"`, prd-loop is already on the right path. The `.js` extension import requirement, `import.meta.dirname`, and top-level `await` are all correctly handled.

## Ecosystem Landscape

### Arg Parsing

| Library | TS Types | Bundle Size | Downloads/wk | Best For |
|---------|----------|-------------|--------------|----------|
| commander + extra-typings | Good (addon) | 6.5 KB | 322M | Large team, ecosystem familiarity |
| citty | First-class | 0 KB (uses util.parseArgs) | 17.7M | Zero-dep TS CLIs, UnJS ecosystem |
| cleye | First-class | ~2 KB (type-flag dep) | 111K | Small-medium TS CLIs |
| cac | Good | 0 deps | 27M | Vite/Vitest ecosystem |
| yargs | External @types | Heavy | 171M | Complex validation, middleware |
| stricli (Bloomberg) | Excellent | 0 deps | Small | Maximum type safety |

Notable: Vite/Vitest use **cac**, tsx uses **cleye**, Nuxt uses **citty**, Yarn uses **clipanion**. Performance-critical CLIs (Biome, Turbo) use Rust.

### Terminal Output

| Concern | Recommended | Runner-up | Avoid |
|---------|-------------|-----------|-------|
| Colors | **ansis** 4.x (5.7 KB, fastest multi-style) | picocolors (single-style only) | chalk (oversized, ESM-only) |
| Spinners | **yocto-spinner** (tiny, ESM) | nanospinner (dual CJS/ESM) | — |
| Task lists | **listr2** 10.x (multi-renderer, CI-aware) | — | — |
| Progress bars | **cli-progress** | — | — |
| Prompts | **@inquirer/prompts** 8.x | — | legacy inquirer, prompts, enquirer |
| CI detection | **ci-info** | — | manual process.env.CI check |

### Process Management

| Concern | Recommended | Why |
|---------|-------------|-----|
| Child process spawning | **execa** v9 | `forceKillAfterDelay`, `cleanup: true`, rich errors, `cancelSignal` |
| Atomic state writes | **write-file-atomic** | temp-write + rename pattern, serialized concurrent writes |
| Signal handling | Custom (see architecture below) | No library needed — pattern is well-documented |

### Build & Distribution

| Tool | Status | Best For |
|------|--------|----------|
| **tsdown** (Rolldown-based) | Recommended for new projects | Successor to tsup, fastest |
| tsup | No longer actively maintained | Migration path exists to tsdown |
| tsc (direct) | Always works, slower | Simple projects, maximum correctness |
| tsx | Dev runner only | Never for published distribution |

## Best Practices

### Arg Parsing
- For prd-loop's scope (4 commands, 3 flags, no plugins), **citty** or **cleye** are the sweet spot — strong types, minimal weight, active maintenance
- Hand-rolling is justified for prototyping but the current implementation silently ignores unknown flags and uses `!` assertions where a discriminated union would provide compile-time safety
- `util.parseArgs` (Node 20+) is the new zero-dep baseline; citty uses it internally

### Signal Handling (Critical Gap)
- Register handlers for both SIGINT and SIGTERM
- Use a once-flag to prevent duplicate cleanup; double Ctrl+C force-exits
- Forward the **same** signal received to children (don't translate SIGINT→SIGTERM; Nx had this bug)
- Exit with `128 + signal_number` (130 for SIGINT, 143 for SIGTERM)
- Add a timeout guardian: if children don't exit within 10s, escalate to SIGKILL
- **Do not** use `detached: true` — shared process group means Ctrl+C propagates automatically

### Child Process Lifecycle
- Track all spawned children in a central `ProcessManager`
- Checkpoint state *before* spawning children (current code only writes state after child returns)
- Use `execa` with `forceKillAfterDelay` (SIGTERM→SIGKILL escalation) and `cleanup: true` (kill children if parent exits)
- Thread an `AbortController` through the dispatch layer; combine user cancellation and timeout with `AbortSignal.any()`

### Error Messages
- Follow the "Context → Problem → Solution" pattern (endorsed by clig.dev)
- Some errors already do this (PRD mismatch, circuit breaker) but many are terse
- Use structured exit codes: 2 for invalid args, 78 for config errors, 130 for SIGINT
- Print stack traces only in debug mode (`--debug` flag or `DEBUG` env var)
- Write logs/diagnostics to stderr, primary output to stdout

### Output & UX
- Add spinners for long-running Claude/Codex calls (currently no visual feedback during minutes-long waits)
- Degrade gracefully: check `process.stdout.isTTY && !ci.isCI` before showing animations
- Support `NO_COLOR` and `FORCE_COLOR` env vars (ansis handles this automatically)
- Consider `--json` flag for machine-readable output (state already has JSONL logging — extend to stdout)

### TypeScript-Specific
- Use Zod for CLI arg validation (not just state) — one schema for types + runtime validation
- Make `CliArgs` a discriminated union to eliminate `!` assertions
- `as const satisfies` for command/config definitions
- Consider branded types for `FilePath`, `PrdPath`, `BranchName` to prevent mixing
- `import.meta.dirname` instead of `__dirname` (Node 20.11+, already ESM)

## Current State

From Codex codebase survey of prd-loop:

**Argument Parsing** (`src/cli.ts:32`): Hand-rolled `parseArgs()` with manual `CliArgs` interface. Commands routed via `switch (cliArgs.command)`. Usage text shown on empty invocation. No `--help` flag, no `--version` flag. Unknown flags silently ignored (flags checked via `Set.has()`, never validated). `CliArgs` is not a discriminated union — forces `!` assertions at lines 337 and 340.

**Process Spawning** (`src/dispatch/`): All tools spawned with `execFile` — Claude (10 min timeout), Codex (15 min timeout), gh (no timeout specified). Working directory set per call. Centralized behind `RealDispatcher`. No `process.on('SIGINT')`, no `process.on('SIGTERM')`, no `AbortController`, no child PID tracking anywhere in `src/`.

**Output** (`src/cli.ts`, `src/orchestrator.ts`): Plain `console.log`/`console.error` with `=== Banner ===` style headers. JSONL logging to disk via `EventLogger` (good). No colors, no spinners, no TTY detection, no `--json` stdout mode. Child output buffered (not streamed) because `execFile` doesn't set `stdio: "inherit"`.

**Error Handling** (`src/cli.ts:278`): Single `die()` function — prints `FATAL:` prefix, exits with code 1. Some errors include context and remediation (PRD mismatch, circuit breaker), many are terse. Config parsing silently falls back on any read/parse failure. No `--debug`/`--verbose` flag.

**TypeScript Patterns**: Zod used heavily for state schema (`src/state.ts`) with `z.infer` for types — this is the strongest-typed part. Not used for CLI args or config validation. ESM configured correctly (`"type": "module"`, `"module": "nodenext"`). Build is plain `tsc`.

**Child Process Lifecycle**: State marked `in_progress` in memory, then child dispatched, then state written only after child returns. If interrupted mid-execution, resume falls back to last completed write boundary. No persisted child PID, no partial output capture, no heartbeat, no graceful shutdown.

## Gap Analysis

| Recommendation | Current State | Gap | Effort |
|----------------|---------------|-----|--------|
| SIGINT/SIGTERM handling | None | **Critical** — no graceful shutdown, orphan processes on Ctrl+C | Medium (new `ProcessManager` + signal wiring) |
| `--help` / `--version` flags | No `--help` flag, no version | Missing CLI conventions | Low (add flags to parser or adopt citty/cleye) |
| Unknown flag validation | Silently ignored | Users won't know they mistyped a flag | Low |
| Discriminated union for CliArgs | Optional fields + `!` assertions | Type safety gap | Low |
| Zod for CLI args | Only for state | Args not runtime-validated | Medium (if adopting Zod CLI pattern) |
| Zod for config | Manual type casting | Config errors silent | Low-Medium |
| Spinners for long operations | None | No visual feedback for minutes-long calls | Low (add yocto-spinner) |
| Colors | None | Harder to scan output | Low (add ansis) |
| TTY detection | None | Would break if piped | Low |
| Error message quality | Inconsistent | Some good, some terse | Low-Medium (audit each `die()` call) |
| Exit codes | Only 0 and 1 | No signal codes, no usage errors | Low |
| State checkpoint before child spawn | Only after child returns | State loss if interrupted mid-execution | Medium |
| execa migration | Raw `execFile` | Missing `forceKillAfterDelay`, `cleanup`, rich errors | Medium |
| Atomic state writes | Plain `writeFile` | Corruption risk on SIGKILL/power loss | Low (swap to write-file-atomic) |
| `--debug` flag | None | No way to get verbose output | Low |
| Build tool | Plain `tsc` | Works but slower than tsdown | Low (nice-to-have, not blocking) |

## Trade-offs & Decision Points

### Arg Parser: Keep Hand-Rolled vs Adopt Library

**Keep hand-rolling**: It works, it's simple, it's 35 lines. Prd-loop has 4 commands and 3 flags — this is near the threshold where hand-rolling is justified. Adding a library for this is arguably premature.

**Adopt citty or cleye**: Gets you `--help` generation, unknown flag rejection, type inference from definitions, and subcommand support for free. Eliminates the `CliArgs` non-discriminated-union problem. The counter-argument: it's another dependency for a tool that currently only depends on zod.

**Lean**: If you're about to add `--version`, `--debug`, `--json`, and unknown flag validation, you're reimplementing what citty gives you in 3 lines. Adopt citty or cleye.

### execa vs Raw child_process

**Keep raw**: Zero new dependencies. The timeouts work. Signal handling can be added manually.

**Adopt execa**: Gets `forceKillAfterDelay` (SIGTERM→SIGKILL escalation), `cleanup: true` (kill children on parent exit), `cancelSignal` integration, and rich error objects with `timedOut`/`isCanceled` flags. ESM-only is not an issue. The counter-argument: it's sindresorhus ecosystem with frequent major version bumps.

**Lean**: Adopt execa. The `forceKillAfterDelay` and `cleanup` behaviors would require 50+ lines to replicate manually, and getting them wrong has real consequences (orphan processes, hung shutdowns).

### Spinner Library

yocto-spinner is the clear pick for an ESM-only project. If you later need dual CJS/ESM (unlikely for prd-loop), nanospinner.

### Color Library

ansis is the best option for new projects — smallest, fastest with chained styles, dual ESM/CJS. prd-loop's output is mostly structural (`=== Phase ===` banners), so color additions should be minimal: green for success, red for errors, dim for secondary info.

### Skill Reference File

The TypeScript-specific delta is large enough for a separate `references/typescript-cli.md`. The library landscape, build tooling, type-system patterns, and ESM considerations are largely orthogonal to what `node-cli.md` covers (runtime-agnostic: chalk, ora, inquirer, testing). Cross-reference rather than duplicate.

## Recommended Approach

### Priority 1: Signal Handling + Process Lifecycle (Do Before Integration Test)

1. Add `ProcessManager` class to track spawned children
2. Wire SIGINT/SIGTERM handlers in `cli.ts` (once-flag, double-press force-exit, timeout guardian)
3. Migrate from `execFile` to `execa` for `forceKillAfterDelay` and `cleanup`
4. Thread `AbortController` through dispatch layer
5. Swap `writeFile` to `write-file-atomic` in `writeState()`
6. Checkpoint state before spawning children, not just after

### Priority 2: CLI Surface Polish (After Integration Test)

7. Add `--help` and `--version` flags (or adopt citty/cleye)
8. Validate unknown flags (reject with error)
9. Make `CliArgs` a discriminated union
10. Add yocto-spinner for long-running operations
11. Add ansis for colored output (success/error/dim)
12. Add `--debug` flag for verbose output
13. Use structured exit codes (2 for bad args, 130 for SIGINT)
14. Audit error messages for Context→Problem→Solution pattern

### Priority 3: Type Safety Deepening (When Touching These Files)

15. Extend Zod to CLI arg validation
16. Extend Zod to config validation (replace manual `applyOverrides`)
17. Consider branded types for `FilePath`, `PrdPath`
18. Use `as const satisfies` for command definitions

### Priority 4: Skill Update

19. Create `references/typescript-cli.md` in the cli-developer skill covering:
    - TypeScript-native arg parsing libraries (citty, cleye, cmd-ts, Optique)
    - Zod-based CLI patterns
    - Build & distribution (tsdown, tsx dev vs compiled dist)
    - ESM considerations (.js extensions, import.meta.dirname)
    - TypeScript-specific patterns (discriminated unions for commands, branded types, satisfies)
20. Add cross-reference from `node-cli.md` to `typescript-cli.md`

## References & Sources

### Arg Parsing
- [Bloomberg Stricli - Alternatives Considered](https://bloomberg.github.io/stricli/docs/getting-started/alternatives)
- [Building CLI apps with TypeScript in 2026](https://dev.to/hongminhee/building-cli-apps-with-typescript-in-2026-5c9d)
- [citty GitHub](https://github.com/unjs/citty)
- [cleye GitHub](https://github.com/privatenumber/cleye)
- [commander.js GitHub](https://github.com/tj/commander.js)
- [commander extra-typings](https://github.com/commander-js/extra-typings)
- [npm trends comparison](https://npmtrends.com/cac-vs-citty-vs-cleye-vs-clipanion-vs-commander-vs-meow-vs-type-flag-vs-yargs)
- [Node.js util.parseArgs docs](https://nodejs.org/api/util.html)

### Process Lifecycle & Signals
- [Beyond Ctrl-C: Dark corners of Unix signal handling](https://sunshowers.io/posts/beyond-ctrl-c-signals/)
- [Node.js child_process documentation](https://nodejs.org/api/child_process.html)
- [execa GitHub](https://github.com/sindresorhus/execa)
- [execa termination docs](https://github.com/sindresorhus/execa/blob/main/docs/termination.md)
- [Turborepo issue #444: SIGINT not propagated](https://github.com/vercel/turborepo/issues/444)
- [Nx issue #18255: incorrect signal sent during shutdown](https://github.com/nrwl/nx/issues/18255)
- [AbortController guide (AppSignal)](https://blog.appsignal.com/2025/02/12/managing-asynchronous-operations-in-nodejs-with-abortcontroller.html)
- [write-file-atomic on npm](https://www.npmjs.com/package/write-file-atomic)

### CLI UX
- [ansis GitHub](https://github.com/webdiscus/ansis)
- [ansis vs chalk benchmark](https://dev.to/webdiscus/comparison-of-nodejs-libraries-to-colorize-text-in-terminal-4j3a)
- [yocto-spinner GitHub](https://github.com/sindresorhus/yocto-spinner)
- [listr2 docs](https://listr2.kilic.dev/)
- [@inquirer/prompts](https://github.com/SBoudrias/Inquirer.js)
- [CLI Guidelines](https://clig.dev/)
- [NO_COLOR standard](https://no-color.org/)
- [ci-info on npm](https://www.npmjs.com/package/ci-info)

### TypeScript-Specific
- [tsdown: The Elegant Bundler](https://tsdown.dev/guide/)
- [tsx compilation docs](https://tsx.is/compilation)
- [Node.js native TypeScript docs](https://nodejs.org/api/typescript.html)
- [TypeScript ESM packages (2ality)](https://2ality.com/2025/02/typescript-esm-packages.html)
- [import.meta.dirname](https://www.sonarsource.com/blog/dirname-node-js-es-modules/)
- [Branded Types in TypeScript](https://www.learningtypescript.com/articles/branded-types)
- [satisfies operator (Builder.io)](https://www.builder.io/blog/satisfies-operator)
- [Zod documentation](https://zod.dev/)

## Open Questions

1. **Should prd-loop adopt a CLI framework (citty/cleye) or keep hand-rolling?** The research leans toward adopting one, but the current surface is small enough that either is defensible.
2. **Is execa's major-version churn acceptable?** It's on v9 with breaking changes between majors. The alternative is a manually-built `ProcessManager` with raw `child_process`.
3. **How much UX polish matters for an internal tool?** prd-loop is primarily used by its author. Spinners and colors are nice but not blocking. Signal handling is blocking regardless of audience.
4. **Should the build tool change from `tsc` to `tsdown`?** tsc works fine for a non-published, single-target CLI. tsdown would matter more if distributing via npm.
5. **Integration test first or polish first?** The handoff recommends integration test as blocking. Signal handling should arguably be done first since the integration test will involve real Claude/Codex calls that need graceful interruption.
