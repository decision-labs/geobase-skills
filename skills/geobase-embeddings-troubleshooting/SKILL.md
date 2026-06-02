---
name: geobase-embeddings-troubleshooting
description: "Diagnose GeoEmbeddings failures across worker creation, catalogue metadata APIs, and application RPC calls."
metadata:
  author: geobase
  version: "0.1.0"
---

# GeoEmbeddings Troubleshooting

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
