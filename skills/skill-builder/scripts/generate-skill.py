#!/usr/bin/env python3
"""
Skill Generator Script

Generates a new Claude Agent Skill with proper structure and templates.
Usage: python generate-skill.py <skill-name> [--template basic|advanced]
"""

import argparse
import os
import re
import sys
from pathlib import Path


def validate_skill_name(name):
    """
    Validate skill name according to Claude requirements.

    Rules:
    - Maximum 64 characters
    - Lowercase letters, numbers, hyphens only
    - No reserved words (anthropic, claude)
    """
    if len(name) > 64:
        return False, "Skill name must be 64 characters or less"

    if not re.match(r'^[a-z0-9-]+$', name):
        return False, "Skill name must contain only lowercase letters, numbers, and hyphens"

    reserved_words = ['anthropic', 'claude']
    if any(word in name.lower() for word in reserved_words):
        return False, f"Skill name cannot contain reserved words: {', '.join(reserved_words)}"

    return True, "Valid"


def create_basic_skill(skill_path, skill_name):
    """Create a basic skill with minimal structure."""

    skill_md = f"""---
name: {skill_name}
description: [TODO: Describe what this skill does and when to use it. Max 1024 characters.]
---

# {skill_name.replace('-', ' ').title()}

[TODO: Add brief overview of the skill's purpose]

## Instructions

### Step 1: [Action Name]

[TODO: Add clear, specific instructions]

### Step 2: [Action Name]

[TODO: Add clear, specific instructions]

## Examples

### Example 1: [Use Case]

**User Request:**
```
[TODO: Add example user request]
```

**Expected Output:**
```
[TODO: Show expected result]
```

## Notes

- [TODO: Add important considerations]
- [TODO: Add edge cases or limitations]
"""

    with open(skill_path / 'SKILL.md', 'w') as f:
        f.write(skill_md)


def create_advanced_skill(skill_path, skill_name):
    """Create an advanced skill with full structure."""

    # Create subdirectories
    (skill_path / 'scripts').mkdir(exist_ok=True)
    (skill_path / 'templates').mkdir(exist_ok=True)
    (skill_path / 'reference').mkdir(exist_ok=True)

    skill_md = f"""---
name: {skill_name}
description: [TODO: Describe what this skill does and when to use it. Max 1024 characters.]
---

# {skill_name.replace('-', ' ').title()}

[TODO: Add comprehensive overview of the skill's capabilities]

## Instructions

### Phase 1: Preparation

1. **Validate Input**
   - [TODO: Define input validation steps]
   - Use `scripts/validate.py` if complex validation needed

2. **Gather Context**
   - [TODO: Define context gathering steps]
   - Reference additional files as needed

### Phase 2: Execution

3. **Execute Core Task**
   - [TODO: Define main execution steps]
   - Use scripts for deterministic operations

4. **Validate Results**
   - [TODO: Define validation steps]
   - Verify outputs meet requirements

### Phase 3: Finalization

5. **Format Output**
   - [TODO: Define output formatting]
   - Use templates for consistent structure

## Best Practices

### Do's
- [TODO: Add recommended practices]
- Use progressive disclosure
- Validate before executing

### Don'ts
- [TODO: Add things to avoid]
- Don't skip validation
- Don't make assumptions

## Examples

### Example 1: [Common Use Case]

**User Request:**
```
[TODO: Add example request]
```

**Execution Flow:**
1. [TODO: Step 1]
2. [TODO: Step 2]
3. [TODO: Step 3]

**Expected Output:**
```
[TODO: Show expected output]
```

## Supporting Resources

### Scripts
- `scripts/validate.py` - Input validation
- `scripts/helper.py` - Helper utilities

### Templates
- `templates/output.md` - Output template

### References
- `reference/docs.md` - Additional documentation

## Validation Checklist

- [ ] Inputs validated
- [ ] Core task completed
- [ ] Outputs verified
- [ ] Results formatted
"""

    with open(skill_path / 'SKILL.md', 'w') as f:
        f.write(skill_md)

    # Create placeholder files
    with open(skill_path / 'scripts' / 'validate.py', 'w') as f:
        f.write(f"""#!/usr/bin/env python3
\"\"\"
Validation script for {skill_name}
\"\"\"

import sys

def validate(input_data):
    # TODO: Implement validation logic
    return True, "Validation successful"

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python validate.py <input>")
        sys.exit(1)

    success, message = validate(sys.argv[1])
    print(message)
    sys.exit(0 if success else 1)
""")

    with open(skill_path / 'templates' / 'output.md', 'w') as f:
        f.write("""# Output Template

## Summary
[Summary of results]

## Details
[Detailed information]

## Next Steps
- [Action 1]
- [Action 2]
""")

    with open(skill_path / 'reference' / 'docs.md', 'w') as f:
        f.write(f"""# {skill_name.replace('-', ' ').title()} Reference

## Overview
[TODO: Add reference documentation]

## API Reference
[TODO: Add API details if applicable]

## Examples
[TODO: Add detailed examples]
""")


def main():
    parser = argparse.ArgumentParser(
        description='Generate a new Claude Agent Skill',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python generate-skill.py my-new-skill
  python generate-skill.py analyzing-data --template advanced
  python generate-skill.py processing-files --description "Processes various file types"
  python generate-skill.py my-skill --dual                    # Output to both .claude/skills/ and skills/
  python generate-skill.py my-skill --repo-dir path/to/skills # Output to both .claude/skills/ and custom repo
        """
    )

    parser.add_argument('skill_name', help='Name of the skill (lowercase, hyphens, max 64 chars)')
    parser.add_argument('--template', choices=['basic', 'advanced'], default='basic',
                        help='Template to use (default: basic)')
    parser.add_argument('--description', help='Optional description for the skill')
    parser.add_argument('--output-dir', default='.claude/skills',
                        help='Output directory (default: .claude/skills)')
    parser.add_argument('--repo-dir', default=None,
                        help='Also output to repo skills directory (e.g., skills)')
    parser.add_argument('--dual', action='store_true',
                        help='Output to both .claude/skills and skills/ (repo root)')

    args = parser.parse_args()

    # Handle --dual flag
    if args.dual:
        args.repo_dir = 'skills'

    # Validate skill name
    valid, message = validate_skill_name(args.skill_name)
    if not valid:
        print(f"Error: {message}", file=sys.stderr)
        sys.exit(1)

    # Create output directory
    output_dir = Path(args.output_dir)
    skill_path = output_dir / args.skill_name

    if skill_path.exists():
        print(f"Error: Skill directory already exists: {skill_path}", file=sys.stderr)
        response = input("Overwrite? (y/N): ")
        if response.lower() != 'y':
            sys.exit(1)

    # Create skill directory
    skill_path.mkdir(parents=True, exist_ok=True)

    # Collect all output paths
    output_paths = [skill_path]

    # Add repo directory if specified
    if args.repo_dir:
        repo_output_dir = Path(args.repo_dir)
        repo_skill_path = repo_output_dir / args.skill_name

        if repo_skill_path.exists():
            print(f"Warning: Repo skill directory already exists: {repo_skill_path}", file=sys.stderr)
            response = input("Overwrite repo copy? (y/N): ")
            if response.lower() != 'y':
                print("Skipping repo output, continuing with local only.")
            else:
                output_paths.append(repo_skill_path)
        else:
            output_paths.append(repo_skill_path)

    # Generate skill in all output paths
    for path in output_paths:
        path.mkdir(parents=True, exist_ok=True)

        if args.template == 'basic':
            create_basic_skill(path, args.skill_name)
        else:
            create_advanced_skill(path, args.skill_name)

    # Print summary
    print(f"\nCreated {args.template} skill:")
    for path in output_paths:
        print(f"\n  {path}/")
        print(f"    - SKILL.md")
        if args.template == 'advanced':
            print(f"    - scripts/validate.py")
            print(f"    - templates/output.md")
            print(f"    - reference/docs.md")

    print(f"\nNext steps:")
    print(f"1. Edit SKILL.md and replace [TODO] items")
    print(f"2. Add a proper description in the YAML frontmatter")
    print(f"3. Provide concrete examples")
    print(f"4. Test the skill with Claude")

    if args.description:
        print(f"\nSuggested description: {args.description}")


if __name__ == '__main__':
    main()
