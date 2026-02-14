---
name: gha
description: Use when investigating GitHub Actions workflow failures, CI/CD pipeline errors, or flaky tests in GitHub Actions.
argument-hint: <url>
allowed-tools: Bash(gh *)
version: "1.0.0"
---

Investigate this GitHub Actions URL: $ARGUMENTS

Use the gh CLI to analyze this workflow run:

1. **Get basic info & identify actual failure**:
   - What workflow/job failed, when, and on which commit?
   - Read the full logs carefully to find what SPECIFICALLY caused the exit code 1
   - Distinguish between warnings/non-fatal errors vs actual failures
   - Look for patterns like "failing:", "fatal:", or script logic that determines when to exit 1

2. **Check flakiness**: Check the past 10-20 runs of THE EXACT SAME failing job:
   - If a workflow has multiple jobs, check history for the SPECIFIC JOB that failed, not just the workflow
   - Use `gh run list --workflow=<workflow-name>` to get run IDs, then `gh run view <run-id> --json jobs` to check the specific job's status
   - Is this a one-time failure or recurring pattern for THIS SPECIFIC JOB?
   - What's the success rate for THIS JOB recently?

3. **Identify breaking commit** (if recurring failures):
   - Find the first run where THIS SPECIFIC JOB failed and the last run where it passed
   - Identify the commit that introduced the failure
   - Verify: does THIS JOB fail in ALL runs after that commit? Pass in ALL runs before?

4. **Root cause**: Based on logs, history, and any breaking commit, what's the likely cause?

5. **Check for existing fix PRs**: Search for open PRs that might already address this:
   - Use `gh pr list --state open --search "<keywords>"` with relevant error messages or file names
   - If a fix PR exists, note it and skip the recommendation

Write a final report with:
- Summary of failure (what specifically triggered exit code 1)
- Flakiness assessment (one-time vs recurring, success rate)
- Breaking commit (if identified and verified)
- Root cause analysis
- Existing fix PR (if found)
- Recommendation (skip if fix PR already exists)
