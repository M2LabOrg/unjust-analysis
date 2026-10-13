# 02 -- Data Acquisition

## Data Sources

### 1. Stop and Search Open Data Tables (Home Office)

**Source:** [Police powers and procedures collection -- GOV.UK](https://www.gov.uk/government/collections/police-powers-and-procedures-england-and-wales)

| Dataset | Coverage | Status |
|---------|----------|--------|
| Open data tables ending March 2023 | FY 2020/21 -- 2022/23 | Already have |
| Open data tables ending March 2024 | FY 2021/22 -- 2023/24 | **NEW -- to download** |
| Open data tables ending March 2025 | FY 2022/23 -- 2024/25 | **NEW -- to download** |

**Format:** ODS (LibreOffice Spreadsheet). Contains multiple tabs with breakdowns by:
- Ethnicity (self-defined and officer-defined)
- Age group
- Sex
- Reason for search
- Outcome
- Police force area
- Legislation type

**Download approach:**
- Direct download from GOV.UK assets
- Script `data/download_data.sh` will use `curl` or `wget` with the exact URLs
- Store originals in `data/raw/`, never modify them

### 2. Ethnicity Facts and Figures (GOV.UK)

**Source:** [Stop and search -- Ethnicity facts and figures](https://www.ethnicity-facts-figures.service.gov.uk/crime-justice-and-the-law/policing/stop-and-search/latest/)

**Downloadable CSVs:**
- `by-ethnicity-table.csv` -- national totals by ethnicity
- `by-ethnicity-and-area-table.csv` -- by ethnicity and region

These provide pre-calculated rates per 1,000 and are useful for QA cross-validation.

### 3. Census 2021 Population Data (ONS)

**Source:** Already have `population-by-ethnicity-and-region-2021.csv` and `TS021-Ethnic-Group-2021-rgn-ONS.xlsx`

**Note:** The 2021 Census is still the latest census. No update needed, but we should standardize which version we use across the pipeline.

### 4. Statistics on Ethnicity and the Criminal Justice System 2024

**Source:** [GOV.UK -- Ethnicity and the Criminal Justice System 2024](https://www.gov.uk/government/statistics/ethnicity-and-the-criminal-justice-system-2024/statistics-on-ethnicity-and-the-criminal-justice-system-2024-html)

This is a valuable secondary source for context and cross-validation. It includes stop-and-search data alongside prosecution, sentencing, and prison data by ethnicity.

### 5. Regional Shapefiles

Already have England & Wales regional boundaries (2022 edition). No update needed.

## Data Dictionary

The key variables we need across all years:

| Variable | Description | Source |
|----------|-------------|--------|
| `year` | Financial year (e.g., 2024/25) | Open data tables |
| `force` | Police force area | Open data tables |
| `region` | England/Wales region | Derived from force mapping |
| `ethnicity_self` | Self-defined ethnicity (5 categories) | Open data tables |
| `ethnicity_officer` | Officer-perceived ethnicity | Open data tables |
| `age_group` | Age band | Open data tables |
| `sex` | Male/Female | Open data tables |
| `reason` | Reason for search (drugs, weapons, etc.) | Open data tables |
| `outcome` | Result of search (arrest, NFA, etc.) | Open data tables |
| `count` | Number of searches | Open data tables |
| `population` | Census population for that group | Census 2021 |
| `rate_per_1000` | Searches per 1,000 population | Calculated |

## Download Script Outline

```bash
#!/bin/bash
# data/download_data.sh
# Downloads raw data from GOV.UK

RAW_DIR="data/raw"
mkdir -p "$RAW_DIR"

# Stop and search open data tables
# March 2024 release
curl -L -o "$RAW_DIR/stop-search-open-data-mar24.ods" \
  "https://assets.publishing.service.gov.uk/media/[exact-id]/stop-search-open-data-tables-mar24.ods"

# March 2025 release
curl -L -o "$RAW_DIR/stop-search-open-data-mar25.ods" \
  "https://assets.publishing.service.gov.uk/media/[exact-id]/stop-search-open-data-tables-mar25.ods"

# Summary tables (for QA)
curl -L -o "$RAW_DIR/stop-search-summary-mar24.ods" \
  "https://assets.publishing.service.gov.uk/media/66f2e4a17da73f17177640ed/stop-search-data-tables-summary-mar24.ods"

# Ethnicity facts and figures CSVs (for QA cross-check)
curl -L -o "$RAW_DIR/ethnicity-stop-search-by-area.csv" \
  "https://www.ethnicity-facts-figures.service.gov.uk/crime-justice-and-the-law/policing/stop-and-search/latest/downloads/by-ethnicity-and-area-table.csv"

curl -L -o "$RAW_DIR/ethnicity-stop-search-by-ethnicity.csv" \
  "https://www.ethnicity-facts-figures.service.gov.uk/crime-justice-and-the-law/policing/stop-and-search/latest/downloads/by-ethnicity-table.csv"

echo "Downloads complete. Verify file sizes."
ls -lh "$RAW_DIR"
```

**Note:** The exact asset URLs for the 2025 ODS files will need to be confirmed from the GOV.UK download page at build time. The script should include SHA256 checksums for reproducibility.
