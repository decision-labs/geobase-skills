---
name: geobase-project-db-data-import
description: "Import local geospatial files (GeoParquet, GeoJSON, GPKG, Shapefile, CSV, Parquet) into project Postgres via ogr2ogr. Triggers on data import, load shapefile, geoparquet ingest, ogr2ogr."
metadata:
  author: geobase
  version: "0.2.0"
---

# Project DB: Local Data Import

## When to use this skill

- Load a **local file** into the Geobase project database
- GeoParquet, GeoJSON, GPKG, Shapefile, CSV, Parquet → Postgres
- Needs `DATABASE_URI` from user `.env.db` (human in the loop)
- **Not** for OSM worker import (`@geobase-worker-osm-import`)

## Required Inputs

- `@geobase` → **Private beta (CLI not shipped)** if `geobase-cli` is unavailable
- authenticated CLI session (`geobase-cli login`) when CLI is installed
- `project_ref`
- local file path (for example `.parquet`, `.geojson`, `.gpkg`, `.shp`, `.csv`)
- target table name

## Secrets (human in the loop)

`DATABASE_URI` / `GEOBASE_DATABASE_URI` and the DB password are **not** available to agents or `geobase-cli` in usable form. `projects env --persona postgres` prints placeholders only.

Before import:

1. Run `geobase-cli projects env <project-ref> --persona postgres --format dotenv` for host, port, database, user (non-secret).
2. **Ask the user** to create a gitignored **`.env.db`** with the real password and a complete `DATABASE_URI` / `GEOBASE_DATABASE_URI` (replace `[PASSWORD]` / `<db-password>`).
3. User loads it locally; do **not** ask them to paste the password or URI in chat.

See `@geobase` → **Secrets (human in the loop)**.

## Core Rule

Use `ogr2ogr` as the default import tool for geospatial vector datasets.
For non-geospatial tabular files, use `COPY`/`\copy` or Python loaders.

## Procedure

1. Validate auth/session and project:
   - `geobase-cli whoami`
   - `geobase-cli projects refs`
   - `geobase-cli projects env <project-ref> --persona postgres --format dotenv`
2. Source DB credentials from the user's **`.env.db`** (after they create it):
   - non-secret fields may come from `projects env`: `GEOBASE_PGHOST`, `GEOBASE_PGPORT`, `GEOBASE_PGDATABASE`, `GEOBASE_PGUSER`
   - password and `DATABASE_URI` / `GEOBASE_DATABASE_URI` must come from `.env.db` only — never from CLI output or chat
3. Validate target table name:
   - keep it short;
   - use letters/digits/underscores only;
   - max length 63.
   - strict preflight (required): verify target table does not already exist.
     Example SQL check:
     `SELECT to_regclass(format('public.%I', '<target_table>')) IS NULL AS table_available;`
4. Inspect local file first:
   - geospatial: `ogrinfo "<path>"`
   - parquet tabular: inspect schema with `duckdb`/Python as needed
5. Decide import path:
   - geospatial vector data -> `ogr2ogr`
   - plain tabular data -> `\copy` / Python
6. Import geospatial vector data (recommended path):

```bash
PGPASSWORD="$GEOBASE_PGPASSWORD" ogr2ogr \
  -f PostgreSQL \
  PG:"host=$GEOBASE_PGHOST port=$GEOBASE_PGPORT dbname=$GEOBASE_PGDATABASE user=$GEOBASE_PGUSER sslmode=require" \
  "<input_file>" \
  -nln public.<target_table> \
  -lco GEOMETRY_NAME=geom \
  -nlt PROMOTE_TO_MULTI
```

> Note: `ogr2ogr` automatically creates a spatial index on the geometry column during import.

7. Optional import modes:
   - replace table: add `-overwrite`
   - append rows: add `-append`
   - reproject: add `-t_srs EPSG:4326` (or project target SRID)
8. Validate import:
   - row count query
   - geometry validity and SRID checks
   - sample data query

## Failure Handling

- If auth fails: run `geobase-cli login`, then retry.
- If project/db connection fails: re-check postgres env output and credentials.
- If geometry import fails:
  - run `ogrinfo` again to confirm layer/geometry types;
  - try `-nlt PROMOTE_TO_MULTI`;
  - set explicit `-t_srs` if CRS is missing/mismatched.
- If table name errors occur: shorten/sanitize table name.

## Security Rules

- Never paste DB passwords in chat.
- Never commit secrets/connection strings to repo files.
- Prefer environment variables or secure local credential storage.
