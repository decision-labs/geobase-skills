#!/usr/bin/env python3
"""Validate skills/catalog.json, SKILL.md frontmatter, and @geobase-* cross-refs."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = ROOT / "skills"
CATALOG_PATH = SKILLS_DIR / "catalog.json"

AREAS = frozenset({"platform", "geoembeddings", "workers", "maps", "data"})
LEGACY_PATH = re.compile(
    r"embeddings/[a-z_-]+\.md|worker/[a-z_]+\.md|project-db/[a-z_]+\.md|"
    r"tileserver\.md|geobase_services/"
)
SKILL_REF = re.compile(r"@geobase(-[a-z0-9-]+)?")
FRONTMATTER = re.compile(r"^---\s*\n(.*?)\n---", re.DOTALL)


def fail(msg: str) -> None:
    print(msg, file=sys.stderr)
    sys.exit(1)


def skill_dirs() -> list[Path]:
    return sorted(p for p in SKILLS_DIR.iterdir() if p.is_dir() and (p / "SKILL.md").is_file())


def frontmatter_name(skill_md: Path) -> str:
    match = FRONTMATTER.search(skill_md.read_text())
    if not match:
        fail(f"{skill_md}: missing YAML frontmatter")
    for line in match.group(1).splitlines():
        if line.startswith("name:"):
            return line.split(":", 1)[1].strip().strip("\"'")
    fail(f"{skill_md}: missing name in frontmatter")


def validate_catalog(names: set[str]) -> None:
    entries = json.loads(CATALOG_PATH.read_text()).get("skills", [])
    if not entries:
        fail("catalog.json has no skills")

    catalog_names: list[str] = []
    for entry in entries:
        name = entry.get("name")
        area = entry.get("area")
        path = Path(entry.get("path", ""))

        if "layer" in entry:
            fail(f"{name}: use 'area' not 'layer'")
        if area not in AREAS:
            fail(f"{name}: invalid area {area!r}")
        role = entry.get("role")
        if role and role != "index":
            fail(f"{name}: unknown role {role!r}")
        if role == "index" and area != "geoembeddings":
            fail(f"{name}: role index only allowed in geoembeddings area")
        if not name or not path.is_dir() or not (path / "SKILL.md").is_file():
            fail(f"invalid catalog entry: {entry!r}")
        catalog_names.append(name)

    on_disk = {p.name for p in skill_dirs()}
    if missing := on_disk - set(catalog_names):
        fail(f"skills missing from catalog.json: {sorted(missing)}")
    if extra := set(catalog_names) - on_disk:
        fail(f"catalog.json entries without SKILL.md dir: {sorted(extra)}")

    for entry in entries:
        for dep in entry.get("dependencies", []):
            if dep not in catalog_names:
                fail(f"{entry['name']}: unknown dependency {dep!r}")

    names.update(catalog_names)


def validate_frontmatter(names: set[str]) -> None:
    for skill_dir in skill_dirs():
        name = frontmatter_name(skill_dir / "SKILL.md")
        if name != skill_dir.name:
            fail(f"name mismatch: directory={skill_dir.name} frontmatter name={name}")
        names.add(name)


def validate_no_legacy_paths() -> None:
    for path in [*(SKILLS_DIR.rglob("*.md")), ROOT / "README.md"]:
        if path.is_file() and LEGACY_PATH.search(path.read_text()):
            fail(f"forbidden legacy path reference in {path.relative_to(ROOT)}")


def validate_skill_refs(known: set[str]) -> None:
    for skill_md in SKILLS_DIR.rglob("SKILL.md"):
        for match in SKILL_REF.findall(skill_md.read_text()):
            ref = f"geobase{match}"
            if ref not in known:
                fail(f"unknown skill reference: @{ref} in {skill_md.relative_to(ROOT)}")


def main() -> None:
    known: set[str] = set()
    validate_catalog(known)
    validate_frontmatter(known)
    validate_no_legacy_paths()
    validate_skill_refs(known)
    print(f"catalog OK ({len(known)} skills)")


if __name__ == "__main__":
    main()
