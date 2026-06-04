# Geobase skills

Agent skills for [Geobase](https://geobase.app): GeoEmbeddings, worker jobs, tileserver, project database import, and (when it ships) platform CLI workflows.

> **Private beta** — Geobase and this skills repo require beta access. `npx skills add decision-labs/geobase-skills` only works if your GitHub account can read the repository.
>
> **`geobase-cli` is not shipped yet.** Skills document the intended CLI workflow for later; during beta, use **Geobase Studio** for project URL, ref, and anon key (`@geobase` → **Private beta (CLI not shipped)**).

Compatible with the [Agent Skills CLI](https://github.com/vercel-labs/skills) (`npx skills`).

## Install

### All skills at once

**Non-interactive (recommended)** — installs every skill under `skills/` without the picker:

```bash
# All skills → Cursor, project scope
npx skills add decision-labs/geobase-skills --skill '*' -a cursor -y

# All skills → Cursor, global (user-wide)
npx skills add decision-labs/geobase-skills --skill '*' -a cursor -g -y

# All skills → every supported agent
npx skills add decision-labs/geobase-skills --all
```

`-y` alone only skips confirmations; use `--skill '*'` or `--all` to select every skill.

**Interactive** — multi-select in the wizard:

```bash
npx skills add decision-labs/geobase-skills
# or
npx skills add git@github.com:decision-labs/geobase-skills.git
```

### Install one skill

```bash
npx skills add decision-labs/geobase-skills --skill geobase-tileserver --yes
```

Replace `geobase-tileserver` with any skill name from the [catalog](#skill-catalog) below.

### Browse the catalog

```bash
npx skills find geobase
```

## Skill catalog

| Area | Skill | Install |
|------|-------|---------|
| **Platform** | Geobase (umbrella) | `npx skills add decision-labs/geobase-skills@geobase` |
| **GeoEmbeddings** | Index | `@geobase-embeddings` |
| | Operations hierarchy | `@geobase-embeddings-management` |
| | Create via workers | `@geobase-embeddings-create-via-workers` |
| | Catalogue metadata (RUD) | `@geobase-embeddings-catalogue-management` |
| | RPC applications | `@geobase-embeddings-rpc-applications` |
| | Troubleshooting | `@geobase-embeddings-troubleshooting` |
| **Workers** | SRAI embeddings | `@geobase-worker-srai-embeddings` |
| | GeoAI embeddings | `@geobase-worker-geoai-embeddings` |
| | OSM import | `@geobase-worker-osm-import` |
| **Maps** | Vector tiles / MapLibre | `@geobase-tileserver` |
| **Data** | Project DB import | `@geobase-project-db-data-import` |

Skills cross-reference each other with `@skill-name` (for example `@geobase` → `@geobase-worker-srai-embeddings`).

## Layout

Each skill is a directory with a `SKILL.md` file (YAML frontmatter + markdown):

```
skills/
  geobase/SKILL.md
  geobase-tileserver/SKILL.md
  geobase-worker-srai-embeddings/SKILL.md
  ...
plugin.json
```

## Source of truth

Edit skills in **this repository** only. Install via `npx skills add decision-labs/geobase-skills`.

## Requirements

- **Beta:** Geobase Studio access and a **Geobase project** (URL, ref, anon key from project settings). No public `geobase-cli` install yet.
- **Later:** `geobase-cli` for platform login and `projects env` (documented in skills; not required during private beta).
- Do **not** commit platform or project secrets into skill files.
- **`DATABASE_URI`** and **`SERVICE_ROLE_KEY`** are not available to agents without a **human in the loop**. Users must place real values in local gitignored files (for example `.env.db`, `.env.secrets`). See `@geobase` → **Secrets (human in the loop)**.

## Smoke tests

```bash
bash scripts/smoke-test.sh
```

Checks: valid `plugin.json`, [agentskills `skills-ref`](https://github.com/agentskills/agentskills/tree/main/skills-ref) validation for every skill, frontmatter `name` matches directory, no legacy `.md` cross-links or private monorepo paths, and `@geobase-*` references resolve to installed skills. CI runs the same script on pull requests (`.github/workflows/smoke.yml`).

## License

Apache License 2.0 — see [LICENSE](LICENSE).
