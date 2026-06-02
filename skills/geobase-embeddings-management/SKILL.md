---
name: geobase-embeddings-management
description: "Use for GeoEmbeddings operations hierarchy: create embeddings via worker jobs, manage table metadata via catalogue API (RUD), and run application RPC APIs (`similarity_search`, `change_detection`)."
metadata:
  author: geobase
  version: "0.2.0"
---

# GeoEmbeddings Operations Hierarchy

Follow this hierarchy:

1. **Create embeddings only via workers**
2. **Catalogue API for RUD metadata management**
3. **Applications use RPC API** (`similarity_search`, `change_detection`)

See detailed skills:

- 1) Create via workers:
  - `embeddings/create-via-workers.md`
- 2) Catalogue metadata management:
  - `embeddings/catalogue-management.md`
- 3) Applications RPC:
  - `embeddings/rpc-applications.md`
- Troubleshooting:
  - `embeddings/troubleshooting.md`

Cross-reference existing worker skills when payload-level details are needed:

- `worker/geoai_embeddings.md`
- `worker/srai_embeddings.md`
- `worker/osm_import.md`

## Failure Handling

- After 2-3 failed attempts, stop retries and switch to diagnosis by layer:
  1. worker job creation/runtime
  2. catalogue metadata APIs
  3. application RPC payload/auth/schema
