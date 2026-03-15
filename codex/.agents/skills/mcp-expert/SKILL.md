---
name: mcp-expert
description: ALWAYS invoke when evaluating, building, debugging, or extending MCP servers or clients. Covers security vetting (install decisions, HIPAA egress, tool description poisoning), building servers/clients with TypeScript or Python SDKs, and protocol compliance. Not for general API design (use api-designer).
---

# MCP Expert

Unified skill for evaluating and building MCP (Model Context Protocol) servers and clients. Two modes: **vetting** (should we install this?) and **development** (let's build one).

---

## Vetting

Security evaluation before installing or trusting any MCP server. MCPs run with your session credentials and process your full context — treat them as production dependencies, not plugins.

### Core Threat Model

Three attacks that are non-theoretical:

- **Tool description poisoning** — malicious instructions embedded in tool metadata that Claude executes; model safety alignment catches <3% of these in benchmarks
- **Supply chain compromise** — malicious npm packages impersonating legitimate MCPs (Sandworm_Mode, Feb 2026: harvested SSH keys, AWS credentials, npm tokens directly from Claude Code configs)
- **Data/command blur** — tools that read external content (docs, issues, DB rows) can receive injected instructions and execute them with your credentials

### Checklist

#### 1. Source & Publisher

- [ ] Publisher is a known organization with meaningful commit history and community presence
- [ ] Package name is exact — check for typosquatting (one-character-off variants)
- [ ] Listed in the official MCP Registry (`registry.modelcontextprotocol.io`) — note: this confirms namespace ownership, not code safety

#### 2. Tool Descriptions (Critical)

- [ ] Read every tool description in the raw source — this is the primary poisoning surface
- [ ] Descriptions contain no instructions, conditionals, or "also do X" clauses — only functional documentation
- [ ] Parameter descriptions are typed field docs, not hidden directives

#### 3. Source Code

- [ ] Review source for: outbound network calls to external URLs, `child_process.exec`, `eval`, obfuscated or minified code, hardcoded external URLs
- [ ] All outbound calls go to documented, expected endpoints — no undocumented exfiltration paths
- [ ] No writes to credential paths (`~/.ssh/`, `~/.aws/`, `.env` files)

> **Hosted MCPs (closed source):** If source is unavailable, mark this section N/A and weight Section 6 (egress policy) and publisher reputation more heavily in the verdict.

#### 4. Dependencies

- [ ] `npm audit` (or `pip audit`, `cargo audit`, etc.) passes with no high or critical findings
- [ ] Versions are pinned (not `^x.y.z` or `@latest`)
- [ ] Dependency tree is shallow and recognizable — no surprise transitive packages

#### 5. Permissions & Scope

- [ ] Credentials are least-privilege — no `admin:*`, `service_role`, or wildcard scopes
- [ ] You can enumerate exactly what the MCP can access given its credentials

#### 6. Data Egress — HIPAA

- [ ] Provider's logging and data retention policy is stated explicitly
- [ ] If any prompt context adjacent to PHI, schema names, table names, or patient data patterns could be present when this MCP is active: require zero-egress (local or self-hosted only)
- [ ] MCP is opt-in per invocation — does not intercept every prompt automatically

### Red Flags — Reject Immediately

- Tool descriptions contain conditional logic, references to "previous messages," or instructions to "also..."
- Source is minified, obfuscated, or the repo is brand new with no history
- Requests `admin:*`, `*`, `service_role`, or equivalent credential scopes
- `npm audit` shows high or critical CVEs with no upstream fix
- Provider cannot state clearly where queries are logged and for how long
- Version constraint is `@latest` or `^x.y.z` — loose pinning is an auto-update attack surface

### Verdict

| Verdict | Criteria | Action |
|---|---|---|
| **Proceed** | All checks pass; egress documented and acceptable | Install, pin exact version, commit to dotfiles |
| **Proceed with mitigations** | Minor gaps, no red flags; manageable egress concerns | Install with scoped credentials + manual update policy |
| **Reject** | Any red flag; unclear egress in HIPAA-adjacent use; unverifiable source | Do not install; consider self-written or local alternative |

### Post-Install Controls

Regardless of verdict:

- Pin exact version — never `@latest`
- Manual update policy — re-run this checklist on every version bump before upgrading
- Re-evaluate if the MCP's scope, credentials, or behavior change

---

## Development

Building, debugging, or extending MCP servers and clients.

### Core Workflow

1. **Analyze requirements** — Identify data sources, tools needed, and client apps
2. **Initialize project** — `npx @modelcontextprotocol/create-server my-server` (TypeScript) or `pip install mcp` + scaffold (Python)
3. **Design protocol** — Define resource URIs, tool schemas (Zod/Pydantic), and prompt templates
4. **Implement** — Register tools and resource handlers; configure transport (stdio for local, Streamable HTTP for remote)
5. **Test** — Run `npx @modelcontextprotocol/inspector` to verify protocol compliance; confirm tools appear, schemas validate, and errors are well-formed JSON-RPC 2.0
6. **Deploy** — Package, add auth/rate-limiting, configure env vars, monitor

### Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Protocol | `references/protocol.md` | Message types, lifecycle, JSON-RPC 2.0 |
| TypeScript SDK | `references/typescript-sdk.md` | Building servers/clients in Node.js |
| Python SDK | `references/python-sdk.md` | Building servers/clients in Python |
| Tools | `references/tools.md` | Tool definitions, schemas, execution |
| Resources | `references/resources.md` | Resource providers, URIs, templates |

### Minimal Working Example

#### TypeScript — Tool with Zod Validation

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const server = new McpServer({ name: "my-server", version: "1.0.0" });

server.tool(
  "get_weather",
  "Fetch current weather for a location",
  {
    location: z.string().min(1).describe("City name or coordinates"),
    units: z.enum(["celsius", "fahrenheit"]).default("celsius"),
  },
  async ({ location, units }) => {
    const data = await fetchWeather(location, units);
    return {
      content: [{ type: "text", text: JSON.stringify(data) }],
    };
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);
```

#### Python — Tool with Pydantic Validation

```python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("my-server")

@mcp.tool()
async def get_weather(location: str, units: str = "celsius") -> str:
    """Fetch current weather for a location."""
    data = await fetch_weather(location, units)
    return str(data)

if __name__ == "__main__":
    mcp.run()
```

### Constraints

#### MUST DO
- Validate all inputs with schemas (Zod/Pydantic)
- Implement JSON-RPC 2.0 protocol correctly
- Use proper transport mechanisms (stdio for local, Streamable HTTP for remote)
- Log protocol messages to stderr (stdout is reserved for stdio transport)
- Add authentication and rate limiting before deploying remotely
- Test protocol compliance with the MCP inspector
- Keep secrets out of source, logs, and tool responses
- In HIPAA-adjacent contexts, apply the same egress controls from the Vetting section

#### MUST NOT DO
- Skip input validation on tool inputs
- Expose sensitive data in resource content or tool responses
- Hardcode credentials or secrets
- Mix synchronous code with async transports
- Return unstructured errors to clients
- Deploy without rate limiting on remote transports
