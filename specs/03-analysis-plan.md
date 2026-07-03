# 03 -- Analysis Plan

## Language Choice: R (primary), with Python optional

**Recommendation: Stay with R.** The existing codebase is in R, the Poisson GLM and Random Forest are well-established in R, and Quarto integrates natively with R. Python can be used for the dashboard data export if needed.

## Pipeline Steps

### Step 1: Data Ingestion & Cleaning (`01_load_and_clean.R`)

- Load all ODS files (2023, 2024, 2025 releases)
- Harmonize column names and ethnicity categories across years
- Remove vehicle-only searches (consistent with current methodology)
- Remove British Transport Police (BTP) records (no census denominator)
- Handle missing ethnicity data (document exclusion rates per year)
- Load and clean Census 2021 data
- Merge stop-search counts with census population denominators
- Output: `data/processed/stop_search_clean.parquet` and `census_clean.parquet`

### Step 2: Exploratory Data Analysis (`02_eda.R`)

- Descriptive statistics by year, ethnicity, region, age, sex, reason
- Time series of total searches (2020/21 -- 2024/25)
- Disparity ratios (Black:White, Asian:White) over time
- Outcome distributions by ethnicity and year
- Missing data analysis (ethnicity missingness by force/year)
- Regional heatmaps

### Step 3: Poisson Regression (`03_model_poisson.R`)

Extend the existing model to include new years:

```
log(count_i) = log(pop_i) + beta_0 + year + region + ethnicity + sex + age_binary + reason_binary
```

- Fit model on pooled data (5 years: 2020/21 -- 2024/25)
- Extract incidence rate ratios (IRR) with confidence intervals
- Compare IRRs across time periods (has the disparity changed?)
- Overdispersion test -- consider Negative Binomial if needed
- Model diagnostics: residual plots, goodness-of-fit

### Step 4: Random Forest (`04_model_rf.R`)

- Fit RF on the same dataset for variable importance
- Compare feature importance rankings across time periods
- Use partial dependence plots for key interactions
- Cross-validate with out-of-bag error

### Step 5: New Insights (`05_new_insights.R`)

This is the key section to go beyond what the government publishes. Potential analyses:

#### 5a. Trend Analysis (Is It Getting Better or Worse?)
- Year-on-year change in disparity ratios (2020/21 through 2024/25)
- Interrupted time series: did any policy change have a measurable effect?
- Compare the trajectory of the official 3.8x figure across years

#### 5b. Outcome Disparity Analysis
- Not just "who gets stopped" but "what happens after"
- Compare arrest rates, NFA rates, and other outcomes BY ethnicity
- Are Black individuals more likely to have "no further action"? (i.e., were they stopped without cause?)
- Calculate the "futility rate" -- stops that produce no actionable outcome, stratified by ethnicity

#### 5c. Regional Deep Dive
- Which police forces have the highest disparity?
- Which forces have improved/worsened over time?
- Rank forces by disparity-adjusted-for-demographics
- Small multiples map showing change over time

#### 5d. Interaction Effects
- Age x Ethnicity: are young Black males the most disproportionately targeted group?
- Region x Ethnicity: which region has the worst disparity?
- Reason x Ethnicity: are drug stops more racially skewed than weapons stops?
- Use the RF partial dependence plots to visualize these

#### 5e. "Reasonable Grounds" Analysis
- If outcome data allows: what proportion of stops on Black individuals lead to finding what was searched for?
- Compare "hit rates" (successful finds) across ethnicities
- A lower hit rate for one group suggests lower thresholds for suspicion

#### 5f. Population-Adjusted Regional Mapping
- Choropleth maps showing rate per 1,000 by ethnicity by region
- Side-by-side maps: raw rate vs population-adjusted rate
- Highlight regions where the gap is largest

### Step 6: Export for Dashboard (`06_export_for_dashboard.R`)

- Export analysis results as JSON files for the React dashboard
- Key datasets to export:
  - `disparity_trend.json` -- IRRs by year
  - `regional_rates.json` -- rates by region and ethnicity
  - `outcome_by_ethnicity.json` -- outcome breakdowns
  - `force_rankings.json` -- forces ranked by disparity
  - `key_findings.json` -- headline numbers for the hero section
  - `geojson/regions.geojson` -- simplified regional boundaries

## Model Validation

- Compare our total counts against published GOV.UK totals for each year
- Compare our disparity ratios against the official published ratios
- Document any differences and explain them (e.g., exclusion criteria)
- All comparisons logged in `qa/qa_report.qmd`
