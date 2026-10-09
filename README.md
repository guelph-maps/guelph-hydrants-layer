# Guelph Hydrants Layer

Turns the City of Guelph [Hydrants](https://gismaps.guelph.ca/hosting/rest/services/OpenData/OpenData2/FeatureServer/3)
layer (3,537 municipal fire hydrants on 2026-10-09) into map-tile layers that
OpenStreetMap mappers can add to the **JOSM** and **iD** editors as a reference
overlay, plus a gap page listing where OSM's hydrants disagree with the City's.

**Live layer and how to add it: https://guelph-maps.github.io/guelph-hydrants-layer/**

Part of the [guelph-maps](https://github.com/guelph-maps) organisation. It is a
clone of [guelph-bus-stops-layer](https://github.com/guelph-maps/guelph-bus-stops-layer)
([live](https://guelph-maps.github.io/guelph-bus-stops-layer/)): the same
`download -> slim -> compare -> vector -> raster -> site -> publish` pipeline,
the same ArcGIS server, the same Overpass, link-gate and publish rules. What
differs follows from the hydrant:

- **download** pages through the layer -- the service caps a reply at 1,000
  rows -- and refuses an extract that does not add up to the service's count;
- **compare** matches by distance alone: a hydrant carries no number a mapper
  can read, so there is no `ref` to key on;
- **raster** draws plain red dots, no labels.

It was built because the
[import audit's recalibration](https://github.com/guelph-maps/guelph-osm-import-audit)
put hydrants first among the layers still unbuilt: the gap is large (OSM had
150 of the City's ~3,500 on 2026-10-09), the City's positions are proven (the
OSM hydrants placed by survey sit a median 1.4 m from them), and it is being
worked right now (44 hydrants added in 2026-07).

## What it produces

- **Vector tiles** (MVT, z12-19) &mdash; interactive in iD; click a hydrant to
  read its `hydrant_id`, `location_id`, `model` and `objectid`.
- **Raster tiles** (PNG, z15-17) &mdash; a small red dot per hydrant, white
  edged, 4 px in radius at z17. Below z15 a city's worth of hydrants is a red
  haze, not a reference.
- A **landing page** with copy-paste "add this layer" instructions for both
  editors.
- A **gap-review page** (`/gaps/`) on an interactive map and a filterable
  table, and its **history page** (`/gaps/history.html`) charting the counts,
  one point per weekly run.

## No ref, on purpose

The City's `HYDRANTID` and `LOCATIONID` are asset numbers. Nothing on the
hydrant carries them, so a mapper standing at one cannot check either, and
neither belongs in OSM's `ref`. They are in the vector tiles and on the gap
page so a row can be named, and the landing page says not to copy them. What a
mapper adds is what they can see: `emergency=fire_hydrant`,
`fire_hydrant:type`, `colour`, `fire_hydrant:position`.

## The gap page

Overpass is asked for every `emergency=fire_hydrant` in the Guelph bounding box
(`nwr`, `out center`). City and OSM hydrants are then paired by distance:
every pair within `FAR_M` (30 m) is a candidate, and the closest pair is
settled first, one to one. Then, per City hydrant:

| Status | Meaning | What to do |
|---|---|---|
| `missing` | no OSM hydrant within 30 m | add it, once you have seen it |
| `far` | its OSM hydrant is 10-30 m away | check which point is right |
| `duplicate` | a second OSM hydrant within 30 m, after a nearer one took this City hydrant | one of the two is probably surplus |
| `notype` | matched within 10 m, no `fire_hydrant:type` | add it |
| `nocolour` | matched within 10 m, no `colour` | add it |
| `noposition` | matched within 10 m, no `fire_hydrant:position` | add it |
| `osm_only` | an OSM hydrant more than 30 m from every City hydrant | probably private -- a look, not a fix |

How the statuses fit together:

- **Every OSM hydrant lands somewhere.** It is matched (within 10 m), `far`,
  a `duplicate`, or `osm_only`. On the first run, one node 11 m from a City
  hydrant a closer node had already taken would have fallen between a "within
  10 m" duplicate and a "beyond 30 m" `osm_only`; 30 m is the line for both.
- **The tag statuses share a row.** A matched hydrant lacking its type and
  its position is one row, with status `notype` (the first missing, in the
  order above) and both in its `lacks`. Each is counted on its own, so the
  header's `notype`/`nocolour`/`noposition` add up to more than the rows. A
  `far` hydrant's tags are not checked: which hydrant it is comes first.
- **`duplicate` wins the row.** A City hydrant with a second OSM hydrant beside
  it is shown as `duplicate`, whatever else applies; its missing tags are still
  counted.
- **`osm_only` is not blame.** The City layer is municipal hydrants. Of the
  four unmatched OSM hydrants on the first run, three were 58, 91 and 153 m
  from any City hydrant -- a campus, a plaza, an industrial yard.

Distances are equirectangular metres on a 0.0005&deg; grid, no GIS dependency.

The Overpass handling is the parks layer's unchanged: every mirror in
`OVERPASS_URLS` is tried `OVERPASS_ROUNDS` times, a reply under
`OSM_MIN_ELEMENTS` (75, half the first live reply) elements or older than
`OSM_MAX_AGE_DAYS` is refused, the page prints the OSM timestamp the mirror
declares, and a run that fell back to cached OSM says so on the page and exits
70 after publishing. The age check is not theoretical here:
overpass.private.coffee answered this very query on 2026-10-09 with HTTP 200, a
full reply, and OSM as of 2026-05-31.

### What a first run looks like

The first live comparison, on 2026-10-09 against OSM as of 21:58Z (150 OSM
hydrants, 3,537 City hydrants):

| missing | far | duplicate | notype | nocolour | noposition | osm_only | matched |
|--:|--:|--:|--:|--:|--:|--:|--:|
| 3,391 | 6 | 1 | 16 | 14 | 83 | 3 | 140 |

140 OSM hydrants sit within 10 m of a City one, 6 more within 30 m, 1 beside
a City hydrant another node already took, and 3 nowhere near one. The tag
counts are over the 140 matched; the recalibration's 17 / 15 / 88 were over
all 150 OSM hydrants.

The count is every hydrant in the City's layer. The recalibration that
proposed this layer clipped to the City boundary first (3,524 hydrants, 3,384
missing at 10 m); 13 of the City's hydrants sit just outside it, and this
layer keeps them.

## Setup

1. Install Python dependencies:
   ```
   pip install -r requirements.txt
   ```
2. Set up WSL2 + tippecanoe once &mdash; see [wsl-setup.md](wsl-setup.md).
3. Create the `gh-pages` source once: in the GitHub repo, set
   **Settings &rarr; Pages &rarr; Source** to the `gh-pages` branch (root).

## Usage

```
python run.py download   # fetch the latest Hydrants GeoJSON (smart-cached)
python run.py slim       # normalise to a slim GeoJSONL
python run.py compare    # diff City hydrants against OSM -> data/gaps.geojson
python run.py backfill   # one-off: reconstruct past weeks' gap counts from OSM history
python run.py vector     # build vector (MVT) tiles via WSL tippecanoe
python run.py raster     # build raster (PNG) tiles
python run.py site       # render the landing page (+ the gap-review page)
python run.py publish    # force-push the site to the gh-pages branch

python run.py build      # download + slim + compare + vector + raster + site
python run.py update     # build + publish  (the scheduled entry point)
```

Build output lands in `build/site/`; that directory is what gets published to
an orphan `gh-pages` branch, recreated on every build so history never grows.

## Tile endpoints

```
https://guelph-maps.github.io/guelph-hydrants-layer/tiles/vector/{z}/{x}/{y}.pbf   (z12-19)
https://guelph-maps.github.io/guelph-hydrants-layer/tiles/raster/{z}/{x}/{y}.png   (z15-17)
```

The vector layer name is `hydrants`. tippecanoe runs with `-r1`, so no hydrant
is thinned out of the low zooms.

## Scheduling (Windows)

Run as Administrator:

```powershell
.\schedule-add.ps1      # registers a weekly task "kk-GuelphHydrantsLayer", Fridays 16:30
.\schedule-remove.ps1   # unregisters it
```

Friday keeps it clear of toronto-parks-layer's Monday, guelph-parks-layer's
Tuesday, guelph-buildings-layer's Wednesday and guelph-bus-stops-layer's
Thursday, so no two of them drive tippecanoe in the same WSL instance at once.
Exit codes and the restart policy are the parks layer's: **75** when there is
no usable link (nothing was fetched or published), **70** after publishing when
the gap page had to fall back to cached OSM.

## Tests

```
python tests\test_tilemath.py
python tests\test_slim.py
python tests\test_raster.py
pytest                       # the above, plus the download / compare / history / publish tests
```

## Licence / attribution

Hydrant data is &copy; City of Guelph, published under the
[Open Government Licence &ndash; City of Guelph](https://gismaps.guelph.ca/Images/OpenDataLicenceVersion2.pdf).
The OSMF Licence Working Group approved that licence as `compatible` on
2024-09-09.

**This project redistributes City data** as published tiles on a public URL,
and the licence attaches a required attribution to that. The landing page, the
gap page and the history page all carry, visibly:

> Contains information licensed under the Open Government Licence – City of Guelph.

linked to the licence text. The same attribution is embedded in the vector tile
metadata. This is a condition of use, not a courtesy: if you fork this, the
notice travels with it.

Hydrant imports are contested in OSM, and this is not one: the layer puts the
City's points in front of a mapper, who adds what they have seen.
