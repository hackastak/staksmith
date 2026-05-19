# package-product

Automate product packaging for Gumroad - creates multi-format bundles (Markdown + PDF + README) with listing instructions.

## What It Does

Handles the complete packaging workflow:
1. **Creates product directory** in vault's Gumroad folder
2. **Prepares multi-format bundle:** Markdown + PDF + README
3. **Generates Gumroad listing instructions** (always assumes multi-format bundle)
4. **Creates tracking file** with status and pricing
5. **Updates Product Calendar** automatically (via Dataview)

Supports:
- Individual skills (from `~/Developer/Staksmith/skills/`)
- Guides and templates (from vault)
- Bundles (collections of multiple products)

## When to Use

- After `/product-ideas` identifies a product to launch
- When you have a complete guide/framework ready to sell
- To bundle related skills into a package
- Before uploading to Gumroad

## Installation

```bash
# Copy to vault's skills directory
cp SKILL.md /path/to/vault/.claude/skills/package-product/
```

## Usage

```bash
# Package an individual skill
/package-product django-patterns

# Package a guide
/package-product adhd-guide

# Package a bundle
/package-product django-mastery-bundle --type bundle
```

The skill will:
1. Ask for product type if not obvious (skill, guide, template, bundle)
2. For bundles, ask which items to include
3. Copy all source files to `~/Developer/Gumroad_Products/[product-name]/`
4. Generate all documentation
5. Create ZIP file
6. Draft Gumroad sales page
7. Update Product Calendar

## Output

After packaging, you'll have:
```
2. Areas/Hackastak_Brand/Gumroad/[Product_Name]/
├── Gumroad_Listing_Instructions.md  # Complete upload guide & listing copy
├── [Product_Name].md                # Markdown version (customer file)
├── [Product_Name].pdf               # PDF version (needs manual generation)
├── README.md                        # Installation guide (customer file)
└── Product_Info.md                  # Internal tracking (status, pricing)
```

**Multi-Format Bundle Contents:**
- 📄 Markdown version for developers
- 📕 PDF version for readers (needs generation)
- 📘 README for installation

Product automatically appears in `Product_Calendar.md` via Dataview.

## Pricing Guidelines

The skill applies these pricing tiers automatically:
- Individual skills: $3-7
- Templates: $5-15
- Guides: $17-49
- Frameworks: $12-29
- Skill bundles: $17-39
- Mixed bundles: $49-97

## Documentation Templates

Generates professional README files tailored to:
- **Skills** - Installation, activation triggers, learning outcomes
- **Guides** - Who it's for, what's included, how to use
- **Bundles** - Value proposition, installation, workflows

## Next Steps After Packaging

1. **Generate PDF from markdown** (pandoc, Obsidian export, or online tool)
2. **Create ZIP bundle** with all 3 formats (MD + PDF + README)
3. **Create cover image** (1600x1200px) - highlight "Multi-Format Bundle"
4. **Upload to Gumroad** - follow `Gumroad_Listing_Instructions.md`
5. **Write supporting blog article** using `/blog-draft`
6. **Schedule launch** with `/product-pipeline`

See `Gumroad_Listing_Instructions.md` for detailed step-by-step instructions.

## Integration

Works with:
- `/product-ideas` - Discover products to package
- `/product-pipeline` - Schedule launches
- `/blog-draft` - Write supporting content

## Version History

- **1.0.0** (2026-05-06) - Initial release
  - Skill packaging workflow
  - Guide/template packaging
  - Bundle packaging
  - README generation (3 templates)
  - CHANGELOG generation
  - WORKFLOWS generation (bundles)
  - ZIP automation
  - Sales page drafting
  - Product Calendar integration
