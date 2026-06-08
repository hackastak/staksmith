# staksmith

[![Stars](https://img.shields.io/github/stars/hackastak/staksmith?style=flat)](https://github.com/hackastak/staksmith/stargazers)
[![Forks](https://img.shields.io/github/forks/hackastak/staksmith?style=flat)](https://github.com/hackastak/staksmith/network/members)
[![Contributors](https://img.shields.io/github/contributors/hackastak/staksmith?style=flat)](https://github.com/hackastak/staksmith/graphs/contributors)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Shell](https://img.shields.io/badge/-Shell-4EAA25?logo=gnu-bash&logoColor=white)
![TypeScript](https://img.shields.io/badge/-TypeScript-3178C6?logo=typescript&logoColor=white)
![Python](https://img.shields.io/badge/-Python-3776AB?logo=python&logoColor=white)
![Go](https://img.shields.io/badge/-Go-00ADD8?logo=go&logoColor=white)
![Markdown](https://img.shields.io/badge/-Markdown-000000?logo=markdown&logoColor=white)

**A collection of skills and configs for AI coding agents.**

staksmith is a curated set of agents, skills, commands, hooks, rules, and MCP configurations for Claude Code and compatible AI agent harnesses. It bundles workflows that have been refined through daily use building real software — test-driven development, code review, security scanning, planning, continuous learning, and more — so you can drop them into any project instead of rebuilding them from scratch.

Works across **Claude Code**, **Cursor**, **Codex**, and **OpenCode**.

---

## What's Inside

staksmith is organized into independent components — install the whole thing or copy only the pieces you want.

| Component | What it is |
|-----------|------------|
| **Agents** | Specialized subagents for delegated work (planner, architect, code-reviewer, security-reviewer, tdd-guide, and language-specific reviewers/build resolvers). |
| **Skills** | Reusable workflow definitions and domain knowledge — TDD, security review, framework patterns (Django, Laravel, Next.js, Go, Swift, Rust, C++), continuous learning, research, and content/product workflows. |
| **Commands** | Slash commands for quick execution (`/plan`, `/tdd`, `/code-review`, `/e2e`, `/build-fix`, `/refactor-clean`, and many more). |
| **Rules** | Always-follow guidelines split into `common/` plus per-language directories. Install only the stacks you use. |
| **Hooks** | Trigger-based automations for session persistence, formatting, type checks, and secret detection. |
| **Contexts** | Dynamic system-prompt contexts for dev, review, and research modes. |
| **MCP configs** | Ready-to-use MCP server configurations for common integrations. |
| **Examples** | Real-world `CLAUDE.md` templates for several stacks. |

---

## 🚀 Quick Start

Get up and running in a couple of minutes.

### Step 1: Install the plugin

```bash
# Add the marketplace
/plugin marketplace add hackastak/staksmith

# Install the plugin
/plugin install staksmith@staksmith
```

### Step 2: Install rules (required)

> ⚠️ **Important:** Claude Code plugins cannot distribute `rules` automatically. Install them manually:

```bash
# Clone the repo first
git clone https://github.com/hackastak/staksmith.git
cd staksmith

# Install dependencies (pick your package manager)
npm install        # or: pnpm install | yarn install | bun install

# macOS/Linux
./install.sh typescript    # or python, golang, swift, php, cpp
# ./install.sh typescript python golang swift php
# ./install.sh --target cursor typescript
```

```powershell
# Windows PowerShell
.\install.ps1 typescript   # or python, golang, swift, php, cpp
# .\install.ps1 typescript python golang swift php
# .\install.ps1 --target cursor typescript
```

For manual install instructions see the README in the `rules/` folder.

### Step 3: Start using

```bash
# Try a command (plugin install uses the namespaced form)
/staksmith:plan "Add user authentication"

# Manual install (Option 2) uses the shorter form:
# /plan "Add user authentication"

# Check what's available
/plugin list staksmith@staksmith
```

✨ **That's it!** You now have access to the full set of agents, skills, and commands.

---

## 🌐 Cross-Platform Support

staksmith supports **Windows, macOS, and Linux**, alongside integration across major IDEs and CLI harnesses (Cursor, OpenCode, Codex). All hooks and scripts are written in Node.js for maximum compatibility.

### Package manager detection

staksmith automatically detects your preferred package manager (npm, pnpm, yarn, or bun) in this priority order:

1. **Environment variable**: `CLAUDE_PACKAGE_MANAGER`
2. **Project config**: `.claude/package-manager.json`
3. **package.json**: `packageManager` field
4. **Lock file**: package-lock.json, yarn.lock, pnpm-lock.yaml, or bun.lockb
5. **Global config**: `~/.claude/package-manager.json`
6. **Fallback**: first available package manager

To set your preferred package manager:

```bash
# Via environment variable
export CLAUDE_PACKAGE_MANAGER=pnpm

# Via global config
node scripts/setup-package-manager.js --global pnpm

# Via project config
node scripts/setup-package-manager.js --project bun

# Detect current setting
node scripts/setup-package-manager.js --detect
```

Or use the `/setup-pm` command in Claude Code.

### Hook runtime controls

Tune hook strictness or disable specific hooks temporarily with environment variables:

```bash
# Hook strictness profile (default: standard)
export ECC_HOOK_PROFILE=standard   # minimal | standard | strict

# Comma-separated hook IDs to disable
export ECC_DISABLED_HOOKS="pre:bash:tmux-reminder,post:edit:typecheck"
```

---

## 📦 Repository Layout

staksmith is a **Claude Code plugin** — install it directly or copy components manually.

```
staksmith/
|-- .claude-plugin/   # Plugin and marketplace manifests
|   |-- plugin.json         # Plugin metadata and component paths
|   |-- marketplace.json    # Marketplace catalog for /plugin marketplace add
|
|-- agents/           # Specialized subagents for delegation
|   |-- planner.md            # Feature implementation planning
|   |-- architect.md          # System design decisions
|   |-- tdd-guide.md          # Test-driven development
|   |-- code-reviewer.md      # Quality and security review
|   |-- security-reviewer.md  # Vulnerability analysis
|   |-- build-error-resolver.md
|   |-- e2e-runner.md         # Playwright E2E testing
|   |-- refactor-cleaner.md   # Dead code cleanup
|   |-- doc-updater.md        # Documentation sync
|   |-- python-reviewer.md    # Python code review
|   |-- go-reviewer.md        # Go code review
|   |-- rust-reviewer.md      # Rust code review
|   |-- cpp-reviewer.md       # C++ code review
|   |-- database-reviewer.md  # Database/Supabase review
|   |-- ...                   # plus build resolvers and orchestration agents
|
|-- skills/           # Workflow definitions and domain knowledge
|   |-- coding-standards/      # Language best practices
|   |-- backend-patterns/      # API, database, caching patterns
|   |-- frontend-patterns/     # React, Next.js patterns
|   |-- tdd-workflow/          # TDD methodology
|   |-- security-review/       # Security checklist
|   |-- verification-loop/     # Continuous verification
|   |-- continuous-learning/   # Auto-extract patterns from sessions
|   |-- django-* / laravel-*   # Framework patterns, security, TDD, verification
|   |-- python-* / golang-* / rust-* / cpp-* / swift-*  # Per-language patterns & testing
|   |-- deep-research/         # Multi-source, fact-checked research
|   |-- ...                    # 100+ skills across engineering, content, and product
|
|-- commands/         # Slash commands for quick execution
|   |-- plan.md               # /plan  - Implementation planning
|   |-- tdd.md                # /tdd   - Test-driven development
|   |-- code-review.md        # /code-review - Quality review
|   |-- e2e.md                # /e2e   - E2E test generation
|   |-- build-fix.md          # /build-fix - Fix build errors
|   |-- refactor-clean.md     # /refactor-clean - Dead code removal
|   |-- verify.md             # /verify - Run verification loop
|   |-- setup-pm.md           # /setup-pm - Configure package manager
|   |-- ...                   # plus language reviews, multi-agent, and session commands
|
|-- rules/            # Always-follow guidelines (copy to ~/.claude/rules/)
|   |-- README.md             # Structure overview and installation guide
|   |-- common/               # Language-agnostic principles
|   |   |-- coding-style.md     # Immutability, file organization
|   |   |-- git-workflow.md     # Commit format, PR process
|   |   |-- testing.md          # TDD, coverage requirements
|   |   |-- performance.md      # Model selection, context management
|   |   |-- patterns.md         # Design patterns, skeleton projects
|   |   |-- hooks.md            # Hook architecture, TodoWrite
|   |   |-- agents.md           # When to delegate to subagents
|   |   |-- security.md         # Mandatory security checks
|   |-- typescript/           # TypeScript/JavaScript specific
|   |-- python/               # Python specific
|   |-- golang/               # Go specific
|   |-- swift/                # Swift specific
|   |-- php/                  # PHP specific
|   |-- cpp/                  # C++ specific
|
|-- hooks/            # Trigger-based automations
|   |-- README.md             # Hook documentation, recipes, and customization guide
|   |-- hooks.json            # All hooks config (PreToolUse, PostToolUse, Stop, etc.)
|   |-- memory-persistence/   # Session lifecycle hooks
|   |-- strategic-compact/    # Compaction suggestions
|
|-- scripts/          # Cross-platform Node.js scripts
|   |-- lib/                  # Shared utilities (file/path/system, package-manager detection)
|   |-- hooks/                # Hook implementations
|   |-- setup-package-manager.js
|
|-- tests/            # Test suite for scripts and utilities
|
|-- contexts/         # Dynamic system prompt injection contexts
|   |-- dev.md                # Development mode context
|   |-- review.md             # Code review mode context
|   |-- research.md           # Research/exploration mode context
|
|-- examples/         # Example CLAUDE.md configs for real-world stacks
|
|-- mcp-configs/      # MCP server configurations
|   |-- mcp-servers.json      # GitHub, Supabase, Vercel, Railway, etc.
```

---

## 🛠️ Ecosystem Tools

### Skill Creator

Generate Claude Code skills from your repository's git history without external services:

```bash
/skill-create                    # Analyze current repo
/skill-create --instincts        # Also generate instincts for continuous-learning
```

This analyzes your git history locally and generates SKILL.md files, instinct collections for continuous-learning, and pattern extraction from your commit history.

### Continuous Learning

The instinct-based learning system captures your patterns over time:

```bash
/instinct-status        # Show learned instincts with confidence
/instinct-import <file> # Import instincts from others
/instinct-export        # Export your instincts for sharing
/evolve                 # Cluster related instincts into skills
```

See `skills/continuous-learning-v2/` for full documentation.

### Write-Time Quality (Plankton)

Plankton (credit: [@alxfazio](https://github.com/alxfazio)) is a recommended companion for write-time code quality enforcement. It runs formatters and linters on every file edit via PostToolUse hooks, then delegates remaining fixes to Claude subprocesses. Supports Python, TypeScript, Shell, YAML, JSON, TOML, Markdown, and Dockerfile. See `skills/plankton-code-quality/` for the integration guide.

---

## 📋 Requirements

### Claude Code CLI

staksmith relies on Claude Code's plugin and hook system. Use a current Claude Code release for the smoothest experience:

```bash
claude --version
```

### Hooks auto-loading behavior

> ⚠️ **For contributors:** Do **NOT** add a `"hooks"` field to `.claude-plugin/plugin.json`. This is enforced by a regression test.

Claude Code **automatically loads** `hooks/hooks.json` from any installed plugin by convention. Explicitly declaring it in `plugin.json` causes a duplicate detection error:

```
Duplicate hooks file detected: ./hooks/hooks.json resolves to already-loaded file
```

A regression test keeps this from being reintroduced.

---

## 📥 Installation

### Option 1: Install as a plugin (recommended)

The easiest way to use staksmith — install it as a Claude Code plugin:

```bash
# Add this repo as a marketplace
/plugin marketplace add hackastak/staksmith

# Install the plugin
/plugin install staksmith@staksmith
```

Or add directly to your `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "staksmith": {
      "source": {
        "source": "github",
        "repo": "hackastak/staksmith"
      }
    }
  },
  "enabledPlugins": {
    "staksmith@staksmith": true
  }
}
```

This gives you instant access to all commands, agents, skills, and hooks.

> **Note:** The Claude Code plugin system does not support distributing `rules` via plugins ([upstream limitation](https://code.claude.com/docs/en/plugins-reference)). Install rules manually:
>
> ```bash
> # Clone the repo first
> git clone https://github.com/hackastak/staksmith.git
>
> # Option A: User-level rules (applies to all projects)
> mkdir -p ~/.claude/rules
> cp -r staksmith/rules/common/* ~/.claude/rules/
> cp -r staksmith/rules/typescript/* ~/.claude/rules/   # pick your stack
> cp -r staksmith/rules/python/* ~/.claude/rules/
> cp -r staksmith/rules/golang/* ~/.claude/rules/
> cp -r staksmith/rules/php/* ~/.claude/rules/
>
> # Option B: Project-level rules (applies to current project only)
> mkdir -p .claude/rules
> cp -r staksmith/rules/common/* .claude/rules/
> cp -r staksmith/rules/typescript/* .claude/rules/     # pick your stack
> ```

---

### 🔧 Option 2: Manual installation

If you prefer manual control over what's installed:

```bash
# Clone the repo
git clone https://github.com/hackastak/staksmith.git

# Copy agents to your Claude config
cp staksmith/agents/*.md ~/.claude/agents/

# Copy rules (common + language-specific)
cp -r staksmith/rules/common/* ~/.claude/rules/
cp -r staksmith/rules/typescript/* ~/.claude/rules/   # pick your stack
cp -r staksmith/rules/python/* ~/.claude/rules/
cp -r staksmith/rules/golang/* ~/.claude/rules/
cp -r staksmith/rules/php/* ~/.claude/rules/

# Copy commands
cp staksmith/commands/*.md ~/.claude/commands/

# Copy skills (copy all, or just the ones you need)
cp -r staksmith/skills/* ~/.claude/skills/
# Or copy a single skill:
# cp -r staksmith/skills/search-first ~/.claude/skills/
```

#### Add hooks to settings.json

Copy the hooks from `hooks/hooks.json` into your `~/.claude/settings.json`.

#### Configure MCPs

Copy the MCP servers you want from `mcp-configs/mcp-servers.json` into your `~/.claude.json`.

**Important:** Replace `YOUR_*_HERE` placeholders with your actual API keys.

---

## 🎯 Key Concepts

### Agents

Subagents handle delegated tasks with limited scope. Example:

```markdown
---
name: code-reviewer
description: Reviews code for quality, security, and maintainability
tools: ["Read", "Grep", "Glob", "Bash"]
model: opus
---

You are a senior code reviewer...
```

### Skills

Skills are workflow definitions invoked by commands or agents:

```markdown
# TDD Workflow

1. Define interfaces first
2. Write failing tests (RED)
3. Implement minimal code (GREEN)
4. Refactor (IMPROVE)
5. Verify coverage thresholds
```

### Hooks

Hooks fire on tool events. Example — warn about `console.log`:

```json
{
  "matcher": "tool == \"Edit\" && tool_input.file_path matches \"\\\\.(ts|tsx|js|jsx)$\"",
  "hooks": [{
    "type": "command",
    "command": "#!/bin/bash\ngrep -n 'console\\.log' \"$file_path\" && echo '[Hook] Remove console.log' >&2"
  }]
}
```

### Rules

Rules are always-follow guidelines, organized into `common/` (language-agnostic) plus language-specific directories:

```
rules/
  common/          # Universal principles (always install)
  typescript/      # TS/JS specific patterns and tools
  python/          # Python specific patterns and tools
  golang/          # Go specific patterns and tools
  swift/           # Swift specific patterns and tools
  php/             # PHP specific patterns and tools
  cpp/             # C++ specific patterns and tools
```

See [`rules/README.md`](rules/README.md) for installation and structure details.

---

## 🗺️ Which Agent Should I Use?

Not sure where to start? Use this quick reference:

| I want to... | Use this command | Agent used |
|--------------|-----------------|------------|
| Plan a new feature | `/staksmith:plan "Add auth"` | planner |
| Design system architecture | `/staksmith:plan` + architect agent | architect |
| Write code with tests first | `/tdd` | tdd-guide |
| Review code I just wrote | `/code-review` | code-reviewer |
| Fix a failing build | `/build-fix` | build-error-resolver |
| Run end-to-end tests | `/e2e` | e2e-runner |
| Find security vulnerabilities | `/security-scan` | security-reviewer |
| Remove dead code | `/refactor-clean` | refactor-cleaner |
| Update documentation | `/update-docs` | doc-updater |
| Review Go code | `/go-review` | go-reviewer |
| Review Python code | `/python-review` | python-reviewer |
| Audit database queries | *(auto-delegated)* | database-reviewer |

### Common Workflows

**Starting a new feature:**
```
/staksmith:plan "Add user authentication with OAuth"
                                              → planner creates implementation blueprint
/tdd                                          → tdd-guide enforces write-tests-first
/code-review                                  → code-reviewer checks your work
```

**Fixing a bug:**
```
/tdd                                          → tdd-guide: write a failing test that reproduces it
                                              → implement the fix, verify test passes
/code-review                                  → code-reviewer: catch regressions
```

**Preparing for production:**
```
/security-scan                                → security-reviewer: OWASP Top 10 audit
/e2e                                          → e2e-runner: critical user flow tests
/test-coverage                                → verify coverage thresholds
```

---

## ❓ FAQ

<details>
<summary><b>How do I check which agents/commands are installed?</b></summary>

```bash
/plugin list staksmith@staksmith
```

This shows all available agents, commands, and skills from the plugin.
</details>

<details>
<summary><b>My hooks aren't working / I see "Duplicate hooks file" errors</b></summary>

This is the most common issue. **Do NOT add a `"hooks"` field to `.claude-plugin/plugin.json`.** Claude Code automatically loads `hooks/hooks.json` from installed plugins. Explicitly declaring it causes duplicate detection errors.
</details>

<details>
<summary><b>Can I use staksmith with a custom API endpoint or model gateway?</b></summary>

Yes. staksmith does not hardcode Anthropic-hosted transport settings. It runs locally through Claude Code's normal CLI/plugin surface, so it works with:

- Anthropic-hosted Claude Code
- Official Claude Code gateway setups using `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN`
- Compatible custom endpoints that speak the Anthropic API Claude Code expects

Minimal example:

```bash
export ANTHROPIC_BASE_URL=https://your-gateway.example.com
export ANTHROPIC_AUTH_TOKEN=your-token
claude
```

If your gateway remaps model names, configure that in Claude Code rather than in staksmith. staksmith's hooks, skills, commands, and rules are model-provider agnostic once the `claude` CLI is already working.

Official references:
- [Claude Code LLM gateway docs](https://docs.anthropic.com/en/docs/claude-code/llm-gateway)
- [Claude Code model configuration docs](https://docs.anthropic.com/en/docs/claude-code/model-config)

</details>

<details>
<summary><b>My context window is shrinking / Claude is running out of context</b></summary>

Too many MCP servers eat your context. Each MCP tool description consumes tokens from your context window.

**Fix:** Disable unused MCPs per project:
```json
// In your project's .claude/settings.json
{
  "disabledMcpServers": ["supabase", "railway", "vercel"]
}
```

Keep under 10 MCPs enabled and under 80 tools active.
</details>

<details>
<summary><b>Can I use only some components (e.g., just agents)?</b></summary>

Yes. Use Option 2 (manual installation) and copy only what you need:

```bash
# Just agents
cp staksmith/agents/*.md ~/.claude/agents/

# Just rules
cp -r staksmith/rules/common/* ~/.claude/rules/
```

Each component is fully independent.
</details>

<details>
<summary><b>Does this work with Cursor / OpenCode / Codex?</b></summary>

Yes. staksmith is cross-platform:
- **Cursor**: Pre-translated configs in `.cursor/`. See [Cursor IDE Support](#cursor-ide-support).
- **OpenCode**: Full plugin support in `.opencode/`. See [OpenCode Support](#-opencode-support).
- **Codex**: Support for both the macOS app and CLI via `AGENTS.md` and `.codex/`. See [Codex Support](#codex-macos-app--cli-support).
- **Claude Code**: Native — this is the primary target.
</details>

<details>
<summary><b>How do I contribute a new skill or agent?</b></summary>

See [CONTRIBUTING.md](CONTRIBUTING.md). The short version:
1. Fork the repo
2. Create your skill in `skills/your-skill-name/SKILL.md` (with YAML frontmatter)
3. Or create an agent in `agents/your-agent.md`
4. Submit a PR with a clear description of what it does and when to use it
</details>

---

## 🧪 Running Tests

staksmith includes a test suite for its scripts and utilities:

```bash
# Run all tests
node tests/run-all.js

# Run individual test files
node tests/lib/utils.test.js
node tests/lib/package-manager.test.js
node tests/hooks/hooks.test.js
```

---

## 🤝 Contributing

**Contributions are welcome and encouraged.**

staksmith is meant to be a community resource. If you have:
- Useful agents or skills
- Clever hooks
- Better MCP configurations
- Improved rules

Please contribute! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Ideas for contributions

- Language-specific skills (C#, Kotlin) — Go, Python, Rust, Swift, C++, and TypeScript already included
- Framework-specific configs (Rails, FastAPI, NestJS) — Django, Laravel already included
- DevOps agents (Kubernetes, Terraform, AWS, Docker)
- Testing strategies (different frameworks, visual regression)
- Domain-specific knowledge (ML, data engineering, mobile)

---

## Cursor IDE Support

staksmith provides **full Cursor IDE support** with hooks, rules, agents, skills, commands, and MCP configs adapted for Cursor's native format.

### Quick Start (Cursor)

```bash
# macOS/Linux
./install.sh --target cursor typescript
./install.sh --target cursor python golang swift php

# Windows PowerShell
.\install.ps1 --target cursor typescript
.\install.ps1 --target cursor python golang swift php
```

### Hook architecture (DRY adapter pattern)

Cursor has more hook events than Claude Code. The `.cursor/hooks/adapter.js` module transforms Cursor's stdin JSON to Claude Code's format, letting the existing `scripts/hooks/*.js` be reused without duplication.

```
Cursor stdin JSON → adapter.js → transforms → scripts/hooks/*.js
                                              (shared with Claude Code)
```

Key hooks:
- **beforeShellExecution** — blocks dev servers outside tmux, git push review
- **afterFileEdit** — auto-format + TypeScript check + console.log warning
- **beforeSubmitPrompt** — detects secrets (sk-, ghp_, AKIA patterns) in prompts
- **beforeTabFileRead** — blocks Tab from reading `.env`, `.key`, `.pem` files
- **beforeMCPExecution / afterMCPExecution** — MCP audit logging

### Rules format

Cursor rules use YAML frontmatter with `description`, `globs`, and `alwaysApply`:

```yaml
---
description: "TypeScript coding style extending common rules"
globs: ["**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx"]
alwaysApply: false
---
```

---

## Codex macOS App + CLI Support

staksmith provides **Codex support** for both the macOS app and CLI, with a reference configuration, a Codex-specific `AGENTS.md` supplement, and shared skills.

### Quick Start (Codex App + CLI)

```bash
# Run Codex CLI in the repo — AGENTS.md and .codex/ are auto-detected
codex

# Optional: copy the global-safe defaults to your home directory
cp .codex/config.toml ~/.codex/config.toml
```

Codex macOS app:
- Open this repository as your workspace.
- The root `AGENTS.md` is auto-detected.
- `.codex/config.toml` and `.codex/agents/*.toml` work best kept project-local.
- The reference `.codex/config.toml` intentionally does not pin `model` or `model_provider`, so Codex uses its own default unless you override it.

### Skills

Skills at `.agents/skills/` are auto-loaded by Codex and include TDD, security review, coding standards, frontend/backend patterns, E2E testing, API design, and verification loops.

### Key limitation

Codex does **not yet provide Claude-style hook execution parity**. staksmith enforcement there is instruction-based via `AGENTS.md`, optional `model_instructions_file` overrides, and sandbox/approval settings.

### Multi-agent support

Current Codex builds support experimental multi-agent workflows:

- Enable `features.multi_agent = true` in `.codex/config.toml`
- Define roles under `[agents.<name>]`
- Point each role at a file under `.codex/agents/`
- Use `/agent` in the CLI to inspect or steer child agents

staksmith ships sample role configs for an `explorer` (read-only evidence gathering), a `reviewer` (correctness, security, missing tests), and a `docs_researcher` (documentation and API verification).

---

## 🔌 OpenCode Support

staksmith provides **full OpenCode support** including plugins and hooks.

### Quick Start

```bash
# Install OpenCode
npm install -g opencode

# Run in the repository root
opencode
```

The configuration is automatically detected from `.opencode/opencode.json`.

### Hook support via plugins

OpenCode's plugin system maps cleanly onto Claude Code's hooks, with additional events:

| Claude Code Hook | OpenCode Plugin Event |
|-----------------|----------------------|
| PreToolUse | `tool.execute.before` |
| PostToolUse | `tool.execute.after` |
| Stop | `session.idle` |
| SessionStart | `session.created` |
| SessionEnd | `session.deleted` |

**Additional OpenCode events**: `file.edited`, `file.watcher.updated`, `message.updated`, `lsp.client.diagnostics`, `tui.toast.show`, and more.

### Documentation

- **Migration Guide**: `.opencode/MIGRATION.md`
- **OpenCode Plugin README**: `.opencode/README.md`
- **Consolidated Rules**: `.opencode/instructions/INSTRUCTIONS.md`
- **LLM Documentation**: `llms.txt`

---

## 🧱 Cross-Tool Notes

Some architectural decisions that make staksmith work across harnesses:

- **AGENTS.md** at the repo root is the universal cross-tool file (read by Claude Code, Cursor, Codex, and OpenCode).
- **DRY adapter pattern** lets Cursor reuse Claude Code's hook scripts without duplication.
- **Skills format** (SKILL.md with YAML frontmatter) works across Claude Code, Codex, and OpenCode.
- Codex's lack of hooks is compensated by `AGENTS.md`, optional `model_instructions_file` overrides, and sandbox permissions.

---

## 📖 Background

These configs are battle-tested across multiple production applications and refined through daily use building real software with Claude Code.

### Inspiration credits

- inspired by [zarazhangrui](https://github.com/zarazhangrui)
- homunculus-inspired by [humanplane](https://github.com/humanplane)

---

## 💸 Token Optimization

Claude Code usage can be expensive if you don't manage token consumption. These settings reduce costs without sacrificing much quality.

### Recommended settings

Add to `~/.claude/settings.json`:

```json
{
  "model": "sonnet",
  "env": {
    "MAX_THINKING_TOKENS": "10000",
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "50"
  }
}
```

| Setting | Recommended | Impact |
|---------|-------------|--------|
| `model` | **sonnet** | Large cost reduction; handles most coding tasks |
| `MAX_THINKING_TOKENS` | **10000** | Big reduction in hidden thinking cost per request |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | **50** | Compacts earlier — better quality in long sessions |

Switch to Opus when you need deep architectural reasoning:
```
/model opus
```

### Daily workflow commands

| Command | When to use |
|---------|-------------|
| `/model sonnet` | Default for most tasks |
| `/model opus` | Complex architecture, debugging, deep reasoning |
| `/clear` | Between unrelated tasks (free, instant reset) |
| `/compact` | At logical task breakpoints (research done, milestone complete) |
| `/cost` | Monitor token spending during a session |

### Strategic compaction

The `strategic-compact` skill suggests `/compact` at logical breakpoints instead of relying on auto-compaction. See `skills/strategic-compact/SKILL.md` for the full decision guide.

**When to compact:**
- After research/exploration, before implementation
- After completing a milestone, before starting the next
- After debugging, before continuing feature work
- After a failed approach, before trying a new one

**When NOT to compact:**
- Mid-implementation (you'll lose variable names, file paths, partial state)

### Context window management

**Critical:** Don't enable all MCPs at once. Each MCP tool description consumes tokens from your context window.

- Keep under 10 MCPs enabled per project
- Keep under 80 tools active
- Use `disabledMcpServers` in project config to disable unused ones

---

## ⚠️ Customization

These configs reflect one opinionated workflow. You should:
1. Start with what resonates
2. Modify for your stack
3. Remove what you don't use
4. Add your own patterns

---

## 🔗 Links

- **Repository:** [github.com/hackastak/staksmith](https://github.com/hackastak/staksmith)
- **Contributing:** [CONTRIBUTING.md](CONTRIBUTING.md)
- **Rules guide:** [rules/README.md](rules/README.md)

---

## 📄 License

MIT — use freely, modify as needed, contribute back if you can.

---

**Star this repo if it helps. Build something great.**
