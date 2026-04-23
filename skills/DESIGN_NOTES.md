# Skill Design Notes

Design decisions and rationale for the Staksmith skill system.

## Core Principles

### 1. Description is Everything
The `description` in YAML frontmatter is the only text a model sees when deciding whether to load a skill. Undertrigger is the default failure mode — write descriptions a little pushy.

### 2. Examples Over Rules
Concrete examples beat abstract rules. Models (and humans) generalize from examples faster than they comply with instructions. Example 1 should always be the minimal happy path.

### 3. Skills are Runbooks, Not Documentation
A skill is executed literally at inference time. Keep instructions procedural and actionable. Design rationale belongs here, not in SKILL.md.

---

## Template Decisions

### Example Structure
- **Example 1**: Always the minimal happy path (under 15 lines for procedural skills)
- **Example 2+**: Tricky cases that teach judgment
- **Skill type matters**: Procedural/transformation skills benefit from minimal happy paths; reference/lookup skills work better with representative query examples

### Why We Removed Quick Start
Quick Start was redundant with Example 1. By making Example 1 explicitly the "minimal happy path," we get the same benefit without duplication.

### Why We Use Troubleshooting Over Pitfalls
The Issue → Symptom → Cause → Solution format is more actionable than the terse "Failure — why. Avoid by fix." format. It guides both humans and Claude through diagnosis.

### Why "When NOT to Use" is Required
Explicitly calling out adjacent cases prevents the most common misfires. Without this, skills get triggered for near-miss cases they weren't designed for.

---

## Cross-Cutting Patterns

### Inbox Skills (inbox-scan, inbox-classify, inbox-organize)
Pipeline architecture — each skill's output feeds the next. Designed for composition via shell pipes.

### Blog Skills (blog-ideas, blog-draft)
Content creation workflow. These skills reference vault paths and published posts for voice matching.

### Sync Skills (code-to-docs-sync, vault-to-code-bridge, weekly-momentum-report)
Bridge between vault knowledge and code repositories. Multi-phase workflows with caching.

### skill-auto-extractor
Meta-skill that learns from git history. Feeds into the continuous learning system.

---

## Decisions Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-04-22 | Merged Quick Start into Example 1 | Reduces redundancy; Example 1 serves same purpose |
| 2026-04-22 | Added "When NOT to Use" as required section | Prevents skill misfires on adjacent cases |
| 2026-04-22 | Adopted Troubleshooting format over Pitfalls | More actionable structure for diagnosis |
| 2026-04-22 | Moved Philosophy to skill-creator | Template should be structure, not tutorial |
| 2026-04-22 | Removed "Why:" annotations from workflow steps | Design rationale belongs in DESIGN_NOTES.md, not SKILL.md |
| 2026-04-22 | Created centralized DESIGN_NOTES.md | Better than per-skill files for cross-cutting decisions |
