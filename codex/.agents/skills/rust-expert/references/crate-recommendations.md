# Crate Recommendations (March 2026)

## Table of Contents

- [CLI](#cli)
- [Serialization](#serialization)
- [HTTP Client](#http-client)
- [Web Framework](#web-framework)
- [Database](#database)
- [Observability](#observability)
- [Date/Time](#datetime)
- [UUID](#uuid)
- [Config](#config)
- [Error Handling](#error-handling)
- [Async Channels](#async-channels)
- [Deprecated Crates](#deprecated-crates)
- [Dependency Management](#dependency-management)

---

## CLI

| Crate | Use When |
|---|---|
| `clap` (derive) | Full-featured parser — subcommands, validation, completions, color help |
| `argh` | Minimal binary size, derive-based, Google-maintained |

## Serialization

| Crate | Use When |
|---|---|
| `serde` + format crates | Default for all serialization. `serde_json`, `serde_yml`, `toml`, `ciborium` (CBOR) |
| `rkyv` | Zero-copy deserialization for performance-critical paths (non-serde API) |

## HTTP Client

| Crate | Use When |
|---|---|
| `reqwest` | Default for async HTTP. Supports JSON, multipart, proxies, rustls/native-TLS |
| `ureq` | Sync, low-overhead, pure-Rust, minimal dependencies |

## Web Framework

| Crate | Use When |
|---|---|
| `axum` | Default for Tokio/hyper stack. Tower middleware ecosystem |
| `actix-web` | Higher raw throughput, built-in HTTP/1+2+TLS, micro-framework style |

Note: `axum` explicitly says runtime independence is not a goal — it is designed for Tokio.

## Database

| Crate | Use When |
|---|---|
| `sqlx` | Async SQL-first development, optional compile-time checked queries, no ORM |
| `diesel` | Typed ORM/query builder, mature, sync |
| `rusqlite` | Direct SQLite, sync, embedded/local DB |
| `sea-orm` | Batteries-included async ORM with migrations, pagination |

Note: Check for prerelease versions — standardize on latest stable non-prerelease for `sqlx` and `sea-orm`.

## Observability

| Crate | Use When |
|---|---|
| `tracing` + `tracing-subscriber` | Application code, async services — structured, span-based diagnostics |
| `log` | Minimal facade for libraries (broad ecosystem compat) |
| `env_logger` | Simple env-driven logger for `log` facade in executables |

Use `tracing` for applications. Use `log` for libraries that need maximum compatibility.

## Date/Time

| Crate | Use When |
|---|---|
| `jiff` | Timezone-aware dates, DST handling, civil datetime arithmetic. By BurntSushi. Best-in-class for timezone work. |
| `chrono` | UTC timestamps, ecosystem interop (many crates accept chrono types), serde compat |
| `time` | Tighter API, explicit rolling MSRV policy. Good for new projects that don't need timezone sophistication. |

**Key insight**: `jiff` supersedes both chrono and time for timezone-aware work in greenfield projects. `chrono` remains valuable for UTC and ecosystem compatibility. Don't mix all three — pick `jiff` + `chrono` or `jiff` alone.

## UUID

| Crate | Use When |
|---|---|
| `uuid` | Always. The standard Rust UUID crate. References RFC 9562. |

## Config

| Crate | Use When |
|---|---|
| `config` | Layered config from files, env vars, and overrides |
| `figment` | Explicit provider composition, merge vs join semantics, profile-style layering |

## Error Handling

| Crate | Use When |
|---|---|
| `thiserror` | Library APIs — callers match on error variants |
| `anyhow` | Application code — errors are reported, not matched |
| `eyre` + `color-eyre` | CLI tools — colorized error chain display |
| `miette` | Compilers/CLIs — source-annotated diagnostic output |
| `snafu` | Complex systems with many error sources and contexts |

## Async Channels

| Need | Crate |
|---|---|
| Async MPSC, within Tokio | `tokio::sync::mpsc` |
| Async broadcast | `tokio::sync::broadcast` |
| Async state watching | `tokio::sync::watch` |
| Async one-shot | `tokio::sync::oneshot` |
| Sync, high performance MPMC | `crossbeam-channel` |
| Mixed sync/async | `flume` (maintenance mode but stable API) |

## Deprecated Crates

| Old | Replacement | Reason |
|---|---|---|
| `lazy_static` | `std::sync::LazyLock` | In std since 1.80 |
| `once_cell::sync::Lazy` | `std::sync::LazyLock` | In std since 1.80 |
| `async-trait` (for static dispatch) | Native async fn in trait | Stable since 1.75 |
| `serde_yaml` | `serde_yml` | `serde_yaml` unmaintained |
| `async-std` | Tokio or `smol` | Discontinued March 2025 |
| `cargo-watch` | `bacon` | Maintainer recommends bacon |
| `cargo-tarpaulin` | `cargo-llvm-cov` | More accurate instrumentation |
| `ansi_term` | `owo-colors` or `colored` | `ansi_term` unmaintained |
| `termcolor` | `owo-colors` or `colored` | Less ergonomic, fewer features |

## Dependency Management

### Supply chain tooling

| Tool | Purpose |
|---|---|
| `cargo-deny` | License compliance, advisories, banned crates, source whitelisting |
| `cargo-audit` | RustSec vulnerability scanning (advisory DB) |
| `cargo-vet` | Human audit trail for third-party code (regulated environments) |
| `cargo-auditable` | Embed dependency info in binaries for post-deploy auditing |
| `cargo-udeps` | Find unused direct dependencies |
| `cargo-outdated` | Find semver-outdated dependencies |

### Practices

- Commit `Cargo.lock` for binaries (always). For libraries, commit it for CI reproducibility.
- Use `--locked` in CI and release builds: `cargo build --locked`
- Run `cargo deny check` and `cargo audit` in CI.
- Prefer registry crates over git dependencies.
- Use `cargo tree --duplicates` to find multi-version duplicates.
- Set `package.rust-version` (MSRV) in Cargo.toml — especially for libraries.
- Treat MSRV bumps as at least a minor version change.
- Use Renovate or Dependabot for automated dependency updates.
