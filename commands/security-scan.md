---
description: Audit a whole codebase for security vulnerabilities inline — secrets, injection, authn/authz, SSRF, unsafe crypto, dependency CVEs, license/SBOM compliance, and the OWASP Top 10. Read-only, runs in the main context without spawning an agent.
---

# Security Scan

Invoke the **`security-scan`** skill to run a read-only security audit of the codebase **inline in this context** — no subagent. Use it to security-review an unfamiliar repo, or before exposing a service.

## What This Command Does

1. **Scope** the whole repo (or a directory/diff you name) and locate the high-risk surface: auth, API routes, DB access, uploads, payments, webhooks, deserialization, shell calls.
2. **Read the posture** — existing security config, `.gitignore` coverage, validation/auth conventions, and any security-tradeoff ADRs.
3. **Run read-only tooling** — dependency/CVE audit per ecosystem (`npm audit`, `pip-audit`, `cargo audit`, `govulncheck`, `bundle audit`, `composer audit`), secret scanning (`gitleaks`/`trufflehog`), SAST (`semgrep`/`eslint-plugin-security`/`bandit`), and license/SBOM resolution (`license-checker`/`pip-licenses`/`cargo license`/`go-licenses`/`syft`) when installed. Missing tools are reported as coverage gaps, never faked.
4. **Walk the surface** across ten security dimensions and emit an anchored, severity-ranked report.

## When to Use

- Auditing a codebase you didn't write, before trusting or shipping it.
- A focused security pass deeper than `/code-review`'s Security dimension.
- You want the audit and its follow-up conversation in **one context** rather than delegated to the `security-reviewer` agent.

## Usage

```text
/security-scan                 # whole repo
/security-scan apps/api        # scope to a directory
/security-scan diff main       # only what the current branch changed vs main
```

## Output

A single inline report: risk verdict, findings tiered **Critical / Major / Minor / Nit** each anchored to `file:line`, a dependency-advisories section, and an explicit **coverage gaps** section naming what the scan could not see. Findings are the deliverable — this command never edits code.

## Related

- Skill: `skills/security-scan/SKILL.md`
- Agent alternative: `agents/security-reviewer.md` (same audit, isolated subagent)
- Broader review: `/code-review` · Secure-coding patterns: `skills/security-review/`
