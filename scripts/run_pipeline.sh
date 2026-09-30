#!/usr/bin/env bash
# Runs the whole pipeline once: ingestion, then dbt build (models + tests).
set -euo pipefail

echo "==> Step 1/2: ingesting exchange rates"
python -m ingestion.fetch_rates

echo "==> Step 2/2: dbt build (target: ${DBT_TARGET:-dev})"
cd dbt_project
dbt build --profiles-dir . --target "${DBT_TARGET:-dev}"

echo "==> Pipeline finished successfully"
