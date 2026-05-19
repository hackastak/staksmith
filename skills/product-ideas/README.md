# product-ideas

Mine your Obsidian vault for sellable digital products.

## What It Does

Scans your vault for:
- Comprehensive guides and tutorials
- Reusable templates and frameworks
- Claude Code skills ready to package
- Reference materials with market value

Then generates a structured report with:
- Product ideas categorized by effort (quick wins, medium, long-term)
- Recommended pricing based on product type and value
- Bundle opportunities (group related products)
- Supporting blog article suggestions
- 90-day revenue projections (conservative to optimistic)

## When to Use

- Monthly product discovery (find what's ready to monetize)
- After completing a major guide or framework
- When planning your Gumroad launch calendar
- To identify gaps in your product portfolio

## Installation

```bash
# Copy to vault's skills directory
cp SKILL.md /path/to/vault/.claude/skills/product-ideas/
```

## Usage

```bash
/product-ideas
```

## Output Example

```markdown
# Product Ideas Report
Generated: 2026-05-06

## Executive Summary
- **New products identified:** 12
- **Quick wins (ready in 1-3 hours):** 4
- **Medium effort (4-8 hours):** 5
- **Long-term projects (9+ hours):** 3
- **Total potential revenue:** $3,200-8,900 (first 90 days)

## Quick Wins 🚀

### 1. BREAK Method Framework ($12)
**Status:** 95% ready | 2 hours to launch
**Target Audience:** Engineering managers, senior developers
**What it is:** Decision framework for engineering decisions
**Why it sells:** Simplifies complex technical decisions
**What's needed:**
- [ ] Add 3 real-world examples
- [ ] Create README with installation guide

**Bundle fit:** Engineering Leadership Bundle
**Blog support:** "How the BREAK Method Saved Me From Analysis Paralysis"

[... more products ...]
```

## Integration

Works with:
- `/package-product` - Package selected products
- `/product-pipeline` - Schedule launches
- `/blog-ideas` - Find supporting content angles
- `/blog-draft` - Write supporting articles

## Configuration

Scans these vault directories by default:
- `3. Resources/` - Reference materials
- `2. Areas/` - Ongoing areas
- `1. Projects/` - Completed projects
- `_templates/` - Reusable templates
- `~/Developer/Staksmith/skills/` - Claude Code skills

## Pricing Guidelines

The skill uses these pricing tiers:
- Templates: $5-15
- Individual skills: $3-7
- Skill bundles: $17-39
- Guides: $17-49
- Frameworks: $12-29
- Mixed bundles: $49-97

## Version History

- **1.0.0** (2026-05-06) - Initial release
  - Vault scanning
  - Product evaluation
  - Pricing recommendations
  - Bundle detection
  - Blog support suggestions
