---
name: geobase-embeddings-management
description: "GeoEmbeddings operations hierarchy: workers for creation, catalogue for RUD metadata, RPC for similarity_search and change_detection. Triggers when the user asks how GeoEmbeddings workflows fit together."
metadata:
  author: geobase
  version: "0.2.1"
---

# GeoEmbeddings Operations Hierarchy

## When to use this skill

- Explain the three GeoEmbeddings surfaces (workers, catalogue, RPC)
- User conflates creating embeddings with querying them
- Onboarding before diving into a specific worker or RPC skill

Follow this hierarchy:

1. **Create embeddings only via workers**
2. **Catalogue API for RUD metadata management**
3. **Applications use RPC API** (`similarity_search`, `change_detection`)

See detailed skills:

- 1) Create via workers:
  - `@geobase-embeddings-create-via-workers`
- 2) Catalogue metadata management:
  - `@geobase-embeddings-catalogue-management`
- 3) Applications RPC:
  - `@geobase-embeddings-rpc-applications`
- Troubleshooting:
  - `@geobase-embeddings-troubleshooting`

Cross-reference existing worker skills when payload-level details are needed:

- `@geobase-worker-geoai-embeddings`
- `@geobase-worker-srai-embeddings`
- `@geobase-worker-osm-import`

## Failure Handling

- After 2-3 failed attempts, stop retries and switch to diagnosis by layer:
  1. worker job creation/runtime
  2. catalogue metadata APIs
  3. application RPC payload/auth/schema
