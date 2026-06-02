---
name: geobase-worker-osm-import
description: "Use when creating and validating OSM import worker jobs in a Geobase project."
metadata:
  author: geobase
  version: "0.1.1"
---

# Worker: OSM Import

## Secrets (human in the loop)

Worker HTTP calls need **`GEOBASE_SERVICE_ROLE_KEY`**. The CLI and agents cannot obtain it. **Ask the user** to put the real key in a gitignored **`.env.secrets`** before any worker API step. Do not paste the key in chat. See `@geobase` → **Secrets (human in the loop)**.

## Required Inputs

- authenticated CLI session (`geobase-cli login`)
- `project_ref`
- `GEOBASE_SERVICE_ROLE_KEY` from user-provided `.env.secrets` (not from chat or CLI placeholders)
- payload JSON with:
  - `areaName`
  - `aoiGeoJson` (`Polygon` or `MultiPolygon`)

## Procedure

1. Validate session:
   - `geobase-cli whoami`
2. Resolve project:
   - `geobase-cli projects refs`
3. Bootstrap non-secret env, then load secrets from disk:
   - `geobase-cli projects env <project-ref> --persona web --format dotenv` → `GEOBASE_PROJECT_REF`, `GEOBASE_API_URI`, anon key, etc.
   - user must provide **`GEOBASE_SERVICE_ROLE_KEY`** in **`.env.secrets`** (human in the loop)
   - `set -a && source .env.secrets && set +a` (user runs locally; agent does not read secret values)
4. Validate payload before submit:
   - `tablePrefix` rule (canonical): `^[a-z][a-z0-9_]{0,62}$`
   - verify target prefixed tables do not already exist in destination schema set.
   - if collisions exist, choose a different `tablePrefix` before submit.
5. Prepare payload file, for example:

```json
{
  "areaName": "demo_area",
  "aoiGeoJson": {
    "type": "Polygon",
    "coordinates": [[[10.0, 59.0], [10.1, 59.0], [10.1, 59.1], [10.0, 59.1], [10.0, 59.0]]]
  },
  "topics": ["buildings", "streets"],
  "tablePrefix": "osm_demo"
}
```

6. Submit using worker endpoint:
   - direct project worker API:
     - `POST https://${GEOBASE_PROJECT_REF}.geobase.app/worker/jobs/osmImportArea`
   - required headers:
     - `apikey: ${GEOBASE_SERVICE_ROLE_KEY}`
     - `Authorization: Bearer ${GEOBASE_SERVICE_ROLE_KEY}`
     - `Content-Type: application/json`
7. Poll job status by id (match path used at submit):
   - direct project worker API:
     - `GET https://${GEOBASE_PROJECT_REF}.geobase.app/worker/jobs/osmImportArea/<job_id>`
8. Polling timing guidance:
   - start every 5s for first minute, then use backoff (10s, 20s, 30s max).
   - large AOI imports can run for extended time; do not treat as failure unless status is `failed` or request times out repeatedly.
9. Stop only on terminal state (`success` or `failed`).
10. Validate imported outputs (tables/layers/row counts/schemas).
11. Record `job_id`, `project_ref`, payload shape, and timestamps.

## Submit Rule (Mandatory)

Submit only after all checks pass:

- `tablePrefix` matches `^[a-z][a-z0-9_]{0,62}$`
- collision checks for target tables passed
- payload fields are unchanged from user intent unless user explicitly approved edits

## Failure Handling

- If auth fails: run `geobase-cli login`, then retry.
- If `project_ref` is invalid: re-check with `geobase-cli projects refs`.
- If 4xx payload errors: fix payload schema first; do not retry unchanged payload.
- If table/prefix validation fails: use `^[a-z][a-z0-9_]{0,62}$` and choose a new prefix.
- If 5xx worker errors: capture request shape + project ref + timestamp; retry once after short delay.
- If worker returns upstream extraction errors (for example `HTTP 502`):
  - retry with a smaller AOI;
  - retry with fewer topics (start with one topic, e.g. `buildings`);
  - confirm `projects status <project-ref>` is healthy before rerun;
  - preserve failed `job_id` and result text for backend debugging.
