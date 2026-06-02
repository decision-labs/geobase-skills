# Geobase skills

Agent skills for [Geobase](https://geobase.app): platform CLI workflows, GeoEmbeddings, worker jobs, tileserver, and project database import.

Compatible with the [Agent Skills CLI](https://github.com/vercel-labs/skills) (`npx skills`).

## Install

### All skills at once

```bash
npx skills add decision-labs/geobase-skills
# or
npx skills add git@github.com:decision-labs/geobase-skills.git
```

Select **all** skills in the wizard, or use your CLI’s non-interactive flags (e.g. `-y`, `-g`).

### Umbrella + search

| Skill | Install |
|-------|---------|
| Geobase (umbrella) | `npx skills add decision-labs/geobase-skills@geobase` |
| GeoEmbeddings index | `@geobase-embeddings` |
| Embeddings management | `@geobase-embeddings-management` |
| SRAI worker jobs | `@geobase-worker-srai-embeddings` |
| GeoAI worker jobs | `@geobase-worker-geoai-embeddings` |
| OSM import worker | `@geobase-worker-osm-import` |
| Vector tiles / MapLibre | `@geobase-tileserver` |
| Project DB import | `@geobase-project-db-data-import` |

```bash
npx skills find geobase
```

## Layout

Each skill is a directory with a `SKILL.md` file (YAML frontmatter + markdown), per the open Agent Skills format:

```
skills/
  geobase/SKILL.md
  geobase-tileserver/SKILL.md
  geobase-worker-srai-embeddings/SKILL.md
  ...
```

[`skills-manifest.json`](skills-manifest.json) maps skill ids to legacy paths used when running `geobase-cli skills --out agent-skills` in a customer repo.

## Source of truth

Edit `skills/<id>/SKILL.md` in this repository.

When developing in the [Geobase monorepo](https://github.com/decision-labs/geobase), the same tree lives at **`geobase-skills/`** at the repo root. `geobase-cli skills` reads from there and writes the legacy `agent-skills/` layout for customer `AGENTS.md` files.

To publish changes:

1. Push updates to `decision-labs/geobase-skills` (this repo).
2. Tag a release if you version installs.
3. Users run `npx skills update` (or re-add) to refresh.

## Requirements

- [`geobase-cli`](https://github.com/decision-labs/geobase/tree/main/cli/geobase-cli) for platform login and `projects env` / worker orchestration.
- Do **not** commit platform or project secrets into skill files.
