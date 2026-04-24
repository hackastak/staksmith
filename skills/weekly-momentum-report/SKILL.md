# Weekly Momentum Report Generator

Aggregate project status from git repos, vault tasks, and GitHub for comprehensive weekly reviews.

## When to Activate

- **Friday EOD**: Weekly ritual before weekend to review accomplishments
- **Sunday Planning**: Prepare for the upcoming week with context on current momentum
- **Monthly Reviews**: Generate monthly roll-ups from weekly reports
- **Standup Prep**: Quick context for team meetings
- **Performance Reviews**: Historical record of deliverables

## What This Skill Does

The Weekly Momentum Report Generator scans your development environment (25+ repositories) and Obsidian vault to create a comprehensive weekly status report. The report uses a **narrative summary format** rather than listing individual tasks, providing a readable overview of what was accomplished, learned, and blocked.

**Key Features:**
- **Narrative Summaries**: Project-by-project breakdown of work done, decisions made, and progress achieved
- **Learning Capture**: Documents new knowledge, technologies explored, and insights gained
- **Blocker Tracking**: Records challenges, platform issues, and architectural concerns
- **Git Changelog**: Automated commit aggregation from all configured repositories
- **Metrics Dashboard**: Commit counts, active projects, and task statistics

**3-Phase Workflow:**

1. **Scan Repos Phase**: Inventory git activity across all repositories
2. **Scan Vault Tasks Phase**: Parse completed/pending tasks from Obsidian backlogs
3. **Generate Report Phase**: Create scaffold with metrics and changelogs; Claude fills narrative sections from daily journal

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
# 2026-W16 - Weekly Momentum Report

Generated: 2026-04-19 17:00

---

## Highlights
- Shipped ProtoFlow admin panel with full user management, request tracking, and dashboard overview
- Added design-only subscription tiers to ProtoFlow, expanding the service offering with lower-overhead options
- Fixed critical error handling and null check issues in the OMS transferFailureAgent for BETA release
- Added GitHub PAT rotation support to RepoG (v0.2.3)

## Summary

**SAP/OMS**: Focused on stabilizing the transferFailureAgent for BETA release. Discovered that Gemini 2.5 Flash Lite was hallucinating tool parameters outside the defined schema, causing silent failures. Fixed by adding proper null checks and error handling to the fetchFailedDispatchTasks tool. Started investigating a deeper architectural issue with capability context variables - the manual review agent re-fetches dispatch tasks instead of pulling from context, causing state drift. Joule platform outages on Wednesday and Thursday blocked progress.

**ProtoFlow**: Major UI milestone - completed the entire admin panel (layout, dashboard, request management, user management). Pivoted strategy to add design-only subscription plans after realizing design services have the lowest overhead and likely highest accessibility. Set up all Stripe products (Creator, Studio, Maker, Production) and integrated keys into the codebase.

**RepoG**: Released v0.2.3 with GitHub PAT rotation support and fixed the SYNC command chunk_type constraint error for partitioned repositories.

## Learning & New Ideas
- **OpenClaw**: Deep-diving into computer-use automation. Considering use cases for sales/marketing automation and potentially running vault skills autonomously. Set up AgentMail account and bought Udemy course.
- **Design services accessibility**: Realized design-only plans may be more sellable than full manufacturing services due to lower barrier to entry for customers
- **Agent context management**: Context variables in Joule are more fragile than expected - need to think through state management patterns for multi-step agent workflows

## Blockers & Challenges
- Joule platform outages (Wed afternoon, Thu morning) blocked OMS agent testing
- Gemini model hallucinating tool parameters not in schema
- Context variable state management in transferFailureAgent needs architectural review

## Metrics
- **Commits**: 7 (ProtoFlow: 6, RepoG: 1)
- **Active projects**: 3 (ProtoFlow, OMS_Athena, RepoG)

---

## Changelog

### ProtoFlow
- chore: add .env.example and update Agency annual pricing (2026-04-18)
- feat: add design-only subscription tiers with Designer and Agency plans (2026-04-16)
- feat: add monthly material weight limits and update subscription pricing (2026-04-14)
- feat: add polish features with loading states, mobile nav, and profile management (2026-04-13)
- feat: add admin panel with user, request, and inquiry management (2026-04-13)
- feat: restructure subscription tiers into all-inclusive and print-only categories (2026-04-13)

### RepoG
- fix: support partitioned chunks and add github token rotation (2026-04-19)
```

## Report Sections

The momentum report contains these sections:

1. **Highlights** - Top 3-4 accomplishments. Focus on shipped features, milestones, and significant progress. Written as bullet points.

2. **Summary** - Narrative breakdown by project area. Describes what was worked on, decisions made, technical details, and progress achieved. Claude synthesizes this from the daily journal entries in the weekly note.

3. **Learning & New Ideas** - New knowledge, insights, technologies explored, or ideas that emerged. Captures growth and exploration beyond task completion.

4. **Blockers & Challenges** - Issues faced, platform problems, architectural concerns, or anything that slowed progress. Useful for retrospectives and planning.

5. **Metrics** - Quantitative summary: commit counts, active projects, task statistics. Auto-generated from cached scan data.

6. **Changelog** - Git commits grouped by repository. Auto-generated from the repos scan. Includes SAP repo command templates for manual population.

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
