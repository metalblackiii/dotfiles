# Code Intelligence (LSP)

TypeScript and Rust LSP servers are active.

## When to Use LSP vs Grep

**Grep/Glob** for initial discovery — finding where a symbol lives in the codebase.
**LSP** for precise navigation once you have a file:line location.

## Diagnostics

Don't proceed after edits without checking LSP diagnostics — type errors surface immediately without running `tsc` or `cargo check`.
