---
name: geobase-embeddings-catalogue-management
description: "Use for GeoEmbeddings table metadata management through the catalogue API: list, update visibility, delete, and count."
metadata:
  author: geobase
  version: "0.1.0"
---

# Catalogue API (RUD Metadata Management)

Use the **Geobase project** PostgREST API (`geoembeddings` schema) to inspect and manage `embeddings_catalogue` metadata on `GEOBASE_PROJECT_URL` — not the Studio host or `/api/projects/...` routes.

## Required inputs

- `GEOBASE_PROJECT_URL` — project host (e.g. `https://<project-ref>.geobase.app`)
- `GEOBASE_ANON_KEY` — send as `apikey` on every request

**Mutations** (PATCH visibility, delete table) require one of:

- `GEOBASE_SERVICE_ROLE_KEY` — project service role; use server-side only as both `apikey` and `Authorization: Bearer`, or
- A **project user** access token — user signed into that project (GoTrue on `GEOBASE_PROJECT_URL`) whose id matches `owner` on the catalogue row for that table.

**Reads** (list/get catalogue, count rows on tables you can access) work with `GEOBASE_ANON_KEY` plus optional project user JWT; RLS limits what each caller sees.

Resolve URL/key with:

```bash
geobase-cli projects env <project-ref> --persona web --format dotenv
```

**CLI gap:** there is no `geobase-cli` command yet to sign in as a **project user** and emit a project access token. Until that ships, use `GEOBASE_SERVICE_ROLE_KEY` server-side or obtain a project user JWT from your app/auth flow. Planned: Geobase CLI roadmap — project user access.

PostgREST base path: `${GEOBASE_PROJECT_URL}/rest/v1`.

## Schema headers

All catalogue calls use the `geoembeddings` schema:

- Reads: `Accept-Profile: geoembeddings`
- RPC writes: `Content-Profile: geoembeddings`

## Endpoints (project PostgREST)

- **List catalogue entries** (latest first):

  `GET /rest/v1/embeddings_catalogue?order=created_at.desc`

  RLS returns rows you own, public tables, and NULL-owner (worker) entries.

- **Get one entry**:

  `GET /rest/v1/embeddings_catalogue?table_name=eq.<table_name>`

- **Update visibility** (`is_public` only):

  `PATCH /rest/v1/embeddings_catalogue?table_name=eq.<table_name>`

  Body: `{ "is_public": true }` or `{ "is_public": false }`

  Requires service role, or a project user JWT where that user owns the catalogue row.

- **Delete table and catalogue entry** (RPC):

  `POST /rest/v1/rpc/delete_embedding_table`

  Body: `{ "p_table_name": "<table_name>" }`

  Requires service role, or a project user JWT where `owner` on that catalogue row equals the caller’s user id.

- **Count embedding rows** (target table, not catalogue):

  `HEAD /rest/v1/<table_name>?select=id` with `Prefer: count=exact`

  Read `Content-Range` for the total.

## Operational guidance

- Always list or get catalogue first and verify exact `table_name` before patch/delete.
- PATCH updates `is_public` only; do not attempt other catalogue columns.
- Run a row count on the embeddings table before destructive deletes.
- Call the project URL only; do not use Studio `/api/projects/...` routes for catalogue operations.
- Keep `GEOBASE_SERVICE_ROLE_KEY` server-side only; in clients, use the signed-in project user’s token when that user owns the table.
- Before PATCH or delete, list the catalogue and confirm `table_name` and `owner` match the caller (or use service role).
- If `PATCH` returns 403 or updates zero rows, the token is not service role and does not own the row (or catalogue writes are not enabled for user JWT on your deployment).

## Client setup (JavaScript)

```ts
import { createClient } from '@supabase/supabase-js'

const geobase = createClient(process.env.GEOBASE_PROJECT_URL!, process.env.GEOBASE_ANON_KEY!, {
  db: { schema: 'geoembeddings' },
  global: {
    headers: { Authorization: `Bearer ${process.env.USER_ACCESS_TOKEN}` },
  },
})

const { data, error } = await geobase
  .from('embeddings_catalogue')
  .select('*')
  .order('created_at', { ascending: false })
```

## Examples (curl)

List:

```bash
curl -sS "${GEOBASE_PROJECT_URL}/rest/v1/embeddings_catalogue?order=created_at.desc" \
  -H "apikey: ${GEOBASE_ANON_KEY}" \
  -H "Authorization: Bearer ${USER_ACCESS_TOKEN}" \
  -H "Accept-Profile: geoembeddings"
```

Update visibility (project user who owns the table, or use `GEOBASE_SERVICE_ROLE_KEY` for both `apikey` and `Authorization`):

```bash
curl -sS -X PATCH "${GEOBASE_PROJECT_URL}/rest/v1/embeddings_catalogue?table_name=eq.${TABLE_NAME}" \
  -H "apikey: ${GEOBASE_ANON_KEY}" \
  -H "Authorization: Bearer ${USER_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "Accept-Profile: geoembeddings" \
  -H "Prefer: return=representation" \
  -d '{"is_public":true}'
```

Delete (same auth as PATCH):

```bash
curl -sS -X POST "${GEOBASE_PROJECT_URL}/rest/v1/rpc/delete_embedding_table" \
  -H "apikey: ${GEOBASE_ANON_KEY}" \
  -H "Authorization: Bearer ${USER_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "Content-Profile: geoembeddings" \
  -d "{\"p_table_name\":\"${TABLE_NAME}\"}"
```

Row count:

```bash
curl -sS -I "${GEOBASE_PROJECT_URL}/rest/v1/${TABLE_NAME}?select=id" \
  -H "apikey: ${GEOBASE_ANON_KEY}" \
  -H "Authorization: Bearer ${USER_ACCESS_TOKEN}" \
  -H "Accept-Profile: geoembeddings" \
  -H "Prefer: count=exact"
```
