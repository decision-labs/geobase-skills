---
name: geobase-titiler
description: "Raster COG tiles via /titiler/v1: satellite, DEM, multispectral, colormap, rescale, MapLibre raster overlay. Triggers on COG, GeoTIFF, raster tiles, Titiler, remote sensing imagery on map."
metadata:
  author: geobase
  version: "0.3.0"
---

# Titiler: Raster COG Tiles

## When to use this skill

- Display **Cloud Optimized GeoTIFF** (COG) raster on a map
- Satellite, DEM, multispectral imagery via `/titiler/v1`
- MapLibre `raster` source (not vector MVT)
- **Not** for PostGIS geometry tables — use `@geobase-tileserver`

Geobase hosts [Titiler](https://developmentseed.org/titiler/) **2.x** (currently `2.0.4` on staging) at `{origin}/titiler/v1` for dynamic COG tiles (satellite imagery, DEMs, multispectral rasters).

See `@geobase` → **Private beta (CLI not shipped)** for project URL and anon key during beta.

## Required Inputs

- `GEOBASE_PROJECT_URL` or `NEXT_PUBLIC_GEOBASE_API_URL` — project base URL (e.g. `https://<ref>.geobase.app`)
- `GEOBASE_ANON_KEY` or `NEXT_PUBLIC_GEOBASE_ANON_KEY` — project anon key
- `COG_URL` — HTTPS URL to a Cloud Optimized GeoTIFF the Titiler service can read (public S3/HTTP, or a URL your project policy allows)

Obtain URL and key from Geobase Studio → **Tile Server** → **Titiler**, or (when shipped):

```bash
geobase-cli projects env <project-ref> --persona web --format dotenv
```

## Base URL

```
{TITILER_BASE} = {API_URL}/titiler/v1
```

Example: `https://<ref>.geobase.app/titiler/v1`

## Auth

Pass the project anon key as query param `apikey` on every request (matches Studio Titiler UI):

```
?apikey={ANON_KEY}
```

For private COGs or stricter policies, prefer server-side proxying so secrets and signed URLs never ship to the browser. Do not commit COG credentials into skill files or repos.

## Core Endpoints

### COG metadata

```bash
# ENCODED_COG_URL = percent-encoded COG_URL
curl "${API_URL}/titiler/v1/cog/info?url=${ENCODED_COG_URL}&apikey=${ANON_KEY}"
```

Returns band metadata and `bounds` in the COG's **native CRS** (not always WGS84). Prefer `tilejson.json` below for MapLibre map framing.

### Extent (for map `bounds`)

**TiTiler 2.x removed `/cog/bounds`.** Use TileJSON for WGS84 bounds MapLibre expects:

```bash
curl "${API_URL}/titiler/v1/cog/WebMercatorQuad/tilejson.json?url=${ENCODED_COG_URL}&apikey=${ANON_KEY}"
```

Returns JSON with `bounds` `[west, south, east, north]` in WGS84, plus `minzoom`, `maxzoom`, and a `tiles` URL template.

### Band statistics (styling hints)

```bash
curl "${API_URL}/titiler/v1/cog/statistics?url=${ENCODED_COG_URL}&apikey=${ANON_KEY}"
```

Use the response to pick `rescale` min/max before tiling.

### Map tiles (Web Mercator)

```
{API_URL}/titiler/v1/cog/tiles/WebMercatorQuad/{z}/{x}/{y}?url={ENCODED_COG_URL}&apikey={ANON_KEY}
```

Always **URL-encode** the `url` query value in application code (`encodeURIComponent` in JS).

## Optional Query Parameters

Append when transforming the raster (Studio URL builder supports the same names):

| Parameter | Purpose | Example |
| --------- | ------- | ------- |
| `bidx` | Band index (repeat param for multiple bands) | `bidx=1` or `bidx=1&bidx=2` |
| `rescale` | Stretch values to display range | `rescale=0,3000` |
| `colormap_name` | Named colormap | `colormap_name=viridis` |
| `expression` | Band math | `expression=(b2-b1)/(b2+b1)` |
| `color_formula` | GDAL color formula | `color_formula=gamma%20b%201.85` |
| `histogram_range` | Histogram stretch range | `histogram_range=0,255` |
| `reproject` | Reproject tiles | per Titiler docs |
| `algorithm` / `algorithm_params` | Raster algorithms | per Titiler docs |
| `buffer` / `nodata` | Edge / nodata handling | per Titiler docs |

Comma-separated `bidx` in UI (e.g. `1,2,3`) becomes multiple `bidx=` query params.

## MapLibre GL JS (raster overlay)

1. Fetch **tilejson** and initialize the map to the COG extent (WGS84 bounds).
2. Add a **raster** source (not vector) pointing at the tile template.

```js
const API_URL = "https://<ref>.geobase.app";
const ANON_KEY = "<anon_key>";
const cogUrl = "https://example.com/path/to/file.tif";
const encoded = encodeURIComponent(cogUrl);

const tilejsonRes = await fetch(
  `${API_URL}/titiler/v1/cog/WebMercatorQuad/tilejson.json?url=${encoded}&apikey=${ANON_KEY}`
);
const tilejson = await tilejsonRes.json();
const { bounds, minzoom, maxzoom } = tilejson;

const map = new maplibregl.Map({
  container: "map",
  bounds: [[bounds[0], bounds[1]], [bounds[2], bounds[3]]],
  style: "https://tiles.basemaps.cartocdn.com/gl/voyager-gl-style/style.json",
});

map.on("load", () => {
  const tileUrl =
    `${API_URL}/titiler/v1/cog/tiles/WebMercatorQuad/{z}/{x}/{y}` +
    `?url=${encoded}&apikey=${ANON_KEY}&rescale=0,3000&colormap_name=viridis`;

  map.addSource("cog", {
    type: "raster",
    tiles: [tileUrl],
    tileSize: 256,
  });

  map.addLayer({
    id: "cog",
    type: "raster",
    source: "cog",
    minzoom: minzoom ?? 0,
    maxzoom: maxzoom ?? 22,
  });
});
```

Stack vector layers from `@geobase-tileserver` above or below the raster layer as needed.

## Studio and Public Docs

- **Studio:** project → **Tile Server** → **Titiler** (URL builder + live preview).
- **Remote sensing guide:** [Getting started with remote sensing](https://docs.geobase.app/guides/remote-sensing/getting-started)
- **Service reference:** [Titiler (raster COG)](https://docs.geobase.app/reference/titiler)
- **Project services hub:** [project-services#titiler-raster-cog](https://docs.geobase.app/reference/project-services#titiler-raster-cog)

## Known Gotchas

### 1. Unencoded `url` breaks tile requests

The COG URL must be percent-encoded in query strings. A raw `https://...` in the middle of the query string often fails or truncates.

### 2. Titiler must reach the COG

Geobase Titiler fetches the COG from the URL you pass. If the asset is private S3 without a reachable signed URL, tiles fail even with a valid `apikey`. Confirm with `cog/info` or `cog/WebMercatorQuad/tilejson.json` first.

### 3. `/cog/bounds` removed in TiTiler 2.x

Do **not** call `/cog/bounds` — it returns 404 on Geobase stacks pinned to Titiler 2.0.4+. Use `tilejson.json` for WGS84 map bounds. `/cog/info` still works but its `bounds` are in the COG native CRS.

### 4. Wrong service for table geometry

Tables with geometry columns use **vector** tileserver (`/tileserver/v1/...pbf`), not Titiler. Use this skill only for external or hosted **raster** COGs.

### 5. `rescale` / bands mismatch

Multiband COGs need correct `bidx` and `rescale` ranges; use `cog/statistics` before guessing display limits.

### 6. Vector vs raster in MapLibre

Titiler layers use `type: "raster"`. Tileserver layers use `type: "vector"` and require `source-layer` — see `@geobase-tileserver`.

## Failure Handling

- **Blank map / 404 on bounds** — you may be calling removed `/cog/bounds`; switch to `cog/WebMercatorQuad/tilejson.json`.
- **Blank map / 4xx on tilejson** — verify `COG_URL`, encoding, and that Titiler can HTTP-read the file.
- **Tiles 200 but empty or wrong colors** — adjust `rescale`, `bidx`, `colormap_name`, or `expression`; inspect `cog/statistics`.
- **Auth errors** — confirm `apikey` matches project anon key from Studio settings.
- After 2–3 failed attempts, stop looping; have the user validate the COG in Studio Titiler preview or curl `cog/info`.

## Related Skills

- `@geobase` — beta env setup, secrets, project scope
- `@geobase-tileserver` — vector MVT tiles from PostGIS tables
