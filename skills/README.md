# Staksmith Skills

This directory is the catalog of every staksmith skill — reusable workflow definitions and codified domain knowledge that Claude Code (and compatible harnesses) load on demand.

A skill is a folder with a `SKILL.md` inside. The frontmatter `description` is what a model reads when deciding whether to load the skill; the body is the instructions it follows once loaded.

- **Authoring guidance:** [`DESIGN_NOTES.md`](DESIGN_NOTES.md)
- **Skill format and contribution rules:** [`../CONTRIBUTING.md`](../CONTRIBUTING.md)
- **Repo overview:** [`../README.md`](../README.md)

---

## Using a skill

Skills are discovered by name and description — you rarely need to invoke one explicitly:

```
User: "Review the changes on this branch"
Claude: [loads review-changes]

User: "Grill me on adding OAuth to the app"
Claude: [loads grill-me]
```

You can also name one directly with `/skill-name`, or `/staksmith:skill-name` when installed as a plugin.

---

## Anatomy of a skill

The only required file is `SKILL.md` with YAML frontmatter:

```markdown
---
name: review-changes
description: Review only the changes in the working tree — the staged and unstaged
  diff against HEAD. Read-only, with attribution so inherited debt doesn't block
  your own work.
origin: staksmith
---

# Review Changes

## When to use
...
```

Most skills are prompt-only. A minority ship supporting files:

| Optional file | Used by | Purpose |
|---------------|---------|---------|
| `scripts/` | 14 skills | Deterministic shell/Node steps the model shells out to (scan → analyze → execute) |
| `config.json` | 9 skills | Tunable paths, thresholds, and dry-run flags so behavior changes without editing prose |

Skills with a `scripts/` phase pipeline cache intermediate results under `~/.claude/homunculus/{skill-name}/`, which makes long runs resumable and inspectable.

> **Vault-dependent skills:** the knowledge-base, writing, and business skills below assume an Obsidian vault and local repo roots. Point them at your own paths (in `config.json` where present, or in the skill body) before first use.

---

## Catalog

### Build & ship

| Skill | What it does |
|-------|--------------|
| `implement` | Implement work described by a spec, tickets, an issue, or the conversation |
| `prototype` | Throwaway prototype to answer a design question |
| `tdd-workflow` | Seams-first TDD with boundary-only mocking and 80%+ coverage |
| `diagnosing-bugs` | Diagnosis loop for hard bugs and performance regressions |
| `resolving-merge-conflicts` | Resolve an in-progress merge/rebase by reading the intent behind each side |
| `draft-commit` | Stage relevant changes and draft a one-line conventional commit |
| `e2e-testing` | Playwright patterns, Page Object Model, CI integration, flaky-test strategy |
| `ai-regression-testing` | Regression strategies for AI-assisted development, sandbox-mode API tests |
| `verification-loop` | Comprehensive verification pass over a session's work |
| `search-first` | Research existing tools and libraries before writing custom code |
| `git-guardrails` | Hook that blocks dangerous git commands before they execute |
| `setup-pre-commit` | Husky + lint-staged pre-commit hooks with type checks and tests |

### Review & security

| Skill | What it does |
|-------|--------------|
| `code-review` | Review the whole branch architecturally, read-only |
| `review-changes` | Review only the working-tree diff, with debt attribution |
| `review-github-pr` | Review a GitHub PR by number across six dimensions |
| `security-review` | Checklist for auth, user input, secrets, endpoints, payments |
| `security-scan` | Audit your `.claude/` config for injection risks via AgentShield |

### Design, decisions & planning

| Skill | What it does |
|-------|--------------|
| `grill-me` | Relentless one-question-at-a-time interview until a plan holds up |
| `batch-grill-me` | Same interview, but every frontier question at once, round by round |
| `grill-with-docs` | Grilling that leaves a paper trail — glossary and ADRs as decisions land |
| `challenge` | Pressure-test a belief by hunting contradictions and hidden assumptions |
| `blueprint` | Turn a one-line objective into a multi-session construction plan |
| `wayfinder` | Map work too big for one session as decision tickets, resolved one at a time |
| `to-spec` | Turn the conversation into a PRD and publish it to the issue tracker |
| `to-tickets` | Break a plan into tracer-bullet tickets with declared blocking edges |
| `to-questionnaire` | Turn a decision you can't answer alone into a questionnaire for someone else |
| `triage` | Move issues and external PRs through a triage state machine |
| `adr-standard` | The house ADR format — mandatory sections, supersede-don't-edit |
| `domain-modeling` | Pin down ubiquitous language and record architectural decisions |
| `codebase-design` | Vocabulary for designing deep modules |
| `improve-codebase-architecture` | Scan for deepening opportunities, report them, then grill the one you pick |
| `setup-ts-deep-modules` | Wire dependency-cruiser so each TS package is a deep module |
| `design-workflow` | Grill the user's recurring loops and turn each into a workflow spec |

### Languages & frameworks

| Skill | What it does |
|-------|--------------|
| `coding-standards` | Universal standards for TypeScript, JavaScript, React, Node |
| `api-design` | REST resource naming, status codes, pagination, versioning, rate limits |
| `backend-patterns` | Backend architecture, API design, DB optimization for Node/Express/Next |
| `frontend-patterns` | React/Next state management, performance, UI practices |
| `nextjs-turbopack` | Next.js 16+ and Turbopack — when to use it over webpack |
| `bun-runtime` | Bun as runtime, package manager, bundler, test runner |
| `python-patterns` / `python-testing` | Pythonic idioms and PEP 8; pytest, fixtures, coverage |
| `golang-patterns` / `golang-testing` | Idiomatic Go; table-driven tests, subtests, benchmarks, fuzzing |
| `rust-patterns` / `rust-testing` | Ownership, traits, concurrency; unit/integration/property tests |
| `cpp-coding-standards` / `cpp-testing` | C++ Core Guidelines; GoogleTest/CTest, sanitizers, coverage |
| `django-patterns` / `django-security` / `django-tdd` / `django-verification` | DRF architecture, ORM, security, pytest-django, pre-release checks |
| `laravel-patterns` / `laravel-security` / `laravel-tdd` / `laravel-verification` | Eloquent, service layers, queues; PHPUnit/Pest; deployment readiness |
| `swiftui-patterns` | SwiftUI architecture, `@Observable` state, navigation, performance |
| `swift-concurrency-6-2` | Swift 6.2 Approachable Concurrency and `@concurrent` offloading |
| `swift-actor-persistence` | Thread-safe persistence with actors and file-backed caches |
| `swift-protocol-di-testing` | Protocol-based DI for mocking file system, network, and APIs |
| `foundation-models-on-device` | Apple FoundationModels — guided generation, tool calling, iOS 26+ |
| `liquid-glass-design` | iOS 26 Liquid Glass material for SwiftUI, UIKit, WidgetKit |
| `compose-multiplatform-patterns` | Compose Multiplatform / Jetpack Compose for KMP projects |

### Data & infrastructure

| Skill | What it does |
|-------|--------------|
| `postgres-patterns` | Query optimization, schema design, indexing, RLS (Supabase-informed) |
| `clickhouse-io` | ClickHouse patterns for high-performance analytical workloads |
| `database-migrations` | Schema/data migrations, rollbacks, zero-downtime deploys |
| `docker-patterns` | Compose for local dev, container security, networking, volumes |
| `deployment-patterns` | CI/CD pipelines, health checks, rollback, production readiness |
| `content-hash-cache-pattern` | SHA-256 content-hash caching — path-independent, auto-invalidating |

### Agent & AI engineering

| Skill | What it does |
|-------|--------------|
| `agentic-engineering` | Eval-first execution, decomposition, cost-aware model routing |
| `ai-first-engineering` | Operating model for teams where agents write most of the code |
| `agent-harness-construction` | Design action spaces, tool definitions, and observation formatting |
| `enterprise-agent-ops` | Observability, security boundaries, lifecycle for long-lived agents |
| `continuous-agent-loop` | Continuous autonomous loops with quality gates and recovery controls |
| `autonomous-loops` | Compatibility alias for `continuous-agent-loop` |
| `ralphinho-rfc-pipeline` | RFC-driven multi-agent DAG with quality gates and merge queues |
| `eval-harness` | Formal eval framework for eval-driven development |
| `iterative-retrieval` | Progressive context refinement for the subagent context problem |
| `cost-aware-llm-pipeline` | Model routing by complexity, budget tracking, prompt caching |
| `regex-vs-llm-structured-text` | When to parse with regex and when to reach for an LLM |
| `claude-api` | Messages API, streaming, tool use, vision, thinking, batches, caching |
| `mcp-server-patterns` | Build MCP servers with the Node/TS SDK — tools, resources, prompts |
| `claude-devfleet` | Dispatch parallel agents in isolated worktrees and read structured results |
| `dmux-workflows` | Multi-agent orchestration across harnesses via tmux pane management |
| `nanoclaw-repl` | Operate and extend NanoClaw v2, the session-aware `claude -p` REPL |
| `team-builder` | Interactive picker for composing and dispatching parallel agent teams |
| `prompt-optimizer` | Analyze a raw prompt, match staksmith components, emit an optimized one |
| `continuous-learning` | Extract reusable patterns from sessions into learned skills |
| `continuous-learning-v2` | Instinct-based learning with confidence scoring and skill evolution |

### Skills & harness setup

| Skill | What it does |
|-------|--------------|
| `skill-creator` | Scaffold a new skill with correct structure and frontmatter |
| `skill-design` | Vocabulary and principles that make a skill predictable |
| `skill-auto-extractor` | Mine git history and session logs for repeatable workflows |
| `skill-stocktake` | Audit skills and commands for quality (Quick Scan or Full Stocktake) |
| `configure-staksmith` | Interactive installer for skills and rules, user- or project-level |
| `project-guidelines-example` | Template for a project-specific skill |
| `strategic-compact` | Suggest `/compact` at logical breakpoints instead of arbitrary ones |
| `wizard` | Generate an interactive bash wizard for a manual A→B procedure |
| `teach` | Teach a concept across sessions with a stateful learning workspace |

### Research & documentation

| Skill | What it does |
|-------|--------------|
| `deep-research` | Multi-source research via firecrawl/exa with cited reports |
| `source-research` | Investigate against primary sources — docs, source code, specs |
| `market-research` | Competitive analysis and industry intel with source attribution |
| `exa-search` | Neural search for web, code, company, and people lookup |
| `documentation-lookup` | Current library docs via Context7 instead of training data |
| `converting-web-to-markdown` | Fetch a URL and convert it to markdown (WebFetch or Playwright) |
| `data-scraper-agent` | Automated scheduled scraper for any public source |
| `code-to-docs-sync` | Detect drift between code and READMEs/CLAUDE.md/API docs |

### Knowledge base (Obsidian vault)

| Skill | What it does |
|-------|--------------|
| `inbox` | Process `0. Inbox/` into PARA directories with per-file confirmation |
| `inbox-scan` / `inbox-classify` / `inbox-organize` | The scan → classify → move phases, usable standalone |
| `sync` | Load full vault context — weeklies, active projects, tasks, recent edits |
| `backlinks` | Find orphans and cluster bridges, then add links and stubs |
| `connect` | Find connections between two topics through the wikilink graph |
| `trace` | Build a chronological timeline of how an idea evolved |
| `graduate` | Promote undeveloped ideas from weekly notes into seedling notes |
| `ideas` | Scan for emerging patterns — what to build, investigate, or write |
| `ghost` | Answer a question in the user's own voice, drawn from their writing |
| `backlog-review` | Verify open backlog items against repo evidence, close the done ones |
| `what-next` | Index a project's open todos, prioritize them, return the top 3 next tasks |
| `weekly-momentum-report` | Aggregate git, vault tasks, and GitHub into a weekly review |
| `vault-to-code-bridge` | Turn vault project notes into ADRs, specs, and CLAUDE.md files |
| `money` | Mine the vault for monetization opportunities, then go beyond it |

### Writing & publishing

| Skill | What it does |
|-------|--------------|
| `article-writing` | Long-form in a distinctive voice derived from examples or brand guides |
| `writing-fragments` | Explore — mine raw fragments before any structure exists |
| `writing-beats` | Exploit — assemble material into a journey of grounded beats |
| `writing-shape` | Exploit — shape material into an argued article, paragraph by paragraph |
| `writing-grounding` | The grounding system shared by the writing skills |
| `blog-ideas` | Generate post ideas from vault expertise, filtered through strategy |
| `blog-draft` | Draft a full post by mining the vault for evidence |
| `polish` | Voice/structure/SEO audit, fixes, and a pre-publish checklist |
| `content` | Content calendar and publishing pipeline — buffer health, pillar balance |
| `content-engine` | Platform-native systems for X, LinkedIn, TikTok, YouTube, newsletters |
| `crosspost` | Distribute across X, LinkedIn, Threads, Bluesky — adapted per platform |
| `x-api` | X/Twitter posting, threads, timelines, search, analytics |
| `frontend-slides` | Animation-rich HTML presentations, from scratch or from a PPTX |

### Media

| Skill | What it does |
|-------|--------------|
| `story-ideas` / `story-script` / `story-pipeline` | Ideas, narration scripts, and calendar for the TikTok story channel |
| `video-editing` | AI-assisted editing pipeline — FFmpeg, Remotion, and beyond |
| `videodb` | Ingest and act on video/audio from files, URLs, RTSP, or live capture |
| `fal-ai-media` | Image, video, and audio generation via fal.ai MCP |

### Product & fundraising

| Skill | What it does |
|-------|--------------|
| `product-ideas` | Mine the vault for sellable digital products, with pricing guidance |
| `product-pipeline` | Product calendar, launches, revenue tracking, what to build next |
| `package-product` | Package guides, templates, and bundles for Gumroad with sales pages |
| `investor-materials` | Decks, one-pagers, memos, accelerator applications, financial models |
| `investor-outreach` | Cold emails, warm intros, follow-ups, and investor updates |
| `nutrient-document-processing` | Convert, OCR, extract, redact, sign, and fill documents via Nutrient DWS |
| `visa-doc-translate` | Translate visa documents and produce a bilingual PDF |

### Operations (codified domain expertise)

Each of these encodes 15+ years of practitioner judgment in a specific operational domain — frameworks, escalation protocols, and decision rules rather than software patterns.

| Skill | Domain |
|-------|--------|
| `carrier-relationship-management` | Carrier portfolios, freight rate negotiation, scorecarding, RFPs |
| `customs-trade-compliance` | HS classification, Incoterms, FTAs, restricted-party screening |
| `energy-procurement` | Electricity/gas tariffs, demand charges, PPAs, hedging, load profiling |
| `inventory-demand-planning` | Forecasting, safety stock, ABC/XYZ, promotional lift, replenishment |
| `logistics-exception-management` | Delays, damages, losses, carrier disputes, freight claims |
| `production-scheduling` | Job sequencing, line balancing, SMED, OEE, drum-buffer-rope |
| `quality-nonconformance` | NCR lifecycle, CAPA, SPC, audits under FDA/IATF 16949/AS9100 |
| `returns-reverse-logistics` | RMA, disposition economics, fraud detection, warranty recovery |

---

## Contributing a skill

```bash
# 1. Create the skill directory
mkdir -p skills/my-skill

# 2. Write skills/my-skill/SKILL.md with `name` and `description` frontmatter

# 3. Only if the skill needs deterministic steps, add scripts/ and config.json,
#    then make the scripts executable (a missing exec bit is a silent failure)
chmod +x skills/my-skill/scripts/*.sh

# 4. Add the skill to the catalog above
```

Then validate:

```bash
node scripts/ci/validate-skills.js   # frontmatter and structure
node scripts/ci/catalog.js --text    # counts must match README.md and AGENTS.md
npm test                             # everything
```

Adding or removing a skill changes the catalog count, so update the totals in the [root README](../README.md) and [`AGENTS.md`](../AGENTS.md) — CI fails otherwise.

### Quality bar

- Description written to trigger — undertriggering is the default failure mode
- Concrete examples before abstract rules; example 1 is the minimal happy path
- Dry-run mode for anything destructive
- JSON output from scripts so skills compose
- Meaningful error messages; scripts use `set -euo pipefail`
- Resumable caching for long-running phases
- Examples and troubleshooting in the skill body, not just rules

See [`DESIGN_NOTES.md`](DESIGN_NOTES.md) for the full rationale.

---

## License

Part of the Staksmith project — MIT, same as the repo.
