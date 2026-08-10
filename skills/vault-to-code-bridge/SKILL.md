---
name: vault-to-code-bridge
description: Convert Obsidian vault project notes into architectural decisions, specifications, and CLAUDE.md files in code repositories.
category: "Second Brain & Vault"
origin: Hackastak
---

# Vault-to-Code Bridge

Convert Obsidian vault project notes into architectural decisions, specifications, and CLAUDE.md files in code repositories.

## When to Activate

- **New project setup**: When creating a new repository for an existing vault project
- **Documentation initialization**: Setting up CLAUDE.md and ARCHITECTURE.md for first time
- **Major refactor**: When architecture notes in vault need to sync to code repo
- **Onboarding prep**: Creating developer documentation from project knowledge
- **Handoff preparation**: Converting tribal knowledge to formal docs

## What This Skill Does

Vault-to-Code Bridge synchronizes your project planning and architecture notes from Obsidian into structured documentation in your code repositories. It transforms loose notes into developer-friendly formats.

**Key Transformations:**
- Vault project notes → CLAUDE.md (developer guide)
- Architecture notes → ARCHITECTURE.md (system overview, regenerable)
- Architecture decisions → `docs/adr/NNNN-slug.md` (one immutable file per ADR)
- Backlog tasks → README features section
- Build notes → Package scripts documentation
- Design patterns → Code conventions guide

## Architecture Decision Records

ADRs do **not** live in `ARCHITECTURE.md`. That file is regenerated from vault notes on every
run, and regeneration would silently overwrite decisions — but an accepted ADR is immutable.

Each decision gets its own file at `docs/adr/NNNN-slug.md`, following the house standard in the
**`adr-standard`** skill: Status, Problem Statement, Considered Options with pros and cons,
Decision, Consequences.

Two rules this skill enforces:

- **Append-only.** An ADR file that already exists is never rewritten. Re-running generation
  scaffolds only decisions that have no file yet, and reports the rest as left untouched.
- **Numbers are never reused,** even when an ADR is superseded or withdrawn. The next number is
  always highest-existing + 1.

To change a decision, write a new ADR that supersedes the old one and edit only the old file's
Status line. Never edit the vault note and regenerate expecting the ADR to update — it won't,
by design.

Scaffolded ADRs land with `Status: Proposed` and the raw vault text under Problem Statement.
Shape them into the house sections before accepting them; `domain-modeling` is the skill for
that conversation.

**2-Phase Workflow:**

1. **Scan Vault Projects Phase**: Map vault projects to code repositories
2. **Generate Docs Phase**: Transform vault content into repo documentation

## Configuration

Edit `config.json` to customize behavior:

```json
{
  "vault_path": "/Users/hackastak/Developer/My_Notes/1. Projects/",
  "repos_root": [
    "/Users/hackastak/Developer/PROJECTS",
    "/Users/hackastak/Developer/SMILESTACKLABS"
  ],
  "templates_path": "./templates/",
  "auto_match_threshold": 0.8,
  "dry_run": true
}
```

**Parameters:**
- `vault_path`: Location of vault projects directory
- `repos_root`: Directories containing code repositories
- `templates_path`: Path to documentation templates
- `auto_match_threshold`: Confidence needed for automatic vault↔repo matching (0.0-1.0)
- `dry_run`: Preview changes without writing files

## Usage

### Quick Start

```bash
# Scan vault and match to repos
cd ~/Developer/Staksmith/skills/vault-to-code-bridge
./scripts/scan-vault-projects.sh

# Generate documentation
./scripts/generate-docs.sh
```

### Selective Generation

Generate docs for specific project:

```bash
./scripts/generate-docs.sh --project "OMS_Athena"
```

### Integration with Claude Code

When invoked through Claude Code:
1. Scans all vault projects
2. Fuzzy-matches project names to repository names
3. Presents matching suggestions for approval
4. Generates CLAUDE.md, ARCHITECTURE.md, updates README
5. Shows preview diffs before writing

## Examples

### Example 1: CLAUDE.md Generation

**Vault Input** (`1. Projects/OMS_Athena/Backlog.md`):
```markdown
# OMS Athena

## Tech Stack
- Next.js 14 (App Router)
- Drizzle ORM + PostgreSQL
- Fastify backend
- Redis caching

## Build Notes
- Uses turbo for monorepo
- Dev: `npm run dev`
- Build: `npm run build`
- Tests: `npm test`

## Architecture Principles
- API routes in app/api/
- Database in separate service layer
- No inline SQL, use Drizzle queries
```

**Generated CLAUDE.md**:
```markdown
# CLAUDE.md - Developer Guide for OMS Athena

## Build & Test Commands

```bash
# Development
npm run dev

# Build
npm run build

# Tests
npm test
```

## Tech Stack

- **Framework**: Next.js 14 (App Router)
- **Database**: PostgreSQL via Drizzle ORM
- **Backend**: Fastify
- **Cache**: Redis
- **Monorepo**: Turborepo

## Code Style & Conventions

### API Routes
Place all API routes in `app/api/` directory following Next.js App Router conventions.

### Database Access
- Use Drizzle ORM for all database operations
- Never write inline SQL
- Database logic belongs in service layer, not routes

## Architecture Overview

Layered architecture:
- Presentation: Next.js App Router
- API: Fastify routes
- Service Layer: Business logic
- Data Layer: Drizzle ORM

## Strict Constraints

- ❌ No inline SQL queries
- ✅ All DB access through Drizzle
- ✅ Separate service layer for business logic
```

### Example 2: ARCHITECTURE.md Generation

**Vault Input** (`1. Projects/BillScribe/Architecture.md`):
```markdown
# Architecture Decisions

## ADR-001: PDF Generation Strategy
- Decision: Use Puppeteer for PDF generation
- Rationale: Need HTML→PDF with custom styling
- Alternatives considered: jsPDF (too limited), PDFKit (complex)
- Consequences: Requires headless Chrome in production

## ADR-002: Invoice Storage
- Decision: Store as JSON in PostgreSQL jsonb column
- Rationale: Flexible schema, queryable, version history
- Trade-off: Slightly slower than normalized tables
```

**Generated ARCHITECTURE.md** (regenerable — index only, no ADR bodies):
```markdown
# Architecture - BillScribe

## System Overview

BillScribe is an invoice generation and management system with PDF export capabilities.

## Architecture Decision Records

ADRs are not stored in this file. This document is regenerated from vault notes, and
regeneration would overwrite them — accepted ADRs are immutable. Each decision lives in
its own file under `docs/adr/`, following the house standard (see the `adr-standard`
skill). The index below is safe to regenerate.

- [ADR-0001: PDF Generation Strategy](docs/adr/0001-pdf-generation-strategy.md)
- [ADR-0002: Invoice Storage](docs/adr/0002-invoice-storage.md)
```

**Generated `docs/adr/0001-pdf-generation-strategy.md`** (immutable once accepted):
```markdown
# ADR-0001: PDF Generation Strategy

**Status:** Accepted
**Date:** 2026-04-07

## Problem Statement

Invoices must be generated as PDFs with custom branding and styling. Rendering has to be
consistent across platforms, and the team needs to preview output before generating.

## Considered Options

### Option A — Puppeteer (headless Chrome)

**Pros:** Full control over styling via HTML/CSS; consistent cross-platform rendering; previewable.
**Cons:** Requires headless Chrome in production; higher resource usage per render.

### Option B — jsPDF

**Pros:** Pure JS, no browser dependency, light runtime.
**Cons:** Limited styling; the branded layout is not achievable without heavy manual positioning.

### Option C — PDFKit

**Pros:** Fine-grained control; no browser dependency.
**Cons:** Low-level API; templating the invoice layout is substantially more work to build and maintain.

## Decision

Use Puppeteer. It beat PDFKit because the invoice layout is fundamentally a styled document,
and expressing it in HTML/CSS is far cheaper to build and change than positioning primitives.

## Consequences

- Flexible templating; styling changes are CSS changes.
- Production must ship headless Chrome, which enlarges the deployment image.
- Render cost per invoice is higher; batch generation needs a queue rather than inline requests.
- Swapping renderers later means rewriting the templates, so this is hard to reverse.
```

### Example 3: README Update

**Vault Input** (tasks from Backlog.md):
```markdown
- [x] User authentication ✅ 2026-03-15
- [x] Invoice creation ✅ 2026-03-20
- [x] PDF export ✅ 2026-04-01
- [ ] Email delivery
- [ ] Recurring billing
```

**Generated README Section**:
```markdown
## Features

### Implemented
- ✅ User authentication and authorization
- ✅ Invoice creation and editing
- ✅ PDF export with custom templates

### Planned
- 🚧 Email delivery for invoices
- 🚧 Recurring billing support
```

## Outputs

### Generated Files

For each matched project:
- `CLAUDE.md` - Developer onboarding guide
- `ARCHITECTURE.md` - System overview, components, data flow, ADR index (regenerated each run)
- `docs/adr/NNNN-slug.md` - One file per decision (append-only; existing files never rewritten)
- `README.md` (updated) - Features, tech stack, project structure

### Mapping Cache

Saves project-to-repo mappings:
```json
{
  "OMS_Athena": {
    "vault_path": "/Users/hackastak/Developer/My_Notes/1. Projects/OMS_Athena",
    "repo_path": "/Users/hackastak/Developer/PROJECTS/oms-athena",
    "confidence": 0.95,
    "match_method": "fuzzy_name"
  }
}
```

Cached at: `~/.claude/homunculus/vault-to-code-bridge/project-mappings.json`

## Tuning Tips

**Improve Matching Accuracy**:
- Use consistent naming between vault and repos
- Add explicit mappings to config:
```json
{
  "manual_mappings": {
    "OMS_Athena": "oms-athena",
    "SmileStack Site": "smilestacklabs-site"
  }
}
```

**Customize Templates**:
Edit `templates/CLAUDE.template.md` to match your team's preferences.

**Selective Sync**:
Only sync specific sections:
```json
{
  "sync_sections": ["build_commands", "tech_stack", "architecture"]
}
```

## Troubleshooting

**Issue**: Project not matched to repository

**Solution**: Add manual mapping in config.json or reduce `auto_match_threshold`.

**Issue**: Generated CLAUDE.md missing sections

**Solution**: Ensure vault notes use recognized headers:
- "Tech Stack" or "Technology Stack"
- "Build" or "Build Commands"
- "Architecture" or "Architecture Principles"

**Issue**: Templates not found

**Solution**: Verify `templates_path` in config points to correct directory. Templates should be in `skills/vault-to-code-bridge/templates/`.

## Dependencies

- `jq`: JSON parsing
- Obsidian vault with PARA structure
- Claude AI access: For intelligent content transformation

## Smart Features

### Fuzzy Matching

Matches vault projects to repos even with naming variations:
- `OMS_Athena` ↔ `oms-athena`
- `SmileStack Site` ↔ `smilestacklabs-site`
- `BillScribe` ↔ `billscribe-app`

### Semantic Extraction

AI understands intent, not just keywords:
- Recognizes architecture decisions even without "ADR" label
- Extracts constraints from various note formats
- Infers tech stack from dependencies and descriptions

### Incremental Updates

Only regenerates changed sections:
- Preserves manual edits in marked regions
- Merges new content with existing docs
- Tracks generation timestamps

## Templates

### CLAUDE.template.md Structure

```markdown
# CLAUDE.md - Developer Guide

## Build & Test Commands
[EXTRACTED]

## Tech Stack
[EXTRACTED]

## Code Style & Conventions
[EXTRACTED]

## Architecture Overview
[EXTRACTED]

## Strict Constraints
[EXTRACTED]
```

### ARCHITECTURE.template.md Structure

```markdown
# Architecture

## System Overview
[EXTRACTED]

## Architecture Decision Records
[ADR_INDEX]          ← links to docs/adr/ only; never ADR bodies

## Key Design Patterns
[EXTRACTED]

## Data Flow
[EXTRACTED]
```

Every section here is regenerated on each run, which is exactly why ADR bodies are excluded.

## Integration Points

### With Other Skills

- **code-to-docs-sync**: Keep generated docs in sync after changes
- **weekly-momentum-report**: Track documentation coverage
- **skill-auto-extractor**: Learn common documentation patterns

### With Vault Commands

- **/sync**: Triggered by vault updates
- **/inbox**: New project notes trigger doc generation

## Related Skills

- **adr-standard**: The house ADR format and the supersede-don't-edit rule this skill writes against
- **domain-modeling**: Shapes scaffolded ADRs into the house sections; maintains `CONTEXT.md`
- **code-to-docs-sync**: Ongoing synchronization
- **/sync**: Vault synchronization
- **inbox-gradient-accelerator**: Organize project notes
