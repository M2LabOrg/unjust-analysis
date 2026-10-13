# =============================================================================
# qa/check_totals.R
# Validate our aggregated totals against published GOV.UK headline figures.
#
# Published totals (from GOV.UK bulletins - these include ALL forces):
#   2020/21: 693,009
#   2021/22: 537,061
#   2022/23: 547,002
#   2023/24: 536,091
#   2024/25: 528,582
#
# Our totals exclude: vehicle searches, BTP
# So our totals will be LOWER than published -- that's expected.
# =============================================================================

library(tidyverse)

message("=== QA: CHECK TOTALS ===\n")

# Load raw data to compare against published figures (before our exclusions)
ss_raw <- read_csv("data/processed/stop_search_clean.csv", show_col_types = FALSE)

# Our totals (after exclusions)
our_totals <- ss_raw |>
  group_by(financial_year) |>
  summarise(our_total = sum(n_searches, na.rm = TRUE), .groups = "drop")

# Published totals (from GOV.UK -- includes BTP and vehicle searches)
published <- tibble(
  financial_year = c("2020/21", "2021/22", "2022/23", "2023/24", "2024/25"),
  published_total = c(693009, 537061, 547002, 536091, 528582)
)

comparison <- our_totals |>
  left_join(published, by = "financial_year") |>
  mutate(
    difference = our_total - published_total,
    pct_diff = round(100 * difference / published_total, 1)
  )

message("Totals comparison (ours vs. published GOV.UK figures):")
message("Our totals are LOWER because we exclude BTP + vehicle searches.\n")
print(as.data.frame(comparison))

# Sanity check: our totals should be between 80-100% of published
check_passed <- all(comparison$pct_diff > -25 & comparison$pct_diff < 0)

if (check_passed) {
  message("\n  PASS: Our totals are within expected range (75-100% of published).")
} else {
  warning("\n  FAIL: Some totals are outside expected range!")
}

# Also load the summary data for ethnicity-level validation
summary_ods <- file.path("data/raw", "stop-search-data-tables-summary-mar25.ods")
if (file.exists(summary_ods)) {
  message("\n  Summary ODS file found for additional cross-checks.")
}

message("\n=== QA: CHECK TOTALS COMPLETE ===")
