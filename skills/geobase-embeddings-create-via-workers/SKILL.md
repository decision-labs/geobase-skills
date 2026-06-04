---
name: geobase-embeddings-create-via-workers
description: "Use when creating GeoEmbeddings tables. Enforces worker-first creation flow and links to task-specific worker skills."
metadata:
  author: geobase
  version: "0.1.0"
---

# Create Embeddings via Workers

Do not create embeddings tables through ad-hoc direct RPC flows. Use worker job APIs.

## Core rules

- Worker jobs are project-scoped and run asynchronously (`pending`/`running`/`success`/`failed`).
- Use worker job routes (project host `/worker/jobs/*`) or Studio project job proxies.
- Treat table creation as a create-operation with strict name validation/collision checks.

## Task-specific guides

- `@geobase-worker-geoai-embeddings`
- `@geobase-worker-srai-embeddings`
- `@geobase-worker-osm-import` *(context only; OSM import is not itself an embeddings creation flow, but can be an upstream data-prep/input step for embeddings workflows).*

## Required inputs

- authenticated CLI session
- `project_ref`
- job payload matching the selected worker task
- **`GEOBASE_SERVICE_ROLE_KEY`** in user-provided **`.env.secrets`** for worker HTTP (human in the loop; see `@geobase`)

## Verification

- confirm job moved to terminal state
- confirm expected embeddings table/catalogue entry exists
- record job id + status for traceability
