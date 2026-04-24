# RDST Pitch Deck

## Hook
What if Ethiopia holds back more Blue Nile water for power generation? Watch the cascade from GERD to the Egyptian Delta — in real units, validated against satellite-observed crop NDVI.

## Problem
The Nile serves **~500 million people across 11 countries**, but policy debates happen in m³/s while public discourse happens in headlines. Three competing tensions:
1. **Ethiopia** needs hydropower (GERD — 6,450 MW nameplate)
2. **Sudan** depends on reliable irrigation (Gezira scheme — 900,000 ha)
3. **Egypt** requires water security (Aswan + Delta for 20M+ people)

Decision-makers need a transparent sandbox to explore cascading effects of reservoir releases, irrigation changes, and environmental-flow constraints on drinking-water reliability (% served), food production (tonnes/yr), and hydropower output (GWh/yr) — **before** they commit to irreversible policy.

## Solution
RDST (Nile Digital Twin) is a policy what-if sandbox that combines:
- A **mass-balance river simulator** with 18 curated nodes along the main stem, both source branches (Blue & White Nile), the Sudd wetland, major dams (GERD, Roseires, Merowe, Aswan/Nasser), and confluence at Khartoum
- A **YAML scenario contract** for reproducible experiments — policy levers are sliders: reservoir release schedules, irrigation area scale factors, minimum delta-flow targets
- A **map-first React dashboard** with animated month scrubber, NDVI satellite overlay, side-by-side compare view, and weighted scoring
- **Satellite-grounded validation**: ERA5 climate reanalysis (2005–2024) drives forcings; Sentinel-2 NDVI validates food KPIs against actual crop health over Gezira and the Delta

## Architecture
Four layers with hard interfaces so lanes work in parallel:

1. **Dataloader** (Python/typer) → fetches ERA5 via CDS API, Sentinel-2 via Copernicus STAC; writes Parquet timeseries + GeoJSON topology + YAML config
2. **Canonical Store** (`data/`) → `nodes.geojson` (geometry), `node_config.yaml` (params per node), `timeseries/*.parquet` (monthly forcings), `overlays/ndvi/*.parquet` (satellite observations)
3. **Sim Engine** (Python/numpy/pandas) → directed acyclic river graph with 8 node types (source, reservoir, reach, confluence, wetland, demand_municipal, demand_irrigation, sink); topological sweep computes mass balance in ~10 ms per full run
4. **Dashboard** (React/Vite/MapLibre GL) → map-first layout: left-rail policy sliders, center animated map with node sizing by storage/flow, right-rail KPI sparklines + score breakdown, bottom scenario tray

## Technical Differentiators
- **Physics-grounded**: Penman–Monteith reservoir evaporation, Muskingum reach routing (lag + attenuation), FAO AquaStat crop-water-productivity coefficients — not black-box heuristics
- **Calibrated against reality**: Simulated Aswan discharge validated against GRDC observed monthly discharge; target <20% relative RMSE via grid search over source catchment scaling and Sudd evaporation fraction
- **Space-data closed loop**: Sentinel-2 NDVI modulates the crop-water-productivity coefficient, closing the satellite-to-KPI validation chain (stretch goal)
- **Hard data contracts**: The dataloader's Parquet output is the immutable contract between L1 and everything downstream — schema-correct stubs unblock all lanes in <30 seconds

## Demo Flow
Three canned scenarios walk through the full story:

1. **Baseline** (historical policy) → Score ~72. Map shows 240 months of flows; KPI sparklines for water/food/energy animate with the month scrubber.
2. **GERD Fast-Fill** (aggressive filling 2020–2023, release pinned to 500 m³/s) → Energy spikes upstream but downstream food drops ~2.3 Mt/month, Egypt water service down ~4%, delta-flow violations appear in summer months.
3. **Drought 2010** (tightened constraints + reduced irrigation demand) → Score collapses; the twin shows *which* downstream users break first — Gezira before Cairo.

Compare view: side-by-side maps with KPI diff chips (`Food −2.3 Mt`, `Energy +6 TWh`).

## Tech Stack
- **Sim Engine:** Python 3.11, numpy, pandas, pydantic (mass-balance physics)
- **Dataloader:** Python, cdsapi, pystac-client, stackstac, xarray, pyarrow (Copernicus data pipeline)
- **API:** FastAPI + uvicorn (stateless REST, file-backed scenario store)
- **Frontend:** React 18 + Vite + TypeScript + MapLibre GL JS + Plotly.js + Zustand
- **Data formats:** Parquet (timeseries), GeoJSON (topology), YAML (node config), JSON (scenarios)
- **DevOps:** Docker Compose, GitHub Actions, `docker compose up` → working app in <5 min

## Team Fit
- Strong Rust systems programming background (architecture design + CLI tooling)
- Experience with geospatial data and satellite imagery (Sentinel-2, Copernicus STAC)
- Full-stack development (Python backend, React frontend)
- Familiar with water resources modeling and policy analysis (Nile basin hydrology)

## Next Steps
- Complete dataloader: real ERA5 fetch + Sentinel-2 NDVI pipeline (stub mode unblocks all lanes)
- Wire sim engine to live data → replace fixture-based dashboard demo
- Implement scenario save/load, weighted scoring, and compare view in the API
- Calibration against GRDC discharge with documented RMSE
- Stretch: Pareto optimizer over GERD release policy space
- Stretch: NDVI-modulated food KPI to close the satellite-data loop

## Current Status
MVP-scale prototype with:
- Serializable scenario model (pydantic), validation, CLI runner
- 240-month simulation pipeline (stub data end-to-end in <30s)
- Polished React dashboard with map-first layout, policy sliders, KPI charts, compare view
- Three canned demo scenarios ready for pitch rehearsal

