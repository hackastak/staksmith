---
name: skill-creator
description: Creates new Claude Agent Skills with proper structure, YAML frontmatter, instructions, and templates. Use when the user wants to create a new skill, generate a SKILL.md file, or scaffold a skill directory.
---

# Skill Creator

This skill helps you create new Claude Agent Skills with the correct structure and best practices.

## Philosophy

A skill is not documentation. It is a runbook that a model will follow literally at inference time. Two things matter more than everything else combined:

1. **The `description` in the frontmatter.** This is the *only* text a model sees when deciding whether to load your skill. If it does not clearly describe the trigger, the skill sits unused. Undertrigger is the default failure mode — write the description a little pushy.

2. **Concrete examples beat abstract rules.** Show one good input→output pair *before* you state the rule. Models (and humans) generalize from examples faster than they comply with instructions.

Everything else in skill design is in service of those two things.

## Instructions

When creating a new skill, follow these steps:

### 1. Gather Requirements

Ask the user for the following information if not provided:
- **Skill name**: Must be lowercase, letters/numbers/hyphens only, max 64 chars
- **Skill purpose**: What the skill does and when Claude should use it
- **Key capabilities**: Specific tasks the skill should handle
- **Supporting resources**: Any scripts, references, or data files needed

### 2. Validate Skill Name

Ensure the skill name follows these rules:
- Maximum 64 characters
- Lowercase letters, numbers, and hyphens only
- No XML tags or reserved words ("anthropic", "claude")
- Use gerund form (e.g., `processing-pdfs`, `analyzing-data`)

### 3. Create Directory Structure

Create the skill directory. Two common locations:
- `.claude/skills/[skill-name]/` - For local/personal use with Claude Code
- `skills/[skill-name]/` - For repo-level sharing (e.g., staksmith)

```bash
# Local only
mkdir -p .claude/skills/[skill-name]

# Repo only
mkdir -p skills/[skill-name]

# Or use the generator script with --dual for both
python3 scripts/generate-skill.py [skill-name] --dual
```

Optionally create subdirectories for organization:
- `templates/` - Template files
- `scripts/` - Executable utilities
- `examples/` - Example files
- `reference/` - API docs or references

### 4. Generate SKILL.md

Create a `SKILL.md` file with this structure:

```markdown
---
name: skill-name
description: [What the skill does] and [when to use it]. Max 1024 characters.
---

# Skill Name

[Brief overview of the skill's purpose]

## Instructions

[Clear, step-by-step procedural guidance]

### Step 1: [Action]
[Detailed instructions]

### Step 2: [Action]
[Detailed instructions]

## Best Practices

- [Key guideline 1]
- [Key guideline 2]

## Examples

### Example 1: Minimal Happy Path
[Simplest working case — under 15 lines, anchors understanding]

### Example 2: [Tricky Case]
[Edge case or ambiguous input that teaches judgment]

## Additional Resources

- See [templates/example.txt](templates/example.txt) for templates
- Run [scripts/helper.py](scripts/helper.py) for automated tasks
```

### 5. Apply Best Practices

**Conciseness**: Keep SKILL.md lean — it loads at inference time, so every line has a token cost. Use progressive disclosure: reference separate files for detailed content rather than embedding everything.

**Appropriate specificity**:
- Exact instructions for fragile operations
- General guidance for flexible tasks
- Pseudocode for medium-complexity workflows

**Progressive disclosure**:
- Level 1: YAML frontmatter (always loaded)
- Level 2: Main SKILL.md instructions (loaded when triggered)
- Level 3: Supporting files (loaded on-demand via bash)

**Description guidelines**:
- Write in third person: "Processes PDFs" not "I can process PDFs"
- Explain both WHAT it does and WHEN to use it
- Maximum 1024 characters

**Content organization**:
- Main SKILL.md as overview
- Separate files for detailed references, forms, APIs
- Keep references one level deep from SKILL.md
- Include table of contents in files over 100 lines

### 6. Add Supporting Files (Optional)

If the skill needs executable code:
- Create utility scripts for deterministic operations
- Handle errors explicitly in scripts
- Document all configuration values
- Use "plan-validate-execute" pattern for critical operations

### 7. Test the Skill

After creation:
1. Test with simple prompts that should trigger the skill
2. Verify the skill loads correctly (check metadata)
3. Test progressive disclosure (supporting files load when needed)
4. Test across different models if supporting multiple

## Templates

Use the template files in the `templates/` directory:
- [basic-skill-template.md](templates/basic-skill-template.md) - Minimal skill structure
- [advanced-skill-template.md](templates/advanced-skill-template.md) - Full-featured skill with scripts

## Common Patterns

### Simple Instructional Skill
For skills that primarily provide guidance without scripts:
- Focus on clear procedural steps
- Include concrete examples
- Reference external docs as needed

### Script-Based Skill
For skills with executable utilities:
- Put deterministic operations in scripts
- Have Claude call scripts via bash
- Validate inputs before execution

### Form/Template Skill
For skills that generate structured output:
- Provide templates in separate files
- Include fill-in-the-blank examples
- Show before/after examples

## Examples

### Example 1: Creating a Simple Skill

User request: "Create a skill for code review"

Steps:
1. Validate name: `code-reviewing` (gerund form)
2. Create directory: `.claude/skills/code-reviewing/`
3. Create SKILL.md with:
   - Description: "Reviews code for quality, security, and best practices. Use when analyzing code changes or conducting code reviews."
   - Instructions for systematic review process
   - Checklist of common issues to look for
   - Examples of good/bad code patterns
4. Add `templates/review-checklist.md` with detailed checklist

### Example 2: Creating a Script-Based Skill

User request: "Create a skill for database migrations"

Steps:
1. Validate name: `managing-db-migrations`
2. Create directory structure:
   ```
   .claude/skills/managing-db-migrations/
   ├── SKILL.md
   ├── scripts/
   │   ├── validate-migration.py
   │   └── backup-db.sh
   └── templates/
       └── migration-template.sql
   ```
3. Create SKILL.md with migration workflow
4. Add validation script that checks SQL syntax
5. Add backup script for safety
6. Include migration template

### Example 3: Creating a Reference Skill

User request: "Create a skill for our internal API"

Steps:
1. Validate name: `using-company-api`
2. Create directory with reference materials:
   ```
   .claude/skills/using-company-api/
   ├── SKILL.md (overview and common patterns)
   ├── API-REFERENCE.md (full endpoint documentation)
   └── examples/
       ├── auth-example.json
       └── request-example.json
   ```
3. Keep SKILL.md concise, pointing to reference docs
4. Include authentication examples
5. Document common error codes

## Validation Checklist

Before completing skill creation, verify:

- [ ] Skill name follows naming rules (lowercase, hyphens, max 64 chars)
- [ ] Description explains both WHAT and WHEN (max 1024 chars)
- [ ] YAML frontmatter is properly formatted
- [ ] Main instructions are clear and procedural
- [ ] Example 1 is the minimal happy path (under 15 lines)
- [ ] At least one tricky case example is included
- [ ] SKILL.md is lean; detailed content in separate reference files
- [ ] Supporting files are referenced correctly
- [ ] Description is in third person
- [ ] Name uses gerund form where appropriate

## Quick Reference

**Minimum viable SKILL.md**:
```markdown
---
name: skill-name
description: Does X when Y condition occurs.
---

# Skill Name

## Instructions
1. Step one
2. Step two

## Examples

### Example 1: Minimal Happy Path
[Simplest working case]

### Example 2: [Tricky Case]
[Edge case that teaches judgment]
```

**File path conventions**:
- Use forward slashes (Unix-style)
- Paths relative to skill directory
- Example: `templates/example.md` not `./templates/example.md`

**Generator script usage**:
```bash
# Basic skill (local only)
python3 scripts/generate-skill.py my-skill

# Advanced skill with scripts/templates
python3 scripts/generate-skill.py my-skill --template advanced

# Output to both .claude/skills/ AND skills/ (repo)
python3 scripts/generate-skill.py my-skill --dual

# Output to custom repo directory
python3 scripts/generate-skill.py my-skill --repo-dir path/to/skills
```
