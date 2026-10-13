# =============================================================================
# 06_export_for_dashboard.R
# Export analysis results as JSON for the React dashboard.
#
# Input:  analysis/output/*.csv
# Output: dashboard/public/data/*.json
# =============================================================================

library(tidyverse)
library(jsonlite)

input_dir  <- "analysis/output"
output_dir <- "dashboard/public/data"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

message("=== 06_export_for_dashboard.R ===\n")

# --- 1. Key findings (hero section) ------------------------------------------

disparity <- read_csv(file.path(input_dir, "disparity_trend.csv"), show_col_types = FALSE)
irr       <- read_csv(file.path(input_dir, "irr_table.csv"), show_col_types = FALSE)
nfa       <- read_csv(file.path(input_dir, "outcomes_by_ethnicity.csv"), show_col_types = FALSE)

latest_year <- max(disparity$financial_year)

# Black raw disparity (latest year)
black_raw <- disparity |>
  filter(financial_year == latest_year, ethnicity == "Black") |>
  pull(ratio_vs_white)

# Adjusted IRR: use the year-specific model (latest year) so the dashboard card
# matches the narrative in the report ("3.3× in 2024/25"), not the pooled model.
yearly_irr_csv <- read_csv(file.path(input_dir, "yearly_irr.csv"), show_col_types = FALSE)
black_irr <- yearly_irr_csv |>
  filter(financial_year == latest_year, term == "ethnicityBlack") |>
  pull(irr) |>
  round(1)

male_irr  <- irr |> filter(term == "sexMale") |> pull(irr) |> round(1)

# NFA rate for Black
nfa_black <- nfa |> filter(ethnicity == "Black", outcome == "No Further Action") |> pull(pct)

# Total searches latest year (including records with no stated ethnicity)
ss_clean <- read_csv("data/processed/stop_search_clean.csv", show_col_types = FALSE)
total_latest <- ss_clean |>
  filter(financial_year == latest_year) |>
  summarise(total = sum(n_searches, na.rm = TRUE)) |>
  pull(total)

key_findings <- list(
  headline_ratio = round(black_raw, 1),
  adjusted_irr = black_irr,
  male_irr = male_irr,
  nfa_rate_black = nfa_black,
  total_searches_latest = total_latest,
  latest_year = latest_year,
  data_years = "2020/21 to 2024/25"
)

write_json(key_findings, file.path(output_dir, "key_findings.json"), pretty = TRUE, auto_unbox = TRUE)

# --- 2. Disparity trend (line chart) -----------------------------------------

trend_data <- disparity |>
  select(financial_year, ethnicity, rate_per_1000, ratio_vs_white) |>
  mutate(across(c(rate_per_1000, ratio_vs_white), \(x) round(x, 2)))

write_json(trend_data, file.path(output_dir, "disparity_trend.json"), pretty = TRUE)

# --- 3. Yearly IRR from model (trend with confidence intervals) ---------------

yearly_irr <- read_csv(file.path(input_dir, "yearly_irr.csv"), show_col_types = FALSE) |>
  mutate(
    ethnicity = str_replace(term, "ethnicity", ""),
    across(c(irr, irr_lower, irr_upper), \(x) round(x, 2))
  ) |>
  select(financial_year, ethnicity, irr, irr_lower, irr_upper)

write_json(yearly_irr, file.path(output_dir, "yearly_irr.json"), pretty = TRUE)

# --- 4. Regional disparity (map data) ----------------------------------------

regional <- read_csv(file.path(input_dir, "regional_disparity.csv"), show_col_types = FALSE) |>
  mutate(across(where(is.numeric), \(x) round(x, 2)))

write_json(regional, file.path(output_dir, "regional_disparity.json"), pretty = TRUE)

# --- 5. Outcomes by ethnicity (bar chart) -------------------------------------

outcomes <- read_csv(file.path(input_dir, "outcomes_by_ethnicity.csv"), show_col_types = FALSE)

write_json(outcomes, file.path(output_dir, "outcomes_by_ethnicity.json"), pretty = TRUE)

# --- 6. NFA by year (trend) --------------------------------------------------

nfa_year <- read_csv(file.path(input_dir, "nfa_by_year.csv"), show_col_types = FALSE)
write_json(nfa_year, file.path(output_dir, "nfa_by_year.json"), pretty = TRUE)

# --- 7. Force rankings -------------------------------------------------------

force_data <- read_csv(file.path(input_dir, "force_by_ethnicity.csv"), show_col_types = FALSE)
write_json(force_data, file.path(output_dir, "force_by_ethnicity.json"), pretty = TRUE)

# --- 8. Reason Black/White ratio (new insights) ------------------------------

if (file.exists(file.path(input_dir, "reason_bw_ratio.csv"))) {
  reason_bw <- read_csv(file.path(input_dir, "reason_bw_ratio.csv"), show_col_types = FALSE) |>
    select(reason, rate_Black, rate_White, black_white_ratio) |>
    mutate(across(where(is.numeric), \(x) round(x, 3))) |>
    arrange(desc(black_white_ratio))
  write_json(reason_bw, file.path(output_dir, "reason_bw_ratio.json"), pretty = TRUE)
}

# --- 9. Persistent missing ethnicity by force --------------------------------

if (file.exists(file.path(input_dir, "missing_persistent_forces.csv"))) {
  missing_forces <- read_csv(file.path(input_dir, "missing_persistent_forces.csv"),
                             show_col_types = FALSE) |>
    mutate(across(where(is.numeric), \(x) round(x, 1)))
  write_json(missing_forces, file.path(output_dir, "missing_persistent_forces.json"),
             pretty = TRUE)
}

message("  Exported ", length(list.files(output_dir, pattern = "\\.json$")), " JSON files to ", output_dir)

# --- 10. Beyond the Headlines insights (data-driven text) --------------------

age_eth   <- read_csv(file.path(input_dir, "age_ethnicity.csv"), show_col_types = FALSE)
reason    <- read_csv(file.path(input_dir, "reason_ethnicity.csv"), show_col_types = FALSE)
missing   <- read_csv(file.path(input_dir, "missing_by_force.csv"), show_col_types = FALSE)
census    <- read_csv("data/processed/census_clean.csv", show_col_types = FALSE)

first_year <- min(disparity$financial_year)

# Finding 01: raw and adjusted trend
raw_first <- disparity |>
  filter(financial_year == first_year, ethnicity == "Black") |> pull(ratio_vs_white) |> round(1)
raw_latest <- round(black_raw, 1)
irr_first <- yearly_irr_csv |>
  filter(financial_year == first_year, term == "ethnicityBlack") |> pull(irr) |> round(1)
irr_latest <- black_irr

# Finding 02: age/sex
age_latest <- age_eth |> filter(financial_year == latest_year)
pct_u25 <- function(eth) {
  rows <- age_latest |> filter(ethnicity == eth)
  total <- sum(rows$total_searches)
  u25 <- rows |> filter(age_under25 == TRUE) |> pull(total_searches)
  round(u25 / total * 100)
}
pct_u25_black <- pct_u25("Black")
pct_u25_white <- pct_u25("White")

# Finding 03: worst region
regional_csv <- read_csv(file.path(input_dir, "regional_disparity.csv"), show_col_types = FALSE)
worst_region_row <- regional_csv |> slice_max(black_white_ratio, n = 1)
worst_region <- worst_region_row$region_clean
worst_ratio <- round(worst_region_row$black_white_ratio, 1)
# Black population share in that region
region_census <- census |> filter(region_clean == worst_region)
region_total_pop <- sum(region_census$population)
region_black_pop <- region_census |> filter(ethnicity == "Black") |> pull(population)
region_black_pct <- round(region_black_pop / region_total_pop * 100)

# Finding 04: NFA
nfa_white <- nfa |> filter(ethnicity == "White", outcome == "No Further Action") |> pull(pct) |> round(0)
nfa_black_round <- round(nfa_black)

# Finding 05: drug searches
drug_latest <- reason |> filter(financial_year == latest_year, reason_drugs == TRUE)
drug_pct_black <- drug_latest |> filter(ethnicity == "Black") |> pull(pct)
drug_pct_white <- drug_latest |> filter(ethnicity == "White") |> pull(pct)

# Finding 06: missing ethnicity
missing_latest <- missing |> filter(financial_year == latest_year)
overall_missing_pct <- round(sum(missing_latest$missing_searches) / sum(missing_latest$total_searches) * 100)
worst_forces <- missing_latest |>
  slice_max(pct_missing, n = 4) |>
  mutate(pct_missing = round(pct_missing)) |>
  select(police_force, pct_missing)

insights <- list(
  latest_year = latest_year,
  first_year = first_year,
  finding_01 = list(
    raw_ratio_first = raw_first,
    raw_ratio_latest = raw_latest,
    irr_first = irr_first,
    irr_latest = irr_latest
  ),
  finding_02 = list(
    pct_under25_black = pct_u25_black,
    pct_under25_white = pct_u25_white,
    male_irr = male_irr
  ),
  finding_03 = list(
    worst_region = worst_region,
    black_white_ratio = worst_ratio,
    black_pop_pct = region_black_pct
  ),
  finding_04 = list(
    nfa_pct_black = nfa_black_round,
    nfa_pct_white = nfa_white,
    raw_ratio = raw_latest
  ),
  finding_05 = list(
    drug_pct_black = drug_pct_black,
    drug_pct_white = drug_pct_white
  ),
  finding_06 = list(
    overall_missing_pct = overall_missing_pct,
    worst_forces = worst_forces
  )
)

write_json(insights, file.path(output_dir, "insights.json"), pretty = TRUE, auto_unbox = TRUE)

message("\n=== 06_export_for_dashboard.R: COMPLETE ===")
