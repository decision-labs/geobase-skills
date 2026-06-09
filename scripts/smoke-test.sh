#!/usr/bin/env bash
# Minimal smoke tests for geobase-skills (no network except skills-ref install via uvx).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SKILLS_REF=(uvx --from 'git+https://github.com/agentskills/agentskills#subdirectory=skills-ref' skills-ref)

echo "==> Validate plugin.json"
python3 -c "import json; json.load(open('plugin.json'))"

echo "==> Validate skills/catalog.json"
python3 <<'PY'
import json
import pathlib
import sys

root = pathlib.Path("skills")
catalog = json.load(open("skills/catalog.json"))
entries = catalog.get("skills", [])
if not entries:
    sys.exit("catalog.json has no skills")

catalog_names = []
for entry in entries:
    name = entry.get("name")
    path = pathlib.Path(entry.get("path", ""))
    if not name or not path.is_dir() or not (path / "SKILL.md").is_file():
        sys.exit(f"invalid catalog entry: {entry!r}")
    catalog_names.append(name)

dirs = sorted(p.name for p in root.iterdir() if p.is_dir() and (p / "SKILL.md").is_file())
missing = set(dirs) - set(catalog_names)
extra = set(catalog_names) - set(dirs)
if missing:
    sys.exit(f"skills missing from catalog.json: {sorted(missing)}")
if extra:
    sys.exit(f"catalog.json entries without SKILL.md dir: {sorted(extra)}")

for entry in entries:
    for dep in entry.get("dependencies", []):
        if dep not in catalog_names:
            sys.exit(f"{entry['name']}: unknown dependency {dep!r}")
PY

echo "==> Validate each skill (agentskills skills-ref)"
shopt -s nullglob
skill_dirs=(skills/*/)
if ((${#skill_dirs[@]} == 0)); then
  echo "No skills found under skills/" >&2
  exit 1
fi
for dir in "${skill_dirs[@]}"; do
  "${SKILLS_REF[@]}" validate "$dir"
done

echo "==> Frontmatter name matches directory"
for dir in "${skill_dirs[@]}"; do
  dir="${dir%/}"
  base="$(basename "$dir")"
  name="$(python3 -c "
import re, pathlib
text = pathlib.Path('$dir/SKILL.md').read_text()
m = re.search(r'^---\s*\n(.*?)\n---', text, re.DOTALL)
if not m:
    raise SystemExit('missing frontmatter in $dir/SKILL.md')
for line in m.group(1).splitlines():
    if line.startswith('name:'):
        print(line.split(':', 1)[1].strip().strip('\"').strip(\"'\"))
        break
else:
    raise SystemExit('missing name in $dir/SKILL.md')
")"
  if [[ "$name" != "$base" ]]; then
    echo "name mismatch: directory=$base frontmatter name=$name" >&2
    exit 1
  fi
done

echo "==> No legacy cross-skill paths or private monorepo links"
if rg -n 'embeddings/[a-z_-]+\.md|worker/[a-z_]+\.md|project-db/[a-z_]+\.md|tileserver\.md|geobase_services/' skills README.md 2>/dev/null; then
  echo "Found forbidden legacy path references (see above)" >&2
  exit 1
fi

echo "==> @skill-name references resolve to installed skills"
known="$(printf '%s\n' "${skill_dirs[@]}" | sed 's|skills/||; s|/$||' | sort)"
while IFS= read -r ref; do
  [[ -z "$ref" ]] && continue
  if ! printf '%s\n' "$known" | grep -qx "$ref"; then
    echo "Unknown skill reference: @$ref" >&2
    exit 1
  fi
done < <(rg -o '@geobase(-[a-z0-9-]+)?' skills -r '$0' --no-filename | sed 's/^@//' | sort -u)

echo "All smoke checks passed (${#skill_dirs[@]} skills)."
