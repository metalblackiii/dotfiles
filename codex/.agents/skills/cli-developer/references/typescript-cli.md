# TypeScript CLI Development

TypeScript-specific patterns for building CLIs. For runtime-agnostic concerns (terminal output, progress bars, interactive prompts, testing), see `node-cli.md`.

## Type-Safe Arg Parsing

The TypeScript CLI parsing ecosystem has split from the Node.js mainstream. These libraries infer types from definitions — one source of truth, no manual interfaces.

### citty (Recommended — Zero Dependencies)

Uses `node:util.parseArgs` internally. Part of the UnJS ecosystem (powers Nuxt CLI).

```typescript
import { defineCommand, runMain } from "citty";

const deploy = defineCommand({
  meta: { name: "deploy", description: "Deploy to environment" },
  args: {
    environment: { type: "string", required: true, description: "Target env" },
    dryRun: { type: "boolean", default: false, description: "Preview only" },
    force: { type: "boolean", default: false, alias: "f" },
  },
  run({ args }) {
    // args.environment is string, args.dryRun is boolean — inferred, not annotated
    if (args.dryRun) {
      console.log(`Would deploy to: ${args.environment}`);
    }
  },
});

const main = defineCommand({
  meta: { name: "mycli", version: "1.0.0" },
  subCommands: { deploy },
});

runMain(main);
```

### cleye (Recommended — Minimal, Used by tsx)

Strongly typed flags with zero configuration. Built on type-flag.

```typescript
import { cli } from "cleye";

const argv = cli({
  name: "mycli",
  version: "1.0.0",
  flags: {
    environment: { type: String, alias: "e", description: "Target env" },
    dryRun: { type: Boolean, default: false, description: "Preview only" },
    port: { type: Number, default: 3000 },
  },
  commands: [
    // subcommands here
  ],
});

// argv.flags.environment is string | undefined
// argv.flags.dryRun is boolean
// argv.flags.port is number
```

### Decision Guide

| Need | Pick |
|------|------|
| Zero deps, subcommands, UnJS ecosystem | **citty** |
| Minimal API, strong inference, single-command | **cleye** |
| Existing codebase using commander | **commander** + `@commander-js/extra-typings` |
| Maximum type safety, compositional | **stricli** (Bloomberg) or **cmd-ts** |
| Vite/Vitest ecosystem | **cac** |
| Script with 1-3 flags | `node:util.parseArgs` (built-in, zero deps) |

What well-known CLIs use: Vite/Vitest → cac, tsx → cleye, Nuxt → citty, Yarn → clipanion, Next.js → arg.

### Zod-Based CLI Parsing

Extend Zod's "define once, infer the type" pattern to the CLI surface:

```typescript
import { z } from "zod";

const CliArgsSchema = z.object({
  environment: z.enum(["dev", "staging", "prod"]),
  port: z.coerce.number().int().min(1).max(65535).default(3000),
  dryRun: z.boolean().default(false),
  config: z.string().optional(),
});

type CliArgs = z.infer<typeof CliArgsSchema>;

// Parse raw argv into validated, typed args
function parseArgs(raw: Record<string, unknown>): CliArgs {
  return CliArgsSchema.parse(raw);
}
```

Libraries: [Zli](https://github.com/robingenz/zli), [Argzod](https://libraries.io/npm/argzod), [@optique/zod](https://github.com/dahlia/optique).

### Discriminated Unions for Command Routing

Replace string-switched routing with exhaustive type-safe dispatch:

```typescript
type Command =
  | { kind: "deploy"; environment: string; dryRun: boolean }
  | { kind: "init"; template: string; force: boolean }
  | { kind: "status" };

function handleCommand(cmd: Command): void {
  switch (cmd.kind) {
    case "deploy":
      deploy(cmd.environment, cmd.dryRun); // TS knows these fields exist
      break;
    case "init":
      init(cmd.template, cmd.force);
      break;
    case "status":
      showStatus();
      break;
    // Adding a new variant without handling it is a compile error
  }
}
```

## Terminal Output (2026 Recommendations)

### Colors — ansis (Replaces chalk)

Smallest (5.7 kB), fastest with chained styles, zero deps, dual ESM/CJS.

```typescript
import { red, green, yellow, blue, bold, dim } from "ansis";

console.error(red.bold("Error:"), "File not found");
console.error(green("Success:"), "Deployment complete");
console.error(yellow("Warning:"), "Deprecated flag");
console.error(dim("hint:"), "Run with --help for usage");

// Semantic helpers
const log = {
  error: (msg: string) => console.error(red.bold("Error:"), msg),
  success: (msg: string) => console.error(green("Done:"), msg),
  warn: (msg: string) => console.error(yellow("Warning:"), msg),
  info: (msg: string) => console.error(blue("Info:"), msg),
};
```

Handles `NO_COLOR`, `FORCE_COLOR`, and TTY detection automatically.

### Spinners — yocto-spinner (Replaces ora for ESM)

Tiny, ESM-only, from the same author as ora.

```typescript
import yoctoSpinner from "yocto-spinner";

const spinner = yoctoSpinner({ text: "Deploying..." }).start();
await deploy();
spinner.success({ text: "Deployed." });

// On failure
spinner.error({ text: "Deployment failed." });
```

For dual CJS/ESM, use `nanospinner` instead.

### Non-Interactive Degradation

```typescript
import ci from "ci-info";

const isInteractive = process.stdout.isTTY === true && !ci.isCI;

if (isInteractive) {
  const spinner = yoctoSpinner({ text: "Building..." }).start();
  await build();
  spinner.success({ text: "Built." });
} else {
  console.error("Building...");
  await build();
  console.error("Built.");
}
```

## Process Lifecycle & Signal Handling

Critical for CLIs that spawn long-running child processes.

### execa (Replaces child_process)

```typescript
import { execa } from "execa";

const controller = new AbortController();

const subprocess = execa("claude", ["-p", prompt], {
  cwd: projectDir,
  cancelSignal: controller.signal,
  forceKillAfterDelay: 5_000,  // SIGKILL 5s after SIGTERM if child ignores it
  timeout: 600_000,             // 10 min timeout
  cleanup: true,                // kill child if parent exits (default)
});

// Cancel from signal handler
process.on("SIGINT", () => controller.abort());

try {
  const { stdout, stderr } = await subprocess;
} catch (error) {
  if (error.isCanceled) { /* user cancelled */ }
  if (error.timedOut) { /* hit timeout */ }
  // Rich error: error.command, error.exitCode, error.stderr
}
```

### Graceful Shutdown Pattern

```typescript
let shuttingDown = false;

function handleShutdown(signal: NodeJS.Signals): void {
  if (shuttingDown) {
    // Double Ctrl+C — force exit
    process.exit(128 + (signal === "SIGINT" ? 2 : 15));
  }
  shuttingDown = true;
  console.error(`\nReceived ${signal}, shutting down...`);

  cleanup()
    .catch((err) => console.error("Cleanup error:", err))
    .finally(() => process.exit(128 + (signal === "SIGINT" ? 2 : 15)));
}

process.on("SIGINT", () => handleShutdown("SIGINT"));
process.on("SIGTERM", () => handleShutdown("SIGTERM"));
```

Key rules:
- Forward the **same** signal received (don't translate SIGINT→SIGTERM)
- Exit with `128 + signal_number` (130 for SIGINT, 143 for SIGTERM)
- Use `.unref()` on timeout timers so they don't keep the process alive
- Do NOT use `detached: true` unless you need process group isolation

### Atomic State Persistence

```typescript
import writeFileAtomic from "write-file-atomic";

// Normal operation: async atomic write (temp file + rename)
await writeFileAtomic(statePath, JSON.stringify(state, null, 2) + "\n");

// Exit handler fallback: sync (only runs if async path didn't complete)
process.on("exit", () => {
  if (dirtyState) {
    const tmp = `${statePath}.tmp`;
    fs.writeFileSync(tmp, JSON.stringify(state, null, 2) + "\n");
    fs.renameSync(tmp, statePath);
  }
});
```

## Build & Distribution

### Build Tools

| Tool | Engine | Status |
|------|--------|--------|
| **tsdown** | Rolldown (Rust) | Recommended for new projects |
| tsup | esbuild | No longer actively maintained — migrate to tsdown |
| tsc | TypeScript compiler | Always works, slower, maximum correctness |
| pkgroll | Rollup | Stable, same author as tsx |

### Dev vs Distribution

```json
{
  "bin": { "mycli": "./dist/cli.js" },
  "scripts": {
    "dev": "tsx src/cli.ts",
    "build": "tsdown src/cli.ts --format esm"
  },
  "files": ["dist/"],
  "engines": { "node": ">=20.0.0" }
}
```

- **Development**: `tsx` for instant feedback
- **Distribution**: Compile to `dist/*.js`, point `bin` at compiled output
- Never point `bin` at a `.ts` file or ship `tsx` as a runtime dependency

### Node.js Native TypeScript (22.18+)

Type stripping is stable and enabled by default. For dev scripts, `#!/usr/bin/env node` works with `.ts` files directly. For published CLIs, still compile — you can't guarantee users' Node version.

Limitations: no enums, ignores tsconfig, no path aliases.

## ESM Patterns

### .js Extensions in Imports

With `"moduleResolution": "nodenext"`, TypeScript requires `.js` extensions even for `.ts` source files:

```typescript
import { parseArgs } from "./helpers.js"; // NOT ./helpers.ts
```

Escape hatches: `rewriteRelativeImportExtensions: true` (TS 5.7+), or use a bundler.

### __dirname Replacement

```typescript
// Node 20.11+
const dir = import.meta.dirname;
const file = import.meta.filename;

// For file URLs (works with fs APIs)
const configUrl = new URL("./config.json", import.meta.url);
```

### Top-Level Await

Works with `"type": "module"` and `"module": "nodenext"`:

```typescript
#!/usr/bin/env node
const config = await loadConfig();
const args = parseArgs(process.argv.slice(2));
await runCommand(args, config);
```

## TypeScript-Specific Patterns

### Branded Types for CLI Values

Prevent mixing up string-typed values at compile time with zero runtime cost:

```typescript
type FilePath = string & { readonly __brand: unique symbol };
type EnvName = string & { readonly __brand: unique symbol };

function deploy(env: EnvName, artifact: FilePath): void { /* ... */ }
// Compile error: can't pass a raw string where EnvName is expected
```

### as const satisfies for Config

Validate config objects while preserving literal types:

```typescript
interface CommandDef {
  description: string;
  args: Record<string, { type: string; required?: boolean }>;
}

const commands = {
  deploy: {
    description: "Deploy to environment",
    args: { env: { type: "string", required: true } },
  },
} as const satisfies Record<string, CommandDef>;
// Validated against CommandDef AND preserves literal types
```

### Type-Safe Config Loading with Zod

One schema for both runtime validation and static types:

```typescript
import { z } from "zod";

const ConfigSchema = z.object({
  timeout: z.number().int().positive().default(30000),
  environment: z.enum(["dev", "staging", "prod"]),
  features: z.array(z.string()).default([]),
});

type Config = z.infer<typeof ConfigSchema>;

async function loadConfig(path: string): Promise<Config> {
  const raw = JSON.parse(await fs.readFile(path, "utf-8"));
  return ConfigSchema.parse(raw);
}
```

## Quick Reference

| Concern | Pick | Why |
|---------|------|-----|
| Arg parsing (zero deps) | citty | TS-first, util.parseArgs under the hood |
| Arg parsing (minimal) | cleye | Strong inference, used by tsx |
| Colors | ansis | Smallest, fastest multi-style, auto NO_COLOR |
| Spinners | yocto-spinner | Tiny ESM, signal-aware |
| Child processes | execa | forceKillAfterDelay, cleanup, rich errors |
| State persistence | write-file-atomic | Atomic writes, crash-safe |
| Build | tsdown | Rolldown-based, replaces tsup |
| Dev runner | tsx | esbuild-powered, instant |
| CI detection | ci-info | Vendor-specific, PR awareness |
