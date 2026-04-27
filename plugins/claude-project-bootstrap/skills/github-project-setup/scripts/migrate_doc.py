#!/usr/bin/env python3
"""
Bulk-migrate a planning doc (deferred.md / TODO.md / etc.) to GitHub issues
and add them to a Project (v2). Generic template — adapt the constants at the
top and the ISSUES list before running.

Usage: copy this file to /tmp/, edit the marked sections, run with python3.
The model invoking the github-project-setup skill should:
  1. Read the source doc
  2. Parse entries into the ISSUES list (one dict per issue)
  3. Fill in REPO, OWNER, PROJECT_NUMBER, PROJECT_ID
  4. Fill in field IDs and option IDs (from `gh project field-list ... --format json`)
  5. Show ISSUES table to user for confirmation
  6. Run the script
"""
import json
import subprocess
import sys

# ── EDIT: project + repo coordinates ─────────────────────────────────────────
REPO           = "OWNER/REPO"           # e.g. "blumenau1001011/TTV"
OWNER          = "OWNER"                # owner of the *project* (user or org)
PROJECT_NUMBER = "1"                    # from project URL .../projects/<N>
PROJECT_ID     = "PVT_xxxxxxxxxxxxxx"   # GraphQL node ID, from `gh project view <N> --owner <owner> --format json`

# ── EDIT: field IDs (from `gh project field-list <N> --owner <owner> --format json`) ──
F_TIER     = "PVTSSF_..."
F_AREA     = "PVTSSF_..."
F_PRIORITY = "PVTSSF_..."

# ── EDIT: option IDs per field. Pick from the same field-list JSON. ─────────
TIER     = {"Novice": "...", "Amateur": "...", "Pro": "...", "Infra": "...", "Tech-debt": "..."}
AREA     = {"Frontend": "...", "Backend": "...", "Design": "...", "Infra": "..."}
PRIORITY = {"P0": "...", "P1": "...", "P2": "..."}


def run(cmd, **kw):
    r = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if r.returncode != 0:
        print(f"FAIL: {' '.join(cmd)}\n{r.stderr}", file=sys.stderr)
        sys.exit(1)
    return r.stdout.strip()


# ── EDIT: one dict per issue ────────────────────────────────────────────────
# `body` should be the markdown text from the source doc, lightly tidied.
# Use the full Tier/Area/Priority values — the script maps them to option IDs.
# `milestone` is optional — set to a milestone title (e.g. "Alpha") if Step 5b
# created milestones; omit otherwise.
ISSUES = [
    # {
    #     "title": "Example feature title",
    #     "labels": ["feature", "frontend"],
    #     "tier": "Amateur",
    #     "area": "Frontend",
    #     "priority": "P1",
    #     "milestone": "Alpha",  # optional
    #     "body": "Multi-line markdown body...",
    # },
]


def main():
    if not ISSUES:
        print("ISSUES list is empty — fill it in before running.", file=sys.stderr)
        sys.exit(1)

    print(f"Creating {len(ISSUES)} issues in {REPO} → project {PROJECT_NUMBER}\n")

    for i, spec in enumerate(ISSUES, 1):
        print(f"[{i:2d}/{len(ISSUES)}] {spec['title']}")

        # Create the issue
        url = run([
            "gh", "issue", "create",
            "-R", REPO,
            "-t", spec["title"],
            "-b", spec["body"],
            "-l", ",".join(spec["labels"]),
        ])
        print(f"           {url}")

        # Optional: assign milestone (skip if spec doesn't include one)
        milestone = spec.get("milestone")
        if milestone:
            issue_number = url.rsplit("/", 1)[-1]
            run([
                "gh", "issue", "edit", issue_number,
                "-R", REPO,
                "--milestone", milestone,
            ])

        # Add to project (returns item ID as JSON)
        item_id_json = run([
            "gh", "project", "item-add", PROJECT_NUMBER,
            "--owner", OWNER,
            "--url", url,
            "--format", "json",
        ])
        item_id = json.loads(item_id_json)["id"]

        # Set Tier / Area / Priority
        for field_id, opt_id in [
            (F_TIER,     TIER[spec["tier"]]),
            (F_AREA,     AREA[spec["area"]]),
            (F_PRIORITY, PRIORITY[spec["priority"]]),
        ]:
            run([
                "gh", "project", "item-edit",
                "--id", item_id,
                "--project-id", PROJECT_ID,
                "--field-id", field_id,
                "--single-select-option-id", opt_id,
            ])

    print("\nDone.")


if __name__ == "__main__":
    main()
