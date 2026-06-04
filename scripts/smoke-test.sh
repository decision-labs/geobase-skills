#!/usr/bin/env bash
# Minimal smoke tests for geobase-skills (no network except skills-ref install via uvx).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SKILLS_REF=(uvx --from 'git+https://github.com/agentskills/agentskills#subdirectory=skills-ref' skills-ref)

echo "==> Validate plugin.json"
python3 -c "import json; json.load(open('plugin.json'))"

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
