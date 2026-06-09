# Architecture

Agent skills catalog for Geobase. Skills are self-contained playbooks (no private monorepo links). Catalog metadata lives in [`skills/catalog.json`](skills/catalog.json), not SKILL.md frontmatter.

## Areas (matches README)

`area` values align with the [README skill catalog](README.md#skill-catalog):

| Area | Purpose | Skills |
| ---- | ------- | ------ |
| **platform** | Umbrella: beta setup, secrets, scope, routing | `@geobase` |
| **geoembeddings** | Embeddings lifecycle: index → create → catalogue → RPC → troubleshoot | `@geobase-embeddings*` |
| **workers** | Background worker jobs (embeddings pipelines, OSM) | `@geobase-worker-*` |
| **maps** | Vector MVT and raster COG visualization | `@geobase-tileserver`, `@geobase-titiler` |
| **data** | Local file import into project Postgres | `@geobase-project-db-data-import` |

Within **geoembeddings**, two skills are routing hubs (`role: "index"` in catalog): `@geobase-embeddings` and `@geobase-embeddings-management`. Load those when the task type is unclear; otherwise use the focused skill.

## Dependencies

`dependencies` in `catalog.json` documents suggested load order (e.g. workers after `@geobase-embeddings-create-via-workers`). Cross-refs in SKILL.md use `@skill-name`.

## Skill anatomy

```
skills/<skill-name>/
  SKILL.md          # frontmatter + guidance (keep focused; split if > ~5KB)
  references/       # optional deep-dives (future)
```

## Validation

- `bash scripts/smoke-test.sh` — `plugin.json`, `scripts/validate_catalog.py`, `skills-ref validate` per skill
- CI: `.github/workflows/smoke.yml`

## Adding a skill

See [docs/skill-authoring.md](docs/skill-authoring.md).
