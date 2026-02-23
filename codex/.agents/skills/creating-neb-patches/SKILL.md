---
name: creating-neb-patches
description: Use when a user asks to create a patch branch or patch PR for a merged main PR in a neb-ms-* repo or neb-www (often provided as a PR URL or number) for hotfix deployment.
---

# Creating Neb Patch Branches

## Overview

Patch branches enable hotfix deployments without waiting for the next full release. The workflow cherry-picks specific commits from `main` onto a versioned patch branch, then PRs against that patch branch.

## When to Use

- A PR has been merged to `main` and needs to ship as a hotfix
- You need to deploy a specific change outside the normal release cycle
- You need to patch `neb-www` using the same patch-branch workflow used in `neb-ms-*` repos

## When NOT to Use

- Normal feature work (just PR to `main`)
- The change hasn't been merged to `main` yet

## Workflow

### 1. Update main locally

```bash
cd <repo>
git checkout main && git pull
```

### 2. Identify the merge commit on main

```bash
git log --oneline -10
```

Note the merge commit SHA — this is what gets cherry-picked.

### 3. Trigger "Create Patch Branch" workflow

Every `neb-ms-*` production repo and `neb-www` has a GitHub Actions workflow called **"Create Patch Branch"**:

```bash
gh workflow run "Create Patch Branch" --repo Chiropractic-CT-Cloud/<repo-name>
```

Wait for it to complete and find the branch name from the logs:

```bash
gh run list --repo Chiropractic-CT-Cloud/<repo-name> --workflow="Create Patch Branch" --limit 1 --json databaseId,status,conclusion
# Once complete:
gh run view <run-id> --repo Chiropractic-CT-Cloud/<repo-name> --log 2>&1 | grep "PATCH-"
```

The branch name follows the pattern `PATCH-X.Y.Z` (e.g., `PATCH-1.158.X`).

**Important behavior (observed in `neb-ms-partner`):**
- The workflow may **reuse an existing patch branch name** if neb-deploy has not advanced (example: `PATCH-1.99.X`).
- This can look like "it did nothing", but it is still the correct outcome.
- Treat workflow success + reported patch branch as source of truth, even when no new branch is created.

### 3a. Required interpretation rules (to avoid stale branch mistakes)

1. **Always run "Create Patch Branch" first**. Never assume the latest `PATCH-*` branch is safe.
2. If the workflow succeeds and reports `PATCH-X.Y.Z`, use that branch (even if it already existed).
3. If workflow fails, stop and fix the workflow issue before creating a patch PR.

Quick extraction pattern:

```bash
RUN_ID=$(gh run list --repo Chiropractic-CT-Cloud/<repo-name> --workflow="Create Patch Branch" --limit 1 --json databaseId --jq '.[0].databaseId')
PATCH_BRANCH=$(gh run view "$RUN_ID" --repo Chiropractic-CT-Cloud/<repo-name> --log 2>&1 | grep -Eo 'PATCH-[0-9]+\.[0-9]+\.X' | head -n1)
```

If `PATCH_BRANCH` is empty, inspect the full run log manually before proceeding.

### 4. Create your working branch off the patch branch

```bash
git fetch origin
git checkout PATCH-X.Y.Z
git checkout -b <your-branch-name>-PATCH-X.Y.Z
```

Branch naming convention: append the patch branch name to your normal branch name.
Example: `mjb-pho-NEB-95363-dd-trace-v5-PATCH-1.158.X`

### 5. Cherry-pick the merge commit

```bash
git cherry-pick <merge-commit-sha> -m 1
```

The `-m 1` flag is required for merge commits — it tells git to use the first parent (main) as the base.

**If lockfile conflicts occur** (common):

```bash
git checkout --theirs package-lock.json
npm install
git add package-lock.json package.json
git cherry-pick --continue --no-edit
```

Use the correct Node version if the repo requires it (check `engines` in `package.json`).

### 6. Push and create PR targeting the patch branch

```bash
git push -u origin <your-branch-name>-PATCH-X.Y.Z
gh pr create --base PATCH-X.Y.Z --title "<original-title> [PATCH]"
```

**Important:** The `--base` flag must target the `PATCH-X.Y.Z` branch, not `main`. Reviewers follow the standard defaults from project instructions.

## Lockfile Conflict Resolution

Cherry-picks almost always conflict on `package-lock.json`. The resolution is always the same:

1. Accept theirs (`git checkout --theirs package-lock.json`)
2. Regenerate (`npm install`)
3. Stage and continue

## Multiple Commits

If you need to cherry-pick multiple commits, cherry-pick them in order:

```bash
git cherry-pick <sha1> -m 1
git cherry-pick <sha2> -m 1
```

## Red Flags — STOP

- **Never cherry-pick TO main** — patches go from main to patch branch, not the reverse
- **Don't skip the "Create Patch Branch" workflow** — it handles versioning and prevents stale patch branch selection
- **Don't force-push patch branches** — other people may be using them
