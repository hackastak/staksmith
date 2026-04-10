# Skill Auto-Extractor from Patterns

Mine git history and session logs to automatically create reusable skill definitions from repeated workflows.

## When to Activate

- **Monthly review**: Regular skill discovery from accumulated work
- **Pattern threshold**: Automatically when same workflow detected 3+ times
- **Post-sprint**: After completing a development cycle
- **Knowledge capture**: Before team member transitions
- **Continuous learning**: Integrated with homunculus evolution system

## What This Skill Does

Skill Auto-Extractor analyzes your development patterns across all repositories and identifies workflows that you repeat frequently. It then generates formal skill definitions that can be reused, shared, and automated.

**Patterns Detected:**
- Repeated commit sequences (e.g., "add Drizzle to Next.js" done 3+ times)
- Common file modifications patterns
- Frequent bash command sequences
- Architecture decisions applied across projects
- Testing workflows
- Deployment patterns

**3-Phase Workflow:**

1. **Scan History Phase**: Extract patterns from git logs and session transcripts
2. **Detect Patterns Phase**: AI-powered analysis to identify reusable workflows
3. **Generate Skill Phase**: Create formal SKILL.md files with step-by-step guides

## Configuration

Edit `config.json` to customize behavior:

```json
{
  "repos_root": [
    "/Users/hackastak/Developer/PROJECTS",
    "/Users/hackastak/Developer/SMILESTACKLABS"
  ],
  "days_back": 30,
  "min_frequency": 3,
  "confidence_threshold": 0.8,
  "output_path": "~/.claude/homunculus/evolved/skills/",
  "session_logs_path": "~/.claude/homunculus/observations.jsonl"
}
```

**Parameters:**
- `repos_root`: Directories to scan for git repositories
- `days_back`: How far back to analyze commit history
- `min_frequency`: Minimum times a pattern must appear
- `confidence_threshold`: AI confidence needed to generate skill (0.0-1.0)
- `output_path`: Where to save generated skills (pending review)
- `session_logs_path`: Optional path to Claude Code session logs

## Usage

### Quick Start

```bash
# Scan git history for patterns
cd ~/Developer/Staksmith/skills/skill-auto-extractor
./scripts/scan-history.sh

# Detect reusable patterns
./scripts/detect-patterns.sh

# Generate skill definitions
./scripts/generate-skill.sh
```

### Integration with Continuous Learning

Automatically discovers skills:
```bash
# Run monthly via cron
0 0 1 * * ~/Developer/Staksmith/skills/skill-auto-extractor/scripts/scan-history.sh
```

### Review Generated Skills

Before promoting to global skills:
```bash
# Review pending skills
ls ~/.claude/homunculus/evolved/skills/

# Promote approved skill
cp -r ~/.claude/homunculus/evolved/skills/add-drizzle-to-nextjs \
     ~/.claude/skills/
```

## Examples

### Example 1: Detected Pattern - "Add Drizzle ORM to Next.js"

**Pattern Detection**:
```json
{
  "pattern_id": "add-drizzle-nextjs",
  "frequency": 5,
  "repos": ["oms-athena", "billscribe", "smilestack-site"],
  "common_steps": [
    "npm install drizzle-orm postgres",
    "create drizzle.config.ts",
    "create db/schema.ts",
    "create db/migrate.ts",
    "update package.json with db:push script"
  ],
  "confidence": 0.92
}
```

**Generated Skill** (`~/.claude/homunculus/evolved/skills/add-drizzle-to-nextjs/SKILL.md`):

```markdown
# Add Drizzle ORM to Next.js Project

Auto-extracted from 5 occurrences across repositories.

## When to Activate

- Setting up database for new Next.js project
- Migrating from Prisma or another ORM to Drizzle
- Adding type-safe database queries

## Steps

### 1. Install Dependencies

```bash
npm install drizzle-orm postgres
npm install -D drizzle-kit
```

### 2. Create Drizzle Configuration

Create `drizzle.config.ts`:

```typescript
import type { Config } from 'drizzle-kit';

export default {
  schema: './db/schema.ts',
  out: './db/migrations',
  driver: 'pg',
  dbCredentials: {
    connectionString: process.env.DATABASE_URL!,
  },
} satisfies Config;
```

### 3. Create Schema File

Create `db/schema.ts`:

```typescript
import { pgTable, text, serial, timestamp } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  email: text('email').notNull().unique(),
  name: text('name'),
  createdAt: timestamp('created_at').defaultNow(),
});
```

### 4. Add Database Scripts

Update `package.json`:

```json
{
  "scripts": {
    "db:push": "drizzle-kit push:pg",
    "db:studio": "drizzle-kit studio"
  }
}
```

### 5. Create Database Client

Create `db/index.ts`:

```typescript
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';

const connectionString = process.env.DATABASE_URL!;
const client = postgres(connectionString);
export const db = drizzle(client);
```

## Verification

```bash
# Push schema to database
npm run db:push

# Open Drizzle Studio
npm run db:studio
```

## Common Variations

- **With Neon**: Use `@neondatabase/serverless` instead of `postgres`
- **With Supabase**: Configure connection string from Supabase dashboard
- **With migrations**: Use `drizzle-kit generate:pg` for migration files

---

*Auto-extracted skill - review before promoting*
```

### Example 2: Detected Pattern - "Setup GitHub Actions CI"

**Pattern Detection**:
```json
{
  "pattern_id": "github-actions-ci",
  "frequency": 4,
  "files_touched": [".github/workflows/ci.yml"],
  "common_steps": [
    "create .github/workflows directory",
    "add ci.yml with Node.js matrix",
    "configure npm ci and npm test",
    "add lint and type-check steps"
  ],
  "confidence": 0.87
}
```

**Generated Skill**: Complete CI workflow template based on actual usage patterns.

### Example 3: Detected Pattern - "Add Authentication to API"

**Pattern Detection**:
```json
{
  "pattern_id": "api-auth-setup",
  "frequency": 3,
  "common_libraries": ["jsonwebtoken", "bcrypt"],
  "common_steps": [
    "install jwt and bcrypt",
    "create auth middleware",
    "add login/register routes",
    "hash passwords with bcrypt",
    "generate JWT tokens"
  ],
  "confidence": 0.85
}
```

## Outputs

### Pattern Analysis Report

Saved to `~/.claude/homunculus/evolved/patterns-report.json`:

```json
{
  "scan_date": "2026-04-07T10:30:00Z",
  "repositories_scanned": 12,
  "commits_analyzed": 342,
  "patterns_detected": 7,
  "patterns": [
    {
      "pattern_id": "add-drizzle-nextjs",
      "name": "Add Drizzle ORM to Next.js",
      "frequency": 5,
      "confidence": 0.92,
      "repos": ["oms-athena", "billscribe", "smilestack-site"]
    }
  ]
}
```

### Generated Skills

Each skill saved to:
```
~/.claude/homunculus/evolved/skills/{pattern-id}/
├── SKILL.md           # Generated skill documentation
├── metadata.json      # Extraction metadata
└── examples/          # Code snippets from actual usage
```

## Tuning Tips

**Increase Sensitivity**:
```json
{
  "min_frequency": 2,
  "confidence_threshold": 0.7
}
```

**Focus on Recent Patterns**:
```json
{
  "days_back": 14
}
```

**Include Session Logs**:
Enable observations in Claude Code to capture command sequences.

## Troubleshooting

**Issue**: No patterns detected

**Solution**:
- Lower `min_frequency` threshold
- Increase `days_back` range
- Check that repositories have commit history

**Issue**: Too many false positives

**Solution**:
- Raise `confidence_threshold`
- Increase `min_frequency`
- Add exclusion patterns to config

**Issue**: Generated skills are too generic

**Solution**: The skill uses AI to extract specifics. Review and manually enhance before promoting.

## Dependencies

- `jq`: JSON parsing
- `git`: Repository access
- `bc`: Calculations
- Claude AI access: For pattern analysis and skill generation

## Smart Features

### Semantic Pattern Recognition

Uses AI to understand intent beyond text matching:
- Recognizes equivalent commands (npm/yarn/pnpm)
- Identifies conceptual patterns (authentication, CRUD, deployment)
- Groups related file changes

### Code Snippet Extraction

Captures actual code from commits:
- Extracts configuration file templates
- Preserves code patterns that worked
- Links to source commits for reference

### Variation Detection

Identifies common variations:
- Different package managers
- Alternative libraries for same purpose
- Environment-specific configurations

### Skill Quality Scoring

Rates generated skills by:
- Frequency (more repetitions = higher confidence)
- Consistency (same steps each time = higher quality)
- Completeness (all files touched consistently)
- Outcomes (successful builds/deployments)

## Integration Points

### With Continuous Learning

Auto-extracted skills feed into homunculus evolution:
```
~/.claude/homunculus/
├── observations.jsonl     # Input: Session logs
├── evolved/
│   ├── patterns-report.json
│   └── skills/            # Output: Generated skills
```

### With Other Skills

- **weekly-momentum-report**: Track skill usage and effectiveness
- **vault-to-code-bridge**: Cross-reference with vault project notes
- **code-to-docs-sync**: Ensure extracted patterns match current docs

### Promotion Workflow

```bash
# Review pending skills
cat ~/.claude/homunculus/evolved/skills/*/SKILL.md

# Promote to global skills
mv ~/.claude/homunculus/evolved/skills/add-drizzle-nextjs \
   ~/Developer/Staksmith/skills/

# Or copy to ~/.claude/skills/ for personal use
```

## Learning Modes

### Passive Learning (Default)

Analyzes existing git history without interrupting workflow.

### Active Learning (Future)

Prompts during workflow: "You've done this 3 times. Create a skill?"

### Supervised Learning (Future)

User tags commits with skill labels for training:
```bash
git commit -m "feat: add auth" --skill="api-authentication"
```

## Pattern Types

### Code Patterns
- Framework additions (ORM, auth, styling)
- Configuration setups (CI/CD, linting, testing)
- Architecture implementations (API routes, middleware)

### Workflow Patterns
- Deployment sequences
- Database migration workflows
- Release processes

### Documentation Patterns
- README sections consistently added
- Comment patterns
- Changelog formats

## Quality Metrics

Generated skills include metadata:
```json
{
  "pattern_id": "add-drizzle-nextjs",
  "confidence": 0.92,
  "frequency": 5,
  "success_rate": 1.0,
  "last_used": "2026-04-05",
  "extraction_date": "2026-04-07",
  "source_repos": ["oms-athena", "billscribe", "smilestack-site"],
  "source_commits": ["abc123", "def456", "ghi789"]
}
```

## Related Skills

- **continuous-learning-v2**: Foundation for learning system
- **weekly-momentum-report**: Track pattern emergence
- **vault-to-code-bridge**: Complement with documented workflows

## Future Enhancements

- **Cross-developer patterns**: Learn from team repositories
- **Skill refinement**: Improve skills based on usage feedback
- **Skill composition**: Combine atomic skills into workflows
- **Skill deprecation**: Detect when patterns become obsolete
