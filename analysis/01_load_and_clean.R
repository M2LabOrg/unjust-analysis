# =============================================================================
# 01_load_and_clean.R
# Load raw stop-and-search and census data, clean, harmonize, and save.
#
# Input:  data/raw/stop-search-open-data-tables-mar21-mar25.ods
#         data/raw/population-by-ethnicity-and-region-2021.csv
# Output: data/processed/stop_search_clean.csv
#         data/processed/census_clean.csv
#         data/processed/merged_rates.csv
# =============================================================================

library(tidyverse)
library(readODS)
library(janitor)

# --- Configuration -----------------------------------------------------------

raw_dir   <- "data/raw"
out_dir   <- "data/processed"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# 1. STOP AND SEARCH DATA
# =============================================================================

message("--- Loading stop-and-search open data (Mar 2025 release, 5 years) ---")

ss_raw <- read_ods(
  file.path(raw_dir, "stop-search-open-data-tables-mar21-mar25.ods"),
  sheet = "open_data"
) |> clean_names()

message("  Raw rows: ", format(nrow(ss_raw), big.mark = ","))
message("  Years: ", paste(sort(unique(ss_raw$financial_year)), collapse = ", "))

# --- Cleaning ----------------------------------------------------------------

ss <- ss_raw |>
  # Remove vehicle searches (no person-level demographics)
  filter(self_defined_ethnicity_group != "N/A - vehicle search") |>
  # Remove BTP (geocode "0" / region "0") -- no census denominator
  filter(region != "0") |>
  # Standardize ethnicity groups to 5 main categories
  mutate(
    ethnicity = case_when(
      self_defined_ethnicity_group == "Asian or Asian British" ~ "Asian",
      self_defined_ethnicity_group == "Black or Black British" ~ "Black",
      self_defined_ethnicity_group == "White"                  ~ "White",
      self_defined_ethnicity_group == "Mixed"                  ~ "Mixed",
      self_defined_ethnicity_group == "Other Ethnic Group"     ~ "Other",
      self_defined_ethnicity_group == "Not Stated"             ~ NA_character_,
      TRUE                                                     ~ NA_character_
    )
  ) |>
  # Create binary age variable: under 25 vs 25+
  mutate(
    age_under25 = case_when(
      age_group %in% c("Under 10", "10-17", "18-24") ~ TRUE,
      age_group %in% c("25-29", "30 or over")        ~ FALSE,
      TRUE                                            ~ NA
    )
  ) |>
  # Create binary reason: drugs vs other
  mutate(
    reason_drugs = reason_for_search == "Drugs"
  ) |>
  # Standardize region names for merging with census
  mutate(
    region_clean = case_when(
      region == "Eastern"                  ~ "East of England",
      region == "Yorkshire and the Humber" ~ "Yorkshire and The Humber",
      TRUE                                 ~ region
    )
  ) |>
  # Keep relevant columns
  select(
    financial_year,
    quarter = financial_year_quarter,
    police_force = police_force_area,
    region, region_clean,
    legislation,
    reason = reason_for_search,
    reason_drugs,
    outcome,
    ethnicity,
    self_defined_ethnicity,
    officer_defined_ethnicity,
    sex,
    age_group,
    age_under25,
    n_searches = number_of_searches
  )

# Report missing ethnicity
n_total     <- nrow(ss)
n_missing_e <- sum(is.na(ss$ethnicity))
message("  After cleaning: ", format(n_total, big.mark = ","), " rows")
message("  Missing ethnicity (Not Stated): ", format(n_missing_e, big.mark = ","),
        " (", round(100 * n_missing_e / n_total, 1), "%)")

# Summary by year
year_summary <- ss |>
  group_by(financial_year) |>
  summarise(
    total_searches = sum(n_searches, na.rm = TRUE),
    n_rows = n(),
    missing_searches = sum(n_searches[is.na(ethnicity)], na.rm = TRUE),
    pct_missing_ethnicity = round(100 * missing_searches / total_searches, 1),
    .groups = "drop"
  )
message("\n  Year summary:")
print(as.data.frame(year_summary))

# =============================================================================
# 2. CENSUS DATA
# =============================================================================

message("\n--- Loading census 2021 data ---")

census_raw <- read_csv(
  file.path(raw_dir, "population-by-ethnicity-and-region-2021.csv"),
  show_col_types = FALSE
) |> clean_names()

# Keep only the 5 main ethnic groups at regional level (not national "All")
census <- census_raw |>
  filter(
    ethnicity %in% c("Asian", "Black", "White", "Mixed", "Other"),
    ethnicity_type == "ONS 2021 5+1",
    geography != "All - England And Wales"
  ) |>
  select(
    region_clean = geography,
    ethnicity,
    population = ethnic_population,
    region_population = regional_population
  ) |>
  mutate(
    population = as.numeric(population),
    region_population = as.numeric(region_population)
  )

message("  Census rows: ", nrow(census))
message("  Regions: ", paste(sort(unique(census$region_clean)), collapse = ", "))
message("  Ethnicities: ", paste(sort(unique(census$ethnicity)), collapse = ", "))

# Verify total population
total_pop <- census |>
  group_by(region_clean) |>
  summarise(total = sum(population), .groups = "drop")
message("\n  Regional population totals:")
print(as.data.frame(total_pop))

# =============================================================================
# 3. MERGE: Aggregate stop-search by year/region/ethnicity and join census
# =============================================================================

message("\n--- Creating merged rates dataset ---")

# Aggregate searches (excluding missing ethnicity)
ss_agg <- ss |>
  filter(!is.na(ethnicity)) |>
  group_by(financial_year, region_clean, ethnicity) |>
  summarise(
    total_searches = sum(n_searches, na.rm = TRUE),
    .groups = "drop"
  )

# Merge with census population
merged <- ss_agg |>
  left_join(census, by = c("region_clean", "ethnicity")) |>
  mutate(
    rate_per_1000 = total_searches / population * 1000
  )

# Check for unmatched rows
n_unmatched <- sum(is.na(merged$population))
if (n_unmatched > 0) {
  warning("  ", n_unmatched, " rows with no census match!")
  message("  Unmatched region/ethnicity combos:")
  print(merged |> filter(is.na(population)) |> select(region_clean, ethnicity) |> distinct())
} else {
  message("  All rows matched with census data.")
}

# =============================================================================
# 4. SAVE
# =============================================================================

message("\n--- Saving processed data ---")

write_csv(ss, file.path(out_dir, "stop_search_clean.csv"))
message("  Saved: stop_search_clean.csv (", format(nrow(ss), big.mark = ","), " rows)")

write_csv(census, file.path(out_dir, "census_clean.csv"))
message("  Saved: census_clean.csv (", nrow(census), " rows)")

write_csv(merged, file.path(out_dir, "merged_rates.csv"))
message("  Saved: merged_rates.csv (", nrow(merged), " rows)")

# =============================================================================
# 5. QUICK DISPARITY CHECK
# =============================================================================

message("\n--- Quick disparity check (latest year) ---")

latest <- merged |>
  filter(financial_year == max(financial_year)) |>
  group_by(ethnicity) |>
  summarise(
    total_searches = sum(total_searches),
    total_population = sum(population),
    rate_per_1000 = total_searches / total_population * 1000,
    .groups = "drop"
  ) |>
  mutate(
    ratio_vs_white = rate_per_1000 / rate_per_1000[ethnicity == "White"]
  )

print(as.data.frame(latest))

message("\n=== 01_load_and_clean.R: COMPLETE ===")
