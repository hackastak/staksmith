---
name: product-pipeline
description: Manage product calendar and launches - view pipeline status, schedule releases, track revenue, and get recommendations on what to work on next.
origin: Hackastak
---

# Product Pipeline Manager

Manage your Gumroad product pipeline with status tracking, launch scheduling, revenue reporting, and strategic recommendations.

## When to Activate

- User runs `/product-pipeline [command]` with commands: status, next, schedule, publish
- User asks "what should I work on next?" in product context
- User wants pipeline overview or health check
- User needs to schedule a product launch
- User wants to track product revenue

## Commands

### `/product-pipeline status`
Show complete pipeline overview with health metrics.

### `/product-pipeline next`
Recommend what product to work on based on pipeline health, category balance, and effort-to-value ratio.

### `/product-pipeline schedule [product-name] [YYYY-MM-DD]`
Schedule a product for launch on a specific date.

### `/product-pipeline publish [product-name] [gumroad-url] [price]`
Mark a product as published, record Gumroad URL and price.

## How It Works

### Command: `status`

Shows a comprehensive pipeline overview with actionable insights.

#### Phase 1: Read Product Calendar

```bash
Read: 2. Areas/Hackastak_Brand/Gumroad/Product_Calendar.md
```

Extract Dataview queries and understand the structure.

#### Phase 2: Scan Product Directories

```bash
Glob: 2. Areas/Hackastak_Brand/Gumroad/*/Product_Info.md
```

For each product directory, read Product_Info.md (if exists) or infer from directory structure.

**Fallback for products without Product_Info.md:**
- Check for Gumroad_Listing_Instructions.md
- Check for Gumroad_Sales_Page.md
- Infer status from file presence (has PDF + README = ready)

#### Phase 3: Calculate Pipeline Health

**Buffer Health (Ready Products)**
- Target: 3-5 products ready to launch
- Status:
  - ✅ Healthy: 3-5 ready
  - ⚠️ Low: 1-2 ready
  - ❌ Empty: 0 ready

**Category Balance**
Count products by category:
- Guides
- Templates
- Skills
- Frameworks
- Bundles

**Recommendation:** Maintain 20-30% of products in each category (except bundles at 10-15%).

**Launch Cadence**
- Target: 1 product every 2 weeks
- Check scheduled launches for next 60 days
- Flag gaps > 3 weeks

**Revenue Health**
- Total revenue from published products
- Average revenue per product
- Revenue by category
- Progress toward $500 MRR target

#### Phase 4: Generate Status Report

```markdown
# Product Pipeline Status
Generated: YYYY-MM-DD HH:MM

## Pipeline Overview

**Total Products:** X
- 📅 Scheduled: X
- ✅ Ready: X
- 🔨 In Progress: X
- 💡 Ideas: X
- 📦 Published: X

## Health Metrics

### Buffer Health: [✅ Healthy | ⚠️ Low | ❌ Empty]
**Ready products:** X/3-5 target

[If Low or Empty:]
⚠️ Action needed: Package products to maintain launch buffer

### Category Balance
| Category   | Count | Target % | Status |
|-----------|-------|----------|---------|
| Guides     | X     | 20-30%   | [✅|⚠️|❌] |
| Templates  | X     | 20-30%   | [✅|⚠️|❌] |
| Skills     | X     | 20-30%   | [✅|⚠️|❌] |
| Frameworks | X     | 20-30%   | [✅|⚠️|❌] |
| Bundles    | X     | 10-15%   | [✅|⚠️|❌] |

[If imbalanced:]
💡 Recommendation: Focus on [under-represented category]

### Launch Cadence
**Target:** 1 product every 2 weeks

**Next 60 days:**
- [YYYY-MM-DD] - [Product Name] ($X)
- [YYYY-MM-DD] - [Product Name] ($X)
- [YYYY-MM-DD] - [Gap warning if > 3 weeks]

[If gaps exist:]
⚠️ Schedule launches to maintain momentum

### Revenue Health
**Total Revenue:** $X,XXX
**Published Products:** X
**Average per Product:** $XX
**Progress to $500 MRR:** XX%

**Top Performers:**
1. [Product Name] - $XXX
2. [Product Name] - $XXX
3. [Product Name] - $XXX

**Revenue by Category:**
- Guides: $XXX
- Templates: $XXX
- Skills: $XXX
- Frameworks: $XXX
- Bundles: $XXX

## Scheduled Launches

[List products with status="scheduled", sorted by launch_date]

| Launch Date | Product | Category | Price |
|------------|---------|----------|-------|
| YYYY-MM-DD | [Name]  | [Cat]    | $X    |

## Ready to Launch

[List products with status="ready"]

| Product | Category | Price | Ready Since |
|---------|----------|-------|-------------|
| [Name]  | [Cat]    | $X    | [Date]      |

💡 Use `/product-pipeline schedule [product-name] [date]` to schedule

## In Progress

[List products with status="drafting" or "polishing"]

| Product | Status | Category | Completion Est. |
|---------|--------|----------|-----------------|
| [Name]  | [Stat] | [Cat]    | [Hours]         |

## Bundle Opportunities 📦

[Scan for natural groupings based on category and theme]

### Recommended Bundle: [Bundle Name] ($X)
**Target Market:** [Who]
**Includes:**
- [Product 1] ($X)
- [Product 2] ($X)
- [Product 3] ($X)

**Individual Total:** $XX
**Bundle Price:** $XX (XX% discount)
**Status:** [ready | needs packaging]

💡 Create with: `/package-product [bundle-name]`

## Priority Recommendations

**Immediate Actions (This Week):**
1. [Action] - [Reason]
2. [Action] - [Reason]
3. [Action] - [Reason]

**Strategic Focus (This Month):**
- [Focus area 1]
- [Focus area 2]

**Long-Term Planning (90 Days):**
- [Strategic goal]
```

---

### Command: `next`

Recommend what to work on based on pipeline analysis and strategic priorities.

#### Phase 1: Analyze Pipeline State

Run status analysis (phases 1-3 from status command).

#### Phase 2: Prioritization Algorithm

**Priority Score Calculation:**

For each product idea or in-progress item, calculate:

```
Priority Score = (Value Score × 0.4) + (Urgency Score × 0.3) + (Effort Score × 0.3)
```

**Value Score (0-100):**
- High-priced products (>$40): 80-100
- Medium-priced ($15-40): 60-80
- Low-priced (<$15): 40-60
- Bundles: +20 bonus
- First in under-represented category: +15 bonus

**Urgency Score (0-100):**
- Buffer empty (0 ready): 100
- Buffer low (1-2 ready): 80
- Launch gap > 3 weeks: 70
- Category imbalance: 60
- Buffer healthy: 40

**Effort Score (0-100, inverted):**
- 1-3 hours to complete: 100
- 4-8 hours: 70
- 9-20 hours: 40
- 20+ hours: 20

#### Phase 3: Generate Recommendation

```markdown
# What to Work On Next
Generated: YYYY-MM-DD HH:MM

## Pipeline Context

**Buffer Status:** [Healthy | Low | Empty]
**Category Balance:** [Balanced | Imbalanced - Need more [X]]
**Launch Schedule:** [On track | Gap in [X weeks]]

## Top Recommendation 🎯

### [Product Name] - Priority Score: XX/100

**Why this product:**
- [Primary reason based on urgency/value/effort]
- [Secondary reason]
- [Strategic benefit]

**What it is:** [Brief description]
**Category:** [Category]
**Estimated Price:** $X
**Effort to Complete:** X hours
**Impact:** [What launching this achieves]

**Next Steps:**
1. [Specific action 1]
2. [Specific action 2]
3. [Specific action 3]

**Timeline:** [Realistic completion estimate]

---

## Alternative Options

### Option 2: [Product Name] - Score: XX/100
**Why:** [Brief reason]
**Effort:** X hours | **Value:** $X

### Option 3: [Product Name] - Score: XX/100
**Why:** [Brief reason]
**Effort:** X hours | **Value:** $X

---

## Quick Wins Available 🚀

[List products ready in 1-3 hours, if any]

1. **[Product Name]** - X hours, $X
   - [What's needed]

2. **[Product Name]** - X hours, $X
   - [What's needed]

💡 Quick wins are ideal when you have < 4 hours available

---

## Strategic Considerations

**Category Focus:**
[Current imbalance and what to prioritize]

**Bundle Opportunities:**
[If 3+ related products exist, recommend bundling]

**Revenue Gaps:**
[If certain price points are missing, recommend products to fill]

**Launch Cadence:**
[If falling behind schedule, prioritize ready-to-launch items]

---

## Action Plan

**Today:**
- [Start recommended product or complete quick win]

**This Week:**
- [Complete and schedule launch]

**Next 2 Weeks:**
- [Pipeline health action]

Use `/product-pipeline schedule [product-name] [date]` when ready to launch.
```

---

### Command: `schedule [product-name] [YYYY-MM-DD]`

Set a launch date for a product and update its status to "scheduled".

#### Phase 1: Validate Product

```bash
# Find product directory
Glob: 2. Areas/Hackastak_Brand/Gumroad/[product-name]*
```

Check:
- Product directory exists
- Product is status "ready" (has required files)
- Date is in the future
- No conflicts with other launches (same date)

#### Phase 2: Update Product Info

**If Product_Info.md exists:**
Update frontmatter:
```yaml
status: scheduled
launch_date: YYYY-MM-DD
```

**If Product_Info.md doesn't exist, create it:**
```yaml
---
status: scheduled
category: [Infer from directory contents]
price: [Extract from Gumroad_Listing_Instructions if available]
launch_date: YYYY-MM-DD
revenue: 0.00
gumroad_url: ""
blog_support: []
---

# [Product Name] - Product Info

Scheduled for launch: YYYY-MM-DD

## Files
[List files in directory]

## Next Steps
1. Final review of Gumroad_Listing_Instructions.md
2. Create cover image
3. Create ZIP bundle
4. Upload to Gumroad on launch day
5. Write supporting blog article
6. Share on X/Twitter
```

#### Phase 3: Check Launch Cadence

Calculate days until launch and days since last launch.

Warn if:
- Too soon: < 5 days (risk of launch fatigue)
- Too far: > 30 days (momentum loss)

#### Phase 4: Generate Launch Checklist

```markdown
✅ Product Scheduled: [Product Name]
Launch Date: YYYY-MM-DD (X days from now)

## Pre-Launch Checklist

**Week Before (YYYY-MM-DD):**
- [ ] Final content review
- [ ] Create cover image (1600x1200px)
- [ ] Generate PDF if not already done
- [ ] Create ZIP bundle
- [ ] Write Gumroad product description
- [ ] Draft supporting blog post
- [ ] Prepare social media announcement

**3 Days Before (YYYY-MM-DD):**
- [ ] Upload to Gumroad (keep in draft mode)
- [ ] Test download as customer
- [ ] Verify all files in ZIP
- [ ] Schedule blog post
- [ ] Prepare email to subscribers (if list exists)

**Launch Day (YYYY-MM-DD):**
- [ ] Publish on Gumroad
- [ ] Publish blog post
- [ ] Post on X/Twitter
- [ ] Share in relevant communities
- [ ] Update Product_Info.md with Gumroad URL
- [ ] Use `/product-pipeline publish [product-name] [url] [price]`

**Week After:**
- [ ] Monitor sales and feedback
- [ ] Respond to customer questions
- [ ] Update product based on feedback
- [ ] Track revenue in Product_Info.md

---

## Launch Cadence Check

[If < 5 days from last launch:]
⚠️ Quick turnaround: Last launch was [X] days ago. Consider spacing launches for maximum impact.

[If > 30 days from last launch:]
💡 Long gap: Last launch was [X] days ago. Consider scheduling another product sooner to maintain momentum.

[If optimal (7-21 days):]
✅ Good timing: Maintains momentum without overwhelming audience.

---

View updated calendar: `2. Areas/Hackastak_Brand/Gumroad/Product_Calendar.md`
```

---

### Command: `publish [product-name] [gumroad-url] [price]`

Mark a product as published and start tracking revenue.

#### Phase 1: Validate Inputs

Check:
- Product exists
- Product is status "scheduled" or "ready"
- Gumroad URL is valid (contains gumroad.com or gumroad.co)
- Price is valid number

#### Phase 2: Update Product Info

Update frontmatter in Product_Info.md:
```yaml
status: published
launch_date: YYYY-MM-DD (today if not set)
gumroad_url: [provided-url]
price: [provided-price]
revenue: 0.00
```

Add published notes:
```markdown
## Published Info

**Launch Date:** YYYY-MM-DD
**Gumroad URL:** [url]
**Price:** $X
**Initial Revenue:** $0.00

## Post-Launch

**First 7 Days:**
- Sales: [Track manually or via Gumroad API]
- Revenue: $X
- Customer Feedback: [Notes]

**First 30 Days:**
- Sales: X
- Revenue: $X
- Top Referrers: [Where sales came from]

**Ongoing:**
[Monthly revenue updates]
```

#### Phase 3: Update Skills Inventory (if applicable)

If product is a skill or skill bundle:
```bash
Read: 2. Areas/Hackastak_Brand/Gumroad/Skills_Inventory.md
```

Update the inventory with published status and Gumroad link.

#### Phase 4: Generate Post-Launch Report

```markdown
🎉 Product Published: [Product Name]

**Launch Details:**
- **Product:** [Product Name]
- **Category:** [Category]
- **Price:** $X
- **Gumroad URL:** [url]
- **Launch Date:** YYYY-MM-DD

---

## Post-Launch Actions

**Today:**
- [ ] Share launch announcement on X/Twitter
- [ ] Post in relevant communities (Reddit, Discord, etc.)
- [ ] Email subscribers (if list exists)
- [ ] Monitor initial feedback

**This Week:**
- [ ] Respond to all customer questions within 24 hours
- [ ] Track referral sources
- [ ] Note feedback for future improvements
- [ ] Update Product_Info.md with sales data

**First Month:**
- [ ] Collect testimonials from happy customers
- [ ] Update product based on feedback
- [ ] Write follow-up blog content
- [ ] Consider bundle opportunities

---

## Revenue Tracking

Revenue is currently tracked manually. Update Product_Info.md regularly:

**Weekly:**
```bash
Edit: 2. Areas/Hackastak_Brand/Gumroad/[Product_Name]/Product_Info.md
# Update revenue field in frontmatter
```

**Monthly Revenue Report:**
Use `/product-pipeline status` to see revenue breakdown.

---

## Pipeline Impact

**Published Products:** X (+1)
**Total Revenue:** $X,XXX
**Buffer Status:** [Current ready count]

[If buffer is low:]
💡 Start work on next product: `/product-pipeline next`

[If buffer is healthy:]
✅ Pipeline healthy. Schedule next launch when ready.

---

## Marketing Opportunities

**Supporting Content:**
- Write case study blog post
- Create tutorial video
- Share customer testimonials
- Bundle with related products

**Cross-Promotion:**
- Mention in other product READMEs
- Add to product bundles
- Link from blog articles
- Feature in email newsletter

View calendar: `2. Areas/Hackastak_Brand/Gumroad/Product_Calendar.md`
```

---

## Bundle Opportunity Detection

Run automatically during `status` and `next` commands.

### Detection Logic

**Scan all products (published + ready + scheduled):**

1. **Category Bundles**
   - Find 3+ skills in same category (Django, Go, Testing)
   - Find 3+ guides on related topics
   - Find 3+ templates for same workflow

2. **Workflow Bundles**
   - Products that work together in a workflow
   - Example: Blog Strategy + Templates + Examples

3. **Audience Bundles**
   - Products targeting same persona
   - Example: "For Content Creators", "For Django Developers"

4. **Value Tier Bundles**
   - Starter: 3-4 complementary products
   - Complete: 5-8 products covering domain
   - Ultimate: 10+ products, comprehensive

### Bundle Scoring

For each potential bundle, calculate:

**Cohesion Score (0-100):**
- All same category: 100
- Related categories: 70
- Same target audience: 80
- Workflow connection: 90
- Loose connection: 40

**Value Score (0-100):**
- Total individual price > $50: 100
- Total individual price $30-50: 80
- Total individual price < $30: 60

**Readiness Score (0-100):**
- All products published: 100
- All products ready/scheduled: 90
- Some products in progress: 50
- Some products are ideas: 20

**Bundle Priority = (Cohesion × 0.4) + (Value × 0.3) + (Readiness × 0.3)**

### Bundle Recommendation Format

```markdown
## Recommended Bundle: [Bundle Name] - Score: XX/100

**Bundle Concept:** [One-line pitch]
**Target Audience:** [Who this is for]
**Value Proposition:** [Why bundle vs individual]

**Includes:**
- [Product 1] ($X)
- [Product 2] ($X)
- [Product 3] ($X)
- [Product N] ($X)

**Pricing:**
- Individual Total: $XX
- Recommended Bundle Price: $XX (XX% discount)
- Profit Margin: $XX

**Readiness:**
- [X] products published
- [X] products ready
- [X] products in progress

**Next Steps:**
[If ready:]
1. Use `/package-product [bundle-name]` to create
2. Set bundle price and create product page
3. Schedule launch

[If not ready:]
1. Complete [product] first
2. Then use `/package-product [bundle-name]`
```

---

## Integration Points

### With Other Skills

**After running `/product-ideas`:**
Pipeline can track new product ideas automatically (if structured correctly).

**After running `/package-product`:**
Product moves from "idea" to "ready" status automatically.

**Before running `/blog-draft`:**
Check pipeline to identify products needing blog support.

### With Product Calendar

The Product_Calendar.md Dataview queries automatically reflect updates made by this skill.

### With Skills Inventory

For skill products, updates Skills_Inventory.md to track published status.

---

## Error Handling

### Product Not Found
```markdown
❌ Error: Product "[product-name]" not found

Searched in: 2. Areas/Hackastak_Brand/Gumroad/

Available products:
- [Product 1]
- [Product 2]
- [Product N]

Use exact product directory name.
```

### Invalid Status Transition
```markdown
❌ Error: Cannot schedule product "[product-name]"

Current status: [status]
Required status: ready

Product must be ready to launch before scheduling.

Check readiness:
- [ ] Has Gumroad_Listing_Instructions.md
- [ ] Has README.md
- [ ] Has product file (PDF/markdown/skill)
- [ ] All files are finalized

Use `/package-product [product-name]` if not yet packaged.
```

### Invalid Date
```markdown
❌ Error: Invalid launch date

Provided: [date]
Issue: [Date is in the past | Invalid format]

Required format: YYYY-MM-DD
Example: 2026-05-15
```

### Missing Required Parameter
```markdown
❌ Error: Missing required parameter

Usage: /product-pipeline publish [product-name] [gumroad-url] [price]

Example:
/product-pipeline publish Django-Patterns-Guide https://gumroad.com/l/django-patterns 7.00
```

---

## Success Metrics

A healthy product pipeline has:

✅ **3-5 products ready** to launch at any time
✅ **Balanced categories** (no single category > 40%)
✅ **Regular cadence** (1 launch every 2-3 weeks)
✅ **Growing revenue** (month-over-month increase)
✅ **Bundle opportunities** identified and in progress
✅ **Strategic clarity** (always know what to work on next)

---

## Example Usage

### Example 1: Check Pipeline Status

```
User: /product-pipeline status
Claude: I'll analyze your product pipeline.

[Reads Product_Calendar.md]
[Scans product directories]
[Calculates metrics]

# Product Pipeline Status
Generated: 2026-05-06 14:30

## Pipeline Overview

**Total Products:** 8
- 📅 Scheduled: 1
- ✅ Ready: 2
- 🔨 In Progress: 2
- 💡 Ideas: 3
- 📦 Published: 3

## Health Metrics

### Buffer Health: ⚠️ Low
**Ready products:** 2/3-5 target

⚠️ Action needed: Package 1-2 more products to maintain launch buffer

### Category Balance
| Category   | Count | Target % | Status |
|-----------|-------|----------|---------|
| Guides     | 3     | 20-30%   | ✅      |
| Templates  | 2     | 20-30%   | ⚠️      |
| Skills     | 1     | 20-30%   | ❌      |
| Frameworks | 1     | 20-30%   | ❌      |
| Bundles    | 1     | 10-15%   | ✅      |

💡 Recommendation: Focus on Skills and Frameworks

### Launch Cadence
**Target:** 1 product every 2 weeks

**Next 60 days:**
- 2026-05-15 - SDD Template ($12)
- 2026-06-01 - (16-day gap - consider scheduling another)

⚠️ Schedule launches to maintain momentum

### Revenue Health
**Total Revenue:** $247
**Published Products:** 3
**Average per Product:** $82
**Progress to $500 MRR:** 49%

**Top Performers:**
1. ADHD Guide - $127
2. Detox Guide - $89
3. SDD Template - $31

[Continue with rest of status report...]

Use `/product-pipeline next` to see recommendations.
```

---

### Example 2: Get Recommendation

```
User: /product-pipeline next

Claude: I'll recommend what to work on based on pipeline analysis.

[Analyzes pipeline]
[Calculates priority scores]

# What to Work On Next
Generated: 2026-05-06 14:35

## Pipeline Context

**Buffer Status:** Low (2/3-5 ready products)
**Category Balance:** Imbalanced - Need more Skills and Frameworks
**Launch Schedule:** On track but needs more scheduled

## Top Recommendation 🎯

### Django Patterns Guide - Priority Score: 88/100

**Why this product:**
- High value skill product ($7) in under-represented category
- Only 3 hours to complete (quick win)
- Skills category is weakest in portfolio (only 1 product)
- Strong market demand based on blog article performance

**What it is:** Collection of 50+ Django patterns for API development, authentication, and database optimization
**Category:** Skills
**Estimated Price:** $7
**Effort to Complete:** 3 hours
**Impact:** Fills critical category gap, adds high-margin product, enables Django bundle

**Next Steps:**
1. Use `/package-product django-patterns` (automated packaging)
2. Generate PDF from markdown (1 hour)
3. Create cover image (1 hour)
4. Review and finalize (1 hour)

**Timeline:** Can be ready to schedule by end of week

---

## Alternative Options

### Option 2: BREAK Method Framework - Score: 79/100
**Why:** Frameworks category gap, 95% complete
**Effort:** 2 hours | **Value:** $12

### Option 3: TDD Workflow Skill - Score: 75/100
**Why:** Adds to Skills category, enables bundle
**Effort:** 4 hours | **Value:** $7

---

## Quick Wins Available 🚀

1. **SDD Template** - 1 hour, $12
   - Just needs final PDF generation and cover

2. **BREAK Method** - 2 hours, $12
   - Add 3 examples and package

💡 Quick wins are ideal when you have < 4 hours available

---

## Strategic Considerations

**Category Focus:**
Skills (1 product) and Frameworks (1 product) are under-represented. Prioritize these categories to balance portfolio.

**Bundle Opportunities:**
With Django Patterns + TDD Workflow + Claude API skills, you'll have enough for a "Developer Productivity Bundle" ($19).

**Revenue Gaps:**
No products in $20-30 range. Consider guide or framework at this price point.

**Launch Cadence:**
Healthy schedule. Maintain by packaging 1 product per week.

---

## Action Plan

**Today:**
- Start packaging Django Patterns Guide

**This Week:**
- Complete and schedule Django Patterns launch
- Start on BREAK Method Framework

**Next 2 Weeks:**
- Launch Django Patterns
- Complete BREAK Method
- Begin work on Developer Productivity Bundle

Use `/product-pipeline schedule django-patterns [date]` when ready to launch.
```

---

### Example 3: Schedule a Launch

```
User: /product-pipeline schedule django-patterns 2026-05-22

Claude: I'll schedule Django Patterns Guide for launch.

[Validates product exists and is ready]
[Updates Product_Info.md]
[Generates launch checklist]

✅ Product Scheduled: Django Patterns Guide
Launch Date: 2026-05-22 (16 days from now)

## Pre-Launch Checklist

**Week Before (2026-05-15):**
- [ ] Final content review
- [ ] Create cover image (1600x1200px)
- [ ] Generate PDF if not already done
- [ ] Create ZIP bundle
- [ ] Write Gumroad product description
- [ ] Draft supporting blog post
- [ ] Prepare social media announcement

**3 Days Before (2026-05-19):**
- [ ] Upload to Gumroad (keep in draft mode)
- [ ] Test download as customer
- [ ] Verify all files in ZIP
- [ ] Schedule blog post
- [ ] Prepare email to subscribers

**Launch Day (2026-05-22):**
- [ ] Publish on Gumroad
- [ ] Publish blog post
- [ ] Post on X/Twitter
- [ ] Share in relevant communities
- [ ] Update Product_Info.md with Gumroad URL
- [ ] Use `/product-pipeline publish django-patterns [url] 7.00`

**Week After:**
- [ ] Monitor sales and feedback
- [ ] Respond to customer questions
- [ ] Update product based on feedback
- [ ] Track revenue in Product_Info.md

---

## Launch Cadence Check

✅ Good timing: 7 days after SDD Template launch. Maintains momentum without overwhelming audience.

---

View updated calendar: `2. Areas/Hackastak_Brand/Gumroad/Product_Calendar.md`
```

---

### Example 4: Mark as Published

```
User: /product-pipeline publish django-patterns https://gumroad.com/l/django-patterns 7.00

Claude: I'll mark Django Patterns as published and start revenue tracking.

[Validates inputs]
[Updates Product_Info.md]
[Updates Skills_Inventory.md]

🎉 Product Published: Django Patterns Guide

**Launch Details:**
- **Product:** Django Patterns Guide
- **Category:** Skills
- **Price:** $7.00
- **Gumroad URL:** https://gumroad.com/l/django-patterns
- **Launch Date:** 2026-05-22

---

## Post-Launch Actions

**Today:**
- [ ] Share launch announcement on X/Twitter
- [ ] Post in Django subreddit
- [ ] Email subscribers
- [ ] Monitor initial feedback

**This Week:**
- [ ] Respond to all customer questions within 24 hours
- [ ] Track referral sources (X, blog, Reddit, etc.)
- [ ] Note feedback for future improvements
- [ ] Update Product_Info.md with sales data

**First Month:**
- [ ] Collect testimonials from happy customers
- [ ] Update product based on feedback
- [ ] Write "Advanced Django Patterns" follow-up
- [ ] Plan Django Mastery Bundle (with TDD + API skills)

---

## Revenue Tracking

Revenue is currently tracked manually. Update Product_Info.md weekly:

```bash
# Edit frontmatter in Product_Info.md
revenue: [updated-amount]
```

Use `/product-pipeline status` monthly to see revenue breakdown.

---

## Pipeline Impact

**Published Products:** 4 (+1)
**Total Revenue:** $247 (will update with Django Patterns sales)
**Buffer Status:** 1 ready product (⚠️ Low - package more!)

💡 Start work on next product: `/product-pipeline next`

---

## Marketing Opportunities

**Supporting Content:**
- "10 Django Patterns That Changed How I Build APIs" (blog)
- Tutorial video demonstrating top 3 patterns
- Share customer success stories

**Cross-Promotion:**
- Mention in TDD Workflow skill README
- Bundle with Claude API skill (Developer Productivity Bundle)
- Link from Django blog articles

**Community Sharing:**
- r/django
- Django Discord
- Python developers on X
- Dev.to with django tag

View calendar: `2. Areas/Hackastak_Brand/Gumroad/Product_Calendar.md`
```

---

## Anti-Patterns to Avoid

❌ **Don't ignore pipeline health** - Launch cadence and buffer matter
❌ **Don't schedule too aggressively** - < 5 days between launches dilutes impact
❌ **Don't neglect categories** - Portfolio balance attracts diverse buyers
❌ **Don't forget revenue tracking** - Manual updates are fine but must be consistent
❌ **Don't skip bundle analysis** - Bundles drive higher revenue per customer
❌ **Don't launch without blog support** - Every product needs content marketing

---

## Key Principles

1. **Maintain buffer** - Always have 3-5 products ready to launch
2. **Balance categories** - Diverse portfolio attracts more buyers
3. **Consistent cadence** - 1 launch every 2 weeks maintains momentum
4. **Track everything** - Revenue, referrers, feedback inform strategy
5. **Think bundles** - Group related products for 30-50% higher value
6. **Strategic prioritization** - Use value/urgency/effort scoring to decide what's next

---

## Notes

- Run `/product-pipeline status` monthly for health check
- Run `/product-pipeline next` when starting new work
- Update revenue manually in Product_Info.md (weekly or after sales)
- Pipeline health drives MRR growth - maintain discipline
- Bundle opportunities emerge naturally with balanced portfolio
- Blog support is critical - products without content support underperform
