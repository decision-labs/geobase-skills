---
name: geobase-tileserver
description: "Use when building frontend map visualisations with the Geobase vector tile server and MapLibre GL JS."
metadata:
  author: geobase
  version: "0.2.0"
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

Iterate styles with **[Maputnik](https://maputnik.github.io/)** (visual editor for the GL style spec). Inspect tile contents with **[mapbox-gl-inspect](https://github.com/lukasmartinelli/mapbox-gl-inspect)** or the Mapbox MVT browser extension (listed under [awesome-vector-tiles](https://github.com/mapbox/awesome-vector-tiles)).

### Color and visual hierarchy

**Match the palette to the data type**

| Data | Scheme | Examples |
| ---- | ------ | -------- |
| Ordered numeric (low → high) | **Sequential** | population, density, elevation |
| Numeric around a meaningful midpoint | **Diverging** | change vs baseline, above/below average |
| Categories (no order) | **Qualitative** | land use class, status, type |

**Color-blind safe ramps for numeric (sequential / diverging) data**

- For choropleth or `interpolate` ramps driven by a numeric tile property, use **color-blind safe** palettes only.
- Pick schemes from **[ColorBrewer 2.0](https://colorbrewer2.org/)** with **“colorblind safe”** enabled (e.g. `YlGnBu`, `PuBu`, `BrBG`, `RdBu`).
- Avoid red–green alone for magnitude or change; prefer blue–orange diverging schemes when you need a clear “two sides” story.
- Perceptually uniform alternatives (also generally color-vision friendly): **Viridis**, **Plasma**, **Cividis** — good for continuous `interpolate` on a single variable.

**General best practices** (aligned with common cartography guidance and MVT tooling ecosystems):

1. **Limit the palette** — aim for roughly **10–12** distinct hues across the whole map; reuse the same hue family for related layers (e.g. transport).
2. **Hierarchy before decoration** — neutral basemap / background (`#f8f9fa`, muted grays); let data layers carry saturation and contrast.
3. **Do not encode meaning with color alone** — combine fill color with **line width**, **opacity**, **stroke**, or **labels** for accessibility and print.
4. **Keep contrast legible, not loud** — similar lightness/saturation across related hues; avoid neon fills on busy basemaps.
5. **Use zoom-aware styling** — simplify at low zoom (`minzoom`, thinner lines, fewer classes); reveal detail as `z` increases.
6. **Prefer `interpolate` + `step` for numbers** — always **`to-number`** MVT properties (see gotcha 1); set explicit `stops` and document the attribute unit.
7. **Class breaks** — for choropleths, choose breaks (quantile, natural breaks, or domain-knowledge thresholds) before picking colors; don’t let the ramp imply precision the data doesn’t have.
8. **Overlapping polygons** — use partial **fill-opacity** (e.g. `0.5–0.7`) or outlines so stacked features remain readable.
9. **Lines vs fills** — roads/boundaries: `line-color` + `line-width`; regions: `fill-color` + subtle `line-color` one step darker.
10. **Test the style** — preview with a color-vision simulator or ColorBrewer’s colorblind filter; verify at multiple zoom levels and on light vs dark UI chrome.

### Example: color-blind safe sequential choropleth

```js
const num = (prop) => ["to-number", ["coalesce", ["get", prop], "0"], 0];

map.addLayer({
  id: "regions_by_pop",
  type: "fill",
  source: "my_source",
  "source-layer": "public.regions",
  paint: {
    "fill-color": [
      "interpolate",
      ["linear"],
      num("population"),
      0, "#f7fcf5",
      50000, "#c7e9c0",
      250000, "#74c476",
      1000000, "#238b45",
      5000000, "#00441b",
    ],
    "fill-opacity": 0.75,
    "fill-outline-color": "#333",
  },
});
```

Stops above follow a **ColorBrewer-style** sequential green ramp; swap hex values from [colorbrewer2.org](https://colorbrewer2.org/) for your class count.

### Example: diverging change (color-blind safe)

Use a **diverging** palette centered on zero or a policy threshold — e.g. `BrBG` or `RdBu` from ColorBrewer, not pure red vs green:

```js
"fill-color": [
  "interpolate",
  ["linear"],
  num("pct_change"),
  -20, "#543005",
  -5, "#bf812d",
  0, "#f6e8c3",
  5, "#80cdc1",
  20, "#003c30",
],
```

### Example: qualitative categories

Use distinct hues with **similar lightness**; assign the strongest saturation to categories you want to emphasize:

```js
"fill-color": [
  "match",
  ["get", "land_use"],
  "residential", "#8da0cb",
  "commercial", "#fc8d62",
  "industrial", "#66c2a5",
  "park", "#e78ac3",
  "#cccccc",
],
```

For many categories (>8–10), consider **binned** symbology, pattern fills, or filtering by zoom instead of one hue per class.

### Further reading

- [MapLibre Style Spec — expressions](https://maplibre.org/maplibre-style-spec/expressions/)
- [ColorBrewer 2.0](https://colorbrewer2.org/) — cartographic palettes (export as JS/CSS)
- [UCGIS BoK: Color Theory (CV-03-009)](https://gistbok-ltb.ucgis.org/current/concept/CV-03-009) — sequential / diverging / qualitative schemes
- [awesome-vector-tiles](https://github.com/mapbox/awesome-vector-tiles) — clients, **Maputnik**, inspectors, tippecanoe, server ecosystem

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
