---
name: geobase-titiler
description: "Use when serving Cloud Optimized GeoTIFF (COG) raster tiles, metadata, and MapLibre raster overlays via Geobase Titiler."
metadata:
  author: geobase
  version: "0.1.0"
---

# Titiler: Raster COG Tiles

Geobase hosts [Titiler](https://developmentseed.org/titiler/) at `{origin}/titiler/v1` for dynamic COG tiles (satellite imagery, DEMs, multispectral rasters). Use **`@geobase-tileserver`** for PostGIS vector MVT tiles — not Titiler.

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

### Extent (for map `bounds`)

```bash
curl "${API_URL}/titiler/v1/cog/bounds?url=${ENCODED_COG_URL}&apikey=${ANON_KEY}"
```

Returns JSON with `bounds` `[west, south, east, north]` in WGS84.

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

1. Fetch bounds and initialize the map to the COG extent.
2. Add a **raster** source (not vector) pointing at the tile template.

```js
const API_URL = "https://<ref>.geobase.app";
const ANON_KEY = "<anon_key>";
const cogUrl = "https://example.com/path/to/file.tif";
const encoded = encodeURIComponent(cogUrl);

const boundsRes = await fetch(
  `${API_URL}/titiler/v1/cog/bounds?url=${encoded}&apikey=${ANON_KEY}`
);
const { bounds } = await boundsRes.json();

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
    minzoom: 0,
    maxzoom: 22,
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

Geobase Titiler fetches the COG from the URL you pass. If the asset is private S3 without a reachable signed URL, tiles fail even with a valid `apikey`. Confirm with `cog/info` or `cog/bounds` first.

### 3. Wrong service for table geometry

Tables with geometry columns use **vector** tileserver (`/tileserver/v1/...pbf`), not Titiler. Use this skill only for external or hosted **raster** COGs.

### 4. `rescale` / bands mismatch

Multiband COGs need correct `bidx` and `rescale` ranges; use `cog/statistics` before guessing display limits.

### 5. Vector vs raster in MapLibre

Titiler layers use `type: "raster"`. Tileserver layers use `type: "vector"` and require `source-layer` — see `@geobase-tileserver`.

## Failure Handling

- **Blank map / 4xx on bounds** — verify `COG_URL`, encoding, and that Titiler can HTTP-read the file.
- **Tiles 200 but empty or wrong colors** — adjust `rescale`, `bidx`, `colormap_name`, or `expression`; inspect `cog/statistics`.
- **Auth errors** — confirm `apikey` matches project anon key from Studio settings.
- After 2–3 failed attempts, stop looping; have the user validate the COG in Studio Titiler preview or curl `cog/info`.

## Related Skills

- `@geobase` — beta env setup, secrets, project scope
- `@geobase-tileserver` — vector MVT tiles from PostGIS tables
