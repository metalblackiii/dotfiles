---
name: self-documenting-code
description: Use when writing or reviewing code for naming quality, comment hygiene, or readability improvements.
user-invokable: false
---

# Self-Documenting Code

## The Rule

Every comment that explains "what" is a naming failure. Before writing a comment, try renaming first.

```
Comment instinct → Rename instead → Comment only if "why" remains unclear
```

---

## When This Applies

**Invoke this skill when:**
- Writing new functions, classes, or modules
- Editing existing code
- Reviewing AI-generated code (including your own output)
- Tempted to add an explanatory comment

---

## The Naming Hierarchy

Good names eliminate the need for comments. Invest time here first.

### Variables

| Bad | Better | Why |
|-----|--------|-----|
| `data` | `userProfiles` | Says what's inside |
| `result` | `validatedEmail` | Says what it represents |
| `temp` | `swapBuffer` | Says why it exists |
| `val` | `discountPercentage` | Says what it measures |
| `x`, `i` | `rowIndex`, `retryCount` | Says what it tracks |
| `flag` | `isAuthenticated` | Says what state it represents |

### Functions

| Bad | Better | Why |
|-----|--------|-----|
| `handleData()` | `validateUserInput()` | Says what action |
| `processItem()` | `calculateShippingCost()` | Says what calculation |
| `doWork()` | `sendPasswordResetEmail()` | Says what effect |
| `getData()` | `fetchActiveSubscriptions()` | Says what's fetched |
| `check()` | `hasValidLicense()` | Says what's checked |
| `update()` | `markInvoiceAsPaid()` | Says what changes |

### The Test

Read the name aloud. If you need to add "which means..." to explain it, the name failed.

---

## Post-Write Check (Required)

After writing code, scan for these patterns and fix before delivering:

### 1. "What" Comments (Delete and Rename)

```typescript
// BAD: Comment explains what
// Initialize the user counter
let count = 0;

// GOOD: Name explains what
let activeUserCount = 0;
```

```typescript
// BAD: Comment narrates the code
// Loop through users and check if active
for (const u of users) {
  if (u.active) { ... }
}

// GOOD: Names make it obvious
for (const user of users) {
  if (user.isActive) { ... }
}
```

### 2. Redundant Comments (Delete Entirely)

```typescript
// BAD: Comment repeats the code
// Return the result
return result;

// Set name to value
user.name = value;

// Check if null
if (x === null) { ... }

// GOOD: Just the code
return calculatedTotal;
user.displayName = normalizedInput;
if (cachedResponse === null) { ... }
```

### 3. Vague Names (Rename to Intent)

Scan for these and replace:
- `data`, `info`, `item`, `obj` → What data? What info?
- `result`, `response`, `output` → Result of what?
- `temp`, `tmp`, `x`, `val` → Why does it exist?
- `handle*`, `process*`, `do*` → What specific action?
- `manager`, `helper`, `utils` → What responsibility?

---

## Comment Survival Test

A comment earns its place ONLY if it explains something the code cannot:

### Survives: WHY (Business Logic)

```typescript
// Expires 90 days after purchase per legal requirement SOX-2024-103
const warrantyExpiration = addDays(purchaseDate, 90);
```

### Survives: WARNING (Dragons)

```typescript
// CRITICAL: Order matters - auth middleware must run before rate limiter
// because rate limits are per-user, not per-IP
app.use(authMiddleware);
app.use(rateLimiter);
```

### Survives: TODO (With Ticket)

```typescript
// TODO(JIRA-1234): Replace with batch API when available
for (const user of users) {
  await updateUser(user);
}
```

### Dies: Everything Else

If the comment explains WHAT the code does or HOW it works, the code should be rewritten to make that obvious.

---

## Quick Reference

| If you're tempted to write... | Instead... |
|------------------------------|------------|
| `// Initialize X` | Name the variable to show its purpose |
| `// Get the X` | Name the function `fetchX` or `findX` |
| `// Check if X` | Name the function `isX` or `hasX` |
| `// Loop through X` | Use descriptive iteration variable |
| `// Handle the X case` | Extract to named function |
| `// This is for X` | Rename to include X in the name |
| `// Returns X` | Name should already indicate return |

---

## The Inversion

Traditional thinking: "Write code, then document it."

Self-documenting thinking: "Name it so well that documentation is redundant."

Time spent on comments → Time spent on names. The latter pays compound interest.

---

## Anti-Patterns

**Comment-First Thinking**: Writing `// Validate email` then `function validate(s)`. Invert: write `function isValidEmail(input)`, no comment needed.

**Changelog Comments**: `// Added 2024-01-15 by John`. That's what git is for.

**Commented-Out Code**: Delete it. Git remembers.

**Nervous Comments**: `// Just in case` or `// Not sure if needed`. Understand your code or remove the uncertainty.

**Apologetic Comments**: `// Sorry, this is hacky`. Fix it or accept it. Don't apologize in code.
