---
name: package-product
description: Automate product packaging for Gumroad - handles guides, templates, skills, frameworks, and bundles. Generates appropriate documentation and sales pages based on product type.
origin: Hackastak
---

# Package Product for Gumroad

Automate the complete packaging workflow for any digital product ready to sell on Gumroad.

## When to Activate

- User runs `/package-product [product-name]` command
- User runs `/package-product [product-name] --type=[type]` for specific type
- User asks to "package [product] for Gumroad"
- User wants to prepare a product for launch
- After selecting products from `/product-ideas` report

## Supported Product Types

1. **guide** - Comprehensive guides, ebooks, PDFs (ADHD Guide, Detox Guide, etc.)
2. **template** - Reusable templates, checklists, frameworks
3. **skill** - Claude Code skills from `~/Developer/Staksmith/skills/`
4. **framework** - Methodologies and systems (BREAK Method, etc.)
5. **bundle** - Collections of related products (Django Mastery, Content Creator, etc.)

## Workflow Overview

### Phase 1: Detect or Ask for Product Type

**If `--type` flag provided:**
Use specified type directly.

**If product directory already exists in Gumroad folder:**
Detect from existing files:
- Has SKILL.md or references Claude Code → `skill`
- Large PDF guide (>20 pages) → `guide`
- Template files → `template`
- Framework/methodology docs → `framework`
- Multiple products → `bundle`

**Otherwise, ask user:**
```
What type of product is "[product-name]"?

1. guide - Comprehensive guide/ebook (delivered as PDF)
2. template - Reusable template or checklist
3. skill - Claude Code skill for developers
4. framework - Methodology or system
5. bundle - Collection of multiple products

Select number or type:
```

### Phase 2: Type-Specific Detection and Validation

#### For type: `guide`

**Auto-detect source:**
1. Check if already in Gumroad folder: `2. Areas/Hackastak_Brand/Gumroad/[Product_Name]/`
2. Search vault for guide files:
   ```bash
   Glob: **/*[product-name]*.md
   ```
3. Look for existing PDF files

**Validation:**
- Product has a substantial PDF (already created)
- OR has markdown that can be converted to PDF
- Warn if PDF doesn't exist and needs to be created

#### For type: `template`

**Auto-detect source:**
1. Check `_templates/` directory
2. Check vault for template files
3. Check if already in Gumroad folder

**Validation:**
- Template file exists
- Template has clear structure

#### For type: `skill`

**Auto-detect source:**
```bash
# Check Staksmith skills directory
ls ~/Developer/Staksmith/skills/[product-name]/SKILL.md
```

**Validation:**
- SKILL.md exists in Staksmith
- Skill has proper frontmatter (name, description, origin)

#### For type: `framework`

**Auto-detect source:**
1. Search vault for framework documentation
2. Check if already in Gumroad folder

**Validation:**
- Framework has clear methodology/steps
- Documentation is complete

#### For type: `bundle`

**Ask for bundle contents:**
```
What should be included in this bundle?

Enter product names (comma-separated):
Example: django-patterns, tdd-workflow, claude-api
```

**Validation:**
- At least 3 items
- All items exist and are accessible

---

### Phase 3: Create Product Directory

**Directory location:**
```bash
mkdir -p "/Users/hackastak/Developer/My_Notes/2. Areas/Hackastak_Brand/Gumroad/[Product_Name]"
```

**If directory already exists:**
- Detect existing files
- Merge with new packaging (don't overwrite PDF if it exists)
- Update Gumroad_Listing_Instructions.md only

---

### Phase 4: Type-Specific File Preparation

#### Type: `guide`

**Files to create/verify:**
```
2. Areas/Hackastak_Brand/Gumroad/[Product_Name]/
├── Gumroad_Listing_Instructions.md  # Sales page copy
├── [Product_Name].pdf                # Main deliverable (verify exists)
└── Product_Info.md                   # Internal tracking
```

**Steps:**
1. **Check for existing PDF:**
   ```bash
   ls "2. Areas/Hackastak_Brand/Gumroad/[Product_Name]"/*.pdf
   ```

2. **If PDF exists:** Note in output that PDF is ready

3. **If PDF doesn't exist:**
   - Check for markdown source
   - Provide instructions for PDF generation
   - Note: Packaging can complete without PDF, but product isn't ready to launch

4. **Generate Gumroad_Listing_Instructions.md** (see Phase 5)

5. **Create Product_Info.md** (see Phase 6)

**No README needed** - Guides are self-contained PDFs

---

#### Type: `template`

**Files to create:**
```
2. Areas/Hackastak_Brand/Gumroad/[Product_Name]/
├── Gumroad_Listing_Instructions.md  # Sales page copy
├── [Product_Name]_Template.md       # The template file
├── HOW_TO_USE.md                    # Usage instructions for customer
└── Product_Info.md                  # Internal tracking
```

**Steps:**
1. **Copy template file:**
   ```bash
   cp [source-path] ./[Product_Name]_Template.md
   ```

2. **Generate HOW_TO_USE.md:**
   ```markdown
   # How to Use: [Template Name]

   ## What This Template Does

   [Brief description of template purpose]

   ## How to Use

   1. **Copy the template**
      - Open `[Product_Name]_Template.md`
      - Copy entire contents to your project

   2. **Fill in the sections**
      - [Section 1]: [What to put here]
      - [Section 2]: [What to put here]
      - [Section N]: [What to put here]

   3. **Customize for your needs**
      - [Customization tip 1]
      - [Customization tip 2]

   ## Examples

   [Show 1-2 examples of filled templates if applicable]

   ## Tips for Best Results

   - [Tip 1]
   - [Tip 2]
   - [Tip 3]

   ## Questions?

   - X: @hackastak
   - Email: dev@hackastak.com
   ```

3. **Generate Gumroad_Listing_Instructions.md** (see Phase 5)

4. **Create Product_Info.md** (see Phase 6)

---

#### Type: `skill`

**Files to create:**
```
2. Areas/Hackastak_Brand/Gumroad/[Product_Name]/
├── Gumroad_Listing_Instructions.md
├── [Product_Name].md          # Markdown version (from SKILL.md)
├── [Product_Name].pdf          # PDF version
├── README.md                   # Installation guide
└── Product_Info.md             # Internal tracking
```

**Steps:**
1. **Copy SKILL.md:**
   ```bash
   cp ~/Developer/Staksmith/skills/[skill-name]/SKILL.md ./[Product_Name].md
   ```

2. **Generate README.md with installation instructions:**
   ```markdown
   # [Skill Name] - Claude Code Skill

   [One-line description from SKILL.md]

   ## What's Included

   - **[Product_Name].md** - Complete skill definition
   - **[Product_Name].pdf** - PDF version for reference
   - [Key pattern 1]
   - [Key pattern 2]
   - [Key pattern 3]

   ## Installation

   ### Quick Install

   ```bash
   # Copy to Claude Code skills directory
   mkdir -p ~/.claude/skills/[skill-name]
   cp [Product_Name].md ~/.claude/skills/[skill-name]/SKILL.md
   ```

   ### Verify Installation

   ```bash
   cat ~/.claude/skills/[skill-name]/SKILL.md
   ```

   You should see the skill definition with frontmatter.

   ### Use in Your Project

   Reference in your project's `CLAUDE.md`:

   ```markdown
   ## [Domain] Development

   Use the [skill-name] skill when [use case].
   ```

   ## When This Skill Activates

   This skill activates when:
   - [Trigger condition 1]
   - [Trigger condition 2]
   - [Trigger condition 3]

   ## What You'll Learn

   - [Learning outcome 1]
   - [Learning outcome 2]
   - [Learning outcome 3]

   ## Support

   Questions? Issues?
   - X: @hackastak
   - Email: dev@hackastak.com
   - Blog: https://hackastak.com

   **Version:** 1.0
   **Last Updated:** [YYYY-MM-DD]
   **Compatible With:** Claude Code v0.18+
   ```

3. **Note PDF generation needed** (manual step)

4. **Generate Gumroad_Listing_Instructions.md** (see Phase 5)

5. **Create Product_Info.md** (see Phase 6)

---

#### Type: `framework`

**Files to create:**
```
2. Areas/Hackastak_Brand/Gumroad/[Product_Name]/
├── Gumroad_Listing_Instructions.md
├── [Product_Name].pdf              # Main deliverable
├── IMPLEMENTATION_GUIDE.md          # How to apply framework
└── Product_Info.md                  # Internal tracking
```

**Steps:**
1. **Copy framework docs** or verify PDF exists

2. **Generate IMPLEMENTATION_GUIDE.md:**
   ```markdown
   # [Framework Name] - Implementation Guide

   ## What This Framework Does

   [Brief description of framework purpose and benefits]

   ## The Framework

   [High-level overview of framework structure]

   ## How to Implement

   ### Step 1: [First Step]
   [Detailed instructions]

   ### Step 2: [Second Step]
   [Detailed instructions]

   ### Step N: [Final Step]
   [Detailed instructions]

   ## Real-World Examples

   ### Example 1: [Scenario]
   [Show framework applied]

   ### Example 2: [Scenario]
   [Show framework applied]

   ## Common Pitfalls

   - **Pitfall 1:** [What to avoid and why]
   - **Pitfall 2:** [What to avoid and why]

   ## Customizing for Your Needs

   [How to adapt framework to different contexts]

   ## Support

   - X: @hackastak
   - Email: dev@hackastak.com
   ```

3. **Generate Gumroad_Listing_Instructions.md** (see Phase 5)

4. **Create Product_Info.md** (see Phase 6)

---

#### Type: `bundle`

**Files to create:**
```
2. Areas/Hackastak_Brand/Gumroad/[Product_Name]/
├── Gumroad_Listing_Instructions.md
├── [item1]/                         # Individual products
├── [item2]/
├── [itemN]/
├── README.md                        # Bundle installation/usage
├── WORKFLOWS.md                     # How to use items together
└── Product_Info.md                  # Internal tracking
```

**Steps:**
1. **Copy all bundle items** to subdirectories

2. **Generate README.md:**
   ```markdown
   # [Bundle Name]

   [One-line value proposition]

   ## What's Included

   [X] items in this bundle:

   1. **[item-1]** - [Brief description]
   2. **[item-2]** - [Brief description]
   3. **[item-N]** - [Brief description]

   **Value:** $[X] if purchased individually
   **Bundle Price:** $[Y] ([Z]% savings)

   ## Quick Start

   [Type-specific installation/usage based on bundle contents]

   ## What You Can Do

   By combining these [items], you can:
   - [Outcome 1]
   - [Outcome 2]
   - [Outcome 3]

   ## Common Workflows

   See `WORKFLOWS.md` for step-by-step workflows using multiple items together.

   ## Support

   - X: @hackastak
   - Email: dev@hackastak.com

   **Version:** 1.0
   **Last Updated:** [YYYY-MM-DD]
   ```

3. **Generate WORKFLOWS.md** (common workflows using bundle items)

4. **Generate Gumroad_Listing_Instructions.md** (see Phase 5)

5. **Create Product_Info.md** (see Phase 6)

---

### Phase 5: Generate Gumroad Listing Instructions (Type-Specific)

Generate `Gumroad_Listing_Instructions.md` with type-appropriate copy.

#### For type: `guide`

```markdown
# Gumroad Listing Instructions - [Product Name]

## Product Setup

**Product Name:** [Product Name]
**Price:** $[X]
**Category:** Education | Self-Help | [Relevant category]
**Product Type:** Digital Product (PDF)

## Short Description (160 chars max)

[One-line hook that describes the transformation or key benefit]

## Long Description

### [Hook - Lead with the pain point]

[2-3 sentences describing the problem this guide solves]

### [Solution - What this guide is]

[2-3 sentences about what's in the guide and how it helps]

## What's Included

📕 **[Product_Name].pdf** - [X]-page comprehensive guide

## What You'll Learn

✅ [Key outcome 1]
✅ [Key outcome 2]
✅ [Key outcome 3]
✅ [Key outcome N]

## Perfect For

- [Target persona 1 with specific pain point]
- [Target persona 2 with specific pain point]
- [Target persona 3 with specific pain point]

❌ **Not for:** [Who shouldn't buy this]

## What You'll Be Able To Do

After reading this guide, you'll:
- [Specific outcome 1]
- [Specific outcome 2]
- [Specific outcome 3]

## Technical Details

- **Format:** PDF
- **Pages:** [X]
- **File Size:** ~[X]MB
- **Compatible With:** Any PDF reader (Adobe, Preview, browsers)
- **Updates:** Free lifetime updates included
- **Support:** Email support via dev@hackastak.com

## Tags

[tag1], [tag2], [tag3], [tag4], [tag5], pdf, guide, ebook

---

## Upload Instructions

### Step 1: Verify PDF

```bash
ls "2. Areas/Hackastak_Brand/Gumroad/[Product_Name]"/*.pdf
```

Ensure PDF is final version.

### Step 2: Upload to Gumroad

1. Go to gumroad.com/products/new
2. Upload `[Product_Name].pdf`
3. Set product name: "[Product Name]"
4. Set price: $[X]
5. Copy description from "Long Description" section above
6. Add all tags from "Tags" section

### Step 3: Create Cover Image

**Recommended Specs:**
- Size: 1600x1200px
- Format: PNG or JPG
- Include: Product name, key benefit, page count

**Content to highlight:**
- Main transformation/benefit
- "📕 [X]-Page PDF Guide"
- Price

### Step 4: Final Checklist

- [ ] PDF is final version
- [ ] Product name is clear and benefit-focused
- [ ] Description highlights transformation
- [ ] Price is set correctly
- [ ] Tags are added
- [ ] Cover image uploaded
- [ ] Test download as customer (use Test mode)

---

## Support & Marketing

**Support Email:** dev@hackastak.com
**X/Twitter:** @hackastak
**Blog:** https://hackastak.com

**Supporting Blog Article Ideas:**
- [Article idea 1 - share key concepts from guide]
- [Article idea 2 - case study or example]
- [Article idea 3 - common mistakes the guide helps avoid]
```

#### For type: `template`

```markdown
# Gumroad Listing Instructions - [Template Name]

## Product Setup

**Product Name:** [Template Name]
**Price:** $[X]
**Category:** Productivity | Business | [Relevant category]
**Product Type:** Digital Product (Markdown Template)

## Short Description (160 chars max)

[One-line description of what the template helps with]

## Long Description

### [Problem]

[2-3 sentences about the problem this template solves]

### [Solution]

[2-3 sentences about how the template provides structure/framework]

## What's Included

📄 **[Product_Name]_Template.md** - Ready-to-use template
📘 **HOW_TO_USE.md** - Step-by-step usage guide with examples

## What You'll Get

✅ [Key component 1]
✅ [Key component 2]
✅ [Key component 3]
✅ [Key component N]

## Perfect For

- [User persona 1]
- [User persona 2]
- [User persona 3]

## How to Use

1. Download the template
2. Copy to your project/notes
3. Fill in the sections
4. Customize for your needs

See `HOW_TO_USE.md` for detailed instructions and examples.

## Technical Details

- **Format:** Markdown (.md)
- **Compatible With:** Obsidian, Notion, VS Code, any text editor
- **Updates:** Free lifetime updates included
- **Support:** Email support via dev@hackastak.com

## Tags

[tag1], [tag2], template, checklist, framework, markdown

---

## Upload Instructions

### Step 1: Create ZIP

```bash
cd "2. Areas/Hackastak_Brand/Gumroad/[Product_Name]"
zip -r [Product_Name]-v1.0.zip [Product_Name]_Template.md HOW_TO_USE.md
```

### Step 2: Upload to Gumroad

1. Go to gumroad.com/products/new
2. Upload `[Product_Name]-v1.0.zip`
3. Set product name: "[Template Name]"
4. Set price: $[X]
5. Copy description from above
6. Add all tags

### Step 3: Create Cover Image

Show template structure and key sections visually.

### Step 4: Final Checklist

- [ ] ZIP contains template and HOW_TO_USE guide
- [ ] Product name is clear
- [ ] Description explains use case
- [ ] Price is set
- [ ] Tags added
- [ ] Cover image uploaded
- [ ] Test download

---

## Support & Marketing

**Support Email:** dev@hackastak.com
**X/Twitter:** @hackastak

**Supporting Blog Article Ideas:**
- [How to use this template effectively]
- [Case study of template in action]
- [Common mistakes this template prevents]
```

#### For type: `skill`

```markdown
# Gumroad Listing Instructions - [Skill Name]

## Product Setup

**Product Name:** [Skill Name] - Multi-Format Bundle
**Price:** $[X]
**Category:** Software Development Tools | Digital Products
**Product Type:** Claude Code Skill (Multi-Format)

## Short Description (160 chars max)

[One-line hook about what the skill enables developers to do]

## Long Description

### [Hook - Developer pain point]

[2-3 sentences about coding challenge this skill solves]

### [Solution - What this skill is]

[2-3 sentences about skill capabilities]

## Multi-Format Bundle - What's Included

This is a **multi-format bundle** that includes:

📄 **Markdown Version** ([Product_Name].md)
- Perfect for developers who want to read in their editor
- Syntax highlighting and easy navigation
- Copy-paste patterns directly

📕 **PDF Version** ([Product_Name].pdf)
- Beautiful formatted document
- Perfect for reading on tablets or printing
- Includes all content from markdown version

📘 **README.md** - Installation & Usage Guide
- Step-by-step installation for Claude Code
- Quick start guide
- Integration examples

## What You'll Learn/Get

✅ [Key pattern/technique 1]
✅ [Key pattern/technique 2]
✅ [Key pattern/technique 3]
✅ [Key pattern/technique N]

## Perfect For

- [Developer persona 1 with specific need]
- [Developer persona 2 with specific need]
- [Developer persona 3 with specific need]

❌ **Not for:** [Who shouldn't buy this]

## What You'll Be Able To Do

After installing this skill, Claude Code will:
- [Capability 1]
- [Capability 2]
- [Capability 3]

## Technical Details

- **Formats:** Markdown (.md) + PDF (.pdf) + README
- **Compatibility:** Claude Code v0.18+
- **Installation:** Copy to `~/.claude/skills/`
- **Updates:** Free lifetime updates included
- **Support:** Email support via dev@hackastak.com

## Tags

claude-code, ai-development, [language/framework], skill, multi-format, digital-download

---

## Upload Instructions

### Step 1: Create ZIP File

```bash
cd "2. Areas/Hackastak_Brand/Gumroad/[Product_Name]"
zip -r [Product_Name]-v1.0.zip [Product_Name].md [Product_Name].pdf README.md
```

### Step 2: Upload to Gumroad

1. Go to gumroad.com/products/new
2. Upload `[Product_Name]-v1.0.zip`
3. Set product name: "[Skill Name] - Multi-Format Bundle"
4. Set price: $[X]
5. Copy description from above
6. Add all tags

### Step 3: Create Cover Image

**Recommended Specs:** 1600x1200px

**Content to highlight:**
- "📄 Markdown + 📕 PDF + 📘 README"
- Main benefit/capability
- "For Claude Code"
- Price

### Step 4: Final Checklist

- [ ] ZIP file contains all 3 formats (MD, PDF, README)
- [ ] Product name includes "Multi-Format Bundle"
- [ ] Description mentions all 3 formats
- [ ] Price is set
- [ ] Tags include "claude-code" and "multi-format"
- [ ] Cover image uploaded
- [ ] Test download

---

## Support & Marketing

**Support Email:** dev@hackastak.com
**X/Twitter:** @hackastak
**Blog:** https://hackastak.com

**Supporting Blog Article Ideas:**
- [Showcase 3-5 patterns from the skill]
- [Real-world use case with before/after]
- [How this skill improved development workflow]
```

#### For type: `framework` and `bundle`

Similar structure to above, adapted for their specific content types.

---

### Phase 6: Create Product_Info.md (All Types)

Create internal tracking file with type-specific metadata.

```yaml
---
status: ready
category: [Guides | Templates | Skills | Frameworks | Bundles]
type: [guide | template | skill | framework | bundle]
price: [X.00]
launch_date:
revenue: 0.00
gumroad_url: ""
blog_support: []
seed_idea: "[One-line description]"
source_location: "[Path to original source]"
# Type-specific fields
bundle_includes: []  # For bundles only
skill_count: 0       # For bundles with skills
pages: 0             # For guides/frameworks (PDF page count)
---

# [Product Name] - Product Info

## Status
Ready for launch

## Files
[List files that were created/verified]

## Next Steps
1. [Type-specific next steps]
2. Create cover image
3. Create final package/ZIP
4. Upload to Gumroad
5. Write supporting blog article
6. Schedule launch

## Tracking
Created: [YYYY-MM-DD]
Launch Target: [YYYY-MM-DD]
```

---

### Phase 7: Output Summary (Type-Specific)

Generate appropriate summary based on product type.

#### For type: `guide`

```markdown
✅ Guide Package Created: [Product Name]

## Files Created/Verified

📁 2. Areas/Hackastak_Brand/Gumroad/[Product_Name]/
├── Gumroad_Listing_Instructions.md  # Upload instructions & listing copy
├── [Product_Name].pdf               # [✅ Exists | ⚠️ Needs creation]
└── Product_Info.md                  # Internal tracking

## Status

✅ Product directory set up
✅ Gumroad listing instructions generated
[✅ | ⚠️] PDF verified
✅ Product info tracking file created

## Next Steps

[If PDF doesn't exist:]
1. **Create PDF from source:**
   - Export from Obsidian, Word, Google Docs, etc.
   - Save as `[Product_Name].pdf` in product directory

[If PDF exists:]
1. **Create cover image** (1600x1200px)
   - Show main benefit
   - Include page count
   - Use Canva, Figma, or `/fal-ai-media`

2. **Upload to Gumroad:**
   - See `Gumroad_Listing_Instructions.md` for complete guide
   - Upload PDF directly (no ZIP needed for single-file products)
   - Set price: $[X]

3. **Write supporting blog article:**
   - See suggestions in `Gumroad_Listing_Instructions.md`
   - Use `/blog-draft` to create

4. **Schedule launch:**
   - Use `/product-pipeline schedule [Product_Name] [YYYY-MM-DD]`

## Product Calendar

✅ Product directory created and will appear in Product_Calendar.md Dataview queries

View with: Open `2. Areas/Hackastak_Brand/Gumroad/Product_Calendar.md`
```

#### For other types

Similar structure, adapted to what files were created and what next steps are needed.

---

## Error Handling

### Product Already Packaged

```markdown
ℹ️ Product directory already exists: [Product Name]

Found existing files:
- [File 1]
- [File 2]
- [File N]

Options:
1. Update Gumroad_Listing_Instructions.md only
2. Re-package completely (will backup existing files)
3. Cancel

What would you like to do?
```

### Source Not Found

```markdown
❌ Error: Cannot find source for "[product-name]"

Searched:
- ~/Developer/Staksmith/skills/[product-name]/
- 2. Areas/Hackastak_Brand/Gumroad/[Product_Name]/
- Vault for matching files

Please specify source location:
- Provide full path to source file
- Or place files in Gumroad/[Product_Name]/ directory manually
```

### Missing Required Files (type: skill)

```markdown
⚠️ Warning: SKILL.md not found

Expected: ~/Developer/Staksmith/skills/[skill-name]/SKILL.md

Cannot package skill without SKILL.md.

Options:
1. Create skill first at expected location
2. Change product type (is this a guide or template instead?)
3. Specify custom source location
```

---

## Integration with Other Skills

**After running `/product-ideas`:**
```bash
/package-product [product-from-report]
```

**Before running `/product-pipeline schedule`:**
Product must be packaged first (have Gumroad_Listing_Instructions.md).

**With `/blog-draft`:**
Use supporting blog article ideas from Gumroad_Listing_Instructions.md.

---

## Key Principles

1. **Type-appropriate packaging** - Don't force all products into same format
2. **Respect existing work** - Don't overwrite PDFs or completed files
3. **Clear next steps** - Always tell user what's needed before launch
4. **Flexible sources** - Find products in Staksmith, vault, or Gumroad folder
5. **Ready to launch** - Output should be immediately usable for Gumroad

---

## Example Usage

### Example 1: Package Existing Guide

```
User: /package-product ADHD_Project_Completion_Guide

Claude: I'll package the ADHD Project Completion Guide for Gumroad.

[Detects product already in Gumroad folder]
[Detects type: guide (has large PDF)]
[Verifies PDF exists]

✅ Guide Package Created: ADHD Project Completion Guide

## Files Created/Verified

📁 2. Areas/Hackastak_Brand/Gumroad/ADHD_Project_Completion_Guide/
├── Gumroad_Listing_Instructions.md  # ✅ Generated
├── ADHDProjectCompletionGuide.pdf   # ✅ Exists (490KB)
└── Product_Info.md                  # ✅ Created

## Status

✅ Product directory already existed
✅ PDF verified and ready
✅ Gumroad listing instructions generated
✅ Product info tracking created

## Next Steps

1. **Review listing copy:**
   Open `Gumroad_Listing_Instructions.md` and customize if needed

2. **Create cover image** (1600x1200px)
   - Highlight "Complete System for ADHD Project Completion"
   - Show page count
   - Use professional design

3. **Upload to Gumroad:**
   - Upload PDF directly
   - Price: $29-49 (comprehensive guide)
   - Copy description from listing instructions

4. **Schedule launch:**
   `/product-pipeline schedule ADHD_Project_Completion_Guide 2026-05-20`

Product is READY TO LAUNCH! 🚀
```

---

### Example 2: Package New Skill

```
User: /package-product django-patterns --type=skill

Claude: I'll package the Django Patterns skill for Gumroad.

[Finds SKILL.md in Staksmith]
[Creates multi-format bundle]

✅ Multi-Format Bundle Package Created: Django Patterns

## Files Created

📁 2. Areas/Hackastak_Brand/Gumroad/Django_Patterns/
├── Gumroad_Listing_Instructions.md  # Upload instructions
├── Django_Patterns.md               # Markdown version
├── Django_Patterns.pdf              # ⏳ Needs generation
├── README.md                        # Installation guide
└── Product_Info.md                  # Internal tracking

## Multi-Format Bundle Contents

📄 **Markdown Version:** Django_Patterns.md (✅ Ready)
📕 **PDF Version:** Django_Patterns.pdf (⚠️ Needs generation)
📘 **README:** Installation & usage guide (✅ Ready)

## Next Steps

1. **Generate PDF from Markdown:**
   ```bash
   cd "2. Areas/Hackastak_Brand/Gumroad/Django_Patterns"
   pandoc Django_Patterns.md -o Django_Patterns.pdf
   # OR: Export from Obsidian, VS Code, or use online converter
   ```

2. **Create ZIP Bundle:**
   ```bash
   zip -r Django_Patterns-v1.0.zip Django_Patterns.md Django_Patterns.pdf README.md
   ```

3. **Create cover image** (1600x1200px)
   - "Multi-Format Bundle" badge
   - "📄 Markdown + 📕 PDF + 📘 README"

4. **Upload to Gumroad:**
   - See `Gumroad_Listing_Instructions.md`
   - Price: $7
   - Upload ZIP

5. **Schedule launch:**
   `/product-pipeline schedule Django_Patterns 2026-05-22`
```

---

### Example 3: Package Template

```
User: /package-product SDD_Template

Claude: I'll package the SDD Template for Gumroad.

[Detects existing product in Gumroad folder]
[Detects type: template]

✅ Template Package Created: SDD Template

## Files Created

📁 2. Areas/Hackastak_Brand/Gumroad/SDD_Template/
├── Gumroad_Listing_Instructions.md
├── SDD_Template.md                 # ✅ Template file
├── HOW_TO_USE.md                   # ✅ Usage guide
└── Product_Info.md

## Next Steps

1. **Create ZIP:**
   ```bash
   cd "2. Areas/Hackastak_Brand/Gumroad/SDD_Template"
   zip -r SDD_Template-v1.0.zip SDD_Template.md HOW_TO_USE.md
   ```

2. **Create cover image**
   - Show template structure visually
   - Highlight key sections

3. **Upload to Gumroad:**
   - Upload ZIP
   - Price: $7-12
   - See `Gumroad_Listing_Instructions.md` for full listing copy

4. **Schedule launch:**
   `/product-pipeline schedule SDD_Template 2026-05-15`

Product is ready after ZIP creation! 🚀
```

---

## Notes

- Always respect existing files (especially PDFs and completed guides)
- Type detection should be smart but allow user override
- Not all products need README.md (only skills and technical products)
- Gumroad listing copy should match product type and audience
- Support both new packaging and updating existing products
