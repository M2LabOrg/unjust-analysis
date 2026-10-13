# report/data/getData.R
#
# Data-loading functions for the UNJUST report.
# Updated to read from the monorepo data/raw/ directory, using the full
# five-year release (2020/21 – 2024/25).
#
# API is backwards-compatible with the legacy load_data_legacy.R used in
# the original report, so existing results.qmd code continues to work.

library(tidyverse)
library(readODS)

# ---------------------------------------------------------------------------
# Stop and Search data
# ---------------------------------------------------------------------------

load_stop_search_data <- function(desired_sheet = "open_data",
                                  print_info    = FALSE,
                                  download      = FALSE) {

  f <- "../data/raw/stop-search-open-data-tables-mar21-mar25.ods"

  stop_search_data <- readODS::read_ods(f, sheet = desired_sheet)

  if (print_info) {
    cat("Stop and search data loaded\n")
    cat("  Rows  :", format(nrow(stop_search_data), big.mark = ","), "\n")
    cat("  Years :", paste(sort(unique(stop_search_data$financial_year)), collapse = ", "), "\n")
  }

  return(stop_search_data)
}


# ---------------------------------------------------------------------------
# Census 2021 data
# ---------------------------------------------------------------------------

load_census_data <- function(print_info = FALSE, download = FALSE) {

  f <- "../data/raw/population-by-ethnicity-and-region-2021.csv"

  data <- read_csv(f, show_col_types = FALSE)

  # Keep only ONS 2021 5+1 classification and exclude the all-England aggregate
  data_filter <- data %>%
    filter(Ethnicity_type == "ONS 2021 5+1",
           Geography != "All - England And Wales") %>%
    select(Geography_code, Geography, Ethnicity, `Ethnic Population`) %>%
    rename(regions_code      = Geography_code,
           region             = Geography,
           ethnic_group_code  = Ethnicity,
           population         = `Ethnic Population`)

  # Harmonise naming to match the stop-and-search levels
  data_filter <- data_filter %>%
    mutate(
      region = str_replace(region, "Yorkshire and The Humber", "Yorkshire and the Humber"),
      region = str_replace(region, "East of England",          "Eastern"),
      ethnic_group_code = case_when(
        ethnic_group_code == "Asian" ~ "Asian or Asian British",
        ethnic_group_code == "Black" ~ "Black or Black British",
        ethnic_group_code == "Other" ~ "Other Ethnic Group",
        TRUE                         ~ ethnic_group_code
      )
    )

  data_filter$ethnic_group_code <- as.factor(data_filter$ethnic_group_code)
  data_filter$region             <- as.factor(data_filter$region)

  if (print_info) print(head(data_filter))

  return(data_filter)
}
