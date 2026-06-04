---
name: geobase-worker-srai-embeddings
description: "Use when creating and validating SRAI embeddings worker jobs (`createSraiEmbeddings`) for a Geobase project."
metadata:
  author: geobase
  version: "0.1.1"
---

# Worker: SRAI Embeddings

## Secrets (human in the loop)

Worker HTTP calls need **`GEOBASE_SERVICE_ROLE_KEY`**. The CLI and agents cannot obtain it. **Ask the user** to put the real key in a gitignored **`.env.secrets`** before any worker API step. Do not paste the key in chat. See `@geobase` → **Secrets (human in the loop)**.

## Required Inputs

- authenticated CLI session (`geobase-cli login`)
- `project_ref`
- `GEOBASE_SERVICE_ROLE_KEY` from user-provided `.env.secrets` (not from chat or CLI placeholders)
- payload JSON with:
  - `tableName`
  - `pipeline` object
  - optional: `uploadArtifactsToStorage`, `pretrainedModelRunId`, `ownerUuid`

## Procedure

1. Validate session and project:
   - `geobase-cli whoami`
   - `geobase-cli projects refs`
2. Bootstrap non-secret env, then load secrets from disk:
   - `geobase-cli projects env <project-ref> --persona web --format dotenv` → `GEOBASE_PROJECT_REF`, `GEOBASE_API_URI`, anon key, etc.
   - user must provide **`GEOBASE_SERVICE_ROLE_KEY`** in **`.env.secrets`** (human in the loop)
   - `set -a && source .env.secrets && set +a` (user runs locally; agent does not read secret values)
3. Fetch canonical model registry JSON and validate selected SRAI model:
   - `https://gist.githubusercontent.com/mhassanch/5acd83c04618c83e29d118ac722bb805/raw/geobase_models_registry.json`
   - map payload SRAI model to registry `id` and ensure it is available.
4. Validate payload:
   - table name rule (canonical): `^[a-z][a-z0-9_]{0,62}$`
   - ensure `pipeline` exists and is an object.
   - strict check (required): verify target table does not already exist before submit.
     - use `@geobase-embeddings-catalogue-management` to list embedding tables (catalogue) before submit.
5. Check worker capacity first:
   - call `GET https://${GEOBASE_PROJECT_REF}.geobase.app/worker/capacity` with:
     - header: `apikey: ${GEOBASE_SERVICE_ROLE_KEY}`
     - header: `Authorization: Bearer ${GEOBASE_SERVICE_ROLE_KEY}`
   - read `maxH3Cells` from response.
6. Estimate H3 cells before submit:
   - estimate cells from AOI + `pipeline.regionalizerArgs.dgg.resolution`.
   - if estimate exceeds `maxH3Cells`, stop and ask user for approved payload changes.
7. If over capacity, stop and ask for explicit user approval. Do not change payload silently.
8. Submit using worker endpoint:
   - direct project worker API:
     - `POST https://${GEOBASE_PROJECT_REF}.geobase.app/worker/jobs/createSraiEmbeddings`
   - required headers:
     - `apikey: ${GEOBASE_SERVICE_ROLE_KEY}`
     - `Authorization: Bearer ${GEOBASE_SERVICE_ROLE_KEY}`
     - `Content-Type: application/json`
9. Poll by id (match path used at submit):
   - direct project worker API:
     - `GET https://${GEOBASE_PROJECT_REF}.geobase.app/worker/jobs/createSraiEmbeddings/<job_id>`
10. Polling timing guidance:
   - start every 5s for first minute, then use backoff (10s, 20s, 30s max).
   - long extraction / fit phases can run for extended time; do not treat as failure unless status is `failed` or request times out repeatedly.
11. Stop only on terminal state (`success` or `failed`).
12. Validate created table and embedding outputs.

### Submit Rule (Mandatory)

Submit only after all checks pass:

- capacity fetched successfully from `/capacity`
- `estimated_h3_cells <= maxH3Cells`
- table-name and collision checks passed
- payload unchanged from user intent unless explicitly approved
- model is validated against registry `id`

## Example Payload

```json
{
  "tableName": "srai_berlin_v1",
  "pipeline": {
    "dataLoaderArgs": {
      "query": "Berlin, Germany",
      "filter": "base_osm"
    },
    "regionalizerArgs": {
      "dgg": { "kind": "h3", "resolution": 9 },
      "query": "Berlin, Germany"
    },
    "fitterArgs": {
      "modelName": "hex2vec"
    }
  },
  "uploadArtifactsToStorage": false
}
```

## Failure Handling

- If auth fails: run `geobase-cli login`, then retry.
- If payload schema fails: fix `pipeline` structure first; do not retry unchanged payload.
- If table validation fails: use `^[a-z][a-z0-9_]{0,62}$` and a new name.
- For upstream OSM extraction instability: use smaller query area and lower complexity pipeline first.
- If job appears stalled during long extraction/fitting: continue polling with backoff before retrying.
- If 5xx worker errors: capture payload shape + project ref + timestamp; retry once.
