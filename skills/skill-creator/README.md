# Skill Creator

A Claude Agent Skill for creating new Claude Agent Skills with proper structure, templates, and best practices.

## What This Skill Does

The Skill Creator helps you:
- Generate new skills with correct YAML frontmatter
- Follow Claude Agent Skills best practices
- Create proper directory structures
- Use appropriate templates (basic or advanced)
- Validate skill names and descriptions
- Add supporting scripts and resources

## When to Use This Skill

Use this skill when you need to:
- Create a new Claude Agent Skill from scratch
- Scaffold a skill directory structure
- Generate a SKILL.md file with proper format
- Add templates and scripts to an existing skill
- Learn about skill creation best practices

## Quick Start

### Using Claude

Simply ask Claude to create a skill:

```
Create a skill for analyzing log files
```

or

```
I need a new skill called data-processing that handles CSV and JSON files
```

Claude will use this skill to generate the proper structure.

### Using the Script Directly

You can also use the generation script directly:

```bash
# Create a basic skill
python .claude/skills/skill-creator/scripts/generate-skill.py my-skill-name

# Create an advanced skill with full structure
python .claude/skills/skill-creator/scripts/generate-skill.py my-skill-name --template advanced

# Specify a custom output directory
python .claude/skills/skill-creator/scripts/generate-skill.py my-skill-name --output-dir ~/custom/path
```

## Files Included

- **SKILL.md** - Main skill instructions and guidance
- **templates/basic-skill-template.md** - Template for simple skills
- **templates/advanced-skill-template.md** - Template for complex skills with scripts
- **scripts/generate-skill.py** - Script to generate new skills programmatically
- **README.md** - This file

## Skill Naming Rules

Skill names must follow these rules:
- Maximum 64 characters
- Lowercase letters, numbers, and hyphens only
- No XML tags or reserved words ("anthropic", "claude")
- Prefer gerund form (e.g., `processing-data`, `analyzing-logs`)

## Templates

### Basic Template

Use the basic template for:
- Simple instructional skills
- Skills that primarily provide guidance
- Skills without executable scripts
- Quick prototypes

### Advanced Template

Use the advanced template for:
- Complex skills with multiple phases
- Skills that need executable utilities
- Skills with validation requirements
- Skills with extensive reference materials

## Best Practices

### Keep It Concise
- SKILL.md should be under 500 lines
- Use progressive disclosure for detailed content
- Reference external files instead of embedding everything

### Be Specific
- Provide clear, procedural instructions
- Include concrete examples
- Explain both WHAT and WHEN in descriptions

### Use Progressive Disclosure
- Level 1: YAML frontmatter (always loaded)
- Level 2: Main SKILL.md (loaded when triggered)
- Level 3: Supporting files (loaded on-demand)

### Organize Content
- Main SKILL.md as overview
- Separate files for references, APIs, examples
- Keep references one level deep
- Add table of contents for files over 100 lines

## Examples

### Example 1: Simple Skill

Creating a code review skill:

```
User: Create a skill for code review

Claude will:
1. Validate the name "code-reviewing"
2. Create .claude/skills/code-reviewing/
3. Generate SKILL.md with review instructions
4. Include examples of common issues
5. Add a review checklist template
```

### Example 2: Advanced Skill

Creating a database migration skill:

```
User: Create an advanced skill for database migrations with validation

Claude will:
1. Validate the name "managing-db-migrations"
2. Create full directory structure
3. Generate SKILL.md with migration workflow
4. Create scripts/validate-migration.py
5. Add templates/migration-template.sql
6. Include error handling examples
```

## Validation Checklist

When creating a skill, ensure:

- [ ] Skill name follows naming rules
- [ ] Description is under 1024 chars and explains WHAT and WHEN
- [ ] YAML frontmatter is properly formatted
- [ ] Instructions are clear and procedural
- [ ] At least one concrete example is included
- [ ] SKILL.md is under 500 lines
- [ ] Supporting files are referenced correctly
- [ ] Description is in third person

## Troubleshooting

### "Invalid skill name" error
- Ensure name is lowercase only
- Use hyphens instead of underscores or spaces
- Remove special characters
- Check length (max 64 characters)

### Skill not loading
- Verify YAML frontmatter syntax
- Check that name and description are present
- Ensure file is named exactly "SKILL.md"
- Confirm directory is in .claude/skills/

### Description too long
- Maximum 1024 characters
- Focus on essential information
- Remove unnecessary details
- Use concise language

## Resources

- [Claude Agent Skills Documentation](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview)
- [Agent Skills Best Practices](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices)

## Version

v1.0.0 - Initial release
