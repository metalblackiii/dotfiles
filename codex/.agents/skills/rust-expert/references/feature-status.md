# Rust Feature Status (March 2026)

This table tracks what's stable, what's nightly, and what's speculative. Update when features stabilize.

**Rule: Never depend on nightly features in production code.**

## Stable — Safe to Use

| Feature | Stable Since | Notes |
|---|---|---|
| Async fn in traits (AFIT) | 1.75 (Dec 2023) | Static dispatch only; dyn dispatch still needs workaround |
| `use<..>` precise capturing | 1.82 (Oct 2024) | Opt out of RPIT lifetime capture |
| Async closures (`AsyncFn*`) | 1.85 (Feb 2025) | `AsyncFn`, `AsyncFnMut`, `AsyncFnOnce` |
| GATs (generic associated types) | 1.65 (Nov 2022) | |
| `core::error::Error` | 1.81 (Sep 2024) | Improved no_std error handling |
| `std::sync::LazyLock` | 1.80 (Jul 2024) | Replaces lazy_static and once_cell |
| `Result::inspect_err` | 1.76 (Feb 2024) | Lightweight logging without changing propagation |
| `[lints]` in Cargo.toml | 1.74 (Nov 2023) | Declarative lint configuration |
| Edition 2024 | 1.85 (Feb 2025) | RPIT capture, unsafe extern, resolver v3 |
| thiserror 2.0 | Late 2024 | no-std support, stricter direct-dep requirement |
| `&raw const` / `&raw mut` | 1.82 (Oct 2024) | Replacement for `static mut` references |

## Nightly — Do NOT Use in Production

| Feature | Status | Notes |
|---|---|---|
| `gen` blocks / generators | Nightly, no stable date | `gen { yield x; }` syntax; `gen` is a reserved keyword in 2024 edition |
| Const traits | Nightly, active dev | `~const Trait` bounds |
| Polonius (new borrow checker) | Nightly, alpha targeted H2 2025 | Enables lending iterators; stable TBD (2026+) |
| Return type notation (RTN) | Nightly, 2026 stabilization goal | `T::method(..): Send` bounds |
| Async Drop | Nightly experiment | No stable date |
| `std::error::Report` | Nightly | Error chain formatting |
| `error_generic_member_access` | Nightly | Backtrace/context through error chains |

## Pre-RFC / Speculative — Multi-Year Horizon

| Feature | Status | Notes |
|---|---|---|
| Keyword generics / effects | Pre-RFC | `async`/`const`/`try` as generic parameters |
| Rust 2027 edition | Planning | Three-year cadence; will only ship if warranted |
| Async iterators (native) | Design phase | Current workaround: `tokio_stream` or manual `Stream` impl |

## Edition Timeline

| Edition | Stable Since | Key Changes |
|---|---|---|
| 2015 | May 2015 | Initial stable Rust |
| 2018 | Dec 2018 | Modules overhaul, NLL, async foundations |
| 2021 | Oct 2021 | Resolver v2, disjoint captures in closures |
| 2024 | Feb 2025 | RPIT capture, unsafe extern, resolver v3, `gen` reserved |
| 2027 | Expected ~2027 | Not yet announced as a formal program |

## Migration

To migrate between editions:

```bash
# Check what needs changing
cargo fix --edition --all-features --allow-dirty

# Update Cargo.toml edition field
# Run full test suite
cargo nextest run --workspace --all-features
```

Different-edition crates interoperate seamlessly — you can depend on 2021-edition crates from a 2024-edition project.
