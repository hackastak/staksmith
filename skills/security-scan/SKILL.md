---
name: security-scan
description: "Audit a whole codebase for security vulnerabilities inline, without delegating to an agent — secrets, injection, authn/authz, SSRF, unsafe crypto, dependency CVEs, license/SBOM compliance, and the OWASP Top 10. Read-only. Use to security-review an unfamiliar repo, or when the user says 'security scan', 'audit this for security', 'check licenses', or invokes '/security-scan'."
category: "Code Review & Quality"
origin: Hackastak
---

Run a **security audit of the codebase as it stands** — the whole repo by default, not a diff — and do it **inline in this context**, without spawning the `security-reviewer` agent. This is the security-focused sibling of `code-review`: same severity ladder, same anchored-report format, but every dimension is a security dimension and the default unit is the entire repository, so it works on code you've never seen.

This is **read-only inspection**: never modify files, never commit, never push, never post anywhere. Read, run read-only tooling, and report.

**Which review skill is this?**

| Skill | Unit | Runs as | When |
|---|---|---|---|
| `review-changes` | working-tree / staged diff vs `HEAD` | inline | tight in-dev loop |
| `code-review` | all code on the current branch | inline | before push / PR — all six dimensions |
| `review-github-pr` | an existing GitHub PR | inline | reviewing a PR |
| `security-reviewer` (agent) | whatever you point it at | subagent | delegated, isolates context |
| **`security-scan`** | **the whole repo (or a scope you name)** | **inline** | **security-auditing a codebase without a subagent** |

Reach for `security-scan` when you want a deep single-axis security pass but want it **in the main context** — so the findings, the code, and the follow-up conversation stay in one place. Reach for the `security-reviewer` agent instead when you want the scan to run in isolation and hand back only a report.

## 1. Scope

By default the unit is **the entire repository**. Establish the surface before reading:

- `git ls-files | wc -l` and a top-level `ls` — the size and shape of the tree.
- Identify languages and package ecosystems from manifest files (`package.json`, `pyproject.toml`/`requirements*.txt`, `Cargo.toml`, `go.mod`, `Gemfile`, `composer.json`, `pom.xml`, `*.csproj`).
- Locate the high-risk surface first, since that's where you'll spend your attention: auth, API/route handlers, DB access, file uploads, payments, webhooks, deserialization, subprocess/shell calls, template rendering, and anywhere `.env`/secrets are read.

If the user named a narrower scope (a directory, a service, "just the API"), honour it and say so at the top of the report. `security-scan` can also run over a diff — if the user asks to scan only what a branch changed, use `git diff --name-only <base>...HEAD` as the file list, but keep reading each file's neighbours since a vulnerability's fix often lives outside the diff.

Only read-only git here: `git ls-files`, `git log`, `git diff`, `git show`, `git status`. Never anything that mutates the tree, index, or refs.

## 2. Find the project's security posture

Before flagging anything, learn what the repo already does about security so you don't report a control that exists:

- `.gitignore` — is `.env`/`.env.local` ignored? Are key material and credential files excluded?
- Existing config: `.eslintrc*` with `eslint-plugin-security`, `bandit`/`ruff` security rules, `.semgrep.yml`, `.gitleaks.toml`, `.pre-commit-config.yaml`, Dependabot/Renovate config, CI security jobs.
- Auth/validation conventions already in use (a validation library like `zod`/`pydantic`, an auth middleware, a secrets manager). A finding that contradicts an established, working control is either wrong or a real regression — decide which.
- `docs/adr/` — an accepted ADR about a security tradeoff (e.g. "we accept X because Y") is not a finding to re-litigate; note it and move on.

## 3. Run the read-only tooling

Run what's installed; **skip cleanly and say so** when a tool is absent — never invent output. All of these are read-only.

**Dependency / CVE audit** — pick by ecosystem detected in step 1:

| Ecosystem | Command |
|---|---|
| npm/pnpm/yarn | `npm audit --audit-level=high` (or `pnpm audit` / `yarn npm audit`) |
| Python | `pip-audit` (fallback `safety check`) |
| Rust | `cargo audit` |
| Go | `govulncheck ./...` |
| Ruby | `bundle audit check --update` |
| PHP | `composer audit` |
| .NET | `dotnet list package --vulnerable` |

**Secret scanning** — `gitleaks detect --no-git` or `trufflehog filesystem .` if available. If neither is installed, fall back to grepping for high-signal patterns: `grep -rnE '(api[_-]?key|secret|token|password|BEGIN [A-Z ]*PRIVATE KEY|AKIA[0-9A-Z]{16})' --include='*.{js,ts,py,go,rb,env,yml,yaml,json}'` and scan committed `.env*` files. Note that a shallow scan can't see secrets in git history — say so.

**SAST** (if present): `semgrep --config auto`, `eslint --plugin security`, `bandit -r .`. Report only findings you can confirm by reading the cited line — treat tool output as leads, not verdicts.

**License / SBOM** — resolve the dependency tree's licenses and, when asked, emit an SBOM. Pick by ecosystem: `license-checker`/`license-checker-rseidelsohn` or `npm sbom` (npm), `pip-licenses` (Python), `cargo license`/`cargo-deny check licenses` (Rust), `go-licenses report ./...` (Go), `licensee`/`bundle exec license_finder` (Ruby), `composer licenses` (PHP). For a portable SBOM across any stack, `syrft`/`syft . -o cyclonedx-json` (or `cdxgen`) — CycloneDX or SPDX. If none is installed, fall back to reading the declared license fields in the manifest/lockfile and the `LICENSE` files of vendored deps, and say the resolution was manual and partial. The project's own intended license is the baseline: find it in `LICENSE`/`package.json`/`Cargo.toml` first, since compatibility is judged against it.

State clearly at the top of the report which tools ran and which were unavailable. "No secret scanner installed" is a coverage gap the user must know about, not a clean result.

## 4. Walk the security surface

Read the high-risk files in full and walk these dimensions. Surface findings tagged **Critical / Major / Minor / Nit**, each with a concrete `file:line`. **Never invent a path or line number** — verify with `grep -n '<symbol>' <path>` before citing; if you can't pin the line, cite the nearest symbol.

1. **Secrets & credentials** — hardcoded keys/tokens/passwords, secrets committed in `.env`/config/fixtures, secrets logged or echoed, credentials in URLs, private keys in the tree.
2. **Injection** — SQL/NoSQL built by string concatenation, command injection via shell with user input (`exec`/`system`/`child_process`), template injection, LDAP/XPath injection, `eval`/`Function`/`pickle`/`yaml.load` on untrusted data.
3. **AuthN / AuthZ** — routes with no auth check, missing object-level authorization (IDOR), weak/absent password hashing (must be bcrypt/argon2/scrypt), JWT not verified or `alg:none` accepted, session fixation, privilege escalation paths.
4. **Input validation & trust boundaries** — unvalidated input crossing into queries, filesystem, subprocess, or responses; missing schema validation on request bodies; mass-assignment; file uploads without type/size/extension limits.
5. **SSRF & path traversal** — `fetch`/`request` on a user-supplied URL without an allowlist, file reads/writes built from user input (`../`), unsafe redirect targets, XXE in XML parsers.
6. **Cryptography** — weak or homegrown crypto, MD5/SHA1 for passwords, ECB mode, static/predictable IVs, hardcoded salts, insecure randomness (`Math.random` for tokens), disabled TLS verification.
7. **Sensitive-data handling** — PII/secret in logs or error responses, stack traces leaked to clients, verbose error messages, unencrypted sensitive data at rest, missing HTTPS enforcement.
8. **Configuration & headers** — debug mode on in prod, default credentials, permissive CORS (`*` with credentials), missing security headers (CSP, HSTS, X-Content-Type-Options), open cloud storage/DB, `.env` served statically.
9. **Dependencies & supply chain** — the CVEs from step 3, plus unpinned or abandoned dependencies, install scripts, and typosquat-shaped names. Rank by exploitability in *this* codebase, not raw CVSS.
10. **Rate limiting & abuse** — no rate limiting on auth/expensive endpoints, no lockout on repeated failures, unbounded resource use, missing idempotency on payment paths, race conditions on balance/inventory (needs `FOR UPDATE`/locking).
11. **License & SBOM compliance** — dependency licenses incompatible with the project's own license (copyleft — GPL/AGPL/LGPL — or `SSPL`/`BUSL`/`CC-BY-NC` pulled into code intended to ship closed-source or under a permissive license), missing or `UNKNOWN`/unlicensed dependencies, a license that changed on a version bump, and — when the user asks for one — a generated SBOM (CycloneDX/SPDX). Judge every dependency license against the project's declared license from step 3; a copyleft transitive dep in a proprietary product is a real finding, not a nit. This is a legal/distribution risk dimension, so severity tracks *ship risk*: an AGPL dep in a closed-source product is Critical, an unknown license on a build-only dev tool is Minor.

If a dimension has nothing material, say so — silence is not a clean bill of health.

## 5. Output

Emit a single inline markdown report. Do not save it to a file, and do not post it anywhere.

```
# Security scan: <repo or scope>

**Scope:** <n files / dir / "whole repo"> · **Tooling:** <tools that ran; note any unavailable>

## Summary
**Risk verdict:** Ship-blocking issues | Fix before exposure | Low risk — monitor

<One short paragraph, 1–3 sentences: the single most important security fact about
this codebase and the why behind the verdict. Not a recap of the findings below.>

## Findings

### Critical

#### `path/file.ts:42`

<Self-contained finding: the vulnerability, how it's exploited, the concrete fix.
One paragraph, 2–4 sentences.>

### Major

#### `path/auth.py:12`

<...>

### Minor

#### `path/config.js:8`

<...>

### Nits

#### `path/util.go:56`

<...>

## Dependency advisories
- <CVE / advisory id — package@version — severity — is it reachable in this code?
  Omit the section if the audit was clean or no auditor was available (say which).>

## License & SBOM
- <Incompatible / unknown / changed licenses — package@version — the license, why it
  conflicts with the project's <declared license>, and the ship risk. Note if an SBOM
  was generated (format + where). Omit the section if the project has no third-party
  deps or license resolution wasn't possible (say which in Coverage gaps).>

## Coverage gaps
- <What this scan could NOT see: no secret scanner installed, git history not scanned,
  a service excluded from scope, a tool that failed. Silent truncation reads as
  "all clear" when it isn't.>

## What looks good
- <1–3 genuine security strengths — a solid auth layer, parameterized queries
  throughout, secrets properly externalized. Not filler.>
```

**Formatting rules, non-negotiable:**

- Each finding is its own `####` subsection, **never** a bullet-list item — bullet findings collapse together in a terminal. Blank line after every `####` header and after every body.
- The `####` header is the backtick-wrapped `file:line`. The body is prose written to the author — no `**Comment:**` prefix, no separate Issue/Why/Fix labels. Include the exploit and the fix inside the paragraph.
- **Hard length budget: one paragraph, 2–4 sentences per finding, Critical included.** Severity buys attention, not words. If a finding won't compress, it's really two findings — split it.
- Multiple locations for one logical finding combine in the header: `#### \`path/file.ts:271, :280\``.
- Some findings have no single location — a missing security header across the app, an absent rate-limiting layer, secrets that need rotating. Give them the same tiers and budget with a header naming the subject (`#### App-level: no rate limiting on auth endpoints`). But **if it can be anchored, anchor it** to the worst example with a count. **Never invent a plausible `file:line`** to satisfy the template — an anchorless header is always correct, a fabricated citation is always fatal.
- Omit any empty section rather than printing "(none)".

## Guardrails

- **Never** run a command that mutates the working tree, index, or refs, or that reaches the network to *change* state. Read-only audit tooling and read-only git only. `npm audit`, `pip-audit`, `gitleaks detect`, `semgrep`, `govulncheck`, and the license/SBOM readers (`license-checker`, `pip-licenses`, `cargo license`, `go-licenses`, `syft`) are fine; `npm audit fix`, `cargo update`, installs, and `git` write commands are not. Note that some license tools resolve dependencies — prefer ones that read the existing lockfile over ones that would fetch or modify it.
- **Never** invent file paths, line numbers, CVE ids, or tool output. Verify every citation. If a tool isn't installed, report it as a coverage gap — do not fabricate its result.
- **Findings are the deliverable; fixes are not.** Don't edit code as part of this skill — hand the report back and let the user decide what to remediate. (`simplify` applies quality fixes; remediation of a security finding is a deliberate, separately-reviewed change.)
- A repo too large to audit thoroughly gets a note at the top and a highest-risk-first pass over the surface from step 1. **Name what you skipped** so the user can ask for a follow-up.
- Rank by exploitability in *this* codebase, not by raw severity labels. A CRITICAL CVE in an unreachable dev dependency outranks nothing; a Major auth gap on a public endpoint outranks it.

## Related skills

- **`code-review`** — the broad six-dimension branch review; its Security dimension is a lighter pass than this one.
- **`security-review`** — the checklist and secure-coding patterns to consult while *writing* the fix a finding calls for.
- **`security-reviewer`** (agent) — the same audit delegated to an isolated subagent when you don't want it inline.
- **`database-reviewer`** — deeper pass when the findings are query- or schema-shaped.
- **`adr-standard`** — what to do when a finding collides with an accepted security-tradeoff ADR.
