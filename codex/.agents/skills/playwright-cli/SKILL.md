---
name: playwright-cli
description: ALWAYS invoke for automating browser interactions for web testing, form filling, screenshots, and data extraction via the playwright-cli CLI. Not for writing Playwright test files in neb-www — use neb-playwright-expert for that.
allowed-tools: Bash(playwright-cli:*)
---

# Browser Automation with playwright-cli

## Tool Selection

- **playwright-cli** — headless/scripted browser automation, network mocking, multi-session, CI/Codex-compatible
- **claude-in-chrome MCP** — inspecting a tab the user already has open, real-time visual debugging in Claude Code

## Core Interaction Loop

1. `open` URL → automatic snapshot shows page state
2. Read element refs (`e1`, `e5`, `e15`) from the snapshot
3. Interact using refs: `click e3`, `fill e5 "value"`, `select e9 "option"`
4. Every command returns a new snapshot — verify state changed as expected
5. `close` when done

## Snapshots and Element Refs

After each command, playwright-cli returns a snapshot — a structured YAML representation of the visible page. Each interactive element gets a ref like `e1`, `e5`, `e15`. Use these refs (not CSS selectors) to target elements.

```yaml
# Example snapshot content
- heading "Example Domain" [level=1]
- text "This domain is for use in illustrative examples."
- link "More information..." [ref=e1]
- textbox "Search" [ref=e2]
- button "Submit" [ref=e3]
```

```bash
# Take a snapshot on demand
playwright-cli snapshot
# Save snapshot to a specific file
playwright-cli snapshot --filename=after-login.yaml
```

## Error Recovery

- **Action fails (element not found):** take a fresh `snapshot` — the page likely changed. Find the new ref and retry.
- **Unexpected page state (login wall, error page):** run `snapshot` + `console` to diagnose before retrying.
- **Browser won't open:** check if a stale session exists with `playwright-cli list`, then `kill-all` if needed.
- **Multiple retries failing:** stop and ask the user rather than looping.

## Commands

### Core

```bash
playwright-cli open [url]              # open browser, optionally navigate
playwright-cli goto <url>              # navigate current page
playwright-cli click <ref>             # click element
playwright-cli fill <ref> "value"      # clear + type into input
playwright-cli type "text"             # type without clearing
playwright-cli select <ref> "value"    # select dropdown option
playwright-cli check <ref>             # check checkbox
playwright-cli uncheck <ref>           # uncheck checkbox
playwright-cli hover <ref>             # hover element
playwright-cli dblclick <ref>          # double-click
playwright-cli drag <ref> <ref>        # drag from → to
playwright-cli upload <filepath>       # file upload
playwright-cli eval "expression"       # evaluate JS
playwright-cli eval "fn" <ref>         # evaluate JS against element
playwright-cli dialog-accept ["text"]  # accept browser dialog
playwright-cli dialog-dismiss          # dismiss browser dialog
playwright-cli resize <w> <h>          # resize viewport
playwright-cli snapshot                # take page snapshot
playwright-cli screenshot [ref]       # capture PNG (--filename= to name)
playwright-cli pdf                     # capture PDF (--filename= to name)
playwright-cli close                   # close browser
```

### Navigation & Input

```bash
playwright-cli go-back / go-forward / reload
playwright-cli press <Key>            # Enter, ArrowDown, Tab, etc.
playwright-cli keydown <Key> / keyup <Key>
playwright-cli mousemove <x> <y> / mousedown [button] / mouseup [button]
playwright-cli mousewheel <dx> <dy>
```

### Tabs

```bash
playwright-cli tab-list / tab-new [url] / tab-close [index] / tab-select <index>
```

### Storage

```bash
playwright-cli state-save [file]       # save cookies + localStorage
playwright-cli state-load <file>       # restore saved state
playwright-cli cookie-list [--domain=] / cookie-get <name> / cookie-set <name> <value> [flags]
playwright-cli cookie-delete <name> / cookie-clear
playwright-cli localstorage-list / localstorage-get <key> / localstorage-set <key> <value>
playwright-cli localstorage-delete <key> / localstorage-clear
playwright-cli sessionstorage-list / sessionstorage-get / sessionstorage-set / sessionstorage-delete / sessionstorage-clear
```

### Network & DevTools

```bash
playwright-cli route "<pattern>" --status=<code> [--body='...'] [--content-type=...] [--header=...] [--remove-header=...]
playwright-cli route-list / unroute ["<pattern>"]
playwright-cli console [level]         # read console messages
playwright-cli network                 # inspect network activity
playwright-cli run-code "async page => { ... }"  # arbitrary Playwright code
playwright-cli tracing-start / tracing-stop
playwright-cli video-start / video-stop <file.webm>
```

## Open Parameters

```bash
playwright-cli open [url] --browser=chrome|firefox|webkit|msedge
playwright-cli open [url] --extension   # connect to existing browser
playwright-cli open [url] --persistent  # persist profile to disk
playwright-cli open [url] --profile=/path/to/profile
playwright-cli open [url] --config=config.json
playwright-cli delete-data              # delete session user data
```

## Browser Sessions

```bash
playwright-cli -s=<name> open [url]    # named session (isolated cookies, storage, tabs)
playwright-cli -s=<name> <command>     # run command in named session
playwright-cli -s=<name> close         # close named session
playwright-cli list                    # list active sessions
playwright-cli close-all / kill-all    # stop all sessions
```

## Local Installation Fallback

If the global binary is unavailable, use `npx @playwright/cli` instead.

## Examples

### Form submission

```bash
playwright-cli open https://example.com/form
playwright-cli snapshot
# snapshot shows: e1 [textbox "Email"], e2 [textbox "Password"], e3 [button "Submit"]
playwright-cli fill e1 "user@example.com"
playwright-cli fill e2 "password123"
playwright-cli click e3
playwright-cli snapshot   # verify success state
playwright-cli close
```

### Debugging with DevTools

```bash
playwright-cli open https://example.com
playwright-cli tracing-start
playwright-cli click e4
playwright-cli fill e7 "test"
playwright-cli console          # check for errors
playwright-cli network          # inspect API calls
playwright-cli tracing-stop     # save trace for analysis
playwright-cli close
```

## Specific tasks

* **Request mocking** [references/request-mocking.md](references/request-mocking.md)
* **Running Playwright code** [references/running-code.md](references/running-code.md)
* **Browser session management** [references/session-management.md](references/session-management.md)
* **Storage state (cookies, localStorage)** [references/storage-state.md](references/storage-state.md)
* **Test generation** [references/test-generation.md](references/test-generation.md)
* **Tracing** [references/tracing.md](references/tracing.md)
* **Video recording** [references/video-recording.md](references/video-recording.md)
