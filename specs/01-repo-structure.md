# 01 -- Repository Structure

## Recommendation: Single New Monorepo

Rather than juggling three repos, we recommend consolidating into **one new repo** (`unjust`) with a clean structure. The two existing repos are preserved as-is for reference.

### Why a monorepo?

- **Reproducibility**: one `git clone` gives you everything
- **Shared data**: analysis feeds both the report and the dashboard
- **Single CI/CD**: one Netlify build deploys both dashboard and report
- **Simpler maintenance**: one place to update dependencies, one README

### Proposed Structure

```
unjust/
├── README.md
├── LICENSE
├── .gitignore
│
├── data/
│   ├── raw/                        # Untouched downloaded files
│   │   ├── stop-search-open-data-mar23.ods
│   │   ├── stop-search-open-data-mar24.ods
│   │   ├── stop-search-open-data-mar25.ods
│   │   ├── census-2021-ethnicity-region.csv
│   │   └── shapefile/
│   ├── processed/                  # Cleaned, analysis-ready datasets
│   │   ├── stop_search_clean.parquet  (or .csv)
│   │   ├── census_clean.parquet
│   │   └── merged_rates.parquet
│   └── download_data.sh            # Script to fetch raw data from GOV.UK
│
├── analysis/                       # All analysis code
│   ├── 01_load_and_clean.R         # (or .py) Data ingestion & cleaning
│   ├── 02_eda.R                    # Exploratory data analysis
│   ├── 03_model_poisson.R          # Poisson GLM with offset
│   ├── 04_model_rf.R               # Random Forest (complementary)
│   ├── 05_new_insights.R           # Trend analysis, outcome disparities, etc.
│   ├── 06_export_for_dashboard.R   # Export JSON/CSV for React dashboard
│   └── utils/
│       ├── load_data.R
│       ├── validate.R              # QA checks
│       └── plot_theme.R            # Consistent ggplot theme
│
├── qa/                             # Quality assurance
│   ├── check_totals.R              # Compare against published GOV.UK totals
│   ├── check_rates.R               # Validate rate calculations
│   ├── check_consistency.R         # Cross-check across years
│   └── qa_report.qmd              # QA log rendered as HTML
│
├── report/                         # Quarto book
│   ├── _quarto.yml
│   ├── index.qmd
│   ├── 01-introduction.qmd
│   ├── 02-literature.qmd
│   ├── 03-methodology.qmd
│   ├── 04-results.qmd
│   ├── 05-discussion.qmd
│   ├── 06-conclusion.qmd
│   ├── references.qmd
│   ├── bibliography.bib
│   ├── harvard.csl
│   └── _book/                      # Build output (gitignored)
│
├── dashboard/                      # React app
│   ├── package.json
│   ├── tailwind.config.js
│   ├── vite.config.ts
│   ├── public/
│   │   └── data/                   # Static JSON for charts
│   ├── src/
│   │   ├── App.tsx
│   │   ├── main.tsx
│   │   ├── components/
│   │   │   ├── Layout.tsx
│   │   │   ├── Hero.tsx
│   │   │   ├── KeyFindings.tsx
│   │   │   ├── DisparityChart.tsx
│   │   │   ├── RegionalMap.tsx
│   │   │   ├── TrendChart.tsx
│   │   │   ├── OutcomeChart.tsx
│   │   │   └── Footer.tsx
│   │   ├── hooks/
│   │   └── styles/
│   └── dist/                       # Build output (gitignored)
│
├── netlify.toml                    # Netlify build config
├── build.sh                        # Orchestrates full build
└── Makefile                        # Alternative build orchestration
```

### Migration from Existing Repos

1. Copy relevant R scripts from `RSS_UNJUST_Report/data/getData.R` and `RSS_UNJUST_Project/Rcode/R/` into `analysis/utils/`
2. Copy and update Quarto chapters from `RSS_UNJUST_Report/*.qmd` into `report/`
3. Copy bibliography and CSL files
4. Copy shapefiles
5. Do NOT copy `_book/`, generated HTML, or `.Rhistory` files
6. The old repos remain untouched as historical reference

### Netlify Deployment

The Netlify site will serve:
- `/` -- the React dashboard (primary landing page)
- `/report/` -- the rendered Quarto HTML book

The `netlify.toml` will configure:
- Build command: `bash build.sh` (builds both dashboard and report)
- Publish directory: `dist/` (a merged output folder)
- The build script copies `dashboard/dist/*` and `report/_book/*` into `dist/`
