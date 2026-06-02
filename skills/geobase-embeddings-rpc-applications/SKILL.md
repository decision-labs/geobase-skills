---
name: geobase-embeddings-rpc-applications
description: "Use for application-facing GeoEmbeddings RPC calls (`similarity_search`, `change_detection`) with correct schema, auth, and overload parameters."
metadata:
  author: geobase
  version: "0.1.0"
---

# Applications: RPC API (Similarity + Change Detection)

Use GeoEmbeddings RPC for embedding-native analysis after embeddings tables exist.

## Required Inputs

- `GEOBASE_PROJECT_URL`
- `GEOBASE_ANON_KEY`
- table name(s) and optional label/filter inputs for your overload

Resolve URL/key with:

```bash
geobase-cli projects env <project-ref> --persona web --format dotenv
```

## Client Setup

JavaScript client should use `geoembeddings` schema:

```ts
import { createClient } from '@supabase/supabase-js'

const geobase = createClient(process.env.GEOBASE_PROJECT_URL!, process.env.GEOBASE_ANON_KEY!, {
  db: { schema: 'geoembeddings' },
})
```

## Similarity Search (`similarity_search`)

PostgREST picks the PostgreSQL overload from the **parameter names** you send. Optional parameters (`?`) share defaults listed under [Defaults and Behavior](#defaults-and-behavior). Authoritative full reference (including `change_detection`): [`API.geoembeddings.functions.redesign.md`](../../../../../geobase_services/geoembeddings_pure_sql/docs/API.geoembeddings.functions.redesign.md).

| Function Name | Parameters | Input Type | Label | Spatial Filter | Output |
|--------------|------------|------------|-------|----------------|--------|
| **Similarity Search (Single Table)** | | | | | |
| `similarity_search` | `table_name`, `patch_id`, `similarity_threshold?`, `result_limit?`, `result_offset?`, `include_geom?`, `include_embeddings?`, `spatial_filter?`, `srid?` | patch_id | ❌ | ✅ Optional | `id`, `similarity` (+ optional `geom`, `embedding`) |
| `similarity_search` | `table_name`, `patch_id`, `label_name`, `similarity_threshold?`, `result_limit?`, `result_offset?`, `include_geom?`, `include_embeddings?`, `spatial_filter?`, `srid?` | patch_id | ✅ | ✅ Optional | `id`, `similarity` (+ optional `geom`, `embedding`) |
| `similarity_search` | `table_name`, `lon`, `lat`, `radius?`, `similarity_threshold?`, `result_limit?`, `result_offset?`, `include_geom?`, `include_embeddings?`, `spatial_filter?`, `srid?` | point/circle | ❌ | ✅ Optional | `id`, `similarity` (+ optional `geom`, `embedding`) |
| `similarity_search` | `table_name`, `lon`, `lat`, `label_name`, `radius?`, `similarity_threshold?`, `result_limit?`, `result_offset?`, `include_geom?`, `include_embeddings?`, `spatial_filter?`, `srid?` | point/circle | ✅ | ✅ Optional | `id`, `similarity` (+ optional `geom`, `embedding`) |
| `similarity_search` | `table_name`, `query_geometry` (Polygon/MultiPolygon), `similarity_threshold?`, `result_limit?`, `result_offset?`, `include_geom?`, `include_embeddings?`, `spatial_filter?`, `srid?` | polygon | ❌ | ✅ Optional | `id`, `similarity` (+ optional `geom`, `embedding`) |
| `similarity_search` | `table_name`, `query_geometry` (Polygon/MultiPolygon), `label_name`, `similarity_threshold?`, `result_limit?`, `result_offset?`, `include_geom?`, `include_embeddings?`, `spatial_filter?`, `srid?` | polygon | ✅ | ✅ Optional | `id`, `similarity` (+ optional `geom`, `embedding`) |
| **Similarity Search (Between Two Tables)** | | | | | |
| `similarity_search` | `table_name_1`, `table_name_2`, `similarity_threshold?`, `result_limit?`, `result_offset?`, `include_geom?`, `include_embeddings?`, `spatial_filter?`, `srid?` | two tables | ❌ | ✅ Optional | `id` (from table_1), `similarity` (+ optional `geom`, `embedding`) |
| `similarity_search` | `table_name_1`, `table_name_2`, `label_name`, `similarity_threshold?`, `result_limit?`, `result_offset?`, `include_geom?`, `include_embeddings?`, `spatial_filter?`, `srid?` | two tables | ✅ | ✅ Optional | `id` (from table_1), `similarity` (+ optional `geom`, `embedding`) |

Examples below use the **patch_id** overload. For point/polygon/two-table calls, send the matching keys from the table (e.g. `lon`, `lat`, `query_geometry`, or `table_name_1` + `table_name_2`).

Minimal JavaScript pattern:

```ts
const { data, error } = await geobase.rpc('similarity_search', {
  table_name: 'your_embeddings_table',
  patch_id: 1,
})

if (error) throw error
```

Raw HTTP pattern:

```bash
curl -sS -X POST "${GEOBASE_PROJECT_URL}/rest/v1/rpc/similarity_search" \
  -H "apikey: ${GEOBASE_ANON_KEY}" \
  -H "Authorization: Bearer ${GEOBASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -H "Content-Profile: geoembeddings" \
  -H "Accept-Profile: geoembeddings" \
  -d '{"table_name":"your_embeddings_table","patch_id":1}'
```

## Change Detection (`change_detection`)

Minimal JavaScript pattern:

```ts
const { data, error } = await geobase.rpc('change_detection', {
  table_name_1: 'baseline_embeddings_table',
  table_name_2: 'comparison_embeddings_table',
  similarity_threshold: 0.0,
})

if (error) throw error
```

Raw HTTP pattern:

```bash
curl -sS -X POST "${GEOBASE_PROJECT_URL}/rest/v1/rpc/change_detection" \
  -H "apikey: ${GEOBASE_ANON_KEY}" \
  -H "Authorization: Bearer ${GEOBASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -H "Content-Profile: geoembeddings" \
  -H "Accept-Profile: geoembeddings" \
  -d '{"table_name_1":"baseline_embeddings_table","table_name_2":"comparison_embeddings_table"}'
```

## Defaults and Behavior

- `similarity_threshold` default `0.0`
- `result_limit` default `NULL` (no limit)
- `result_offset` default `0`
- `include_geom` default `false`
- `include_embeddings` default `false`
- `spatial_filter` default `NULL`
- `srid` default `4326`
- point overloads: `radius` default `NULL`, `unit` default `'m'` (`'m'` or `'deg'`)
- `change_detection` returns `change_score = 1 - similarity`
- PostgREST selects overload by the exact parameter keys you send
