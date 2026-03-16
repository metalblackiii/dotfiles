# Ratchet Use Case Recipes

Concrete examples of metric + verify command + scope for common scenarios. Not loaded by the skill automatically — this is a human reference for "what could I ratchet?"

## Test Coverage

**When:** Inheriting a codebase with low coverage, or coverage regression after a refactor.

```
Goal:       Increase test coverage
Direction:  higher is better
Verify:     npm test -- --coverage 2>&1 | grep "All files" | awk '{print "SCORE:", $4}'
Scope:      src/**/*.test.ts, src/**/*.ts (to add missing tests)
Iterations: 15-20 (coverage gains slow down as you climb)
```

Variant for a single module: narrow scope to `src/auth/**` and grep for that directory's coverage line.

## Lint / Type Errors

**When:** Enabling stricter lint rules or `strict: true` in tsconfig and facing a wall of errors.

```
Goal:       Eliminate lint errors
Direction:  lower is better
Verify:     npx eslint . --format json 2>/dev/null | jq 'map(.errorCount) | add // 0' | xargs -I{} echo "SCORE: {}"
Scope:      src/**/*.ts
Iterations: 10-15
```

TypeScript variant:
```
Verify:     npx tsc --noEmit 2>&1 | grep -c "error TS" | xargs -I{} echo "SCORE: {}"
```

## Bundle Size

**When:** Bundle has grown, need to trim before a release.

```
Goal:       Reduce production bundle size
Direction:  lower is better
Verify:     npm run build 2>&1 | grep -oP 'Total size: \K[0-9.]+' | xargs -I{} echo "SCORE: {}"
Scope:      src/**/*.ts, webpack.config.js (or vite.config.ts)
Iterations: 10
```

Adapt the grep to match your bundler's output format.

## Query Performance

**When:** A slow endpoint backed by Sequelize or raw SQL.

```
Goal:       Reduce query execution time
Direction:  lower is better
Verify:     node scripts/bench-endpoint.js 2>&1 | grep "avg_ms" | awk '{print "SCORE:", $2}'
Scope:      src/services/slow-endpoint.ts, src/models/*.ts
Iterations: 10
```

Requires a small benchmark script that hits the endpoint N times and averages. Write this during the interview phase.

## N+1 Query Elimination

**When:** ORM code making too many round-trips.

```
Goal:       Reduce total SQL queries per request
Direction:  lower is better
Verify:     node scripts/count-queries.js 2>&1 | tail -1 | xargs -I{} echo "SCORE: {}"
Scope:      src/services/target-service.ts
Iterations: 5-8 (usually a few eager-loading fixes)
```

## Migration: Reduce Manual Steps

**When:** A migration runbook has too many manual commands.

```
Goal:       Reduce manual steps in migration
Direction:  lower is better
Verify:     grep -cE "^(- \[ \]|[0-9]+\.)" docs/migration-runbook.md | xargs -I{} echo "SCORE: {}"
Scope:      docs/migration-runbook.md, scripts/migrate.sh
Iterations: 8
```

Each iteration automates one manual step into the script and removes it from the runbook.

## Readability: Function Length

**When:** A file has grown unwieldy with long functions.

```
Goal:       Reduce max function length (lines)
Direction:  lower is better
Verify:     ast-grep or a custom script that reports longest function body
Scope:      src/target-file.ts
Iterations: 10
```

Proxy metric — not perfect, but long functions correlate with complexity. Pair with tests-still-pass as a gate.

## API Response Time

**When:** An endpoint is too slow and you want to iterate on optimizations.

```
Goal:       Reduce p95 response time
Direction:  lower is better
Verify:     hey -n 100 -c 10 http://localhost:3000/api/target 2>&1 | grep "95%" | awk '{print "SCORE:", $2}'
Scope:      src/routes/target.ts, src/services/target.ts
Iterations: 10-15
```

Requires `hey` (HTTP load generator) or `ab`. Start the server before the ratchet loop.

## Dependency Count

**When:** Pruning bloated node_modules or reducing attack surface.

```
Goal:       Reduce production dependency count
Direction:  lower is better
Verify:     npm ls --prod --parseable 2>/dev/null | wc -l | xargs -I{} echo "SCORE: {}"
Scope:      package.json
Iterations: 8
```

Each iteration removes or replaces a dependency. Verify command also confirms nothing broke (npm ls exits non-zero on missing deps).
