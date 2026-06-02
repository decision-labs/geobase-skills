---
name: geobase-project-db-data-import
description: "Use when importing local user data files (GeoParquet, GeoJSON, GPKG, Shapefile, CSV, Parquet) into a Geobase project database."
metadata:
  author: geobase
  version: "0.1.0"
---

# Project DB: Local Data Import

## Required Inputs

- authenticated CLI session (`geobase-cli login`)
- `project_ref`
- local file path (for example `.parquet`, `.geojson`, `.gpkg`, `.shp`, `.csv`)
- target table name

## Core Rule

Use `ogr2ogr` as the default import tool for geospatial vector datasets.
For non-geospatial tabular files, use `COPY`/`\copy` or Python loaders.

## Procedure

1. Validate auth/session and project:
   - `geobase-cli whoami`
   - `geobase-cli projects refs`
   - `geobase-cli projects env <project-ref> --persona postgres --format dotenv`
2. Source DB connection values from the generated postgres persona env:
   - use `GEOBASE_PGHOST`, `GEOBASE_PGPORT`, `GEOBASE_PGDATABASE`, `GEOBASE_PGUSER`, `GEOBASE_PGPASSWORD`
   - if needed, replace placeholders in `GEOBASE_DATABASE_URI` / `DATABASE_URI`
   - ⚠️ **`GEOBASE_PGPASSWORD` is always output as `<db-password>` — the CLI does not expose the real password.**
     Ask the user to provide it and write it to a local `.env` file before proceeding. Never write the password to a tracked file.
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
