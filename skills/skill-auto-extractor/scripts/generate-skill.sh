#!/usr/bin/env bash
# generate-skill.sh - Phase 3: Generate skill definitions
# Creates SKILL.md files from detected patterns

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found at $CONFIG_FILE" >&2
    exit 1
fi

CONFIDENCE_THRESHOLD=$(jq -r '.confidence_threshold' "$CONFIG_FILE")
OUTPUT_PATH=$(jq -r '.output_path' "$CONFIG_FILE" | sed "s|~|$HOME|")
CACHE_PATH=$(jq -r '.cache_path' "$CONFIG_FILE" | sed "s|~|$HOME|")

# Check for patterns
PATTERNS_FILE="$CACHE_PATH/patterns-detected.json"

if [[ ! -f "$PATTERNS_FILE" ]]; then
    echo "Error: No patterns detected. Run detect-patterns.sh first." >&2
    exit 1
fi

# Load patterns
patterns_data=$(cat "$PATTERNS_FILE")
patterns=$(echo "$patterns_data" | jq '.patterns')
pattern_count=$(echo "$patterns" | jq 'length')

if [[ $pattern_count -eq 0 ]]; then
    echo "No patterns to generate skills from." >&2
    exit 0
fi

echo "Generating skills from $pattern_count patterns..." >&2
echo "Confidence threshold: $CONFIDENCE_THRESHOLD" >&2
echo "Output path: $OUTPUT_PATH" >&2

# Create output directory
mkdir -p "$OUTPUT_PATH"

# Initialize counters
generated=0
skipped=0

# Function to generate skill for "Add Drizzle ORM" pattern
generate_drizzle_skill() {
    local pattern="$1"
    local pattern_id=$(echo "$pattern" | jq -r '.pattern_id')
    local frequency=$(echo "$pattern" | jq -r '.frequency')
    local repos=$(echo "$pattern" | jq -r '.repos | join(", ")')

    local skill_dir="$OUTPUT_PATH/$pattern_id"
    mkdir -p "$skill_dir"

    cat > "$skill_dir/SKILL.md" <<'EOF'
# Add Drizzle ORM to Next.js Project

**Auto-extracted skill** - Review before promoting to global skills.

## Origin

This skill was automatically extracted from repeated patterns in your git history.

## When to Activate

- Setting up database for new Next.js project
- Migrating from Prisma or another ORM to Drizzle
- Adding type-safe database queries to existing project

## Steps

### 1. Install Dependencies

```bash
npm install drizzle-orm postgres
npm install -D drizzle-kit
```

### 2. Create Drizzle Configuration

Create `drizzle.config.ts` in project root:

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
    "db:studio": "drizzle-kit studio",
    "db:generate": "drizzle-kit generate:pg"
  }
}
```

### 5. Create Database Client

Create `db/index.ts`:

```typescript
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './schema';

const connectionString = process.env.DATABASE_URL!;
const client = postgres(connectionString);
export const db = drizzle(client, { schema });
```

### 6. Add Environment Variable

Add to `.env.local`:

```
DATABASE_URL="postgresql://user:password@localhost:5432/dbname"
```

## Verification

```bash
# Push schema to database
npm run db:push

# Open Drizzle Studio to verify
npm run db:studio
```

## Common Variations

### With Neon Database

```bash
npm install @neondatabase/serverless
```

```typescript
import { drizzle } from 'drizzle-orm/neon-http';
import { neon } from '@neondatabase/serverless';

const sql = neon(process.env.DATABASE_URL!);
export const db = drizzle(sql);
```

### With Supabase

Use Supabase connection string from dashboard.

### With Migrations (Production)

```bash
# Generate migration
npm run db:generate

# Apply migration
npx drizzle-kit migrate:pg
```

## References

- Drizzle ORM Docs: https://orm.drizzle.team
- Next.js Database Guide: https://nextjs.org/docs/app/building-your-application/data-fetching

---

*Auto-extracted from your development patterns*
EOF

    # Create metadata file
    cat > "$skill_dir/metadata.json" <<EOF
{
  "pattern_id": "$pattern_id",
  "extraction_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "frequency": $frequency,
  "source_repos": $(echo "$pattern" | jq '.repos'),
  "confidence": $(echo "$pattern" | jq '.confidence'),
  "status": "pending_review"
}
EOF

    echo "    ✓ Generated: $skill_dir/SKILL.md" >&2
}

# Function to generate skill for "GitHub Actions CI" pattern
generate_ci_skill() {
    local pattern="$1"
    local pattern_id=$(echo "$pattern" | jq -r '.pattern_id')
    local frequency=$(echo "$pattern" | jq -r '.frequency')

    local skill_dir="$OUTPUT_PATH/$pattern_id"
    mkdir -p "$skill_dir"

    cat > "$skill_dir/SKILL.md" <<'EOF'
# Setup GitHub Actions CI/CD

**Auto-extracted skill** - Review before promoting to global skills.

## Origin

This skill was automatically extracted from repeated CI/CD setup patterns.

## When to Activate

- Setting up CI/CD for new repository
- Adding automated testing to existing project
- Standardizing deployment pipeline

## Steps

### 1. Create Workflow Directory

```bash
mkdir -p .github/workflows
```

### 2. Create CI Workflow File

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [18.x, 20.x]

    steps:
    - uses: actions/checkout@v4

    - name: Use Node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v4
      with:
        node-version: ${{ matrix.node-version }}
        cache: 'npm'

    - name: Install dependencies
      run: npm ci

    - name: Run linter
      run: npm run lint

    - name: Run type check
      run: npm run type-check

    - name: Run tests
      run: npm test

    - name: Build
      run: npm run build
```

### 3. Ensure Scripts Exist

Update `package.json`:

```json
{
  "scripts": {
    "lint": "eslint .",
    "type-check": "tsc --noEmit",
    "test": "jest",
    "build": "next build"
  }
}
```

### 4. Commit and Push

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add GitHub Actions workflow"
git push
```

## Verification

- Check Actions tab in GitHub repository
- Verify workflow runs on push
- Confirm all steps pass

## Common Variations

### With Coverage Reporting

```yaml
- name: Run tests with coverage
  run: npm test -- --coverage

- name: Upload coverage
  uses: codecov/codecov-action@v3
```

### With Deploy Step

```yaml
deploy:
  needs: test
  runs-on: ubuntu-latest
  if: github.ref == 'refs/heads/main'

  steps:
  - uses: actions/checkout@v4
  - name: Deploy to production
    run: npm run deploy
```

---

*Auto-extracted from your development patterns*
EOF

    # Create metadata file
    cat > "$skill_dir/metadata.json" <<EOF
{
  "pattern_id": "$pattern_id",
  "extraction_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "frequency": $frequency,
  "source_repos": $(echo "$pattern" | jq '.repos'),
  "confidence": $(echo "$pattern" | jq '.confidence'),
  "status": "pending_review"
}
EOF

    echo "    ✓ Generated: $skill_dir/SKILL.md" >&2
}

# Function to generate generic skill from pattern
generate_generic_skill() {
    local pattern="$1"
    local pattern_id=$(echo "$pattern" | jq -r '.pattern_id')
    local pattern_name=$(echo "$pattern" | jq -r '.name')
    local frequency=$(echo "$pattern" | jq -r '.frequency')
    local repos=$(echo "$pattern" | jq -r '.repos | join(", ")')

    local skill_dir="$OUTPUT_PATH/$pattern_id"
    mkdir -p "$skill_dir"

    cat > "$skill_dir/SKILL.md" <<EOF
# $pattern_name

**Auto-extracted skill** - Review and enhance before promoting.

## Origin

This skill was automatically extracted from $frequency occurrences in: $repos

## When to Activate

(To be determined - review source commits for context)

## Steps

(To be extracted from commit analysis)

### Common Files Modified

$(echo "$pattern" | jq -r '.common_files[]? // empty | "- \(.)"')

## Notes

This is a placeholder skill generated from detected patterns. Please review the source commits and enhance this documentation with:

1. Specific activation triggers
2. Step-by-step instructions
3. Code examples
4. Verification steps
5. Common variations

## Source Information

- **Pattern Type**: $(echo "$pattern" | jq -r '.pattern_type')
- **Frequency**: $frequency
- **Repositories**: $repos
- **Confidence**: $(echo "$pattern" | jq -r '.confidence')

---

*Auto-extracted - requires manual enhancement*
EOF

    # Create metadata file
    cat > "$skill_dir/metadata.json" <<EOF
{
  "pattern_id": "$pattern_id",
  "extraction_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "frequency": $frequency,
  "source_repos": $(echo "$pattern" | jq '.repos'),
  "confidence": $(echo "$pattern" | jq '.confidence'),
  "status": "needs_enhancement"
}
EOF

    echo "    ⚠ Generated placeholder: $skill_dir/SKILL.md" >&2
}

# Process each pattern
for i in $(seq 0 $((pattern_count - 1))); do
    pattern=$(echo "$patterns" | jq ".[$i]")
    pattern_id=$(echo "$pattern" | jq -r '.pattern_id')
    pattern_name=$(echo "$pattern" | jq -r '.name')
    confidence=$(echo "$pattern" | jq -r '.confidence')

    echo "[$((i + 1))/$pattern_count] $pattern_name" >&2
    echo "  Confidence: $confidence" >&2

    # Skip if below confidence threshold
    if (( $(echo "$confidence < $CONFIDENCE_THRESHOLD" | bc -l) )); then
        echo "  Status: SKIPPED (confidence below threshold)" >&2
        ((skipped++))
        continue
    fi

    # Generate skill based on pattern type
    case "$pattern_id" in
        "add-drizzle-orm")
            generate_drizzle_skill "$pattern"
            ;;
        "github-actions-ci")
            generate_ci_skill "$pattern"
            ;;
        *)
            generate_generic_skill "$pattern"
            ;;
    esac

    ((generated++))
done

echo "" >&2
echo "=== Generation Summary ===" >&2
echo "Skills generated: $generated" >&2
echo "Skills skipped: $skipped" >&2
echo "Output location: $OUTPUT_PATH" >&2
echo "" >&2
echo "Next steps:" >&2
echo "1. Review generated skills: ls $OUTPUT_PATH" >&2
echo "2. Enhance placeholder skills with details" >&2
echo "3. Promote approved skills to ~/Developer/Staksmith/skills/" >&2

# Output summary
summary=$(cat <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "skills_generated": $generated,
  "skills_skipped": $skipped,
  "output_path": "$OUTPUT_PATH",
  "generated_skills": $(ls -1 "$OUTPUT_PATH" 2>/dev/null | jq -R . | jq -s '.' || echo '[]')
}
EOF
)

echo "$summary" | jq '.'
