# Node.js Performance Profiling Tooling Analysis

**Date**: 2026-02-27
**Context**: Evaluating profiling/load-testing tools for neb microservices (Node.js/Express/Sequelize, Aurora/MySQL, Kafka, Docker/Kubernetes)
**Motivation**: [Reddit discussion](https://www.reddit.com/r/ClaudeCode/comments/1rfz2rm/) on LLM-generated code optimizing for correctness over performance. Added review checks to `analyzing-prs` for sequential-await and loop-query patterns; now evaluating tooling for deeper performance visibility.

---

## Tools Evaluated

| Tool | Category | Verdict |
|------|----------|---------|
| **clinic.js** | On-demand profiling | Use tactically (dev/staging only); not actively maintained |
| **autocannon** | HTTP load testing | Adopt — actively maintained, integrates with clinic.js |
| **Grafana Pyroscope** | Continuous profiling | Evaluate for production — fills the biggest gap |

---

## 1. clinic.js

**What it is**: Open-source Node.js profiling suite (NearForm). Four tools: Doctor (triage), Bubbleprof (async flow), Flame (CPU flamegraphs), HeapProfiler (memory).

### Strengths

- **Bubbleprof is unique** — no other tool visualizes async operation flow this way. Excellent for diagnosing Sequelize query chains and Kafka consumer patterns.
- **Doctor as triage** — quickly identifies whether a problem is CPU-bound, I/O-bound, or event-loop-related before you reach for specialized tools.
- **Zero config** — wrap your start command, generate profiling, no code changes.
- **Built-in autocannon integration** — `clinic doctor --on-port 'autocannon localhost:$PORT' -- node server.js` profiles under load seamlessly.
- **Free, no infrastructure required** — runs on developer laptops.
- **HIPAA-safe for local use** — no data sent externally (disable telemetry with `NO_INSIGHT=1`).

### Limitations

- **Not actively maintained** — last release June 2023 (v13.0.0). README warns: "Due to its strong ties to Node.js internals, it may not work or the results you get may not be accurate."
- **Forward compatibility risk** — tight coupling to V8/Node internals means potential breakage with Node.js 22+ LTS.
- **CJS module bug** (Issue #447) — fails silently when generating reports for CommonJS projects due to ESM d3-color import issue.
- **Analysis hangs** (Issue #466) — "Analysing data" step can freeze indefinitely.
- **Not production-safe** — instrumentation overhead too high for production; designed for dev/staging only.
- **Cannot attach to running processes** — must be present from application start.
- **No CI/CD thresholds** — HTML output only, no JSON for programmatic analysis.

### Usage

```bash
# Install
npm install -g clinic

# Triage first
clinic doctor --on-port 'autocannon localhost:$PORT/api/patients' -- node server.js

# Follow Doctor's recommendation:
clinic bubbleprof --on-port 'autocannon localhost:$PORT' -- node server.js  # I/O issues
clinic flame -- node server.js                                               # CPU issues
clinic heapprofiler -- node server.js                                        # Memory issues

# Docker/containers — suppress telemetry prompt
NO_INSIGHT=1 clinic doctor -- node server.js
```

### Recommendation

**Use tactically for dev/staging debugging** — Bubbleprof's async visualization is uniquely valuable for Sequelize/Kafka patterns. Don't depend on it long-term given inactive maintenance. Watch for forks or successors.

### Sources

- [GitHub: clinicjs/node-clinic](https://github.com/clinicjs/node-clinic) (5.9K stars, 105 open issues)
- [clinicjs.org](https://clinicjs.org/)
- [npm: clinic](https://www.npmjs.com/package/clinic) (~48K weekly downloads)
- [CJS bug: Issue #447](https://github.com/clinicjs/node-clinic/issues/447)
- [Analysis hang: Issue #466](https://github.com/clinicjs/node-clinic/issues/466)

---

## 2. autocannon

**What it is**: HTTP/1.1 benchmarking tool by Matteo Collina (Fastify creator). CLI + programmatic Node.js API.

### Strengths

- **Detailed latency percentiles** — p2.5 through p99.999, standard deviation, min/max out of the box.
- **Seamless clinic.js integration** — built-in `--autocannon` flag in clinic.js for profiling under load.
- **Multi-core support** — worker threads (`-w` flag) for high throughput (100K+ req/sec with 4 workers).
- **Programmatic API** — same-runtime integration for test scripts, CI gates, custom threshold checks.
- **HTTP pipelining** — reveals concurrency bottlenecks in Express middleware.
- **Actively maintained** — 8.4K stars, 305K weekly npm downloads, v8.0.0 released 2025.
- **Part of Fastify ecosystem** — official benchmarking tool for Fastify, maintained alongside pino and clinic.js.

### Limitations

- **HTTP/1.1 only** — no WebSocket, HTTP/2, or HTTP/3 support. Use Artillery for WebSocket testing.
- **No complex user flows** — can't chain requests based on prior responses (login → action → verify).
- **No distributed load** — single machine only. No built-in multi-region orchestration.
- **No built-in CI thresholds** — must parse result object programmatically (autocannon-ci wrapper helps but isn't turnkey).
- **CPU-bound** — JavaScript runtime uses more CPU than compiled tools like wrk. Always use `-w` flag.

### Usage

```bash
# Install
npm install -g autocannon

# Basic benchmark
autocannon -c 100 -d 30 http://localhost:3000/api/patients

# With pipelining and workers
autocannon -c 100 -d 40 -p 10 -w 4 http://localhost:3000/api/patients

# POST with auth
autocannon -m POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer token" \
  -b '{"patient_id": "12345"}' \
  http://localhost:3000/api/appointments

# Paired with clinic.js
clinic doctor --autocannon [ /api/patients -c 100 -d 30 ] -- node server.js
clinic flame --autocannon [ /api/patients -c 50 -d 20 ] -- node server.js
```

### CI/CD Threshold Script

```javascript
const autocannon = require('autocannon');

async function benchmark() {
  const result = await new Promise((resolve, reject) => {
    autocannon({
      url: 'http://localhost:3000/api/patients',
      connections: 100,
      duration: 30
    }, (err, result) => err ? reject(err) : resolve(result));
  });

  if (result.latency.p99 > 200) {
    console.error(`FAIL: p99 ${result.latency.p99}ms > 200ms threshold`);
    process.exit(1);
  }
  console.log(`PASS: p99 ${result.latency.p99}ms`);
}

benchmark();
```

### Recommendation

**Adopt** — low friction, excellent for quick developer benchmarks and clinic.js pairing. For complex multi-step API flows or distributed load testing, supplement with k6.

### Sources

- [GitHub: mcollina/autocannon](https://github.com/mcollina/autocannon) (8.4K stars)
- [npm: autocannon](https://www.npmjs.com/package/autocannon) (305K weekly downloads)
- [GitHub: mcollina/autocannon-ci](https://github.com/mcollina/autocannon-ci)
- [NearForm: Load testing with Autocannon](https://nearform.com/insights/load-testing-with-autocannon/)

---

## 3. Grafana Pyroscope (Third Candidate)

**What it is**: Open-source continuous profiling platform. Collects, aggregates, and visualizes performance data from production with low overhead (~0.5-1% CPU). Acquired by Grafana Labs in 2023.

**Why this fills the gap**: clinic.js and autocannon are point-in-time diagnostic tools. Neither provides ongoing production visibility, historical comparisons, or distributed tracing across microservices. Pyroscope is always-on.

### Strengths

- **Production-safe** — 0.5-1% CPU overhead with sampling. No code instrumentation beyond initial setup.
- **Continuous monitoring** — detects performance regressions after deploys by comparing profiles over time.
- **Kubernetes-native** — built-in pod scraping, service discovery, Helm chart deployment.
- **Grafana ecosystem** — correlate profiles with Prometheus metrics, Loki logs, Tempo traces.
- **Cross-service visibility** — tag profiles by service, endpoint, version for distributed system analysis.
- **HIPAA considerations** — profiles contain function names and stack traces, not data values. Self-hosted option for full data control.
- **Active maintenance** — 10.4K GitHub stars, backed by Grafana Labs, Apache 2.0 license.
- **CI/CD integration** — GitHub Actions support, PR comments with performance analysis, performance budgets.

### Limitations

- **Infrastructure required** — need Pyroscope server (self-hosted) or Grafana Cloud subscription.
- **Storage costs** — continuous profiling generates data; needs object storage (S3) for retention.
- **Node.js dynamic tagging** — `tagWrapper()` only works for CPU profiling, not heap/wall.
- **No built-in Sequelize instrumentation** — need manual tagging for query-level profiling.
- **Learning curve** — team needs to learn flamegraph interpretation and continuous profiling concepts.
- **No deep async analysis** — doesn't replace Bubbleprof for async flow visualization.

### Setup

```javascript
import Pyroscope from '@pyroscope/nodejs'

Pyroscope.init({
  serverAddress: 'http://pyroscope-server:4040',
  appName: 'neb-ms-appointments',
  tags: {
    environment: process.env.NODE_ENV,
    region: process.env.AWS_REGION
  }
})

Pyroscope.start()

const app = express()
app.use(Pyroscope.expressMiddleware())
```

```bash
# Kubernetes deployment
helm repo add grafana https://grafana.github.io/helm-charts
helm install pyroscope grafana/pyroscope --namespace observability --create-namespace
```

### Cost

| Option | Monthly (est.) | Ops Burden | HIPAA |
|--------|---------------|------------|-------|
| Self-hosted OSS | $50-200 (infra only) | High | Self-managed |
| Grafana Cloud | Usage-based (free tier available) | Low | Verify BAA support |

### Recommendation

**Evaluate in staging** — deploy to one microservice for 2 weeks, validate overhead and signal quality. If useful, roll out to production gradually. This is the "make it fast" phase tool that closes the loop the Reddit post identified.

### Sources

- [GitHub: grafana/pyroscope](https://github.com/grafana/pyroscope) (10.4K stars)
- [Grafana Pyroscope docs](https://grafana.com/docs/pyroscope/latest/)
- [Node.js SDK](https://grafana.com/docs/pyroscope/latest/configure-client/language-sdks/nodejs/)
- [Deploy on Kubernetes](https://grafana.com/docs/pyroscope/latest/deploy-kubernetes/)
- [Grafana acquires Pyroscope (2023)](https://grafana.com/about/press/2023/03/15/grafana-labs-acquires-pyroscope-the-company-behind-the-popular-open-source-continuous-profiling-project/)

---

## Three-Tool Strategy

```
┌─────────────────────────────────────────────────┐
│  Development & Debugging (dev/staging)          │
│                                                  │
│  clinic.js — deep on-demand profiling            │
│  autocannon — synthetic load generation          │
│  High overhead OK. Manual workflow.              │
└──────────────────────┬──────────────────────────┘
                       │
              Issue identified by ↓ or investigated from ↑
                       │
┌──────────────────────┴──────────────────────────┐
│  Continuous Monitoring (production)              │
│                                                  │
│  Pyroscope — always-on, low-overhead profiling   │
│  Detect regressions. Compare deploys.            │
│  Cross-service visibility.                       │
└─────────────────────────────────────────────────┘
```

**Workflow example** — slow endpoint after deploy:
1. **Pyroscope** alerts: CPU on `/patients/:id` up 40% after v1.2.3
2. **autocannon** reproduces in staging: `autocannon -c 100 -d 30 http://localhost:3000/api/patients/123`
3. **clinic.js** diagnoses: `clinic flame --autocannon [ /api/patients/123 -c 50 ] -- node server.js`
4. **Root cause**: flamegraph shows Sequelize eager-loading N+1
5. **Fix + validate**: autocannon confirms improvement, deploy, Pyroscope confirms production baseline restored

---

## Next Steps

1. **Now**: Install clinic.js + autocannon on developer machines. Run against slowest endpoint in local dev.
2. **Week 2**: Document findings. Create team runbook for clinic.js/autocannon usage.
3. **Month 1**: Deploy Pyroscope to staging (one microservice). Validate overhead and signal.
4. **Month 2**: If Pyroscope proves useful, roll out to production. Set up Grafana dashboards.
5. **Ongoing**: Monitor clinic.js maintenance status. Watch for successors to Bubbleprof.
