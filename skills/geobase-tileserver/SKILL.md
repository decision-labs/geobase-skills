---
name: geobase-tileserver
description: "Use when building frontend map visualisations with the Geobase vector tile server and MapLibre GL JS."
metadata:
  author: geobase
  version: "0.2.2"
---

# Tileserver: Frontend Map Visualisation

## Required Inputs

- `NEXT_PUBLIC_GEOBASE_API_URL` — project base URL (e.g. `https://<ref>.geobase.app`)
- `NEXT_PUBLIC_GEOBASE_ANON_KEY` — project anon key
- target table name that has a geometry column (auto-detected by tileserver)

Obtain both from:

```bash
geobase-cli projects env <project-ref> --persona web --format dotenv
```

## Tile URL Pattern

```
{API_URL}/tileserver/v1/{schema}.{table}/{z}/{x}/{y}.pbf?apikey={ANON_KEY}
```

Example:

```
https://<ref>.geobase.app/tileserver/v1/public.my_table/{z}/{x}/{y}.pbf?apikey=<anon_key>
```

Use `/cached/` for static datasets that do not change frequently:

```
https://<ref>.geobase.app/tileserver/v1/cached/public.my_table/{z}/{x}/{y}.pbf?apikey=<anon_key>
```

Function/RPC tiles are also supported:

```
{API_URL}/tileserver/v1/rpc.<function_name>/{z}/{x}/{y}.pbf?apikey={ANON_KEY}
```

Example:

```
https://<ref>.geobase.app/tileserver/v1/rpc.get_routing_tiles/{z}/{x}/{y}.pbf?apikey=<anon_key>
```

Use additional function parameters as query params.

## MapLibre GL JS Source Setup

```js
map.addSource("my_source", {
  type: "vector",
  tiles: [`${API_URL}/tileserver/v1/public.my_table/{z}/{x}/{y}.pbf?apikey=${ANON_KEY}`],
});

map.addLayer({
  id: "my_layer",
  type: "fill",           // or "line", "circle", "symbol"
  source: "my_source",
  "source-layer": "public.my_table",   // must match fully-qualified table name
  paint: { ... },
});
```

For function/RPC tiles, `source-layer` is commonly `"default"` unless your function sets another name.

## Properties and Filters

Limit returned attributes for smaller tile payloads:

```
?properties=name,population,area
```

Filter rows with CQL:

```
?filter=population > 1000000
```

Always URL-encode filter values in app code:

```js
const filter = "population > 1000000 AND name LIKE 'San%'";
const tileUrl = `${API_URL}/tileserver/v1/public.cities/{z}/{x}/{y}.pbf?apikey=${ANON_KEY}&filter=${encodeURIComponent(filter)}`;
```

## Styling

Refer to the **[MapLibre Style Spec](https://maplibre.org/maplibre-style-spec/)** for all paint/layout properties, expressions, and filter syntax.

For Geobase-specific tileserver configuration, filters, caching, and integration examples see the **[Geobase Tileserver docs](https://docs.geobase.app/tileserver)**.

**Color basics**

- Match scheme to data: **sequential** for ordered numbers, **diverging** for values around a meaningful midpoint, **qualitative** for categories (no natural order).
- For numeric choropleths and `interpolate` ramps, use **color-blind safe** palettes only. Avoid red–green for magnitude or change; use blue–orange diverging when you need two sides.
- **Basemap:** prefer **Carto vector** GL styles (light: Voyager, dark: Dark Matter), then stack Geobase tileserver layers on top:
  - `https://tiles.basemaps.cartocdn.com/gl/voyager-gl-style/style.json`
  - `https://tiles.basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json`
- Keep the map palette small (~10–12 hues); let data layers carry contrast over the basemap.
- Do not rely on color alone — use line weight, opacity, outlines, or labels too.
- Pick class breaks before colors; use `interpolate` / `step` with **`to-number`** on tile properties (see gotcha 1).
- Simplify at low zoom (`minzoom`, fewer classes); use partial fill opacity when polygons overlap.

## Known Gotchas

### 1. Numeric columns arrive as strings in MVT

PostgreSQL `numeric`, `float`, `double precision` columns are serialised as **strings** inside MVT tiles (e.g. `"38.6"` not `38.6`). Numeric MapLibre expressions will silently evaluate to `0` / fallback if you don't cast.

Always wrap numeric property reads with `["to-number", ...]`:

```js
["to-number", ["coalesce", ["get", "my_numeric_col"], "0"], 0]
```

### 2. `source-layer` must use the fully-qualified table name

```js
"source-layer": "public.my_table"   // ✓ correct
"source-layer": "my_table"          // ✗ will not match — layer renders nothing
```

### 3. Empty tile (0 bytes, HTTP 200) means wrong tile coordinates

The tileserver returns an empty tile (not an error) when `{z}/{x}/{y}` does not intersect the data extent. Recalculate the correct coordinates for your data's bounding box before debugging styling or auth issues.

### 4. RLS / private tables need auth headers (not only apikey)

When RLS is enabled and data is private, include user JWT in tile requests.
For MapLibre, inject `Authorization` with `transformRequest`:

```js
const transformRequest = (url, resourceType) => {
  if (resourceType === "Tile" && url.startsWith(API_URL) && accessToken) {
    return {
      url,
      headers: { Authorization: `Bearer ${accessToken}` }
    };
  }
};
```

## Failure Handling

- **Black / invisible features** — numeric property not cast to number (see gotcha 1), or wrong `source-layer` name (gotcha 2).
- **No tiles loading** — check anon key, verify tile URL returns non-zero bytes at the correct `{z}/{x}/{y}`.
- **Auth errors on tiles** — pass `apikey` as a query param, or use `transformRequest` to inject an `Authorization: Bearer` header for RLS-protected tables.
