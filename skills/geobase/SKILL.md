---
name: geobase
description: "Use for Geobase CLI workflows end-to-end: auth/session checks, project discovery, endpoint/env inspection, and worker job operations."
metadata:
  author: geobase
  version: "0.2.1"
---

# Geobase

## Install (Skills CLI)

Published as [decision-labs/geobase-skills](https://github.com/decision-labs/geobase-skills). **Private beta** — install requires GitHub access to that repository.

```bash
# All Geobase skills (non-interactive)
npx skills add decision-labs/geobase-skills --skill '*' -a cursor -y

# All skills, global install
npx skills add decision-labs/geobase-skills --skill '*' -a cursor -g -y

# Interactive wizard (multi-select skills)
npx skills add decision-labs/geobase-skills

# Umbrella skill only
npx skills add decision-labs/geobase-skills@geobase -g -y
```

Search for focused skills: `npx skills find geobase` (e.g. `@geobase-tileserver`, `@geobase-worker-srai-embeddings`).

## Core Principles

**1. Keep control-plane vs project scope clear.**
`login`, `whoami`, and `projects list/refs` are control-plane operations. Worker/data operations are project-scope operations.

**2. Verify session first.**
Run `geobase-cli whoami` before project or worker operations.

**3. Resolve the project ref explicitly.**
Use `geobase-cli projects refs` or `projects list`; never guess.

**4. Discover commands with `--help`; do not guess.**
CLI surfaces evolve. Check command shape before execution.

**5. Verify outcomes, not just command success.**
Inspect returned fields, URLs, status values, and downstream effects.

**6. Secrets require a human in the loop.**
`DATABASE_URI` / `GEOBASE_DATABASE_URI` and `SERVICE_ROLE_KEY` / `GEOBASE_SERVICE_ROLE_KEY` are **not** available to the CLI or to agents in a usable form. `projects env` may print placeholders (`[PASSWORD]`, `<db-password>`, `<service-role-key>`). **Stop and ask the user** to put real values in local gitignored files (for example `.env.db`, `.env.secrets`) before any step that needs DB access or privileged worker/API calls. Never guess, invent, or paste these values in chat.

**7. Strict table-name verification before create operations.**
Before any action that creates tables (worker jobs, imports, SQL), you must verify target names for both validity and collisions; never skip this check.

## Required Inputs

- authenticated CLI session (`geobase-cli login`)
- `project_ref` (for project-scoped actions)

## Command Discovery

Always check help before running non-trivial commands:

- `geobase-cli --help`
- `geobase-cli projects --help`
- `geobase-cli projects endpoints --help`
- `geobase-cli projects env --help`

## Canonical Model Registry

Use this gist as the canonical model catalog for skills:

- JSON: `https://gist.githubusercontent.com/mhassanch/5acd83c04618c83e29d118ac722bb805/raw/geobase_models_registry.json`

Before any model-based workflow (GeoAI/SRAI):

1. Fetch the registry JSON.
2. Validate that requested `modelName`/model id exists in `models`.
3. Map payload `modelName` to registry `id` (do not match label text).
4. Read model constraints from registry (`bands`, `minTileSize`, availability) and enforce them in payload construction.

## Standard Workflow (All Geobase tasks)

1. Validate auth/session:
   - `geobase-cli whoami`
2. Resolve target project:
   - `geobase-cli projects refs`
   - `geobase-cli projects list`
3. Inspect project services:
   - `geobase-cli projects endpoints <project-ref>`
4. Generate environment templates when needed:
   - `geobase-cli projects env <project-ref> --persona web --format dotenv`
   - `geobase-cli projects env <project-ref> --persona postgres --format dotenv`
   - `geobase-cli projects env <project-ref> --persona datascience --format dotenv`
   - ⚠️ Postgres/datascience personas emit **placeholders** for DB password and URIs (`GEOBASE_PGPASSWORD=<db-password>`, `[PASSWORD]` in `DATABASE_URI` / `GEOBASE_DATABASE_URI`). The CLI does not expose usable `DATABASE_URI` or `SERVICE_ROLE_KEY` to agents — see **Secrets (human in the loop)** below and `@geobase-project-db-data-import`.
5. Verify follow-up state using status/health and concrete output checks.

## Strict Table Verification (Create Operations)

For any workflow that creates tables, run this check first:

1. Validate format:
   - lowercase required;
   - `^[a-z][a-z0-9_]{0,62}$`;
   - max length 63.
2. Verify the table does not already exist in target schema.
3. If a collision exists, stop and require a new name; do not overwrite unless explicitly requested.

## GeoEmbeddings Management

Use `@geobase-embeddings` as the index, then follow focused skills:

- `@geobase-embeddings-create-via-workers`
- `@geobase-embeddings-catalogue-management`
- `@geobase-embeddings-rpc-applications`
- `@geobase-embeddings-troubleshooting`

## Related Skills

For worker job flows and troubleshooting, use:

- `@geobase-worker-osm-import`
- `@geobase-worker-geoai-embeddings`
- `@geobase-worker-srai-embeddings`

For project database ingestion/import workflows, use:

- `@geobase-project-db-data-import`

For map tiles and map visualization workflows, use:

- `@geobase-tileserver`

For embeddings management workflows, use:

- `@geobase-embeddings-management`

## Failure Handling

- If auth fails: run `geobase-cli login`, then retry.
- If `project_ref` is invalid: re-check with `geobase-cli projects refs`.
- After 2-3 failed attempts, stop looping and switch to diagnosis (routing, auth scope, payload, service status).

## Secrets (human in the loop)

These values are **never** something an agent or `geobase-cli` can supply on its own. The user must provide them out of band.

| Variable | What `projects env` gives you | What the user must do |
| -------- | ------------------------------ | ---------------------- |
| `DATABASE_URI` / `GEOBASE_DATABASE_URI` | Connection string with `[PASSWORD]` placeholder | Set real DB password; write a complete URI to **`.env.db`** (or equivalent), gitignored |
| `SERVICE_ROLE_KEY` / `GEOBASE_SERVICE_ROLE_KEY` | Placeholder or value that must not flow through the agent | Copy from Studio / project settings into **`.env.secrets`** (or equivalent), gitignored |

**Agent workflow**

1. Run `geobase-cli projects env <ref> --persona …` only to collect **non-secret** host, ref, anon key, URLs, etc.
2. **Stop** before `psql`, `ogr2ogr`, worker job HTTP calls, or any privileged API use.
3. Ask the user to create `.env.db` and/or `.env.secrets` with real `DATABASE_URI` and `SERVICE_ROLE_KEY` (and related `GEOBASE_*` aliases if they prefer).
4. User loads files locally (example: `set -a && source .env.secrets && source .env.db && set +a`). The agent must **not** ask the user to paste secret values into chat.
5. Proceed only after the user confirms the files exist on disk.

Add `.env.db`, `.env.secrets`, `.env.postgres.local`, and similar paths to `.gitignore` if not already present.

## Security Rules

- Never paste `SERVICE_ROLE_KEY`, DB passwords, or full `DATABASE_URI` values in chat.
- Never commit secrets to repo files (including generated `projects env` output that was hand-filled).
- Never expose privileged keys in public/client env vars (`NEXT_PUBLIC_*`, browser bundles, logs).
- Keep project anon keys and service-role keys separated by intended usage.
