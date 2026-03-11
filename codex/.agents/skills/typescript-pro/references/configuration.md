# TypeScript Configuration

## Strict Mode Configuration

All strict sub-flags are included by `"strict": true`. Listed individually here for reference — you do not need to set them separately.

```jsonc
{
  "compilerOptions": {
    // strict: true enables all of these:
    "strict": true,
    //   "noImplicitAny": true,
    //   "strictNullChecks": true,
    //   "strictFunctionTypes": true,
    //   "strictBindCallApply": true,
    //   "strictPropertyInitialization": true,
    //   "noImplicitThis": true,
    //   "alwaysStrict": true,

    // Additional checks (not included in strict)
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "exactOptionalPropertyTypes": true
  }
}
```

## Bundled Web App Example (Vite / esbuild / webpack)

```jsonc
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Preserve",
    "moduleResolution": "bundler",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "strict": true,
    "noEmit": true,
    "allowImportingTsExtensions": true,
    "verbatimModuleSyntax": true,
    "moduleDetection": "force",
    "isolatedModules": true,
    "skipLibCheck": true
  }
}
```

## Project References

```json
// Root tsconfig.json
{
  "files": [],
  "references": [
    { "path": "./packages/shared" },
    { "path": "./packages/frontend" },
    { "path": "./packages/backend" }
  ]
}

// packages/shared/tsconfig.json
{
  "compilerOptions": {
    "composite": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "declaration": true,
    "declarationMap": true
  },
  "include": ["src/**/*"]
}

// packages/frontend/tsconfig.json
{
  "compilerOptions": {
    "composite": true,
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "references": [
    { "path": "../shared" }
  ],
  "include": ["src/**/*"]
}
```

## Module Resolution Decision Tree

Pick based on where your code **actually runs**:

| Scenario | `module` | `moduleResolution` | Why |
|----------|----------|-------------------|-----|
| **Node.js app** | `"NodeNext"` | `"NodeNext"` | Enforces Node's ESM/CJS rules; type checking differs from bundler even when emitted JS looks similar |
| **Node.js, pinned version** | `"Node18"` or `"Node20"` | (implied) | Stable semantics; `NodeNext` is a moving target tracking latest Node |
| **Bundled app (Vite, etc.)** | `"Preserve"` or `"ESNext"` | `"bundler"` | Matches bundler semantics; pair with `noEmit`, `allowImportingTsExtensions`, `verbatimModuleSyntax` |
| **Library** | `"NodeNext"` | `"NodeNext"` | Code valid under Node rules works in bundlers; `bundler` admits imports only bundlers accept |

**Avoid:** `"Classic"`, `"node"` / `"node10"` — deprecated, will error in TS 7.

```jsonc
// Node.js app or library
{
  "compilerOptions": {
    "module": "NodeNext",
    "moduleResolution": "NodeNext"
  }
}

// Bundler-first app (Vite, esbuild, webpack)
{
  "compilerOptions": {
    "module": "Preserve",
    "moduleResolution": "bundler",
    "noEmit": true,
    "allowImportingTsExtensions": true,
    "verbatimModuleSyntax": true,
    "moduleDetection": "force"
  }
}
```

## Node Type-Stripping Workflow (TS 5.8+)

Node can run `.ts` files directly via built-in type stripping (`--experimental-strip-types` flag in Node 22.6+, enabled by default since 22.18.0 and 23.6.0). It only erases type annotations — no enums, no namespaces, no parameter properties, no `import =`. To ensure your code is compatible:

```jsonc
// tsconfig.json for Node type-stripping compatibility
{
  "compilerOptions": {
    "erasableSyntaxOnly": true,              // (5.8) Ban non-erasable TS syntax
    "verbatimModuleSyntax": true,            // (5.0) Explicit import/export elision
    "rewriteRelativeImportExtensions": true, // (5.7) .ts → .js in emitted output
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "target": "ES2022",
    "strict": true
  }
}
```

**What `erasableSyntaxOnly` bans:**
- `enum` declarations → use `as const` objects instead
- `namespace` declarations (non-`declare`) → use ES modules
- Parameter properties (`constructor(public x: number)`) → use explicit assignment
- `import =` / `export =` → use standard ESM syntax

**Why `rewriteRelativeImportExtensions`:** Node requires explicit file extensions in imports. This flag lets you write `import "./foo.ts"` in source while `tsc` emits `import "./foo.js"` — bridging the gap between author-time and runtime resolution.

**Workflow:**
1. Enable `erasableSyntaxOnly` + `verbatimModuleSyntax` + `rewriteRelativeImportExtensions` in tsconfig
2. Run `tsc --noEmit` to catch non-erasable syntax
3. Fix violations (usually enum → `as const`)
4. Code can now run via `node src/index.ts` (22.18.0+ / 23.6.0+) or `node --experimental-strip-types src/index.ts` (22.6–22.17)
5. `tsx` remains the better dev runner (handles `.tsx`, respects `tsconfig`, supports watch mode)

## Path Mapping

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@components/*": ["src/components/*"],
      "@utils/*": ["src/utils/*"],
      "@shared/*": ["../shared/src/*"],
      "@types": ["src/types/index.ts"]
    }
  }
}
```

```typescript
// Usage with path mapping
import { Button } from '@components/Button';
import { formatDate } from '@utils/date';
import type { User } from '@types';
```

## Incremental Compilation

```json
{
  "compilerOptions": {
    "incremental": true,
    "tsBuildInfoFile": "./dist/.tsbuildinfo",
    "composite": true
  }
}
```

## Declaration Files

```jsonc
{
  "compilerOptions": {
    // Generate .d.ts files
    "declaration": true,
    "declarationMap": true,
    "emitDeclarationOnly": false,

    // Bundle declarations
    "declarationDir": "./types",

    // For libraries
    "stripInternal": true
  }
}
```

### Isolated Declarations (TS 5.5+)

`isolatedDeclarations` enables external tools (tsdown, Oxc, etc.) to generate `.d.ts` files without running the full type checker — each file's declarations are self-contained. This unlocks parallel declaration emit and faster builds.

```jsonc
{
  "compilerOptions": {
    "declaration": true,
    "isolatedDeclarations": true
  }
}
```

**What it requires:** all exported functions, classes, and variables must have explicit return types and type annotations. The compiler will error on implicit types that cross file boundaries.

```typescript
// Error under isolatedDeclarations — inferred return type
export function createUser(name: string) {
  return { id: crypto.randomUUID(), name };
}

// Fixed — explicit return type
export function createUser(name: string): { id: string; name: string } {
  return { id: crypto.randomUUID(), name };
}
```

**When to adopt:**
- Library authors using tsdown/Oxc for declaration emit
- Monorepos where parallel declaration generation matters
- Projects already following "explicit return types on public APIs"

**When to skip:** application code where declaration files aren't published. The annotation burden isn't worth it if you're not distributing types.
```

```typescript
// Using JSDoc for .d.ts generation
/**
 * Creates a user
 * @param name - User's name
 * @param email - User's email
 * @returns The created user
 * @example
 * ```ts
 * const user = createUser('John', 'john@example.com');
 * ```
 */
export function createUser(name: string, email: string): User {
  return { id: generateId(), name, email };
}
```

## Build Optimization

```json
{
  "compilerOptions": {
    // Performance
    "skipLibCheck": true,
    "skipDefaultLibCheck": true,

    // Faster builds
    "incremental": true,
    "assumeChangesOnlyAffectDirectDependencies": true,

    // Smaller output
    "removeComments": true,
    "importHelpers": true,

    // Tree shaking support
    "module": "ESNext",
    "target": "ES2020"
  }
}
```

## Multiple Configurations

```json
// tsconfig.json (base)
{
  "compilerOptions": {
    "strict": true,
    "target": "ES2022"
  }
}

// tsconfig.build.json (production)
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "sourceMap": false,
    "removeComments": true,
    "declaration": true
  },
  "exclude": ["**/*.test.ts", "**/*.spec.ts"]
}

// tsconfig.test.json (testing)
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "types": ["jest", "node"],
    "esModuleInterop": true
  },
  "include": ["src/**/*.test.ts", "src/**/*.spec.ts"]
}
```

## Framework-Specific Configs

```json
// React + Vite
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "jsx": "react-jsx",
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "strict": true
  }
}

// Next.js
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}

// Node.js + Express
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "sourceMap": true
  }
}
```

## Custom Type Definitions

```typescript
// src/types/global.d.ts
declare global {
  interface Window {
    myApp: {
      version: string;
      config: AppConfig;
    };
  }

  namespace NodeJS {
    interface ProcessEnv {
      DATABASE_URL: string;
      API_KEY: string;
      NODE_ENV: 'development' | 'production' | 'test';
    }
  }
}

export {};

// src/types/modules.d.ts
declare module '*.svg' {
  const content: string;
  export default content;
}

declare module '*.css' {
  const classes: { [key: string]: string };
  export default classes;
}

declare module 'untyped-library' {
  export function doSomething(value: string): number;
}
```

## Compiler API Usage

```typescript
// programmatic compilation
import ts from 'typescript';

function compile(fileNames: string[], options: ts.CompilerOptions): void {
  const program = ts.createProgram(fileNames, options);
  const emitResult = program.emit();

  const allDiagnostics = ts
    .getPreEmitDiagnostics(program)
    .concat(emitResult.diagnostics);

  allDiagnostics.forEach(diagnostic => {
    if (diagnostic.file) {
      const { line, character } = ts.getLineAndCharacterOfPosition(
        diagnostic.file,
        diagnostic.start!
      );
      const message = ts.flattenDiagnosticMessageText(
        diagnostic.messageText,
        '\n'
      );
      console.log(
        `${diagnostic.file.fileName} (${line + 1},${character + 1}): ${message}`
      );
    } else {
      console.log(
        ts.flattenDiagnosticMessageText(diagnostic.messageText, '\n')
      );
    }
  });

  const exitCode = emitResult.emitSkipped ? 1 : 0;
  console.log(`Process exiting with code '${exitCode}'.`);
  process.exit(exitCode);
}

compile(['src/index.ts'], {
  noEmitOnError: true,
  target: ts.ScriptTarget.ES2022,
  module: ts.ModuleKind.ES2022,
  strict: true
});
```

## Performance Monitoring

```json
{
  "compilerOptions": {
    "diagnostics": true,
    "extendedDiagnostics": true,
    "generateCpuProfile": "profile.cpuprofile",
    "explainFiles": true
  }
}
```

```bash
# Run with diagnostics
tsc --diagnostics

# Extended diagnostics
tsc --extendedDiagnostics

# Generate trace
tsc --generateTrace trace

# Analyze with @typescript/analyze-trace
npx @typescript/analyze-trace trace
```

## Quick Reference

| Option | Purpose |
|--------|---------|
| `strict` | Enable all strict checks |
| `verbatimModuleSyntax` | (5.0) Explicit import type / export type elision |
| `isolatedModules` | Each file can be transpiled separately |
| `erasableSyntaxOnly` | (5.8) Ban non-erasable syntax for Node type-stripping |
| `noUncheckedSideEffectImports` | (5.6) Catch typos in side-effect imports |
| `moduleDetection: "force"` | Treat all files as modules |
| `exactOptionalPropertyTypes` | Distinguish `undefined` from missing |
| `noUncheckedIndexedAccess` | Index access returns `T \| undefined` |
| `composite` | Enable project references |
| `incremental` | Enable incremental compilation |
| `skipLibCheck` | Skip .d.ts checking for faster builds |
| `moduleResolution` | How modules are resolved (`NodeNext` or `bundler`) |
| `paths` | Path mapping for imports |
| `declaration` | Generate .d.ts files |
| `sourceMap` | Generate source maps |
| `noEmit` | Don't emit output (type check only) |
| `allowImportingTsExtensions` | Import .ts files directly (bundler mode) |
| `isolatedDeclarations` | (5.5) Parallel declaration emit without full type resolution |
