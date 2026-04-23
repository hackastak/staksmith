---
name: your-skill-name
description: Detailed description of what this skill does and when to use it. Include both the capability and the trigger conditions.
---

# Your Skill Name

[Comprehensive overview of the skill's capabilities and use cases]

## Overview

This skill provides [primary capability] by [method]. It is designed for [target use case] and automatically activates when [trigger condition].

## Instructions

### Phase 1: Preparation

1. **Validate Input**
   - Check that [required condition 1]
   - Verify [required condition 2]
   - Use `scripts/validate-input.py` to validate complex inputs

2. **Gather Context**
   - Read [relevant files or data]
   - Check [system state or configuration]
   - Reference [reference/API-DOCS.md](reference/API-DOCS.md) for API details

### Phase 2: Execution

3. **Plan Approach**
   - Analyze [what needs to be analyzed]
   - Determine [what needs to be determined]
   - Create execution plan following [standard or pattern]

4. **Execute Core Task**
   - Perform [primary operation]
   - Use `scripts/helper-utility.py` for [specific deterministic operation]
   - Monitor [what to monitor]

5. **Validate Results**
   - Run `scripts/validate-output.py` to verify [what to verify]
   - Check that [success criteria]
   - Generate intermediate outputs in [format]

### Phase 3: Finalization

6. **Format Output**
   - Structure results using [templates/output-template.md](templates/output-template.md)
   - Include [required sections]
   - Highlight [important findings]

7. **Document Actions**
   - Log [what was done]
   - Note [any anomalies or edge cases]
   - Provide [recommendations or next steps]

## Best Practices

### Do's
- Always validate inputs before processing
- Use provided scripts for deterministic operations
- Follow the plan-validate-execute pattern
- Document assumptions and decisions
- Check error conditions explicitly

### Don'ts
- Don't skip validation steps for "simple" cases
- Don't generate code inline when scripts exist
- Don't proceed if validation fails
- Avoid making assumptions without verification
- Never expose sensitive data in outputs

## When NOT to Use

<!-- Explicitly call out adjacent cases this skill is NOT for. This prevents the most common misfires. -->

- [Adjacent case this skill is NOT for] — use [alternative skill] instead.
- [Another near-miss case] — use [alternative approach] instead.

## Supporting Resources

### Scripts

- **validate-input.py**: Validates [input type] against [criteria]
  ```bash
  python scripts/validate-input.py <input-file>
  ```

- **helper-utility.py**: Performs [specific operation]
  ```bash
  python scripts/helper-utility.py --option value
  ```

- **validate-output.py**: Verifies [output conditions]
  ```bash
  python scripts/validate-output.py <output-file>
  ```

### Templates

- **templates/output-template.md**: Standard format for results
- **templates/config-template.json**: Configuration file structure

### References

- **reference/API-DOCS.md**: Complete API documentation
- **reference/ERROR-CODES.md**: Common error codes and solutions

## Examples

### Example 1: Minimal Happy Path

<!-- Example 1 format depends on skill type:

MINIMAL HAPPY PATH (under 15 lines) works best for:
- Procedural skills (do X → Y → Z)
- Transformation skills (input → output)
- Script-based skills (run command, get result)

REGULAR EXAMPLES work better for:
- Reference/lookup skills (show representative queries)
- Decision-based skills (show different branches)
- Reactive/contextual skills (show triggering conditions)

For procedural/transformation skills, keep this under 15 lines. -->

**User Request:**
```
[Simplest user request that triggers this skill]
```

**Expected Output:**
```
[Sample output — the happy path result]
```

**Note:** This is the minimal case — everything works, no edge cases.

### Example 2: [Edge Case]

**User Request:**
```
[Request that represents an edge case or complex scenario]
```

**Special Considerations:**
- [What makes this case special]
- [Additional steps required]
- [Modified validation criteria]

**Execution Flow:**

1. Detect edge case condition
2. Apply modified validation rules
3. Use alternative processing path
4. Include additional context in output

**Expected Output:**
```
[Sample output for edge case]
```

### Example 3: [Error Handling]

**User Request:**
```
[Request that might fail or need error handling]
```

**Error Detection:**
- Check for [error condition 1]
- Validate [constraint]
- Test [requirement]

**Recovery Actions:**
- If [error type]: [recovery step]
- If validation fails: [alternative approach]
- If resources unavailable: [fallback method]

## Validation Checklist

Before completing any task with this skill:

- [ ] All inputs validated successfully
- [ ] Required resources accessible
- [ ] Pre-conditions met
- [ ] Execution plan verified
- [ ] Core operations completed
- [ ] Outputs validated
- [ ] Results properly formatted
- [ ] Documentation generated
- [ ] No errors or warnings
- [ ] Post-conditions satisfied

## Troubleshooting

### Common Issues

**Issue: [Common problem]**
- Symptom: [How it manifests]
- Cause: [Why it happens]
- Solution: [How to fix]

**Issue: [Another common problem]**
- Symptom: [Description]
- Cause: [Root cause]
- Solution: [Resolution steps]

## Progressive Disclosure

This skill uses a three-level loading approach:

1. **Level 1**: YAML metadata (always loaded)
2. **Level 2**: This SKILL.md file (loaded when skill is triggered)
3. **Level 3**: Supporting files loaded on-demand:
   - Scripts called via bash commands
   - References read when needed
   - Templates accessed during output generation

This minimizes token usage by only loading what's necessary for each specific task.

## Configuration

Optionally create a `config.json` file to customize behavior:

```json
{
  "setting1": "value1",
  "setting2": "value2",
  "limits": {
    "max_items": 100,
    "timeout_seconds": 30
  }
}
```

Load with: `cat .claude/skills/your-skill-name/config.json`

## Testing

To test this skill:

1. Use a simple request: "[basic trigger phrase]"
2. Verify skill loads by checking for [indicator]
3. Test progressive disclosure by [method]
4. Verify scripts execute correctly
5. Check output format matches template

## Version History

- v1.0.0: Initial release
  - [Feature 1]
  - [Feature 2]
