#!/usr/bin/env python3
"""Surgically update the '# Weekly Momentum Report' section of a weekly note.

Only the auto-changelog block (between markers) is rewritten; the Daily Journal
and any narrative above the block are left untouched. The changelog is keyed by
repo so updates merge additively across machines:

  - Repos this machine OWNS (scanned this run) are regenerated, dropping their
    previous entries -> idempotent rerun, no duplicates.
  - Repos owned this run with zero commits are removed.
  - Repos written by ANOTHER machine (not owned this run) are preserved -> you can
    run it on one machine, then add to it from another.

Usage:
  merge-report.py <note_path> <repos_scan_json> <owned_csv> <updated_ts>
"""
import json
import re
import sys

HEADING = "# Weekly Momentum Report"
START = "<!-- momentum:auto:start -->"
END = "<!-- momentum:auto:end -->"

REPO_BLOCK_RE = re.compile(
    r"<!-- repo:(?P<name>.+?) count=(?P<count>\d+) -->\n"
    r"(?P<body>.*?)"
    r"\n<!-- /repo:(?P=name) -->",
    re.DOTALL,
)


def render_repo_block(name, count, commit_lines):
    body = "\n".join(commit_lines) if commit_lines else "- (no commit messages)"
    return (
        f"<!-- repo:{name} count={count} -->\n"
        f"### {name} — {count} commit{'s' if count != 1 else ''}\n"
        f"{body}\n"
        f"<!-- /repo:{name} -->"
    )


def render_block(repos):
    """repos: ordered list of (name, count, text) where text is the full repo block."""
    total = sum(c for _, c, _ in repos)
    n = len(repos)
    header = (
        f"_Auto-changelog · updated {UPDATED_TS}_\n\n"
        f"**Commits:** {total} across {n} repo{'s' if n != 1 else ''}"
    )
    if repos:
        joined = "\n\n".join(t for _, _, t in repos)
        inner = f"{header}\n\n{joined}"
    else:
        inner = f"{header}\n\n_No local commits recorded for this week yet._"
    return f"{START}\n{inner}\n{END}"


def main():
    global UPDATED_TS
    note_path, scan_path, owned_csv, UPDATED_TS = sys.argv[1:5]

    with open(note_path) as f:
        text = f.read()
    lines = text.split("\n")

    # Locate the section heading
    h_idx = next((i for i, l in enumerate(lines) if l.strip() == HEADING), None)
    if h_idx is None:
        sys.stderr.write(
            f"merge-report: '{HEADING}' section not found in {note_path}; "
            "leaving note untouched.\n"
        )
        sys.exit(2)

    # Section body runs until the next top-level '# ' heading or EOF
    end_idx = len(lines)
    for i in range(h_idx + 1, len(lines)):
        if re.match(r"^# \S", lines[i]):
            end_idx = i
            break
    body = "\n".join(lines[h_idx + 1:end_idx])

    # Split narrative (kept) from the managed block
    if START in body and END in body:
        pre = body[: body.index(START)]
        block_text = body[body.index(START): body.index(END) + len(END)]
    else:
        pre = body
        block_text = ""

    existing = {}   # name -> (count, full_text), preserves other machines' repos
    order = []
    for m in REPO_BLOCK_RE.finditer(block_text):
        name = m.group("name")
        existing[name] = (int(m.group("count")), m.group(0))
        order.append(name)

    # This run's commits
    with open(scan_path) as f:
        scan = json.load(f)
    this_run = {}
    for repo in scan:
        if repo.get("commit_count", 0) > 0:
            lines_out = [f"- {c['message']} ({c['date']})" for c in repo["commits"]]
            this_run[repo["name"]] = lines_out

    owned = {o for o in owned_csv.split(",") if o}
    # Legacy safety: if nothing is explicitly owned, treat scanned repos as owned
    if not owned:
        owned = set(this_run.keys())

    # Apply: regenerate owned repos, drop owned-but-empty, keep the rest
    for name in owned:
        if name in this_run:
            cnt = len(this_run[name])
            existing[name] = (cnt, render_repo_block(name, cnt, this_run[name]))
            if name not in order:
                order.append(name)
        else:
            if name in existing:
                del existing[name]
                order = [n for n in order if n != name]

    ordered = [(n, existing[n][0], existing[n][1]) for n in order if n in existing]
    new_block = render_block(ordered)

    pre = pre.rstrip()
    new_body = f"{pre}\n\n{new_block}" if pre else new_block
    # Collapse blank-line runs only within the rebuilt section — never touch the
    # Daily Journal or anything else in the note.
    new_body = re.sub(r"\n{3,}", "\n\n", new_body).strip("\n")

    new_lines = lines[: h_idx + 1] + [""] + new_body.split("\n") + [""] + lines[end_idx:]
    out = "\n".join(new_lines)
    if not out.endswith("\n"):
        out += "\n"
    with open(note_path, "w") as f:
        f.write(out)

    sys.stderr.write(
        f"merge-report: updated {len(owned & set(this_run))} owned repo(s); "
        f"section now lists {len(ordered)} repo(s).\n"
    )


if __name__ == "__main__":
    main()
