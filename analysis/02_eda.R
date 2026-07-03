# =============================================================================
# 02_eda.R
# Exploratory data analysis: descriptive stats, trends, distributions.
#
# Input:  data/processed/stop_search_clean.csv
#         data/processed/census_clean.csv
#         data/processed/merged_rates.csv
# Output: analysis/output/*.csv (summary tables for report & dashboard)
# =============================================================================

library(tidyverse)

out_dir <- "analysis/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

message("=== 02_eda.R: Exploratory Data Analysis ===\n")

# --- Load data ---------------------------------------------------------------
ss     <- read_csv("data/processed/stop_search_clean.csv", show_col_types = FALSE)
census <- read_csv("data/processed/census_clean.csv", show_col_types = FALSE)
merged <- read_csv("data/processed/merged_rates.csv", show_col_types = FALSE)

# =============================================================================
# 1. DISPARITY RATIOS OVER TIME (the trend question)
# =============================================================================

message("--- 1. Disparity ratios by year ---")

disparity_trend <- merged |>
  group_by(financial_year, ethnicity) |>
  summarise(
    total_searches = sum(total_searches),
    total_population = sum(population),
    .groups = "drop"
  ) |>
  mutate(rate_per_1000 = total_searches / total_population * 1000) |>
  group_by(financial_year) |>
  mutate(
    white_rate = rate_per_1000[ethnicity == "White"],
    ratio_vs_white = round(rate_per_1000 / white_rate, 2)
  ) |>
  ungroup()

message("  Disparity ratios (vs White):")
disparity_trend |>
  select(financial_year, ethnicity, rate_per_1000, ratio_vs_white) |>
  pivot_wider(names_from = ethnicity, values_from = c(rate_per_1000, ratio_vs_white)) |>
  print(n = 10)

write_csv(disparity_trend, file.path(out_dir, "disparity_trend.csv"))

# =============================================================================
# 2. OUTCOME ANALYSIS BY ETHNICITY (the futility question)
# =============================================================================

message("\n--- 2. Outcome analysis by ethnicity ---")

outcomes_by_ethnicity <- ss |>
  filter(!is.na(ethnicity)) |>
  group_by(ethnicity, outcome) |>
  summarise(n = sum(n_searches, na.rm = TRUE), .groups = "drop") |>
  group_by(ethnicity) |>
  mutate(
    total = sum(n),
    pct = round(100 * n / total, 1)
  ) |>
  ungroup()

# Focus on NFA (No Further Action) rate by ethnicity
nfa_rates <- outcomes_by_ethnicity |>
  filter(outcome == "No Further Action") |>
  select(ethnicity, nfa_count = n, total, nfa_pct = pct) |>
  arrange(desc(nfa_pct))

message("  No Further Action rates by ethnicity (all years):")
print(as.data.frame(nfa_rates))

write_csv(outcomes_by_ethnicity, file.path(out_dir, "outcomes_by_ethnicity.csv"))

# NFA by ethnicity AND year
nfa_by_year <- ss |>
  filter(!is.na(ethnicity)) |>
  group_by(financial_year, ethnicity, outcome) |>
  summarise(n = sum(n_searches, na.rm = TRUE), .groups = "drop") |>
  group_by(financial_year, ethnicity) |>
  mutate(total = sum(n), pct = round(100 * n / total, 1)) |>
  filter(outcome == "No Further Action") |>
  select(financial_year, ethnicity, nfa_pct = pct)

write_csv(nfa_by_year, file.path(out_dir, "nfa_by_year.csv"))

# =============================================================================
# 3. REGIONAL ANALYSIS
# =============================================================================

message("\n--- 3. Regional analysis ---")

regional_rates <- merged |>
  mutate(rate_per_1000 = total_searches / population * 1000) |>
  select(financial_year, region_clean, ethnicity, total_searches, population, rate_per_1000)

# Regional disparity: Black vs White ratio by region (latest year)
regional_disparity <- regional_rates |>
  filter(financial_year == max(financial_year)) |>
  select(region_clean, ethnicity, rate_per_1000) |>
  pivot_wider(names_from = ethnicity, values_from = rate_per_1000, names_prefix = "rate_") |>
  mutate(
    black_white_ratio = round(rate_Black / rate_White, 2)
  ) |>
  arrange(desc(black_white_ratio))

message("  Black:White disparity by region (2024/25):")
print(as.data.frame(regional_disparity))

write_csv(regional_rates, file.path(out_dir, "regional_rates.csv"))
write_csv(regional_disparity, file.path(out_dir, "regional_disparity.csv"))

# =============================================================================
# 4. FORCE-LEVEL ANALYSIS
# =============================================================================

message("\n--- 4. Force-level analysis ---")

force_by_ethnicity <- ss |>
  filter(!is.na(ethnicity)) |>
  group_by(financial_year, police_force, ethnicity) |>
  summarise(total_searches = sum(n_searches, na.rm = TRUE), .groups = "drop")

# Forces with highest volume for Black ethnicity (latest year)
force_black <- force_by_ethnicity |>
  filter(financial_year == max(financial_year), ethnicity == "Black") |>
  arrange(desc(total_searches))

message("  Top 10 forces by Black stop-and-search volume (2024/25):")
print(as.data.frame(head(force_black, 10)))

write_csv(force_by_ethnicity, file.path(out_dir, "force_by_ethnicity.csv"))

# =============================================================================
# 5. AGE x ETHNICITY INTERACTION
# =============================================================================

message("\n--- 5. Age x Ethnicity breakdown ---")

age_ethnicity <- ss |>
  filter(!is.na(ethnicity), !is.na(age_under25)) |>
  group_by(financial_year, ethnicity, age_under25) |>
  summarise(total_searches = sum(n_searches, na.rm = TRUE), .groups = "drop")

# Latest year summary
age_eth_latest <- age_ethnicity |>
  filter(financial_year == max(financial_year)) |>
  group_by(ethnicity) |>
  mutate(pct_under25 = round(100 * total_searches / sum(total_searches), 1)) |>
  filter(age_under25 == TRUE) |>
  select(ethnicity, searches_under25 = total_searches, pct_under25) |>
  arrange(desc(pct_under25))

message("  Proportion of searches on under-25s by ethnicity (2024/25):")
print(as.data.frame(age_eth_latest))

write_csv(age_ethnicity, file.path(out_dir, "age_ethnicity.csv"))

# =============================================================================
# 6. DRUG STOPS vs OTHER REASONS BY ETHNICITY
# =============================================================================

message("\n--- 6. Drug stops vs other reasons ---")

reason_ethnicity <- ss |>
  filter(!is.na(ethnicity)) |>
  group_by(financial_year, ethnicity, reason_drugs) |>
  summarise(total_searches = sum(n_searches, na.rm = TRUE), .groups = "drop") |>
  group_by(financial_year, ethnicity) |>
  mutate(pct = round(100 * total_searches / sum(total_searches), 1))

drug_pct_latest <- reason_ethnicity |>
  filter(financial_year == max(financial_year), reason_drugs == TRUE) |>
  select(ethnicity, drug_searches = total_searches, pct_drugs = pct) |>
  arrange(desc(pct_drugs))

message("  Drug-related search proportion by ethnicity (2024/25):")
print(as.data.frame(drug_pct_latest))

write_csv(reason_ethnicity, file.path(out_dir, "reason_ethnicity.csv"))

# =============================================================================
# 7. SEX BREAKDOWN
# =============================================================================

message("\n--- 7. Sex breakdown ---")

sex_summary <- ss |>
  filter(!is.na(ethnicity), sex %in% c("Male", "Female")) |>
  group_by(financial_year, sex) |>
  summarise(total = sum(n_searches, na.rm = TRUE), .groups = "drop") |>
  group_by(financial_year) |>
  mutate(pct = round(100 * total / sum(total), 1))

message("  Sex distribution:")
print(as.data.frame(sex_summary))

write_csv(sex_summary, file.path(out_dir, "sex_summary.csv"))

# =============================================================================
# 8. MISSING DATA ANALYSIS
# =============================================================================

message("\n--- 8. Missing ethnicity data by force ---")

missing_by_force <- ss |>
  group_by(financial_year, police_force) |>
  summarise(
    total_searches    = sum(n_searches, na.rm = TRUE),
    missing_searches  = sum(n_searches[is.na(ethnicity)], na.rm = TRUE),
    pct_missing       = round(100 * missing_searches / total_searches, 1),
    .groups = "drop"
  ) |>
  filter(financial_year == max(financial_year)) |>
  arrange(desc(pct_missing))

message("  Forces with highest missing ethnicity (2024/25):")
print(as.data.frame(head(missing_by_force, 10)))

write_csv(missing_by_force, file.path(out_dir, "missing_by_force.csv"))

message("\n=== 02_eda.R: COMPLETE ===")
message("Output saved to: ", out_dir)
