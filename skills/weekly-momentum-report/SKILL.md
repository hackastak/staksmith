# Weekly Momentum Report Generator

Aggregate project status from git repos, vault tasks, and GitHub for comprehensive weekly reviews.

## When to Activate

- **Friday EOD**: Weekly ritual before weekend to review accomplishments
- **Sunday Planning**: Prepare for the upcoming week with context on current momentum
- **Monthly Reviews**: Generate monthly roll-ups from weekly reports
- **Standup Prep**: Quick context for team meetings
- **Performance Reviews**: Historical record of deliverables

## What This Skill Does

The Weekly Momentum Report Generator scans your development environment (25+ repositories) and Obsidian vault to create a comprehensive weekly status report. It combines:

- **Git Activity**: Commits, branches, uncommitted work across all repos
- **Vault Tasks**: Completed and pending items from project backlogs
- **Package Versions**: Track releases and version bumps
- **Executive Summary**: AI-generated insights on momentum and blockers

**3-Phase Workflow:**

1. **Scan Repos Phase**: Inventory git activity across all repositories
2. **Scan Vault Tasks Phase**: Parse completed/pending tasks from Obsidian
3. **Generate Report Phase**: Synthesize findings into formatted weekly note

## Configuration

Edit `config.json` to customize behavior:

```json
{
  "repos_root": [
    "/Users/hackastak/Developer/PROJECTS",
    "/Users/hackastak/Developer/SMILESTACKLABS"
  ],
  "vault_path": "/Users/hackastak/Developer/My_Notes",
  "author_name": "hackastak",
  "days_back": 7,
  "output_format": "markdown"
}
```

**Parameters:**
- `repos_root`: Array of directories containing git repositories
- `vault_path`: Root of Obsidian vault
- `author_name`: Git author name to filter commits
- `days_back`: Number of days to look back (default: 7)
- `output_format`: "markdown" or "slide_deck"

## Usage

### Quick Start

```bash
# Generate report for current week
cd ~/Developer/Staksmith/skills/weekly-momentum-report
./scripts/scan-repos.sh
./scripts/scan-vault-tasks.sh
./scripts/generate-report.sh
```

### Integration with Claude Code

When invoked through Claude Code, the skill will:
1. Automatically scan all configured repositories
2. Parse vault tasks for the specified time period
3. Generate AI-powered insights
4. Create/update the weekly note in your vault
5. Present a summary of key accomplishments and blockers

### Automation

Set up weekly automation via launchd:

```bash
# Create launchd plist at ~/Library/LaunchAgents/
# Run every Friday at 5 PM
```

## Examples

### Example Report Output

```markdown
# 2026-W14 - Weekly Review

## Highlights
- ✅ Shipped OMS v2.1 with authentication refactor
- ✅ Completed BillScribe PDF generation feature
- ✅ Migrated 3 projects to Drizzle ORM

## Commits by Repository

### OMS_Athena (8 commits)
- feat: add JWT refresh token rotation
- fix: session timeout handling
- docs: update API authentication guide
- test: add auth integration tests

### BillScribe (5 commits)
- feat: PDF generation with custom templates
- fix: invoice calculation rounding errors
- refactor: extract PDF service

### SmileStackLabs/site (2 commits)
- content: add blog post on AI workflows
- fix: mobile navigation styling

## Vault Tasks Completed (12)

### OMS_Athena
- [x] Design JWT refresh strategy ✅ 2026-04-05
- [x] Implement session expiry handling ✅ 2026-04-06
- [x] Write API security documentation ✅ 2026-04-07

### BillScribe
- [x] Research PDF generation libraries ✅ 2026-04-04
- [x] Build template system ✅ 2026-04-06
- [x] Add invoice preview feature ✅ 2026-04-07

## Pending Tasks (8)

### OMS_Athena
- [ ] Deploy v2.1 to staging
- [ ] Conduct security audit
- [ ] Setup monitoring alerts

### BillScribe
- [ ] Add email delivery for invoices
- [ ] Implement recurring billing

## Blockers & Challenges
- Waiting on design feedback for BillScribe dashboard
- OMS staging environment needs database migration

## Next Week Priorities
1. Complete OMS v2.1 staging deployment
2. Security audit and penetration testing
3. BillScribe email integration
4. Blog post publication

## Metrics
- Total commits: 15 across 3 active projects
- Tasks completed: 12
- Active branches: 6
- Repos with uncommitted changes: 2
```

## Outputs

### Weekly Note

Automatically creates/updates: `~/Developer/My_Notes/_Weekly/{YYYY}/{YYYY-WXX.md}`

Uses the existing weekly note template structure.

### Cache Files

Intermediate data saved for inspection:
- `~/.claude/homunculus/weekly-momentum-report/repos-scan.json`
- `~/.claude/homunculus/weekly-momentum-report/tasks-scan.json`
- `~/.claude/homunculus/weekly-momentum-report/last-report.json`

## Tuning Tips

**Adjust Time Window**:
- For bi-weekly reviews: `"days_back": 14`
- For monthly: `"days_back": 30`

**Filter Repositories**:
Add `"exclude_repos"` array to config:
```json
{
  "exclude_repos": ["archived-project", "sandbox"]
}
```

**Custom Report Sections**:
Edit `scripts/generate-report.sh` to modify report structure.

## Troubleshooting

**Issue**: No commits found for your username

**Solution**: Verify `author_name` in config.json matches your git config:
```bash
git config user.name
```

**Issue**: Vault tasks not detected

**Solution**: Ensure tasks use Obsidian Tasks format:
```markdown
- [ ] Task description
- [x] Completed task ✅ YYYY-MM-DD
```

**Issue**: Weekly note path not found

**Solution**: Check vault structure has `_Weekly/{YYYY}/` directory. Script will create if missing.

## Dependencies

- `jq`: JSON parsing
- `git`: Repository scanning
- `bc`: Date calculations
- Claude AI access: For summary generation

## Integration Points

### GitHub Integration (Optional)

Add GitHub MCP server for enhanced data:
- Pull request status
- Issue tracking
- Code review metrics

### Vault Integration

Reads from:
- `1. Projects/*/Backlog.md`
- `1. Projects/*/Tasks.md`

Writes to:
- `_Weekly/{YYYY}/{YYYY-WXX.md}`

## Related Skills

- **/sync**: Synchronize vault with external data
- **code-to-docs-sync**: Keep documentation current
- **vault-to-code-bridge**: Connect vault notes to code repos
