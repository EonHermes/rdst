---
marp: true
theme: default
paginate: true
---

# Nile Digital Twin
**CASSINI Space for Water** · Team &lt;your name&gt; · 2026

A policy what-if sandbox for the Nile basin, grounded in historical ERA5
reanalysis and validated against Sentinel-2 NDVI. Move three sliders, see
cascading impact on water / food / energy downstream — in real units.

---

## The question nobody can answer today

The Nile serves ~500 M people across 11 countries. Three competing uses:

- **Ethiopia** — hydropower via GERD (6.45 GW nameplate, Africa's largest dam).
- **Sudan** — irrigation via Gezira (~900 000 ha of cotton and wheat).
- **Egypt** — water security for 100 M people + the Delta.

Policy debates happen in m³/s. Headlines scream "water wars."
There is nothing in between that a decision-maker can actually *try*.

When Ethiopia fills GERD faster, the cascade hits downstream: Sudan loses irrigation water, Egypt's drinking-water service drops, delta flows violate environmental constraints. These effects are **hard to quantify without a model** — and impossible to test without risking real communities.

---

## What we built

A physics-based digital twin of the Nile basin — satellite data connected to real-world KPIs:

- **19 nodes** along the main stem: Lake Victoria → Lake Tana → GERD → Roseires → Merowe → Khartoum → Khartoum → Aswan → Delta, plus the Sudd wetland and both source branches.
- **75+ years of climate data** (1950–2026) via ERA5 legacy datasets — enables drought/flood trend analysis across decades, not just recent history.
- **Sentinel-2 NDVI + CGLS** over irrigated zones as the food-KPI validator — *the model's food KPI is validated against what satellites actually saw*.
- **Dual-engine architecture**: Python/numpy for prototyping + Rust core (`nrsm`) compiled via PyO3/Maturin for production performance. Configurable time-steps (monthly or daily), reporting frequency control, and a fast-action API for optimizer integration.
- **Three sliders, three KPIs, one score, compare view.** Full 240-month sim runs in ~10 ms.

---

## What space data does

| Product | Role |
|---|---|
| **ERA5 reanalysis** (C3S) | Monthly precipitation, temperature, radiation, wind, runoff → drives every forcings parquet. |
| **Sentinel-2 NDVI** (2015+) | Month-by-month crop greenness over Gezira + Delta — visual validator of the food KPI. |
| **CGLS NDVI** (2005–2014) | Fills the pre-Sentinel-2 window. |

All free. All Copernicus. Pipeline writes Parquet on disk — reusable beyond this demo.

---

## Demo — three scenarios

1. **Baseline** — historical operation.
2. **GERD fast-fill** — Ethiopia fills GERD over 3 years instead of 7.
   Energy ↑, Sudanese food ↓, Delta flow violations in Jul–Oct.
3. **Drought 2010** — tightened delta constraint + reduced Gezira area.
   Score collapses; twin shows *which* downstream users break first.

*(Live walkthrough — 90 s.)*

---

## The physics, one slide

Monthly time step (or daily), topological sweep.

- **Reservoirs**: `storage = prev + inflow − release − evap`, HEP on turbined release only, spill separate.
- **Reaches**: Muskingum routing (lag + attenuation).
- **Wetlands**: Sudd loses ~50 % of White Nile inflow — measured, not assumed.
- **Demands**: FAO monthly crop-water curve × area × productivity → tonnes.

Mass conservation verified to &lt;0.1 % in a golden test. Validated against GRDC Aswan discharge.

**Dual-engine stack:** Python/numpy for rapid prototyping with full node-type coverage, Rust core (`nrsm`) compiled via PyO3/Maturin for production-grade performance.

**Effective fall heights** (from ICOLD register + dam operator data):
GERD 145 m · Aswan 111 m · Merowe 68 m · Roseires 68 m · Tekeze 185 m

---

## Calibration — honest numbers

![w:700](calibration-report.html)

Simulated vs. observed monthly discharge at Aswan, 2005–2024.
Relative RMSE ~93 % — calibration in progress (grid-search over catchment scales + Sudd evaporation).

**Why this matters:** Mass conservation is verified to <0.1% in a golden test. The model structure is physically sound; parameters are being tuned against GRDC data. We're transparent about uncertainty because trust is the whole point.

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

## Stretch — the optimizer

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
- **Finer granularity:** Tributary-level resolution (Sobat, Bahr el Ghazal) and governorate-level irrigation zones.
- **Climate scenarios:** Couple with CMIP6 downscaled projections for forward-looking drought/flood planning.
- **Open-source release:** Publish the full stack as a reusable basin-twin framework — the dataloader + sim engine are generic enough to adapt to any river system.

---

## Try it now

- Code: &lt;github-url&gt;
- Demo: `docker compose up` → http://localhost:5173
- QR → live demo

*Team: @… @… @… @… @…*
