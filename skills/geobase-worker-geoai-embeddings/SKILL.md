---
name: geobase-worker-geoai-embeddings
description: "Use when creating and validating GeoAI embeddings worker jobs (`createGeoEmbeddings`) for a Geobase project."
metadata:
  author: geobase
  version: "0.1.1"
---

# Worker: GeoAI Embeddings

## Secrets (human in the loop)

Worker HTTP calls need **`GEOBASE_SERVICE_ROLE_KEY`**. The CLI and agents cannot obtain it. **Ask the user** to put the real key in a gitignored **`.env.secrets`** before any worker API step. Do not paste the key in chat. See `@geobase` → **Secrets (human in the loop)**.

## Required Inputs

- authenticated CLI session (`geobase-cli login`)
- `project_ref`
- `GEOBASE_SERVICE_ROLE_KEY` from user-provided `.env.secrets` (not from chat or CLI placeholders)
- payload JSON with:
  - `geotiffPath` (URL)
  - `tableName`
  - optional: `modelName`, `tileSize`, `normalizeEmbeddings`, `bands`, `uploadArtifactsToStorage`

## Procedure

1. Validate session and project:
   - `geobase-cli whoami`
   - `geobase-cli projects refs`
2. Bootstrap non-secret env, then load secrets from disk:
   - `geobase-cli projects env <project-ref> --persona web --format dotenv` → `GEOBASE_PROJECT_REF`, `GEOBASE_API_URI`, anon key, etc.
   - user must provide **`GEOBASE_SERVICE_ROLE_KEY`** in **`.env.secrets`** (human in the loop)
   - `set -a && source .env.secrets && set +a` (user runs locally; agent does not read secret values)
3. Fetch canonical model registry JSON and validate selected model:
   - `https://gist.githubusercontent.com/mhassanch/5acd83c04618c83e29d118ac722bb805/raw/geobase_models_registry.json`
   - map payload `modelName` to registry `id` (do not match on label/name text).
   - ensure that registry entry is available.
4. Validate payload before submit:
   - table name rule (canonical): `^[a-z][a-z0-9_]{0,62}$`
   - strict check (required): verify target table does not already exist before submit.
     - use `embeddings/catalogue-management.md` to list embedding tables (catalogue) before submit.
5. Inspect GeoTIFF band metadata with GDAL:
   - `gdalinfo "<geotiffPath>"`
   - map payload `bands` to desired channels from output.
   - strict indexing rule: `bands` are **0-based** (first band is index `0`).
   - for RGB imagery, use `[0, 1, 2]`.
6. Check worker capacity first:
   - call `GET https://${GEOBASE_PROJECT_REF}.geobase.app/worker/capacity` with:
     - header: `apikey: ${GEOBASE_SERVICE_ROLE_KEY}`
     - header: `Authorization: Bearer ${GEOBASE_SERVICE_ROLE_KEY}`
   - read `maxGeoPatches` from response.
7. Estimate GeoAI patches before submit:
   - read width/height with `gdalinfo -json`.
   - compute tile count from `tileSize`.
   - compute `estimated_geo_patches = total_tiles * patches_per_tile`.
8. If over capacity, stop and ask for explicit user approval. Do not change payload silently.
   - decision order:
     1) increase `tileSize` (must still satisfy model minimum tile size),
     2) switch to a lower `patches_per_tile` model,
     3) clip AOI / split imagery into multiple jobs.
9. Submit using worker endpoint:
   - direct project worker API:
     - `POST https://${GEOBASE_PROJECT_REF}.geobase.app/worker/jobs/createGeoEmbeddings`
   - required headers:
     - `apikey: ${GEOBASE_SERVICE_ROLE_KEY}`
     - `Authorization: Bearer ${GEOBASE_SERVICE_ROLE_KEY}`
     - `Content-Type: application/json`
10. Poll by id (match path used at submit):
   - direct project worker API:
     - `GET https://${GEOBASE_PROJECT_REF}.geobase.app/worker/jobs/createGeoEmbeddings/<job_id>`
   - required headers:
     - `apikey: ${GEOBASE_SERVICE_ROLE_KEY}`
     - `Authorization: Bearer ${GEOBASE_SERVICE_ROLE_KEY}`
     - `Content-Type: application/json`
11. Polling timing guidance:
   - start every 5s for first minute, then use backoff (10s, 20s, 30s max).
   - common long-running phase: uploading embeddings to database.
   - do not treat long upload phase as failure unless status is `failed` or request times out repeatedly.
12. Stop only on terminal state (`success` or `failed`).
13. Validate output table row count, schema, and embeddings availability.

## Submit Rule (Mandatory)

Submit only after all checks pass:

- `gdalinfo` succeeded and dimensions were parsed.
- `estimated_geo_patches <= maxGeoPatches`.
- table-name and collision checks passed.
- payload fields are unchanged from user intent unless user explicitly approved edits.
- `modelName` is validated against registry `id`.

## Example Payload

```json
{
  "geotiffPath": "https://huggingface.co/datasets/geobase/geoai-cogs/resolve/main/geoembeddings-demo/building-detection_sm.tif",
  "tableName": "geoai_building_detection_sm",
  "modelName": "dinov3-vitl16-pretrain-sat493m",
  "bands": [0, 1, 2],
  "tileSize": 256,
  "normalizeEmbeddings": true,
  "uploadArtifactsToStorage": false
}
```

## Failure Handling

- If auth fails: run `geobase-cli login`, then retry.
- If table validation fails: use `^[a-z][a-z0-9_]{0,62}$` and a new name.
- If GeoTIFF fetch fails: verify URL/path accessibility and format.
- If job appears stalled in upload phase: continue polling with backoff before retrying.
- If 5xx worker errors: capture payload shape + project ref + timestamp; retry once.
