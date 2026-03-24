# Agent Teams Messaging Internals

Reference for how Claude Code agent teams communicate under the hood. Useful for debugging stuck teams or understanding delivery timing.

## Message delivery

- **Lead** reads only stdin (stream-json). To message the lead, use `relayLeadInboxMessages()` which converts inbox entries to stdin. The lead does NOT monitor inbox files directly.
- **Teammates** are independent CLI processes. Each monitors its own inbox file (`~/.claude/teams/{team}/inboxes/{member}.json`) via `fs.watch` and reads messages directly. No relay through the lead needed.
- **`from: "user"` works** for direct-messaging teammates — the teammate correctly identifies the sender and responds to `inboxes/user.json`.

## Do not relay through the lead

Relaying user→teammate messages through the lead causes three bugs:
1. Lead responds instead of the target teammate (LLM interprets relay as a question to itself)
2. Duplicate messages from `markInboxMessagesRead()` triggering FileWatcher loops
3. Teammate suppresses user-facing responses due to relay prompt instructions

Direct inbox writes are the correct approach for user→teammate communication.

## Delivery timing

- Messages are delivered **between turns only** — you cannot interrupt a mid-turn tool execution
- Idle agents receive messages within fractions of a second (inbox-change triggers wakeup)
- Active agents receive messages after their current turn completes (1-30 seconds)

## Inbox message format

```json
{
  "from": "user",
  "text": "message content",
  "timestamp": "2026-03-23T15:30:00.000Z",
  "read": false,
  "summary": "short summary for context window",
  "messageId": "uuid"
}
```

## Inbox file paths

```
~/.claude/teams/{team}/inboxes/{member}.json   — per-teammate inbox
~/.claude/teams/{team}/inboxes/user.json       — teammate responses to user
```

## Source

Derived from research in [777genius/claude_agent_teams_ui](https://github.com/777genius/claude_agent_teams_ui) (`docs/team-management/research-messaging.md`), empirically confirmed March 2026.
