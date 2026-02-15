# Red Team Adversarial

Adversarial thinking for finding weaknesses before adversaries do.

## Core Principle

Red teaming asks: **"If someone wanted to break, exploit, or game this, how would they do it?"** This applies beyond security: competitors, disgruntled users, perverse incentives, and regulatory challenges are all adversarial forces.

## Process

1. **Identify the asset** — What are you protecting?
2. **Construct adversary personas** — Who would attack this and why?
3. **Map attack vectors** — How would each persona exploit weaknesses?
4. **Assess impact** — Rank by likelihood x impact
5. **Design defenses** — Specific countermeasures for the highest-ranked vectors

## Adversary Personas

Generic "attackers" produce generic findings. Specific personas produce actionable insights.

| Persona | Motivation | Typical Vectors |
|---------|-----------|----------------|
| **External Attacker** | Financial gain, data theft | API exploitation, credential stuffing, injection |
| **Competitor** | Market advantage | Feature copying, talent poaching, FUD campaigns |
| **Disgruntled Insider** | Revenge, financial gain | Privilege escalation, data exfiltration, sabotage |
| **Careless User** | None (accidental) | Misconfiguration, weak passwords, sharing credentials |
| **Regulator** | Compliance enforcement | Audit findings, data handling violations |
| **Opportunistic Gamer** | Personal benefit | Exploiting loopholes in business logic |

## Attack Vectors by Category

| Category | Vectors | Example |
|----------|---------|---------|
| **Technical** | Injection, auth bypass, race conditions | SQL injection in search parameter |
| **Business Logic** | Workflow bypass, state manipulation | Applying expired entitlement via API replay |
| **Social** | Phishing, pretexting, authority exploitation | "I'm the admin, I need access now" |
| **Operational** | Supply chain, dependency poisoning | Compromised npm package in build pipeline |
| **Information** | Data leakage, metadata exposure | User enumeration via login error messages |
| **Economic** | Resource exhaustion, denial of wallet | Lambda invocation flood causing cost spike |

## Perverse Incentive Detection

| Question | What It Reveals |
|----------|----------------|
| "How will people game this?" | Loopholes in business logic |
| "What behavior does this reward that we don't want?" | Misaligned incentives |
| "What's the cheapest way to get the reward without the effort?" | Shortcut exploitation |
| "If we measure X, what Y gets sacrificed?" | Goodhart's Law in action |

## Output Template

```markdown
## Red Team Analysis: [Target]

### Asset Under Assessment
[What we're protecting and why it matters]

### Adversary Profiles
#### Adversary 1: [Name/Role]
- **Motivation:** [Why] | **Capability:** [What they can do] | **Access:** [Starting point]

### Attack Vectors (Ranked)
| # | Vector | Adversary | Likelihood | Impact | Risk |
|---|--------|-----------|-----------|--------|------|

### Perverse Incentives
| Incentive Created | Unintended Behavior | Severity |
|-------------------|-------------------|----------|

### Recommended Defenses
| Attack Vector | Defense | Effort | Priority |
|--------------|---------|--------|----------|
```
