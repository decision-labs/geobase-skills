#!/usr/bin/env bash
# Minimal smoke tests for geobase-skills (network: skills-ref via uvx only).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SKILLS_REF=(uvx --from 'git+https://github.com/agentskills/agentskills#subdirectory=skills-ref' skills-ref)

echo "==> Validate plugin.json"
python3 -c "import json; json.load(open('plugin.json'))"

echo "==> Validate catalog, frontmatter, cross-refs"
python3 scripts/validate_catalog.py

echo "==> Validate each skill (agentskills skills-ref)"
shopt -s nullglob
skill_dirs=(skills/*/)
for dir in "${skill_dirs[@]}"; do
  "${SKILLS_REF[@]}" validate "$dir"
done

echo "All smoke checks passed (${#skill_dirs[@]} skills)."
