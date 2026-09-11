#!/usr/bin/env python3
"""Validate every skill in this repo: structure, frontmatter, and index coverage.

Usage:  python3 scripts/validate-skills.py
Exit 0 if everything is valid, 1 otherwise.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SKILLS = ROOT / "skills"
REQUIRED_FM = ("name", "description", "license")


def frontmatter(text):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return None
    out, key = {}, None
    for line in m.group(1).split("\n"):
        km = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", line)
        if km:
            key, val = km.group(1), km.group(2).strip()
            out[key] = "" if val in (">", "|", ">-", "|-") else val
        elif key and line.startswith((" ", "\t")):
            out[key] = (out[key] + " " + line.strip()).strip()
    return out


def main():
    claude_md = (ROOT / "CLAUDE.md").read_text()
    readme = (ROOT / "README.md").read_text()
    rows, failures = [], 0

    for d in sorted(p for p in SKILLS.iterdir() if p.is_dir()):
        sk = d / "SKILL.md"
        problems = []
        if not sk.exists():
            print(f"FAIL {d.name}: no SKILL.md - it will not be discovered")
            failures += 1
            continue
        text = sk.read_text()
        fm = frontmatter(text)
        if fm is None:
            print(f"FAIL {d.name}: no YAML frontmatter")
            failures += 1
            continue

        for field in REQUIRED_FM:
            if not fm.get(field):
                problems.append(f"missing `{field}`")
        if fm.get("name") != d.name:
            problems.append(f"name '{fm.get('name')}' != dir '{d.name}'")
        desc = fm.get("description", "")
        if "Trigger" not in desc:
            problems.append("description has no Trigger")
        if len(desc) < 80:
            problems.append("description too short to route on")

        has_cmd = "\n## Commands" in text
        has_flags = "\n## Red Flags" in text
        if "\n## When to Use" not in text:
            problems.append("no '## When to Use'")
        if "\n## Critical Patterns" not in text:
            problems.append("no '## Critical Patterns'")
        if not has_cmd and not has_flags:
            problems.append("needs '## Commands' or '## Red Flags'")

        for comp in sorted(f.name for f in d.glob("*.md") if f.name != "SKILL.md"):
            if comp not in text:
                problems.append(f"companion {comp} unreferenced")

        if f"`{d.name}`" not in claude_md:
            problems.append("not listed in CLAUDE.md")
        if f"`{d.name}`" not in readme and d.name not in readme:
            problems.append("not listed in README.md")

        failures += bool(problems)
        rows.append((d.name, len(text.splitlines()),
                     "cmd" if has_cmd else "ref", "; ".join(problems) or "ok"))

    w = max(len(r[0]) for r in rows)
    print(f"{'skill':<{w}}  lines  kind  status")
    for n, l, k, st in rows:
        mark = " " if st == "ok" else "!"
        print(f"{mark}{n:<{w}} {l:>5}  {k:<4}  {st}")
    print(f"\n{len(rows) - failures}/{len(rows)} skills valid")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
