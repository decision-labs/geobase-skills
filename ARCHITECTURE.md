# Architecture

Agent skills catalog for Geobase. Skills are self-contained playbooks (no private monorepo links). Layer metadata lives in [`skills/catalog.json`](skills/catalog.json), not SKILL.md frontmatter, so the same skill file works across harnesses.

## Layers

| Layer | Purpose | Skills |
| ----- | ------- | ------ |
| **platform** | Umbrella: beta setup, secrets, scope, routing | `@geobase` |
| **index** | Route to the right data/maps skill | `@geobase-embeddings`, `@geobase-embeddings-management` |
| **data** | GeoEmbeddings, workers, DB import | `@geobase-embeddings-*` (except index), `@geobase-worker-*`, `@geobase-project-db-data-import` |
| **maps** | Vector MVT and raster COG visualization | `@geobase-tileserver`, `@geobase-titiler` |

Dependency direction: platform → index → data/maps. Cross-refs use `@skill-name` in prose; `catalog.json` `dependencies` documents the intended order for contributors.

## Skill anatomy

```
skills/<skill-name>/
  SKILL.md          # frontmatter + guidance (keep focused; split if > ~5KB)
  references/       # optional deep-dives (future)
```

Frontmatter:

```yaml
---
name: geobase-tileserver
description: One sentence with trigger keywords for agent routing.
metadata:
  author: geobase
  version: "0.2.0"
---
```

Body conventions (inspired by [CARTO Agent Skills](https://github.com/CartoDB/agent-skills)):

1. **When to use this skill** — bulleted triggers
2. **Required inputs** / quick reference
3. **Procedures** — commands, URLs, code
4. **Known gotchas** / **Failure handling**
5. **Always-on guidance** — invariants (especially in `@geobase`)
6. **Related skills** — `@geobase-*` cross-refs

## Beta vs CLI

During **private beta**, `@geobase` is the source of truth for Studio-first workflows. `geobase-cli` sections describe the target workflow once the CLI ships. Do not assume CLI is on `PATH`.

## Validation

- `scripts/smoke-test.sh` — `plugin.json`, `skills-ref validate`, frontmatter names, `catalog.json` sync, `@geobase-*` refs, no legacy private paths
- CI: `.github/workflows/smoke.yml`

## Adding a skill

See [docs/skill-authoring.md](docs/skill-authoring.md).
