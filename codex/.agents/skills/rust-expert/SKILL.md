---
name: rust-expert
description: ALWAYS invoke when writing, reviewing, or modifying Rust code — including Cargo.toml, CI pipelines, dependency choices, and error handling. Do not write Rust code directly without loading this skill first.
---

# Rust Expert

## Overview

Encodes Rust best practices that general LLM knowledge gets wrong or outdated — deprecated patterns, edition 2024 specifics, crate selection nuances, CI quality gates, and common anti-patterns. Based on research conducted March 2026 against primary sources (official docs, crate READMEs, release notes).

## When to Use

- Writing new Rust code or modifying existing Rust code
- Choosing crates or dependencies
- Setting up CI, lints, or quality tooling
- Reviewing Rust PRs
- Configuring Cargo.toml, rustfmt.toml, clippy settings

## Deprecated Patterns — Flag These Immediately

| Old Pattern | Replacement | Since |
|---|---|---|
| `lazy_static!` macro | `std::sync::LazyLock` | Rust 1.80 |
| `once_cell::sync::Lazy` | `std::sync::LazyLock` | Rust 1.80 |
| `#[async_trait]` (static dispatch) | Native `async fn` in traits | Rust 1.75 |
| `serde_yaml` | `serde_yml` (community fork, `serde_yaml` unmaintained) | 2024 |
| `async-std` runtime | Tokio or `smol` (`async-std` discontinued March 2025) | 2025 |
| `cargo-watch` | `bacon` (cargo-watch maintainer recommends bacon) | 2024 |
| `ansi_term` / `termcolor` | `owo-colors` or `colored` | 2024 |
| `cargo-tarpaulin` | `cargo-llvm-cov` (more accurate, actively maintained) | 2024 |

When you see these in existing code, flag them. When writing new code, use the replacement.

**Exception**: `#[async_trait]` is still needed for `dyn Trait` with async methods (native dyn async trait is not yet stable). Use `dynosaur` for new code if dyn dispatch is required.

## Edition 2024 (Rust 1.85+)

When `edition = "2024"` is set in Cargo.toml:

- **RPIT lifetime capture**: `-> impl Trait` now captures ALL in-scope lifetimes. Use `use<'a>` syntax to opt out of specific captures. This is a behavioral change from 2021.
- **`unsafe_op_in_unsafe_fn`**: deny-by-default. Every unsafe call inside an `unsafe fn` requires its own `unsafe {}` block.
- **Unsafe extern**: `extern "C" { ... }` → `unsafe extern "C" { ... }`. Individual items can be marked `safe` inside.
- **`static mut` references**: hard error. Use `&raw const`/`&raw mut` or sync primitives.
- **`gen` keyword reserved**: cannot use `gen` as an identifier (preparation for generator blocks).
- **Prelude additions**: `Future`, `IntoFuture`, `AsyncFn`, `AsyncFnMut`, `AsyncFnOnce`.
- **Cargo resolver v3**: MSRV-aware dependency resolution (implied by `edition = "2024"`). Virtual workspaces must still set `resolver = "3"` explicitly.
- **`style_edition = "2024"`** in `rustfmt.toml` to match formatting expectations.

## Crate Selection

Use `references/crate-recommendations.md` for the full table. Key decisions where LLMs often get it wrong:

| Decision | Correct Choice | Why LLMs Get It Wrong |
|---|---|---|
| Timezone-aware dates | `jiff` (by BurntSushi) | LLMs recommend chrono; jiff has superior DST/timezone handling |
| UTC timestamps / ecosystem interop | `chrono` | Still the ecosystem standard for UTC and serde compat |
| Benchmarking (new project) | `divan` | LLMs default to criterion; divan has better ergonomics and allocation profiling |
| Benchmarking (existing) | `criterion` | Mature, established — don't migrate without reason |
| Dyn async trait | `dynosaur` | LLMs recommend `#[async_trait]`; dynosaur is the modern path |
| Code coverage | `cargo-llvm-cov` | LLMs recommend tarpaulin; llvm-cov is more accurate |
| File watching | `bacon` | LLMs recommend cargo-watch; bacon is the successor |
| YAML serde | `serde_yml` | LLMs recommend serde_yaml; it's unmaintained |

### Version Numbers — Never Trust LLM Knowledge

LLM training data has a cutoff. Crate versions drift daily. **Never hardcode a version from memory.**

- Use `cargo add <crate>` — always resolves the real latest from crates.io
- Use `cargo outdated` to audit existing dependencies
- Use `cargo update` to bump `Cargo.lock` within semver bounds
- In VS Code, Version Lens + Even Better TOML show live version info inline in `Cargo.toml`
- In CI, `cargo deny` and `cargo audit` catch known-vulnerable versions

When adding a dependency in code or `Cargo.toml`, prefer omitting the version and letting `cargo add` resolve it, or use `cargo add <crate>@latest`. Do not guess version numbers.

## Error Handling Conventions

### The Real Axis: Handle vs Report

The common "thiserror for libraries, anyhow for applications" is directionally correct but incomplete. The real axis is **handle vs report**: use typed errors where callers branch on failure mode; use opaque errors where callers just propagate/log.

| Situation | Crate |
|---|---|
| Library public API — callers match on variants | `thiserror` |
| Application — errors go to logs/users | `anyhow` |
| CLI — colorized error chain output | `eyre` + `color-eyre` |
| CLI/compiler — source-annotated diagnostics | `miette` |
| Complex system — many error sources | `snafu` |

### Anti-Patterns

- **Do NOT embed `{source}` in `#[error("...")]`** — breaks error chain composition (source gets printed twice by reporters like anyhow/eyre)
- **Do NOT blanket `#[from]` on all variants** — collapses error diversity, makes matching useless
- **Do NOT log and propagate** — choose one. The handler (function that stops `?` propagation) logs.
- **Do NOT use `Box<dyn Error>` in library APIs** — callers can't match. Use thiserror enum or `anyhow`-style for applications.
- Error messages: lowercase, no trailing punctuation, describe only the current error

### What's New
- `thiserror` 2.0 (late 2024): no-std support, stricter direct-dependency requirement
- `core::error::Error` stabilized in 1.81
- `Result::inspect_err` stabilized in 1.76 — lightweight logging without changing propagation

## CI Quality Gate

```bash
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo nextest run --workspace --all-features
cargo deny check
cargo audit
cargo llvm-cov nextest --lcov --output-path lcov.info
```

### Lint Configuration

Prefer `[lints]` in `Cargo.toml` (stable since 1.74) over attributes in source files:

```toml
[lints.clippy]
all = "deny"
unwrap_used = "deny"
expect_used = "deny"
pedantic = "warn"
```

### Minimum Config Files

| File | Purpose |
|---|---|
| `rustfmt.toml` | `edition = "2024"`, `style_edition = "2024"` |
| `deny.toml` | `cargo deny init`, then customize advisories/licenses/bans |
| `Cargo.toml [lints]` | Clippy lint levels |
| `.github/workflows/ci.yml` | Quality gate pipeline |

## Testing Structure

| Layer | Convention |
|---|---|
| Unit tests | `#[cfg(test)] mod tests` at bottom of each source file |
| Integration tests | `tests/` directory — each file is a separate crate |
| Shared test helpers | `tests/common/mod.rs` (NOT `tests/common.rs` — that becomes its own test) |
| Fixtures | `tests/fixtures/` or `testdata/` |
| Benchmarks | `benches/*.rs` |
| Fuzz targets | `fuzz/fuzz_targets/*.rs` |

### Test tool preferences

| Tool | Purpose |
|---|---|
| `cargo-nextest` | Test runner (up to 3x faster, process-per-test isolation) |
| `proptest` | Property-based testing (preferred over quickcheck) |
| `insta` | Snapshot testing for structured/large output |
| `mockall` | Trait-based mocking |
| `wiremock` | HTTP endpoint mocking |
| `cargo-mutants` | Mutation testing — finds code where tests pass even when logic is changed |

### Test naming
- `snake_case`, descriptive: `empty_string_returns_none`
- No `test_` prefix (redundant with `#[test]`)
- Under ~60 characters
- Nested `mod` inside `tests` for grouping

## Async Decision Framework

```
Is this CPU-bound without I/O?
  → Rayon or spawn_blocking. NOT async.

Many concurrent connections / I/O?
  → async/await with Tokio (de facto standard)

Simple sync CLI tool?
  → No async. Don't add Tokio for no reason.

Long-lived blocking workload?
  → Dedicated OS thread (not spawn_blocking, which has a pool limit)
```

### Async Anti-Patterns

1. **Blocking in async** — never `std::thread::sleep`, `std::fs::*`, or `std::io::*` inside async. Use `tokio::fs`, `tokio::time::sleep`, or `spawn_blocking`.
2. **`std::sync::Mutex` across `.await`** — guard is not Send; use `tokio::sync::Mutex` or scope the lock explicitly.
3. **Nested `block_on`** — calling `block_on` from within an async context → deadlock.
4. **Cancellation unsafety** — code after `.await` may never run if the future is dropped. Use RAII guards for cleanup.
5. **RAII guard starvation** — holding DB connection pool handles across unrelated await points starves the pool.

### Runtime Landscape (2025-2026)

| Runtime | Status | Use When |
|---|---|---|
| Tokio | De facto standard | Default for all async |
| smol | Maintained, lightweight | Runtime-agnostic or migrating from async-std |
| async-std | **Discontinued** (March 2025) | Never — migrate away |
| embassy | Active, embedded | Firmware / no_std |

## Tooling

### CLI Tools

| Tool | Purpose | Notes |
|---|---|---|
| `bacon` | Watch + rebuild/test/clippy | Replaces cargo-watch. `bacon clippy`, `bacon test`, `bacon run` |
| `sccache` | Shared compilation cache | Speeds up rebuilds and CI. Supports local, S3, GCS, Redis backends |
| `cargo-nextest` | Fast test runner | Process-per-test isolation, up to 3x faster |
| `cargo-mutants` | Mutation testing | Finds untested code paths by modifying logic and checking if tests catch it |
| `cargo-deny` | Supply chain policy | Advisories, licenses, bans, source whitelisting |
| `cargo-audit` | Vulnerability scanning | RustSec advisory database |
| `cargo-expand` | Macro debugging | Shows expanded macro output |
| `cargo-udeps` | Find unused deps | Reduce supply chain surface |
| `cargo-bloat` | Binary size analysis | Find what's bloating your binary |
| `cargo-msrv` | MSRV verification | Find minimum supported Rust version |

### VS Code Extensions

| Extension | Purpose |
|---|---|
| `rust-analyzer` | LSP — code completion, diagnostics, refactoring |
| `CodeLLDB` | Debugger with Rust visualizers |
| `Even Better TOML` | TOML editing with schema validation for Cargo.toml |
| `Dependi` | Inline crate version info and update hints |
| `Error Lens` | Inline error/warning display |

## Project Structure

| Decision | Best Practice |
|---|---|
| Workspace vs single crate | Single crate until you have 2+ deliverables or painful compile times |
| lib+bin pattern | Yes — keep `main.rs` thin (~50 lines), real logic in `lib.rs` |
| Module file style | `foo.rs` preferred over `foo/mod.rs` for new code; be consistent |
| Module depth | Max 2-3 levels; flatten with `pub use` re-exports |
| Workspace layout | `crates/` subdirectory, virtual manifest, `resolver = "3"` |
| Public API | Re-export key types from `lib.rs`; module paths are implementation detail |

### Structure Anti-Patterns
- `mod lib;` from `main.rs` — use `your_crate_name::...` instead
- Splitting crates prematurely — wait for stability, not speculation
- Mixing `mod.rs` and `foo.rs` styles within one crate

## Feature Status Awareness

See `references/feature-status.md` for the detailed table. Key rule: **never depend on nightly features in production code**. If a feature is listed as "nightly" or "pre-RFC", do not use it or recommend it for production.

Stable highlights (safe to use):
- Async fn in traits (1.75), async closures (1.85)
- GATs (1.65), `use<..>` precise capturing (1.82)
- `core::error::Error` (1.81), `LazyLock` (1.80)

Not yet stable (do NOT use in production):
- `gen` blocks/generators, const traits, Polonius borrow checker
- Async Drop, async iterators, keyword generics/effects
- Return type notation (RTN)
