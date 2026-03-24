# ESM Migration: CJS → Native ESM

## Babel Removal (the common neb pattern)

Most legacy Node.js projects write ESM source but compile to CJS via Babel. The migration removes Babel and runs native ESM.

### Step-by-step

```bash
# 1. Add "type": "module" to package.json
# This tells Node to treat .js files as ESM

# 2. Remove Babel dependencies
npm uninstall @babel/core @babel/cli @babel/preset-env @babel/register babel-plugin-istanbul

# 3. Remove Babel config
rm .babelrc babel.config.js babel.config.json

# 4. Update npm scripts
# Before: "start": "node -r @babel/register src/index.js"
# After:  "start": "node src/index.js"

# Before: "build": "babel src -d dist"
# After:  remove (tsc replaces this later) or keep as simple copy

# 5. Update test runner
# Before: "test": "nyc mocha -r @babel/register"
# After:  "test": "c8 mocha --experimental-vm-modules"
# (c8 replaces nyc — native V8 coverage, no Babel plugin needed)
```

### What breaks and how to fix it

#### `__dirname` and `__filename`

```javascript
// BAD — not available in ESM
const dir = __dirname;
const file = __filename;

// GOOD — Node 21.2+ / 20.11+
const dir = import.meta.dirname;
const file = import.meta.filename;

// GOOD — older Node versions
import { fileURLToPath } from "node:url";
import { dirname } from "node:path";
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
```

#### `require()` calls

```javascript
// BAD — require() not available in ESM
const pkg = require("./package.json");
const dotenv = require("dotenv");

// GOOD — static import
import dotenv from "dotenv";

// GOOD — JSON import (Node 22+)
import pkg from "./package.json" with { type: "json" };

// GOOD — dynamic import (for conditional loading)
const mod = await import("./optional-module.js");

// GOOD — createRequire (escape hatch for CJS-only packages)
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const cjsOnlyPkg = require("cjs-only-package");
```

#### `require('dotenv').config()`

```javascript
// BAD — CJS pattern
require("dotenv").config();

// GOOD — side-effect import (loads .env on import)
import "dotenv/config";

// GOOD — explicit config
import dotenv from "dotenv";
dotenv.config({ path: ".env.local" });
```

#### `module.exports` / `exports`

```javascript
// BAD — CJS exports
module.exports = { foo, bar };
module.exports.default = main;

// GOOD — ESM named exports
export { foo, bar };
export default main;
```

#### Dynamic `require-all` (filesystem module loading)

```javascript
// BAD — require-all loads all files in a directory
const consumers = require("require-all")({
  dirname: join(__dirname, "consumers"),
  filter: /(.+)\.js$/,
});

// GOOD — explicit imports (preferred for small sets)
import { orderConsumer } from "./consumers/order.js";
import { paymentConsumer } from "./consumers/payment.js";

// GOOD — dynamic glob (for large sets)
import { readdir } from "node:fs/promises";
import { join } from "node:path";

async function loadModules(dir) {
  const files = await readdir(dir);
  const modules = {};
  for (const file of files) {
    if (file.endsWith(".js")) {
      const name = file.replace(".js", "");
      modules[name] = await import(join(dir, file));
    }
  }
  return modules;
}
```

**Important:** Dynamic `import()` is async. If the existing code depends on synchronous module loading at startup, the initialization pattern must change to use top-level `await` or an async init function.

#### Dynamic `require(variable)` (migration runner pattern)

```javascript
// BAD — variable require in migration runner
const migration = require(migrationPath);

// GOOD — dynamic import
const migration = await import(migrationPath);

// Note: if using umzug, upgrade to umzug v3+ which supports ESM natively
```

## CJS → ESM Gotchas

### Default exports from CJS packages

```javascript
// CJS package: module.exports = function() {}

// BAD — may not work depending on the package
import fn from "cjs-package";

// If it doesn't work, the package may need:
import pkg from "cjs-package";
const fn = pkg.default || pkg;

// Or use createRequire as escape hatch
```

### `.js` extensions become required

```javascript
// BAD — works in CJS, breaks in ESM
import { foo } from "./utils";

// GOOD — explicit extension
import { foo } from "./utils.js";
```

### `"type": "module"` affects ALL .js files

Once `"type": "module"` is in `package.json`, every `.js` file in that package is ESM. Files that must remain CJS need the `.cjs` extension.

```
package.json          ← "type": "module"
src/index.js          ← ESM (import/export)
config/database.cjs   ← renamed from .js to .cjs (still CJS)
```

### Top-level await

ESM supports top-level `await`. Use it for async initialization:

```javascript
// server.js — ESM
const db = await connectToDatabase();
const server = createServer(db);
server.listen(3000);
```

## Test Runner Migration

### Mocha

```bash
# Before (Babel)
mocha -r @babel/register "test/**/*.test.js"

# After (native ESM)
mocha --experimental-vm-modules "test/**/*.test.js"
# Or with Node 22+, --experimental-vm-modules may not be needed
```

### Coverage: nyc → c8

nyc depends on Istanbul instrumentation (often via Babel plugin). c8 uses V8's native coverage — no instrumentation needed.

```bash
npm uninstall nyc @istanbuljs/nyc-config-babel babel-plugin-istanbul
npm install -D c8

# Before
nyc mocha -r @babel/register "test/**/*.test.js"

# After
c8 mocha "test/**/*.test.js"
```

```json
// package.json
{
  "scripts": {
    "test": "c8 mocha 'test/**/*.test.js'",
    "coverage": "c8 report --reporter=text --reporter=lcov"
  }
}
```

## Migration Order for Multi-Package Projects

1. **Shared libraries first** (they're consumed by everything else)
2. **Leaf services** (no downstream consumers)
3. **Core services** (depended on by others)
4. **Frontend** (usually has its own build pipeline)

Each package migrates independently. Don't try to do them all at once.
