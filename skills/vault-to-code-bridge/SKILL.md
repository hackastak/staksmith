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
- Architecture decisions → ARCHITECTURE.md (ADRs)
- Backlog tasks → README features section
- Build notes → Package scripts documentation
- Design patterns → Code conventions guide

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

**Generated ARCHITECTURE.md**:
```markdown
# Architecture - BillScribe

## System Overview

BillScribe is an invoice generation and management system with PDF export capabilities.

## Architecture Decision Records

### ADR-001: PDF Generation Strategy

**Status**: Accepted
**Date**: 2026-04-07

**Context**: Need to generate professional invoices as PDF files with custom branding and styling.

**Decision**: Use Puppeteer for HTML-to-PDF conversion.

**Rationale**:
- Full control over styling via HTML/CSS
- Consistent rendering across platforms
- Can preview before generating PDF

**Alternatives Considered**:
- jsPDF: Limited styling capabilities
- PDFKit: Low-level API, complex for templating

**Consequences**:
- ⊕ Flexible templating system
- ⊕ Easy styling with CSS
- ⊖ Requires headless Chrome in production environment
- ⊖ Slightly higher resource usage

### ADR-002: Invoice Storage

**Status**: Accepted
**Date**: 2026-04-07

**Context**: Need flexible invoice schema that can evolve without migrations.

**Decision**: Store invoices as JSON in PostgreSQL JSONB column.

**Rationale**:
- Schema flexibility for custom fields
- Still queryable via PostgreSQL JSON operators
- Built-in version history via immutable records

**Trade-offs**:
- ⊕ No migration needed for schema changes
- ⊕ Queryable with PostgreSQL JSON functions
- ⊖ Slightly slower than normalized tables for complex queries
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
- `ARCHITECTURE.md` - Architecture decisions and system overview
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
[EXTRACTED]

## Key Design Patterns
[EXTRACTED]

## Data Flow
[EXTRACTED]
```

## Integration Points

### With Other Skills

- **code-to-docs-sync**: Keep generated docs in sync after changes
- **weekly-momentum-report**: Track documentation coverage
- **skill-auto-extractor**: Learn common documentation patterns

### With Vault Commands

- **/sync**: Triggered by vault updates
- **/inbox**: New project notes trigger doc generation

## Related Skills

- **code-to-docs-sync**: Ongoing synchronization
- **/sync**: Vault synchronization
- **inbox-gradient-accelerator**: Organize project notes
