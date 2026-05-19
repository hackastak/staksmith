---
name: product-ideas
description: Mine your Obsidian vault for sellable digital products - guides, templates, frameworks, and skill bundles. Evaluates market fit, recommends pricing, and identifies bundle opportunities.
origin: Hackastak
---

# Product Ideas Generator

Mine your vault for sellable digital products and generate market-ready product ideas.

## When to Activate

- User runs `/product-ideas` command
- User asks "what can I sell from my vault?"
- User wants to discover monetizable content
- User needs product recommendations for Gumroad/digital platforms

## How It Works

This skill performs a 5-phase discovery process to find sellable products in your vault.

### Phase 1: Read Product Calendar

First, read the Product Calendar to understand what's already in the pipeline:

```markdown
Read: 2. Areas/Hackastak_Brand/Gumroad/Product_Calendar.md
```

Extract:
- Products already tracked (avoid duplicates)
- Category balance (guides, templates, skills, frameworks, bundles)
- Revenue targets and gaps

### Phase 2: Scan Vault for Sellable Content

Scan these key areas for potential products:

**3. Resources/** - Reference materials, frameworks, playbooks
```bash
Glob: 3. Resources/**/*.md
```

Look for:
- Comprehensive guides (>500 lines, well-structured)
- Frameworks with clear methodology (BREAK Method, PARA, etc.)
- Reference documents with reusable value
- Process documentation

**2. Areas/** - Ongoing areas with mature content
```bash
Glob: 2. Areas/**/*.md
```

Look for:
- Brand strategy documents (Blog_Strategy, Brand_Guide)
- Business frameworks (Pricing_Strategy, Launch_Strategy)
- Workflow documentation
- Templates in use

**1. Projects/** - Completed projects with extractable value
```bash
Glob: 1. Projects/**/*.md
```

Look for:
- Post-mortems with lessons learned
- Project templates that worked well
- Technical documentation worth sharing

**_templates/** - Reusable templates
```bash
Glob: _templates/**/*.md
```

All templates are potential products.

**~/Developer/Staksmith/skills/** - Claude Code skills
```bash
bash: ls -1 ~/Developer/Staksmith/skills/*/SKILL.md | wc -l
```

Count skills for bundle opportunities.

### Phase 3: Evaluate Product Potential

For each candidate, evaluate:

**Completeness Score (0-100)**
- 100: Ready to package, just needs README
- 80-99: Needs minor additions (examples, polish)
- 60-79: Needs significant work (structure, content)
- <60: Not ready, park for future

**Market Fit Indicators**
- ✅ Solves a specific pain point
- ✅ Actionable/immediately useful
- ✅ Evergreen content (not time-sensitive)
- ✅ Unique angle or expertise
- ✅ Clear target audience

**Effort to Launch (Hours)**
- 1-3 hours: Quick win (package + sales page)
- 4-8 hours: Medium effort (needs polish + examples)
- 9-20 hours: Major effort (significant additions needed)
- 20+ hours: Long-term project

### Phase 4: Recommend Pricing

Use these pricing guidelines:

**Templates/Checklists:** $5-15
- Simple templates: $5-7
- Comprehensive templates with examples: $10-15

**Skills (Individual):** $3-7
- Single skill: $3-5
- High-value skill (claude-api, tdd-workflow): $5-7

**Skills (Bundles):** $17-39
- 3-5 skills: $17-24
- 6-10 skills: $24-29
- 11+ skills: $29-39

**Guides:** $17-49
- Short guides (<2000 words): $17-24
- Comprehensive guides (2000-5000 words): $24-39
- Premium guides with case studies: $39-49

**Frameworks:** $12-29
- Simple frameworks: $12-17
- Complete systems with examples: $17-29

**Bundles (Mixed Content):** $49-97
- Starter bundle (3-4 items): $49-67
- Complete bundle (5-8 items): $67-97
- Ultimate library: $147-197

### Phase 5: Identify Bundle Opportunities

Look for natural groupings:
- **Topic clusters** (Django skills, content creation tools)
- **Workflow bundles** (Blog strategy + templates + examples)
- **Role-based** (For developers, for creators, for managers)
- **Journey-based** (Beginner to advanced)

Check bundle economics:
- Bundle should be 30-50% discount vs buying individually
- Minimum 3 items per bundle
- Cohesive value proposition

### Phase 6: Suggest Blog Support

For each product idea, recommend supporting blog articles:
- Showcase 2-3 patterns from the product
- Provide value even without purchase
- End with soft CTA to full product

Example:
- Product: Django Patterns Guide
- Blog: "10 Django Patterns That Changed How I Build APIs"
- Outcome: Reader learns 3 patterns, wants remaining 50+ patterns

## Output Format

Generate a structured report:

```markdown
# Product Ideas Report
Generated: YYYY-MM-DD

## Executive Summary
- **New products identified:** X
- **Quick wins (ready in 1-3 hours):** X
- **Medium effort (4-8 hours):** X
- **Long-term projects (9+ hours):** X
- **Total potential revenue:** $X,XXX (first 90 days, conservative)

## Quick Wins 🚀

### 1. [Product Name] ($X)
**Status:** X% ready | X hours to launch
**Target Audience:** [Who needs this]
**What it is:** [One sentence description]
**Why it sells:** [Pain point it solves]
**What's needed:**
- [ ] Task 1
- [ ] Task 2

**Pricing rationale:** [Why this price]
**Bundle fit:** [Which bundle it belongs in]
**Blog support:** [Article idea to write]

---

### 2. [Product Name] ($X)
[Same structure]

## Medium Effort Products 🔨

[Same structure for 4-8 hour products]

## Long-Term Projects 🏗️

[Same structure for 9+ hour products]

## Bundle Opportunities 📦

### [Bundle Name] ($X)
**Includes:**
- Item 1
- Item 2
- Item N

**Target audience:** [Who]
**Value prop:** [Why bundle vs individual]
**Individual price total:** $X
**Bundle price:** $Y (Z% discount)
**Marketing angle:** [One-line pitch]

## Blog Article Ideas 📝

1. **[Article Title]** → Supports [Product Name]
   - Showcase X patterns/concepts
   - CTA to full product at end

2. [More articles]

## Category Balance 📊

Current pipeline:
- Guides: X
- Templates: X
- Skills: X
- Frameworks: X
- Bundles: X

**Recommendation:** [Focus on under-represented categories]

## Revenue Projection (90 Days)

**Conservative:**
- X individual sales @ $Y avg = $Z
- X bundle sales @ $Y avg = $Z
- **Total: $X,XXX**

**Moderate:**
[Same structure]

**Optimistic:**
[Same structure]

## Priority Recommendations

**This Week:**
1. [Product] - [Reason]
2. [Product] - [Reason]
3. [Product] - [Reason]

**Next 30 Days:**
[Strategic recommendations]

**Next 90 Days:**
[Long-term strategy]
```

## Key Principles

1. **Quick wins first** - Launch ready products before building new ones
2. **Bundle thinking** - Group related products for higher value
3. **Blog integration** - Every product gets blog support
4. **Pricing psychology** - Use tiered pricing to guide buyers
5. **Category balance** - Diversify product mix
6. **Effort visibility** - Be honest about work required

## Example Usage

```
User: /product-ideas
```

```
Assistant: I'll scan your vault for sellable products.

[Reads Product_Calendar]
[Scans vault directories]
[Evaluates candidates]
[Generates report]

# Product Ideas Report
Generated: 2026-05-06

## Executive Summary
- **New products identified:** 18
- **Quick wins (ready in 1-3 hours):** 5
- **Medium effort (4-8 hours):** 8
- **Long-term projects (9+ hours):** 5
- **Total potential revenue:** $4,200-12,500 (first 90 days, conservative-optimistic)

## Quick Wins 🚀

### 1. BREAK Method Framework ($12)
**Status:** 95% ready | 2 hours to launch
**Target Audience:** Engineering managers, senior developers
**What it is:** Decision framework for engineering (Boundaries, Requirements, Edge cases, Architecture, Key metrics)
**Why it sells:** Simplifies complex technical decisions into memorable acronym
**What's needed:**
- [ ] Add 3 real-world examples
- [ ] Create README with installation guide
- [ ] Package as PDF + markdown

**Pricing rationale:** Simple framework, high utility, $12 is impulse buy
**Bundle fit:** Engineering Leadership Bundle (new opportunity)
**Blog support:** "How the BREAK Method Saved Me From Analysis Paralysis"

[Continue for all products...]
```

## Anti-Patterns to Avoid

❌ **Don't recommend incomplete work** - Only suggest products that are 60%+ complete
❌ **Don't ignore pricing psychology** - $7 converts better than $8
❌ **Don't create bundles with <3 items** - Not enough value
❌ **Don't recommend products without target audience** - Must know who buys
❌ **Don't forget blog integration** - Every product needs content support
❌ **Don't over-estimate revenue** - Be conservative in projections

## Success Metrics

A good product idea has:
- Clear target audience (not "everyone")
- Specific pain point solved
- 70%+ completeness score
- Reasonable effort to launch (<8 hours ideal)
- Natural blog article tie-in
- Bundle opportunity identified

## Integration with Other Skills

- Use `/package-product` after selecting products from this report
- Use `/product-pipeline` to schedule launches
- Use `/blog-ideas` to find supporting content angles
- Use `/blog-draft` to write supporting articles

## Notes

- Run this skill monthly to discover new opportunities
- Update product ideas based on blog performance (popular articles = product demand)
- Watch for vault content that's growing organically (sign of valuable topic)
- Consider audience size when pricing (niche = higher price, broad = lower price)
