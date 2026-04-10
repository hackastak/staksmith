# Staksmith Skills - Workflow Automation Suite

This directory contains 5 custom AI skills designed to automate workflows across your Obsidian vault (My_Notes) and 25+ development repositories.

## Skills Overview

### 1. Inbox Gradient Accelerator
**Location**: `inbox-gradient-accelerator/`

Auto-classify and organize vault inbox items based on AI content analysis.

**Use Cases:**
- Nightly automation for continuous inbox maintenance
- On-demand when inbox has 10+ unprocessed items
- Post-capture to immediately organize new notes
- Weekly review prep

**Key Features:**
- Scans `0. Inbox/` for unprocessed notes
- AI classification into PARA categories (Projects/Areas/Resources)
- Auto-moves high-confidence items (≥70%)
- Tags uncertain items with `#needs-review`

**Quick Start:**
```bash
cd inbox-gradient-accelerator
./scripts/scan-inbox.sh
./scripts/classify.sh
./scripts/organize.sh
```

---

### 2. Weekly Momentum Report Generator
**Location**: `weekly-momentum-report/`

Aggregate project status from git repos, vault tasks, and GitHub for weekly reviews.

**Use Cases:**
- Friday EOD weekly review ritual
- Sunday planning sessions
- Monthly roll-ups
- Standup prep

**Key Features:**
- Scans all repos for commits (last 7 days)
- Parses completed/pending tasks from vault backlogs
- Tracks uncommitted changes
- Generates markdown report in `_Weekly/{YYYY}/{YYYY-WXX.md}`

**Quick Start:**
```bash
cd weekly-momentum-report
./scripts/scan-repos.sh
./scripts/scan-vault-tasks.sh
./scripts/generate-report.sh
```

---

### 3. Code-to-Docs Sync
**Location**: `code-to-docs-sync/`

Detect and fix documentation drift between code and docs.

**Use Cases:**
- Post-merge checks (git hook integration)
- Weekly documentation audits
- Pre-release verification
- CI/CD pipeline integration

**Key Features:**
- Detects README tech stack vs package.json mismatches
- Verifies CLAUDE.md build commands vs actual scripts
- Checks API docs vs route files
- Flags stale documentation (configurable threshold)

**Quick Start:**
```bash
cd code-to-docs-sync
./scripts/detect-drift.sh
./scripts/analyze-drift.sh
./scripts/sync-docs.sh
```

---

### 4. Vault-to-Code Bridge
**Location**: `vault-to-code-bridge/`

Convert Obsidian vault project notes into CLAUDE.md and ARCHITECTURE.md files in code repos.

**Use Cases:**
- New project setup from vault notes
- Documentation initialization
- Major refactor documentation
- Onboarding prep
- Handoff preparation

**Key Features:**
- Maps vault projects to code repos (fuzzy matching)
- Generates CLAUDE.md from backlog + architecture notes
- Creates ARCHITECTURE.md with ADRs from vault
- Updates README with features from tasks
- Template-based generation (customizable)

**Quick Start:**
```bash
cd vault-to-code-bridge
./scripts/scan-vault-projects.sh
./scripts/generate-docs.sh
```

---

### 5. Skill Auto-Extractor
**Location**: `skill-auto-extractor/`

Mine git history to automatically create reusable skill definitions from repeated workflows.

**Use Cases:**
- Monthly pattern discovery
- Automatic when pattern detected 3+ times
- Post-sprint knowledge capture
- Team knowledge transfer
- Continuous learning integration

**Key Features:**
- Analyzes git commit patterns across all repos
- Detects repeated workflows (framework setup, CI/CD, auth, etc.)
- Generates formal SKILL.md files
- Includes code examples from actual usage
- Saves to `~/.claude/homunculus/evolved/skills/` for review

**Quick Start:**
```bash
cd skill-auto-extractor
./scripts/scan-history.sh
./scripts/detect-patterns.sh
./scripts/generate-skill.sh
```

---

## Architecture

All skills follow a consistent 3-phase pattern inspired by `continuous-learning-v2`:

```
skills/{skill-name}/
├── SKILL.md              # User-facing documentation
├── config.json           # Tunable parameters
└── scripts/
    ├── scan.sh           # Phase 1: Inventory/detection
    ├── analyze.sh        # Phase 2: AI analysis
    └── execute.sh        # Phase 3: Implementation
```

### Configuration Philosophy

Each skill has a `config.json` that allows customization without code changes:
- File paths (vault location, repo roots)
- Thresholds (confidence, frequency, staleness)
- Behavior flags (dry_run, auto_commit)
- Exclusion lists (ignored repos, folders)

### Caching Strategy

All skills cache intermediate results in `~/.claude/homunculus/{skill-name}/`:
- Enables resume capability for long-running operations
- Incremental re-evaluation
- Debugging and inspection
- Performance optimization

### Integration Points

#### Obsidian Vault
- **Read from**: `1. Projects/*/Backlog.md`, `0. Inbox/`, `_Weekly/`
- **Write to**: `_Weekly/{YYYY}/{YYYY-WXX.md}`, organized project folders

#### Git Repositories
- **Scans**: `~/Developer/PROJECTS/`, `~/Developer/SMILESTACKLABS/`
- **Reads**: Commit logs, file changes, package.json
- **Writes**: CLAUDE.md, ARCHITECTURE.md, README.md (when approved)

#### Continuous Learning
- **Evolved skills**: `~/.claude/homunculus/evolved/skills/`
- **Observations**: `~/.claude/homunculus/observations.jsonl` (optional)

---

## Usage

### Invoking via Claude Code

Skills are discoverable through the Skill tool when using Claude Code. Simply reference them by name:

```
User: "Run the inbox gradient accelerator"
Claude: [Invokes inbox-gradient-accelerator skill]
```

### Direct Script Execution

All scripts can be run directly from the command line:

```bash
# Navigate to skill directory
cd ~/Developer/Staksmith/skills/weekly-momentum-report

# Run individual phases
./scripts/scan-repos.sh
./scripts/scan-vault-tasks.sh
./scripts/generate-report.sh

# Or chain them
./scripts/scan-repos.sh && \
./scripts/scan-vault-tasks.sh && \
./scripts/generate-report.sh
```

### Automation

Set up weekly/monthly automation using launchd or cron:

```bash
# Example: Weekly momentum report every Friday at 5 PM
0 17 * * 5 ~/Developer/Staksmith/skills/weekly-momentum-report/scripts/scan-repos.sh

# Example: Inbox accelerator nightly at 11 PM
0 23 * * * ~/Developer/Staksmith/skills/inbox-gradient-accelerator/scripts/scan-inbox.sh
```

---

## Configuration

### Global Settings

Key paths configured across all skills:

```json
{
  "vault_path": "/Users/hackastak/Developer/My_Notes",
  "repos_root": [
    "/Users/hackastak/Developer/PROJECTS",
    "/Users/hackastak/Developer/SMILESTACKLABS"
  ],
  "author_name": "hackastak",
  "cache_path": "~/.claude/homunculus/{skill-name}/"
}
```

### Per-Skill Customization

Each skill's `config.json` can be edited to adjust behavior:

**inbox-gradient-accelerator/config.json:**
```json
{
  "confidence_threshold": 0.7,  // Lower for more auto-moves
  "dry_run": true               // Preview before moving
}
```

**weekly-momentum-report/config.json:**
```json
{
  "days_back": 7,              // Look back period
  "output_format": "markdown"  // or "slide_deck"
}
```

**code-to-docs-sync/config.json:**
```json
{
  "staleness_threshold_days": 30,  // Flag old docs
  "auto_commit": false              // Require manual approval
}
```

**vault-to-code-bridge/config.json:**
```json
{
  "auto_match_threshold": 0.8,  // Fuzzy match confidence
  "dry_run": true,               // Preview before writing
  "manual_mappings": {           // Override fuzzy matching
    "OMS_Athena": "oms-athena"
  }
}
```

**skill-auto-extractor/config.json:**
```json
{
  "min_frequency": 3,            // Pattern must occur 3+ times
  "confidence_threshold": 0.8,   // AI confidence for generation
  "days_back": 30                // History analysis window
}
```

---

## Dependencies

All skills require:
- **jq**: JSON parsing (`brew install jq`)
- **git**: Repository access
- **bc**: Numerical calculations (usually pre-installed)
- **Claude AI access**: For intelligent analysis

Some skills have optional dependencies:
- **ripgrep (rg)**: Fast content searching (recommended)
- **GitHub CLI (gh)**: For enhanced PR/issue integration

---

## Testing

### Verification Checklist

- [x] All 5 skills have complete SKILL.md files
- [x] All supporting scripts are executable
- [x] Config files present and valid JSON
- [x] Cache directories created (`~/.claude/homunculus/`)
- [x] Templates exist (vault-to-code-bridge)
- [x] Scripts use proper error handling (set -euo pipefail)
- [x] JSON outputs are valid

### Manual Testing

Test each skill individually:

```bash
# 1. Inbox Gradient Accelerator
cd inbox-gradient-accelerator
./scripts/scan-inbox.sh | jq '.'

# 2. Weekly Momentum Report
cd weekly-momentum-report
./scripts/scan-repos.sh | jq '.'

# 3. Code-to-Docs Sync
cd code-to-docs-sync
./scripts/detect-drift.sh | jq '.'

# 4. Vault-to-Code Bridge
cd vault-to-code-bridge
./scripts/scan-vault-projects.sh | jq '.'

# 5. Skill Auto-Extractor
cd skill-auto-extractor
./scripts/scan-history.sh | jq '.'
```

---

## Troubleshooting

### Common Issues

**Issue**: Skill scripts not found or not executable

**Solution**:
```bash
chmod +x ~/Developer/Staksmith/skills/*/scripts/*.sh
```

**Issue**: JSON parsing errors

**Solution**: Ensure `jq` is installed: `brew install jq`

**Issue**: Vault path not found

**Solution**: Verify paths in config.json use absolute paths (or correct `~` expansion)

**Issue**: No patterns/repos detected

**Solution**:
- Check date range (increase `days_back`)
- Verify git author name matches (`git config user.name`)
- Lower thresholds (confidence, frequency)

---

## Future Enhancements

### Planned Features

1. **AI-powered classification improvements** (inbox-gradient-accelerator)
   - Learn from user corrections
   - Contextual understanding from wikilinks

2. **GitHub integration** (weekly-momentum-report)
   - Pull request status
   - Issue tracking
   - Code review metrics

3. **Incremental sync** (vault-to-code-bridge)
   - Only update changed sections
   - Preserve manual edits with markers

4. **Pattern composition** (skill-auto-extractor)
   - Combine atomic patterns into workflows
   - Skill deprecation detection

5. **Cross-skill intelligence**
   - Share learned patterns between skills
   - Unified continuous learning feedback loop

### Integration Opportunities

- **MCP Servers**: GitHub, Memory, File System
- **Git Hooks**: Post-commit, pre-push automation
- **CI/CD**: Documentation drift checks in pipelines
- **Obsidian Plugins**: Direct vault integration

---

## Contributing

### Adding New Skills

Follow the established pattern:

```bash
# 1. Create skill directory
mkdir -p ~/Developer/Staksmith/skills/my-new-skill/scripts

# 2. Add SKILL.md with frontmatter
# 3. Create config.json
# 4. Implement 3-phase scripts (scan → analyze → execute)
# 5. Make scripts executable
# 6. Add to this README
```

### Skill Quality Standards

- ✅ Clear activation triggers in SKILL.md
- ✅ Tunable parameters in config.json
- ✅ Dry-run mode for destructive operations
- ✅ JSON outputs for composability
- ✅ Error handling with meaningful messages
- ✅ Cache/resume capability for long operations
- ✅ Examples and troubleshooting in docs

---

## License

These skills are part of the Staksmith project and follow the same license.

## Acknowledgments

Built on patterns from:
- `continuous-learning-v2` - Learning framework
- `skill-stocktake` - Caching patterns
- `security-review` - Simple skill structure
- Obsidian PARA methodology
- Claude Code skill system

---

**Last Updated**: 2026-04-08
**Version**: 1.0.0
**Author**: hackastak
