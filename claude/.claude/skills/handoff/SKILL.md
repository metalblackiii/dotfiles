---
name: handoff
description: Use when ending a session with work in progress, or when context usage is high and a fresh start would help.
version: "1.0.0"
---

Write or update a handoff document so the next agent with fresh context can continue this work.

Steps:
1. Check if HANDOFF.md already exists in the project root
2. If it exists, read it first to understand prior context before updating
3. Create or update the document with:
   - **Goal**: What we're trying to accomplish
   - **Current Progress**: What's been done so far
   - **What Worked**: Approaches that succeeded
   - **What Didn't Work**: Approaches that failed (so they're not repeated)
   - **Next Steps**: Clear action items for continuing
4. Save as HANDOFF.md in the project root
5. Tell the user to start a fresh conversation with just the HANDOFF.md path
