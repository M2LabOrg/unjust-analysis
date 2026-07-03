# =============================================================================
# 05_new_insights.R
# Novel analyses beyond what the government publishes.
#
# Input:  data/processed/stop_search_clean.csv, census_clean.csv
# Output: analysis/output/reason_bw_ratio.csv
#         analysis/output/reason_detail_by_ethnicity.csv
#         analysis/output/missing_trend_by_force.csv
# =============================================================================

library(tidyverse)

out_dir <- "analysis/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

message("=== 05_new_insights.R: Novel Analyses ===\n")

ss     <- read_csv("data/processed/stop_search_clean.csv", show_col_types = FALSE)
census <- read_csv("data/processed/census_clean.csv", show_col_types = FALSE)

# Population totals by ethnicity (England & Wales, aggregated across regions)
pop_by_eth <- census |>
  group_by(ethnicity) |>
  summarise(population = sum(population), .groups = "drop")

# =============================================================================
# 1. RACIAL SKEW BY SEARCH REASON
#    Which reason for search shows the greatest Black/White rate disparity?
# =============================================================================

message("--- 1. Racial skew by search reason ---")

reason_detail <- ss |>
  filter(!is.na(ethnicity), !is.na(reason)) |>
  group_by(reason, ethnicity) |>
  summarise(total_searches = sum(n_searches, na.rm = TRUE), .groups = "drop") |>
  left_join(pop_by_eth, by = "ethnicity") |>
  mutate(rate_per_1000 = total_searches / population * 1000)   # no early rounding

write_csv(reason_detail, file.path(out_dir, "reason_detail_by_ethnicity.csv"))

# Total searches per reason (used for reliability filtering)
reason_totals <- reason_detail |>
  group_by(reason) |>
  summarise(total_searches = sum(total_searches), .groups = "drop")

# Black/White rate ratio per reason — compute ratio from unrounded rates,
# exclude reasons with fewer than 1,000 total searches (unreliable)
reason_bw_ratio <- reason_detail |>
  select(reason, ethnicity, rate_per_1000) |>
  pivot_wider(names_from = ethnicity, values_from = rate_per_1000,
              names_prefix = "rate_") |>
  filter(!is.na(rate_Black), !is.na(rate_White), rate_White > 0) |>
  left_join(reason_totals, by = "reason") |>
  filter(total_searches >= 1000) |>   # drop near-zero-volume reasons
  mutate(
    black_white_ratio = round(rate_Black / rate_White, 2),
    rate_Black        = round(rate_Black, 4),
    rate_White        = round(rate_White, 4)
  ) |>
  arrange(desc(black_white_ratio))

message("  Black/White rate ratio by search reason:")
print(as.data.frame(reason_bw_ratio |> select(reason, rate_Black, rate_White, black_white_ratio)))

write_csv(reason_bw_ratio, file.path(out_dir, "reason_bw_ratio.csv"))
message("  Saved: reason_bw_ratio.csv, reason_detail_by_ethnicity.csv")

# =============================================================================
# 2. MISSING ETHNICITY: IS IT SYSTEMATIC?
#    Do certain forces persistently fail to record ethnicity?
# =============================================================================

message("\n--- 2. Missing ethnicity: systematic patterns ---")

# Force-level missingness trend over time
missing_trend <- ss |>
  group_by(financial_year, police_force, region_clean) |>
  summarise(
    total_searches    = sum(n_searches, na.rm = TRUE),
    missing_searches  = sum(n_searches[is.na(ethnicity)], na.rm = TRUE),
    pct_missing       = round(100 * missing_searches / total_searches, 1),
    .groups           = "drop"
  )

# Forces with consistently high missingness (mean > 15% across all years)
persistent_missing <- missing_trend |>
  group_by(police_force, region_clean) |>
  summarise(
    mean_pct_missing = round(mean(pct_missing), 1),
    max_pct_missing  = round(max(pct_missing), 1),
    n_years          = n(),
    .groups          = "drop"
  ) |>
  filter(n_years >= 3) |>   # only forces with multi-year data
  arrange(desc(mean_pct_missing))

message("  Top 10 forces by mean missing ethnicity %:")
print(as.data.frame(head(persistent_missing, 10)))

write_csv(missing_trend,       file.path(out_dir, "missing_trend_by_force.csv"))
write_csv(persistent_missing,  file.path(out_dir, "missing_persistent_forces.csv"))
message("  Saved: missing_trend_by_force.csv, missing_persistent_forces.csv")

message("\n=== 05_new_insights.R: COMPLETE ===")
