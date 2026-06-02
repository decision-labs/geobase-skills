---
name: geobase
description: "Use for Geobase CLI workflows end-to-end: auth/session checks, project discovery, endpoint/env inspection, and worker job operations."
metadata:
  author: geobase
  version: "0.2.0"
---

# Geobase

## Install (Skills CLI)

Published as [decision-labs/geobase-skills](https://github.com/decision-labs/geobase-skills).

```bash
# All Geobase skills (interactive: select all)
npx skills add decision-labs/geobase-skills

# Or install this umbrella skill only
npx skills add decision-labs/geobase-skills@geobase -g -y
```

Search for focused skills: `npx skills find geobase` (e.g. `@geobase-tileserver`, `@geobase-worker-srai-embeddings`).

```bash
geobase-cli skills --out agent-skills
```

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

**6. Treat secrets as sensitive.**
Never commit keys or expose privileged credentials in client/public contexts.

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
   - ⚠️ The postgres persona always outputs `GEOBASE_PGPASSWORD=<db-password>` as a placeholder.
     The CLI does not expose the real password. See `project-db/data_import.md` for the `.env` workflow.
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

Use `embeddings.md` as the coordinator, then follow focused files:

- `embeddings/create-via-workers.md`
- `embeddings/catalogue-management.md`
- `embeddings/rpc-applications.md`
- `embeddings/troubleshooting.md`

## Related Skills

For worker job flows and troubleshooting, use:

- `worker/osm_import.md`
- `worker/geoai_embeddings.md`
- `worker/srai_embeddings.md`

For project database ingestion/import workflows, use:

- `project-db/data_import.md`

For map tiles and map visualization workflows, use:

- `tileserver.md`

For embeddings management workflows, use:

- `embeddings.md`

## Failure Handling

- If auth fails: run `geobase-cli login`, then retry.
- If `project_ref` is invalid: re-check with `geobase-cli projects refs`.
- After 2-3 failed attempts, stop looping and switch to diagnosis (routing, auth scope, payload, service status).

## Security Rules

- Never paste service-role keys in chat.
- Never commit secrets to repo files.
- Never expose privileged keys in public/client env vars (`NEXT_PUBLIC_*`, browser bundles, logs).
- Keep project anon keys and service-role keys separated by intended usage.
