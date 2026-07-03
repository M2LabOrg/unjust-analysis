# UNJUST -- Stop and Search Analysis

[![Reproducibility](https://github.com/M2LabOrg/unjust-analysis/actions/workflows/reproduce.yml/badge.svg)](https://github.com/M2LabOrg/unjust-analysis/actions/workflows/reproduce.yml)

Statistical analysis of police stop-and-search practices on Black communities in England & Wales (2020/21 -- 2024/25).

A project by [Michel Mesquita, Ph.D., CStat](https://m2lab.io) for [UNJUST](https://www.theunjustproject.com/) through the Royal Statistical Society's *Statisticians for Society* programme.

## Structure

| Folder | Purpose |
|--------|---------|
| `data/` | Raw and processed datasets |
| `analysis/` | R scripts for cleaning, modelling, and insight generation |
| `qa/` | Quality assurance checks and validation report |
| `report/` | Quarto book (HTML + PDF) |
| `dashboard/` | React + Tailwind interactive dashboard |
| `specs/` | Project specifications and plan |

## Deployment

The live dashboard is at [unjust.netlify.app](https://unjust.netlify.app) (Netlify). The Quarto report is served at `/report/` from the same deploy.

Netlify's build environment does not have R or Quarto, so `report/_book/` (the rendered HTML output) is committed to the repository. The build step simply copies it into the dashboard's `dist/` folder. If you re-render the report locally (`cd report && quarto render`), commit the updated `_book/` alongside any source changes before pushing.

## Quick Start

```bash
# 1. Download data
bash data/download_data.sh

# 2. Run analysis (requires R)
Rscript analysis/01_load_and_clean.R
Rscript analysis/02_eda.R
Rscript analysis/03_model_poisson.R

# 3. Build report (requires Quarto)
cd report && quarto render

# 4. Build dashboard (requires Node.js)
cd dashboard && npm install && npm run build

# 5. Full build (for deployment)
bash build.sh
```

## Data Sources

- [Home Office -- Police Powers and Procedures](https://www.gov.uk/government/collections/police-powers-and-procedures-england-and-wales) (Stop and search open data tables, FY 2020/21 -- 2024/25)
- [ONS Census 2021](https://www.ons.gov.uk/census) (Population by ethnicity and region)
- [Ethnicity Facts and Figures](https://www.ethnicity-facts-figures.service.gov.uk/crime-justice-and-the-law/policing/stop-and-search/latest/) (Pre-calculated rates for QA cross-validation)

## Licence

This repository uses a dual licence:

| Component | Licence |
|-----------|---------|
| Code (R scripts, analysis, dashboard source) | [Apache 2.0](LICENSE) |
| Report text, findings, and figures | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |

Under CC BY 4.0 you are free to share and adapt the report content for any purpose, provided you give appropriate credit to the authors and UNJUST.

Data sources are publicly available under the [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/) (Home Office stop and search data) and the [ONS Open Licence](https://www.ons.gov.uk/methodology/geography/licences) (Census 2021 population denominators).

© 2024–2026 Michel Mesquita / M2Lab CSDS, in collaboration with UNJUST.
