---
name: geobase
description: >
  Use for Geobase platform and project workflows: Studio/env setup during private
  beta, and geobase-cli (when shipped) for auth, project discovery, endpoints, and
  worker orchestration.
metadata:
  author: geobase
  version: "0.2.1"
---

# Geobase

## Install (Skills CLI)

Published as [decision-labs/geobase-skills](https://github.com/decision-labs/geobase-skills). **Private beta** — skills repo and `geobase-cli` install require beta access; CLI not shipped yet.

```bash
# All Geobase skills (non-interactive)
npx skills add decision-labs/geobase-skills --skill '*' -a cursor -y

# All skills, global install
npx skills add decision-labs/geobase-skills --skill '*' -a cursor -g -y

# Interactive wizard (multi-select skills)
npx skills add decision-labs/geobase-skills

# Umbrella skill only
npx skills add decision-labs/geobase-skills@geobase -g -y

# List every skill in the repo (preferred over search during beta)
npx skills add decision-labs/geobase-skills --list
```

**Discovery:** Bundle on [skills.sh](https://skills.sh/decision-labs/geobase-skills) — no separate registration; listing comes from install telemetry. `npx skills find geobase` may return no results while install counts are low; use `--list` or the bundle URL. Focused skills: `@geobase-tileserver`, `@geobase-titiler`, `@geobase-worker-srai-embeddings`, etc.

## Private beta (CLI not shipped)

**`geobase-cli` is not publicly available during private beta.** Do not tell users to install it or assume it is on `PATH`.

**Use this workflow until the CLI ships:**

1. Ask the user for their **project ref** and confirm they can open the project in **Geobase Studio**.
2. Collect **non-secret** project connection values from Studio / project settings (not from chat secrets):
   - `GEOBASE_PROJECT_URL` (or project API base URL, e.g. `https://<ref>.geobase.app`)
   - `GEOBASE_ANON_KEY`
   - `GEOBASE_PROJECT_REF` (or equivalent ref used in worker URLs)
3. For worker jobs, DB import, or catalogue mutations: follow **Secrets (human in the loop)** — user supplies `.env.secrets` / `.env.db` locally; never request pasted keys in chat.
4. Run worker HTTP, PostgREST/RPC, tileserver, and `ogr2ogr` steps using those env vars directly.

Sections below that reference `geobase-cli` describe the **target** workflow once the CLI is released. Prefer the beta steps above when the CLI is missing or fails with “command not found”.

## Core Principles

**1. Keep control-plane vs project scope clear.**
`login`, `whoami`, and `projects list/refs` are control-plane operations. Worker/data operations are project-scope operations.

**2. Verify session first (when CLI is available).**
Run `geobase-cli whoami` before project or worker operations. During beta without CLI, confirm project access via Studio and explicit `project_ref` from the user.

**3. Resolve the project ref explicitly.**
Use `geobase-cli projects refs` or `projects list` when the CLI is installed; otherwise take `project_ref` from the user / Studio; never guess.

**4. Discover commands with `--help`; do not guess.**
CLI surfaces evolve. Check command shape before execution.

**5. Verify outcomes, not just command success.**
Inspect returned fields, URLs, status values, and downstream effects.

**6. Secrets require a human in the loop.**
`DATABASE_URI` / `GEOBASE_DATABASE_URI` and `SERVICE_ROLE_KEY` / `GEOBASE_SERVICE_ROLE_KEY` are **not** available to the CLI or to agents in a usable form. `projects env` may print placeholders (`[PASSWORD]`, `<db-password>`, `<service-role-key>`). **Stop and ask the user** to put real values in local gitignored files (for example `.env.db`, `.env.secrets`) before any step that needs DB access or privileged worker/API calls. Never guess, invent, or paste these values in chat.

**7. Strict table-name verification before create operations.**
Before any action that creates tables (worker jobs, imports, SQL), you must verify target names for both validity and collisions; never skip this check.

## Required Inputs

- `project_ref` (for project-scoped actions)
- **Beta:** `GEOBASE_PROJECT_URL`, `GEOBASE_ANON_KEY`, and secrets in user-local `.env.*` files (see **Private beta** and **Secrets**)
- **When CLI ships:** authenticated CLI session (`geobase-cli login`)

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

### Private beta (no CLI)

1. Confirm `project_ref` and Studio access with the user.
2. Use Studio / project settings for `GEOBASE_PROJECT_URL`, `GEOBASE_ANON_KEY`, and service URLs.
3. Load secrets from user-local `.env.secrets` / `.env.db` after **Secrets (human in the loop)** — do not use chat for passwords or service-role keys.
4. Verify outcomes on the project (worker job status, RPC responses, tile URLs, import row counts).

### When `geobase-cli` is available

1. Validate auth/session: `geobase-cli whoami`
2. Resolve target project: `geobase-cli projects refs` / `projects list`
3. Inspect project services: `geobase-cli projects endpoints <project-ref>`
4. Generate environment templates when needed:
   - `geobase-cli projects env <project-ref> --persona web --format dotenv`
   - `geobase-cli projects env <project-ref> --persona postgres --format dotenv`
   - `geobase-cli projects env <project-ref> --persona datascience --format dotenv`
   - ⚠️ Postgres/datascience personas emit **placeholders** for DB password and URIs. Usable `DATABASE_URI` and `SERVICE_ROLE_KEY` still require **Secrets (human in the loop)** and `@geobase-project-db-data-import`.
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

- `@geobase-tileserver` — vector MVT from PostGIS tables
- `@geobase-titiler` — raster COG tiles (satellite, DEM, multispectral)

For embeddings management workflows, use:

- `@geobase-embeddings-management`

## Failure Handling

- If `geobase-cli` is not installed: use **Private beta (CLI not shipped)**; do not ask the user to clone a private monorepo for the CLI.
- If auth fails (CLI available): run `geobase-cli login`, then retry.
- If `project_ref` is invalid: re-check with the user or `geobase-cli projects refs` when available.
- After 2-3 failed attempts, stop looping and switch to diagnosis (routing, auth scope, payload, service status).

## Secrets (human in the loop)

These values are **never** something an agent or `geobase-cli` can supply on its own. The user must provide them out of band.

| Variable | Beta / CLI template | What the user must do |
| -------- | ------------------- | ---------------------- |
| `DATABASE_URI` / `GEOBASE_DATABASE_URI` | Studio or CLI may show `[PASSWORD]` placeholders only | Set real DB password; write a complete URI to **`.env.db`** (or equivalent), gitignored |
| `SERVICE_ROLE_KEY` / `GEOBASE_SERVICE_ROLE_KEY` | Not available to agents via CLI during beta | Copy from Studio / project settings into **`.env.secrets`** (or equivalent), gitignored |

**Agent workflow**

1. Collect **non-secret** host, ref, anon key, URLs from Studio / project settings, or (when shipped) `geobase-cli projects env <ref> --persona …`.
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
