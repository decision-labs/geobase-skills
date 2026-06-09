---
name: geobase-embeddings-troubleshooting
description: "Diagnose GeoEmbeddings failures across worker jobs, catalogue API, and RPC. Triggers on embeddings error, job failed, RPC 4xx, empty similarity results, catalogue mismatch."
metadata:
  author: geobase
  version: "0.2.0"
---

# GeoEmbeddings Troubleshooting

## When to use this skill

- Worker job failed or stuck after create attempt
- Catalogue API returns unexpected rows or auth errors
- RPC returns empty results, wrong overload, or schema errors
- User already tried create/RPC once and needs diagnosis (not first-time setup)

## Worker creation issues

- If jobs fail immediately: validate payload shape against task requirements and ensure required env vars are present on worker.
- If jobs stall: check worker health/status and job queue progression before retrying.
- If create operations collide: verify table name and require a new one.

## Catalogue API issues

- If PATCH fails: ensure `table_name` is exact and body includes only `is_public`.
- If DELETE fails: verify table exists and inspect count first.
- If 401/403: verify auth scope for Studio project API route.

## RPC issues

- If function ambiguity/error: payload keys must match exactly one overload.
- If no rows returned: lower threshold or review spatial overlap/query geometry.
- If auth fails: verify `apikey`, `Authorization` header, and table visibility/RLS.
- If schema errors: set `db.schema = 'geoembeddings'` (JS) or include `Content-Profile` / `Accept-Profile` headers.
