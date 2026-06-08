# money

A revenue advisor that mines your Obsidian vault for monetization opportunities — then goes beyond it.

> **Vault-only skill.** `/money` runs inside the My_Notes Obsidian vault. This directory is the canonical, versioned copy of the skill kept in the Staksmith repo for documentation and reuse; the live command lives at `My_Notes/.claude/commands/money.md`.

## What It Does

Acts as a strategic revenue advisor that:

- **Scans the vault** for assets, skills, relationships, IP, audience, and credibility signals (evidence-based, not aspirational)
- **Diagnoses the revenue system first** — conversion (CPM), revenue mix (one-time vs. recurring vs. passive vs. equity), sales infrastructure, pricing model, and product-vs-service ratio
- **Goes beyond the vault** — surfaces blind spots, market context, packaging gaps, and positioning mismatches the user can't see from inside their own perspective
- **Recommends prioritized opportunities** — top 5 by effort-to-revenue, the immediate play, the biggest upside, the surprising one, and the single structural fix with the most compounding impact
- **Ends with artifacts** — specific documents/tools it can build right now to drive revenue (rate cards, sponsorship decks, outreach templates, pitch docs, landing pages)

The guiding principle: the vault is the starting point, not the ceiling. A list of ideas built on a broken revenue system is useless — diagnose the system, then prescribe.

## When to Use

- "How do I make more money from what I already have?"
- Monthly/quarterly revenue strategy review
- Before a pricing change, product launch, or new offering
- When attention isn't converting to revenue and you don't know why

## Usage

```bash
/money              # full vault analysis
/money [domain]     # focused on a specific area (e.g. /money Hackastak_Brand)
```

## Installation

```bash
# Copy to the vault's commands directory
cp SKILL.md /path/to/vault/.claude/commands/money.md
```

The vault command is plain instruction markdown (no frontmatter); `SKILL.md` here keeps the skill frontmatter for the Staksmith skill registry.

## Output Structure

```
1. Deep Vault Scan          — orphans, deadends, context, weekly notes, calendar
2. Asset Inventory          — skills, relationships, IP, audience, credibility
3. Revenue Diagnostics      — CPM, revenue mix, sales system, pricing, product ratio
4. Beyond the Vault         — blind spots, market context, packaging gap, positioning
5. Revenue Opportunities    — services, products, near/mid/long-term, pricing, network, equity
6. Temporal Tracking        — what prior /money runs surfaced and what changed
7. Anti-Patterns            — guardrails against generic/unrealistic advice
8. Prioritization           — top 5, immediate play, biggest upside, surprise, structural fix
9. Actionable Builds        — artifacts to create right now
```

## Integration

- `/product-ideas` — drills into the "products to build" output category
- `/package-product` — packages a chosen product for Gumroad
- `/product-pipeline` — schedules and tracks launches
- `/blog-ideas`, `/blog-draft` — content that feeds the conversion funnel

## Configuration

```
VAULT_PATH=~/Developer/My_Notes
```

Uses the [Obsidian CLI](https://help.obsidian.md/cli) when available (faster, with backlink/tag/search access); falls back to direct filesystem reads otherwise.

## Version History

- **1.0.0** (2026-06-08) — Initial release.
