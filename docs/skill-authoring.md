# Authoring a new skill

## 1. Pick a name and layer

Naming: `geobase-<domain>-<verb-or-noun>` (lowercase, hyphens). The name must match the directory under `skills/`.

Layers (see [ARCHITECTURE.md](../ARCHITECTURE.md)):

- **platform** — only `@geobase`
- **index** — routing hubs for a domain
- **data** — embeddings, workers, import
- **maps** — tileserver, titiler

## 2. Add a catalog entry

Edit [`skills/catalog.json`](../skills/catalog.json):

```json
{
  "name": "geobase-my-skill",
  "layer": "data",
  "dependencies": ["geobase"],
  "description": "One sentence with trigger keywords — when should an agent load this skill?",
  "path": "skills/geobase-my-skill"
}
```

The `description` drives agent routing. Include user-intent phrases (e.g. "similarity search", "COG", "OSM import"), not only product jargon.

## 3. Create SKILL.md

```yaml
---
name: geobase-my-skill
description: Same routing sentence as catalog (can be slightly shorter).
metadata:
  author: geobase
  version: "0.1.0"
---
```

Body checklist:

- [ ] **When to use this skill** (bullets)
- [ ] **Required inputs** (env vars, beta Studio path)
- [ ] Procedures with fenced code (bash / ts / sql)
- [ ] **Known gotchas** or **Failure handling**
- [ ] **Related skills** (`@geobase`, domain peers)
- [ ] No links to private monorepo paths
- [ ] Public docs only (`https://docs.geobase.app/...`)

Keep SKILL.md under ~5KB; move depth to `references/*.md` if needed.

## 4. Update catalog surfaces

- [`README.md`](../README.md) skill table (if new area)
- [`plugin.json`](../plugin.json) description if scope changed
- [`skills/geobase/SKILL.md`](../skills/geobase/SKILL.md) related skills if umbrella should route here

## 5. Validate locally

```bash
bash scripts/smoke-test.sh
```

## PR review focus

- Description includes clear **when** triggers
- Beta / CLI-not-shipped callouts where relevant
- Cross-refs resolve (`@geobase-*` exists)
- `catalog.json` entry matches directory and frontmatter `name`
