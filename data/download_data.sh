#!/bin/bash
set -e

# =============================================================================
# UNJUST -- Download raw data from GOV.UK
#
# Sources:
#   - Home Office: Police powers and procedures (stop and search open data)
#   - Ethnicity Facts and Figures: Pre-calculated rates (for QA)
#
# Usage: bash data/download_data.sh
# Run from the repo root directory.
# =============================================================================

RAW_DIR="data/raw"
mkdir -p "$RAW_DIR"

echo "=== Downloading UNJUST raw data ==="

# ---------------------------------------------------------------------------
# 1. Stop and search open data tables (confirmed URLs as of April 2026)
#    Source: https://www.gov.uk/government/collections/police-powers-and-procedures-england-and-wales
#
#    The March 2025 file supersedes all earlier ones -- it covers FY 2020/21
#    to 2024/25 (5 years) in a single dataset.
# ---------------------------------------------------------------------------

echo "--- Stop and search: main open data (Mar 2021 to Mar 2025) ---"
curl -L --progress-bar -o "$RAW_DIR/stop-search-open-data-tables-mar21-mar25.ods" \
  "https://assets.publishing.service.gov.uk/media/6909d83d7a88fd270a95fd3e/stop-search-open-data-tables-mar21-mar25.ods"

echo "--- Stop and search: outcomes tables (Mar 2025) ---"
curl -L --progress-bar -o "$RAW_DIR/stop-search-data-tables-outcomes-mar25.ods" \
  "https://assets.publishing.service.gov.uk/media/6909d96b88a98da87e292243/stop-search-data-tables-outcomes-mar25.ods"

echo "--- Stop and search: summary tables (Mar 2025) ---"
curl -L --progress-bar -o "$RAW_DIR/stop-search-data-tables-summary-mar25.ods" \
  "https://assets.publishing.service.gov.uk/media/6909d5489456634d9795fd2f/stop-search-data-tables-summary-mar25.ods"

# ---------------------------------------------------------------------------
# 2. Ethnicity Facts and Figures CSVs (for QA cross-validation)
#    Source: https://www.ethnicity-facts-figures.service.gov.uk/
# ---------------------------------------------------------------------------

echo "--- Ethnicity Facts and Figures: by ethnicity ---"
curl -L --progress-bar -o "$RAW_DIR/ethnicity-stop-search-by-ethnicity.csv" \
  "https://www.ethnicity-facts-figures.service.gov.uk/crime-justice-and-the-law/policing/stop-and-search/latest/downloads/by-ethnicity-table.csv"

echo "--- Ethnicity Facts and Figures: by ethnicity and area ---"
curl -L --progress-bar -o "$RAW_DIR/ethnicity-stop-search-by-area.csv" \
  "https://www.ethnicity-facts-figures.service.gov.uk/crime-justice-and-the-law/policing/stop-and-search/latest/downloads/by-ethnicity-and-area-table.csv"

# ---------------------------------------------------------------------------
# 3. NOTE: Census 2021 data is already committed to the repo
#    (data/raw/population-by-ethnicity-and-region-2021.csv)
#    and does not need to be re-downloaded.
# ---------------------------------------------------------------------------

echo ""
echo "=== Downloads complete ==="
ls -lh "$RAW_DIR"/*.ods "$RAW_DIR"/*.csv 2>/dev/null || true

echo ""
echo "=== Next: run the analysis pipeline ==="
echo "  Rscript analysis/01_load_and_clean.R"
echo "  Rscript analysis/02_eda.R"
echo "  Rscript analysis/03_model_poisson.R"
echo "  Rscript analysis/06_export_for_dashboard.R"
