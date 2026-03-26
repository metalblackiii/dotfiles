---
command: login-support-app
description: Log into the neb-www support app in Chrome
argument-hint: "[local|dev|staging]"
---

# Login Support App

Log into the neb-www support application using Chrome browser tools.

## Prerequisites

Environment variables must be set in the user's shell:

- `SUPPORT_APP_PRACTICE_EMAIL` — login email
- `SUPPORT_APP_PRACTICE_PASSWORD` — login password

If either is missing, stop and tell the user to set them.

## Environment URLs

| Argument | URL |
|----------|-----|
| *(none)* | `http://localhost:8082/support` |
| `local` | `http://localhost:8082/support` |
| `dev` | `https://dev.nebula.care/support` |
| `staging` | `https://staging.nebula.care/support` |

The command accepts an optional argument (e.g., `/login-support-app staging`). Default is local.

## Steps

1. **Read credentials** from environment variables using Bash: `echo $SUPPORT_APP_PRACTICE_EMAIL` and `echo $SUPPORT_APP_PRACTICE_PASSWORD`. If either is empty, stop and tell the user.

2. **Load chrome tools** — use ToolSearch to load: `tabs_context_mcp`, `tabs_create_mcp`, `navigate`, `javascript_tool`, `read_page`.

3. **Get tab context** — call `tabs_context_mcp` to see current browser state.

4. **Create a tab** — create a new tab with `tabs_create_mcp`.

5. **Navigate** to the support app URL (based on the argument, default `http://localhost:8082/support`).

6. **Wait for login form** — use `javascript_tool` to poll for `neb-login-page`:
   ```js
   new Promise((resolve, reject) => {
     let attempts = 0;
     const check = () => {
       const el = document.querySelector('neb-login-page');
       if (el) return resolve('ready');
       if (++attempts > 20) return reject('login page not found after 10s');
       setTimeout(check, 500);
     };
     check();
   })
   ```

7. **Fill credentials and submit** — use `javascript_tool` to set Lit component properties and invoke its internal login handler. `form_input` does NOT work because the Lit component ignores DOM-level value changes. Call `__handlers.login()` (not `onLogin()` directly — `onLogin` is a parent-supplied callback that expects `(email, password)` arguments; the handler wraps it).
   ```js
   const loginPage = document.querySelector('neb-login-page');
   loginPage.__email = '<email>';
   loginPage.__password = '<password>';
   loginPage.__handlers.login();
   'submitted'
   ```

8. **Verify login** — wait 3s, then use `read_page` with `filter: "interactive"` to check whether the page transitioned away from the login form. If you still see email/password inputs, check `document.querySelector('neb-login-page').__error` for an error message and report it. If you see navigation links or a search bar, login succeeded.
