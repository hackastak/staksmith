# AI-Powered Code-to-Docs Sync

Detect drift between code and documentation (READMEs, CLAUDE.md, API docs), propose automated fixes.

## When to Activate

- **Post-merge**: After merging PRs to main branch (via git hook)
- **Weekly audit**: Regular documentation health checks
- **Pre-release**: Before cutting releases to ensure docs are current
- **On-demand**: When you suspect documentation is stale
- **CI/CD integration**: Automated checks in deployment pipeline

## What This Skill Does

Code-to-Docs Sync monitors your repositories for documentation drift - when code changes but documentation doesn't keep up. It automatically detects mismatches and proposes specific fixes.

**Common Drift Patterns Detected:**
- README tech stack vs package.json dependencies
- CLAUDE.md build commands vs package.json scripts
- API documentation vs actual route definitions
- Architecture docs vs code structure
- Stale "last updated" dates

**3-Phase Workflow:**

1. **Detect Drift Phase**: Scan docs and code for inconsistencies
2. **Analyze Drift Phase**: AI-powered analysis of what changed and why
3. **Sync Docs Phase**: Apply approved fixes, preserving manual content

## Configuration

Edit `config.json` to customize behavior:

```json
{
  "repos_root": [
    "/Users/hackastak/Developer/PROJECTS",
    "/Users/hackastak/Developer/SMILESTACKLABS"
  ],
  "watch_files": ["README.md", "CLAUDE.md", "CONTRIBUTING.md", "docs/*.md"],
  "ignore_repos": [],
  "auto_commit": false,
  "staleness_threshold_days": 30
}
```

**Parameters:**
- `repos_root`: Directories to scan for repositories
- `watch_files`: Documentation files to monitor (supports globs)
- `ignore_repos`: Repositories to skip
- `auto_commit`: Auto-commit fixes (default: false, requires approval)
- `staleness_threshold_days`: Flag docs not updated in N days

## Usage

### Quick Start

```bash
# Detect drift across all repos
cd ~/Developer/Staksmith/skills/code-to-docs-sync
./scripts/detect-drift.sh

# Analyze detected drift
./scripts/analyze-drift.sh

# Apply fixes (interactive)
./scripts/sync-docs.sh
```

### Integration with Git Hooks

Add to `.git/hooks/post-merge`:

```bash
#!/bin/bash
# Auto-check docs after merging
~/Developer/Staksmith/skills/code-to-docs-sync/scripts/detect-drift.sh
```

### CI/CD Integration

Add to GitHub Actions workflow:

```yaml
- name: Check Documentation Drift
  run: |
    ~/Developer/Staksmith/skills/code-to-docs-sync/scripts/detect-drift.sh
    if [ $? -ne 0 ]; then
      echo "::warning::Documentation drift detected"
    fi
```

## Examples

### Example 1: Tech Stack Drift

**Detected Drift**:
```json
{
  "repo": "OMS_Athena",
  "file": "README.md",
  "drift_type": "outdated",
  "section": "Tech Stack",
  "details": "README lists Express but package.json uses Fastify"
}
```

**Proposed Fix**:
```diff
## Tech Stack

- Node.js 20+
-- Express.js
+- Fastify
- PostgreSQL
- Redis
```

### Example 2: Build Commands Drift

**Detected Drift**:
```json
{
  "repo": "BillScribe",
  "file": "CLAUDE.md",
  "drift_type": "incorrect",
  "section": "Build Commands",
  "details": "CLAUDE.md shows 'npm run build' but script is 'npm run compile'"
}
```

**Proposed Fix**:
```diff
## Build Commands

-npm run build
+npm run compile
```

### Example 3: Missing API Endpoints

**Detected Drift**:
```json
{
  "repo": "OMS_Athena",
  "file": "docs/API.md",
  "drift_type": "missing",
  "section": "Endpoints",
  "details": "New /api/auth/refresh endpoint not documented"
}
```

**Proposed Fix**:
```markdown
### POST /api/auth/refresh

Refresh JWT access token using refresh token.

**Request Body:**
```json
{
  "refreshToken": "string"
}
```

**Response:** 200 OK with new access token
```

### Example 4: Stale Documentation

**Detected Drift**:
```json
{
  "repo": "SmileStackLabs/site",
  "file": "README.md",
  "drift_type": "stale",
  "details": "Last modified 45 days ago, code modified 2 days ago"
}
```

**Action**: Flag for manual review

## Outputs

### Drift Report

Saved to `~/.claude/homunculus/code-to-docs-sync/drift-report.json`:

```json
{
  "scan_date": "2026-04-07T10:30:00Z",
  "repositories_scanned": 12,
  "drift_detected": 5,
  "drift_items": [
    {
      "repo": "OMS_Athena",
      "file": "README.md",
      "drift_type": "outdated",
      "severity": "medium",
      "auto_fixable": true
    }
  ]
}
```

### Fix Preview

Before applying changes, generates side-by-side diff showing:
- Current documentation state
- Proposed changes
- Rationale for each change

## Tuning Tips

**Adjust Staleness Threshold**:
- For active projects: `"staleness_threshold_days": 14`
- For stable projects: `"staleness_threshold_days": 90`

**Focus on Critical Docs**:
```json
{
  "watch_files": ["README.md", "CLAUDE.md"]
}
```

**Auto-Fix Safe Changes**:
```json
{
  "auto_commit": true,
  "auto_fix_types": ["version_bump", "dependency_list"]
}
```

## Troubleshooting

**Issue**: False positives for manual documentation

**Solution**: Add ignore comments to preserve sections:
```markdown
<!-- sync:ignore -->
This section is manually maintained
<!-- /sync:ignore -->
```

**Issue**: Can't detect API routes

**Solution**: Configure route detection patterns in `detect-drift.sh`:
```bash
# For Next.js App Router
ROUTE_PATTERN="app/api/**/*.ts"

# For Express
ROUTE_PATTERN="src/routes/**/*.ts"
```

**Issue**: Proposed fixes are incorrect

**Solution**: Review and reject fixes. The skill learns from feedback (future enhancement).

## Dependencies

- `jq`: JSON parsing
- `git`: Repository operations
- `diff`: Change detection
- Claude AI access: For intelligent drift analysis

## Smart Features

### Semantic Analysis

Uses AI to understand intent, not just text matching:
- Recognizes synonyms ("build" vs "compile")
- Understands context (dev vs prod commands)
- Preserves formatting and style

### Safe Editing

- Never overwrites manually-maintained sections
- Preserves custom formatting
- Creates backups before modifying files
- Atomic commits (all-or-nothing)

### Learning Mode (Future)

Track which fixes are accepted/rejected to improve suggestions:
```json
{
  "learning_enabled": true,
  "feedback_log": "~/.claude/homunculus/code-to-docs-sync/feedback.jsonl"
}
```

## Integration Points

### With Other Skills

- **vault-to-code-bridge**: Generate initial docs
- **weekly-momentum-report**: Include docs health in reports
- **skill-auto-extractor**: Learn common drift patterns

### With MCP Servers

- GitHub MCP: Check PR descriptions match code
- Memory MCP: Remember repo-specific preferences

## Related Skills

- **/review-pr**: Include docs checks in PR reviews
- **vault-to-code-bridge**: Sync vault notes to code docs
- **weekly-momentum-report**: Track docs maintenance

## Git Integration

### Automatic Commits

When `auto_commit: true`:

```bash
git add README.md
git commit -m "docs: sync tech stack with package.json

- Update framework name
- Add new dependencies
- Remove deprecated tools

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

### Pre-commit Hook

Prevent commits with stale docs:

```bash
#!/bin/bash
# .git/hooks/pre-commit
if ~/path/to/detect-drift.sh --strict; then
  exit 0
else
  echo "Documentation drift detected. Run sync-docs.sh first."
  exit 1
fi
```
