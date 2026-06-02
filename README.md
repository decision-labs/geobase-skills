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

Select **all** skills in the wizard, or use non-interactive flags (e.g. `-y`, `-g`).

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

Each skill is a directory with a `SKILL.md` file (YAML frontmatter + markdown):

```
skills/
  geobase/SKILL.md
  geobase-tileserver/SKILL.md
  geobase-worker-srai-embeddings/SKILL.md
  ...
```

## Source of truth

Edit skills in **this repository** only. The [Geobase monorepo](https://github.com/decision-labs/geobase) documents install via `npx skills` and links here — it does not vendor a duplicate copy.

## Requirements

- [`geobase-cli`](https://github.com/decision-labs/geobase/tree/main/cli/geobase-cli) for platform login and `projects env` / worker orchestration.
- Do **not** commit platform or project secrets into skill files.
- **`DATABASE_URI`** and **`SERVICE_ROLE_KEY`** are not available to the CLI or agents without a **human in the loop**. Users must place real values in local gitignored files (for example `.env.db`, `.env.secrets`). See the `@geobase` skill, section **Secrets (human in the loop)**.
