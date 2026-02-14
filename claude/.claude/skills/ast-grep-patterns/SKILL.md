---
name: ast-grep-patterns
description: Use when doing large refactoring across multiple files, searching for structural code patterns (empty catches, unsafe async, silent fallbacks), or migrating APIs across a codebase. Not for simple text searches — use Grep for those.
version: "1.0.0"
---

# ast-grep Patterns

## Decision Tree

```
"Find text/string/name"       → Grep
"Find by code structure"      → ast-grep
"Refactor pattern across repo" → ast-grep
One-off search, <10 files     → Grep
```

When in doubt, start with Grep. Escalate to ast-grep only when Grep produces too many false positives or can't express the structural constraint.

## Running

```bash
ast-grep -p 'PATTERN' path/to/search
ast-grep -p 'PATTERN' --lang js path/to/search
ast-grep -p 'PATTERN' --json path/to/search   # structured output
```

## Patterns for Node.js / Express / Lit

### Empty Catch Blocks
```
ast-grep -p 'try { $$$TRY } catch ($ERR) { }' src/
```

### Async Without Try/Catch
```
ast-grep -p 'async ($$$PARAMS) => { $$$BODY }' --lang js src/
```
Then filter results missing try/catch — ast-grep `not` rules require a config file for complex negation.

### Console.log Left in Code
```
ast-grep -p 'console.log($$$ARGS)' src/
```

### Silent Fallbacks (|| DEFAULT)
```
ast-grep -p '$DATA || $DEFAULT' src/
```
Review each — some are intentional, flag ones hiding missing data.

### Functions With Many Parameters
```
ast-grep -p 'function $NAME($P1, $P2, $P3, $P4, $P5, $$$REST) { $$$BODY }' src/
```

### msRequest Without Error Handling
```
ast-grep -p 'await msRequest($$$ARGS)' src/
```
Cross-reference with surrounding try/catch — bare awaits on cross-service calls are risky.

## Config File (Optional)

For complex rules with negation, create `sgconfig.yml`:

```yaml
ruleDirs:
  - rules/

# rules/empty-catch.yml
id: empty-catch
language: javascript
rule:
  pattern: |
    try { $$$TRY } catch ($ERR) { }
message: "Empty catch block swallows errors silently"
severity: warning
```

Run: `ast-grep scan` in project root.
