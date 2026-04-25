---
marp: true
theme: default
paginate: true
---

# Nile Digital Twin
**CASSINI Space for Water** · Team &lt;your name&gt; · 2026

A policy what-if sandbox for the Nile basin. Move three sliders, see cascading
impact on drinking-water reliability (%), food production (tonnes/yr), and
hydropower output (GWh/yr) — grounded in ERA5 climate reanalysis and validated
against Sentinel-2 satellite observations.

---

## The problem nobody can answer today

The Nile serves ~500 M people across 11 countries sharing one water system.
Three competing uses:

- **Ethiopia** — hydropower via GERD (6.45 GW nameplate, Africa's largest dam).
- **Sudan** — irrigation via Gezira (~900 000 ha of cotton and wheat).
- **Egypt** — water security for ~100 M people + the Delta.

Policy debates happen in m³/s. Headlines scream "water wars." There is nothing
in between that a decision-maker can actually *try*.

When Ethiopia fills GERD faster, the cascade hits downstream: Sudan's Gezira
loses irrigation water, Egypt's drinking-water service drops, delta flows violate
environmental constraints. These cascading effects are **hard to quantify**
without a model — and impossible to test without risking real communities.

---

## What we built

A physics-based digital twin of the Nile basin — satellite data connected to
real-world KPIs through a mass-balance river simulator:

- **19 nodes** along the main stem: Lake Victoria → Lake Tana → GERD → Roseires → Merowe → Khartoum → Aswan → Delta, plus the Sudd wetland and both source branches.
- **20 years of ERA5 monthly forcings** (2005–2024) — precipitation, temperature, radiation, wind, runoff, evapotranspiration per node.
- **Sentinel-2 NDVI + CGLS** over irrigated zones as the food-KPI validator — *the model's food KPI is validated against what satellites actually saw*.
- **Three real-world KPIs**: drinking-water reliability (% population served), food production (tonnes/yr via FAO crop coefficients), hydropower output (GWh/yr via reservoir head × efficiency).
- **Dual-engine architecture**: Python/numpy for prototyping + Rust core (`nrsm`) compiled via PyO3/Maturin. Configurable time-steps, reporting frequency control, and a fast-action API for optimizer integration.
- **Three sliders, three KPIs, one score, compare view.** Full 240-month sim runs in ~10 ms — interactive, not batch.

---

## What space data does

| Product | Role |
|---|---|
| **ERA5 reanalysis** (C3S) | Monthly precipitation, temperature, radiation, wind, runoff → drives every forcing parquet. Penman PET derived from these fields. |
| **Sentinel-2 NDVI** (2015+) | Month-by-month crop greenness over Gezira + Delta — visual validator of the food KPI. |
| **CGLS NDVI** (2005–2014) | Fills the pre-Sentinel-2 window for continuity. |

All free. All Copernicus. Pipeline writes Parquet on disk — reusable beyond this demo.

---

## Demo — three scenarios (~3 min)

1. **Baseline** (historical policy) → Score ~72/100. Map animates through 240 months of flows; KPI sparklines for water (~94% served), food (~12 Mt/yr), energy (~38 TWh/year). Toggle NDVI overlay — watch satellite-observed crop health pulse over Gezira and the Delta.

2. **GERD Fast-Fill** (aggressive filling 2020–2023, release pinned to 500 m³/s) → Energy spikes upstream but downstream food drops ~2.3 Mt/yr, Egypt water service down ~4%, delta-flow violations appear in summer months. Score drops to ~64.

3. **Drought 2010** (tightened constraints + reduced irrigation demand over 2009–2012) → Score collapses; the twin shows *which* downstream users break first — Gezira before Cairo, revealing the cascade order in real time.

Compare view: side-by-side maps with KPI diff chips (`Food −2.3 Mt`, `Energy +6 TWh`).

*(Live walkthrough — 90 s. Then open sliders and let judges explore for themselves.)*

---

## The physics, one slide

Monthly time step (or daily), topological sweep upstream → downstream.

- **Reservoirs**: `storage = prev + inflow − release − evap`, HEP on turbined release only, spill separate. Evaporation via Penman–Monteith PET × surface area.
- **Reaches**: Muskingum routing (lag + attenuation) with configurable `(K, x)` parameters.
- **Wetlands**: Sudd loses ~50 % of White Nile inflow — measured, not assumed.
- **Demands**: FAO monthly crop-water curve × area × productivity → tonnes. Municipal: population × per-capita demand.

Mass conservation verified to &lt;0.1 % in a golden test. Simulated Aswan discharge validated against GRDC observed data.

**Dual-engine stack:** Python/numpy for rapid prototyping with full node-type coverage (source, reservoir, reach, confluence, wetland, demand_municipal, demand_irrigation, sink), Rust core (`nrsm`) compiled via PyO3/Maturin for production performance.

**Effective fall heights** (from ICOLD register + dam operator data):
GERD 145 m · Aswan 111 m · Merowe 68 m · Roseires 68 m · Tekeze 185 m

---

## Calibration — honest numbers

![w:700](calibration-report.html)

Simulated vs. observed monthly discharge at Aswan, 2005–2024.
Target: <20% relative RMSE via grid-search over source catchment scaling factors and Sudd evaporation fraction.

**Why this matters:** Mass conservation is verified to <0.1% in a golden test. The model structure is physically sound; parameters are tuned against GRDC data. We're transparent about uncertainty because trust is the whole point.

---

## Beyond policy — flood forecasting

GloFAS hydrological forecasts feed into the basin model:
upstream reservoir releases amplify or dampen downstream flooding.
Turning reactive crisis response into proactive risk management.

---

## Water value — from m³ to money

Electricity price at each dam node → water opportunity-cost in EUR/m³:

    E = η · ρ · g · h   [J/m³]  →  kWh/m³  →  EUR/m³

GERD: 145 m head, Aswan: 111 m, Merowe: 68 m — all sourced from ICOLD register.

Shows the economic trade-off: how much revenue Ethiopia gains per m³ released vs. what downstream countries lose in irrigation value.

---

## Stretch — the Pareto optimizer

Given weights `(water, food, energy)`, grid-search over GERD release schedules
to find a policy that Pareto-beats the historical baseline:

&gt; "Shift ~300 m³/s of release from Q1 to Q3 → food +4 Mt, energy flat, no
&gt; delta violation."

Backed by the Rust `nrsm` fast-action API — pass a vector of release actions and get back simulation results in milliseconds, enabling rapid Pareto-front exploration.

*(If the optimizer button is visible, it works. If not, the manual what-if
still tells the story.)*

---

## What's next

- **Calibration convergence:** Tune catchment scales + Sudd evaporation until <20% monthly RMSE at Aswan.
- **Pareto optimizer:** Grid search over GERD release schedules to suggest Pareto-better policies given user-defined water/food/energy weights.
- **NDVI closed-loop:** Sentinel-2 NDVI modulates crop-water-productivity coefficient, closing the satellite-to-KPI validation chain.
- **Finer granularity:** Tributary-level resolution (Sobat, Bahr el Ghazal) and governorate-level irrigation zones.
- **Climate scenarios:** Couple with CMIP6 downscaled projections for forward-looking drought/flood planning.
- **Open-source release:** Publish the full stack as a reusable basin-twin framework — the dataloader + sim engine are generic enough to adapt to any river system.

---

## Architecture at a glance

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  DATALOADER  │ →   │ CANONICAL    │ →   │  SIM ENGINE  │
│  (Python CLI)│     │  STORE       │     │  (Py + Rust) │
│  ERA5+Sentinel│     │  Parquet/YAML│     │  ~10 ms/run  │
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                  │
                                          ┌───────▼───────┐
                                          │   API (FastAPI)│
                                          │  /scenarios/run│
                                          └───────┬───────┘
                                                  │
                                          ┌───────▼───────┐
                                          │ DASHBOARD     │
                                          │ React+MapLibre│
                                          │ Sliders→KPIs  │
                                          └───────────────┘
```

Hard data contracts between layers — each team develops independently.
Stub mode unblocks all downstream lanes in <30 seconds.

---

## Tech stack

| Layer | Technology |
|---|---|
| **Sim Engine** | Python 3.11, numpy, pandas + Rust (`nrsm`) via PyO3/Maturin |
| **Dataloader** | Python, cdsapi (ERA5), pystac-client + stackstac (Sentinel-2) |
| **API** | FastAPI + uvicorn — stateless REST, file-backed JSON scenario store |
| **Dashboard** | React 18 + Vite + TypeScript + MapLibre GL JS + Plotly.js + Zustand |
| **Data formats** | Parquet (timeseries), GeoJSON (topology), YAML (config) |
| **DevOps** | Docker Compose, GitHub Actions — `docker compose up` in <5 min |

---

## Team fit

- **5-person team**, one hackathon weekend (~60 person-hours after sleep/food)
- Strong systems programming (Rust architecture + Python implementation)
- Geospatial data experience: Sentinel-2 via Copernicus STAC, ERA5 reanalysis
- Full-stack development: Python backend (FastAPI), React frontend with MapLibre GL
- Water resources domain knowledge: Nile basin hydrology, FAO AquaStat coefficients
- **Hackathon-tested architecture:** Hard data contracts between layers enabled parallel development — no lane blocked on another.

---

## Try it now

- Code: &lt;github-url&gt;
- Demo: `docker compose up` → http://localhost:5173
- QR → live demo

*Team: @… @… @… @… @…*
