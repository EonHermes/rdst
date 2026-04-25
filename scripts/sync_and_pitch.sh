#!/bin/bash
set -euo pipefail

cd /home/dl/rdst

# Log file for debugging
LOG_FILE="/home/dl/rdst/logs/cron_sync_pitch_$(date +%Y%m%d_%H%M%S).log"
mkdir -p /home/dl/rdst/logs
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Starting rdst upstream sync and pitch deck update at $(date) ==="

# 1. Sync upstream
echo "Fetching upstream..."
git fetch upstream

echo "Checking if we can fast-forward..."
if git merge-base --is-ancestor upstream/main main; then
    echo "Already up to date with upstream/main"
else
    echo "Merging upstream/main into main..."
    git merge upstream/main -m "Merge upstream/main" || {
        echo "Merge conflict detected. Attempting to resolve..."
        # If there are conflicts, we try to resolve them by favoring upstream changes for non-pitch files?
        # For simplicity, we abort and let the user know.
        echo "Merge conflict. Please resolve manually."
        exit 1
    }
    echo "Push to origin/main..."
    git push origin main
fi

# 2. Work on pitch deck
# We'll look for existing pitch deck files and update them based on the design docs.
PITCH_DECK_DIR="/home/dl/rdst/pitch_deck"
mkdir -p "$PITCH_DECK_DIR"
PITCH_DECK_FILE="$PITCH_DECK_DIR/pitch_deck.md"

# Check if there's a design doc or plan that we can use to update the pitch.
# We'll concatenate the key plan files and generate a simple pitch if none exists.
if [ ! -f "$PITCH_DECK_FILE" ]; then
    echo "Creating initial pitch deck from design docs..."
    cat > "$PITCH_DECK_FILE" << 'EOF'
# RDST Pitch Deck

## Hook
What if Ethiopia holds back more Blue Nile water for power generation? Watch the cascade from GERD to the Egyptian Delta — in real units, validated against satellite-observed crop NDVI.

## Problem
Water-policy tradeoffs in the Nile basin are complex and opaque. Stakeholders need a transparent, real-time simulator to explore the cascading effects of reservoir releases, irrigation changes, and environmental-flow constraints on drinking water, food production, and hydropower.

## Solution
RDST (Nile Digital Twin) is a policy what-if sandbox that combines:
- A Rust simulation core (Nile River Systems Model) for mass-balance hydraulics
- A YAML scenario contract for reproducible experiments
- A React dashboard for exploring flows, storage, losses, and key KPIs (drinking water, food, energy)
- Satellite data integration (ERA5, Sentinel-2 NDVI) for validation

## Architecture
Four layers with hard interfaces:
1. Dataloader (Python) → fetches ERA5, Sentinel-2, reservoir metadata
2. Canonical Store (data/) → GeoJSON, YAML config, Parquet timeseries
3. Sim Engine (Rust) → directed acyclic river graph, daily timestep, monthly aggregation
4. Dashboard (React/Vite) → MapLibre GL map, policy sliders, KPI charts, compare view

## Demo Flow
1. User adjusts GERD release schedule via slider
2. Simulator recomputes daily balances for 2005–2024 (240 monthly steps)
3. Dashboard updates:
   - Map: node colors (served fraction) and edge widths (flow)
   - Charts: drinking water reliability, food production (tonnes/yr), hydropower (GWh/yr)
   - Compare view: side-by-side scenarios with diff chips

## Tech Stack
- **Backend:** Rust (Axum, Tokio) for simulation core
- **Data:** Parquet timeseries, YAML scenario contracts, GeoJSON for topology
- **Frontend:** React + Vite + MapLibre GL + Plotly.js
- **Dev:** GitHub Actions, Docker, Cargo, npm

## Team Fit
- Strong Rust systems programming background
- Experience with geospatial data and satellite imagery
- Full-stack development (Rust backend, React frontend)
- Familiar with water resources modeling and policy analysis

## Next Steps
- Integrate CLI JSON output directly into the visualizer (replace fixture data)
- Add policy sliders for reservoir release schedules, irrigation area, environmental flow
- Implement scenario save/load and comparison scoring
- Stretch: Pareto optimizer over policy space
- Stretch: NDVI-modulated food KPI to close the space-data loop

## Current Status
MVP-scale prototype with:
- Serializable Rust scenario model, validation, CLI runner
- 30-day aggregation and result summaries
- Polished React local visualizer using typed demo data (to be replaced with live simulator output)

EOF
else
    echo "Pitch deck already exists. Appending any new insights from design docs..."
    # We could update the pitch deck with new content, but for simplicity we just note that it exists.
    echo "Pitch deck found at $PITCH_DECK_FILE. No automatic update performed."
fi

# 3. Commit and push any changes to the pitch deck (if we created or updated it)
if [ -d "$PITCH_DECK_DIR" ] && [ -n "$(git ls-files --others --exclude-standard "$PITCH_DECK_DIR")" ] || git diff --quiet "$PITCH_DECK_FILE"; then
    echo "No changes to pitch deck."
else
    echo "Committing pitch deck changes..."
    git add "$PITCH_DECK_FILE"
    git commit -m "chore: update pitch deck from design docs" || echo "Commit failed (maybe no changes?)"
    git push origin main
fi

echo "=== Finished at $(date) ==="