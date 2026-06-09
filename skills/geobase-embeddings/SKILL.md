---
name: geobase-embeddings
description: "GeoEmbeddings index — route embedding tasks by hierarchy: worker creation, catalogue metadata (RUD), application RPC, troubleshooting. Triggers on geoembeddings, embeddings table, similarity search entry point."
metadata:
  author: geobase
  version: "0.2.0"
---

# GeoEmbeddings Skills Index

## When to use this skill

- User asks about GeoEmbeddings but the task type is unclear
- Need the correct order: create tables → catalogue → RPC apps
- Routing before loading a worker or RPC skill

Use this hierarchy:

1. Create embeddings only via workers:
   - `@geobase-embeddings-create-via-workers`
2. Manage metadata via catalogue API (RUD):
   - `@geobase-embeddings-catalogue-management`
3. Build applications with RPC APIs:
   - `@geobase-embeddings-rpc-applications`
4. Troubleshooting:
   - `@geobase-embeddings-troubleshooting`
