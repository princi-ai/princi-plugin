#!/usr/bin/env python3
"""Validate discoverable Agent Skills in the portable plugin package."""

import re
import sys
from pathlib import Path

import yaml


ALLOWED_FIELDS = {"name", "description", "license", "allowed-tools", "metadata"}
NAME_PATTERN = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*\Z")


def validate_skill(skill_dir: Path) -> list[str]:
    path = skill_dir / "SKILL.md"
    if not path.is_file():
        return ["SKILL.md is missing"]

    content = path.read_text(encoding="utf-8")
    match = re.match(r"\A---\r?\n(.*?)\r?\n---(?:\r?\n|\Z)", content, re.DOTALL)
    if match is None:
        return ["SKILL.md must start with YAML frontmatter delimited by ---"]

    try:
        frontmatter = yaml.safe_load(match.group(1))
    except yaml.YAMLError as exc:
        return [f"invalid YAML frontmatter: {exc}"]
    if not isinstance(frontmatter, dict):
        return ["frontmatter must be a YAML mapping"]

    errors = []
    unexpected = set(frontmatter) - ALLOWED_FIELDS
    if unexpected:
        errors.append(f"unsupported frontmatter fields: {', '.join(sorted(unexpected))}")

    name = frontmatter.get("name")
    if not isinstance(name, str) or not NAME_PATTERN.fullmatch(name) or len(name) > 64:
        errors.append("name must be hyphen-case and at most 64 characters")
    elif name != skill_dir.name:
        errors.append(f"name {name!r} must match folder {skill_dir.name!r}")

    description = frontmatter.get("description")
    if not isinstance(description, str) or not description.strip():
        errors.append("description must be a non-empty string")
    elif len(description.strip()) > 1024 or any(c in description for c in "<>") or "[TODO:" in description:
        errors.append("description must be at most 1024 characters with no angle brackets or TODO placeholder")

    if re.search(r"(?m)^ {0,3}\[TODO:[^\n]*\]\s*$", content[match.end():]):
        errors.append("skill body contains an unfinished TODO placeholder")

    return errors


def main() -> int:
    bad = False
    for skill_dir in sorted(Path("skills").iterdir()):
        if not skill_dir.is_dir():
            continue  # The Agent Plugins package check reports stray entries.
        errors = validate_skill(skill_dir)
        if errors:
            bad = True
            for error in errors:
                print(f"::error file={skill_dir / 'SKILL.md'}::{error}")
        else:
            print(f"   {skill_dir / 'SKILL.md'} -> valid")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
