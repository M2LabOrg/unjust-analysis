# =============================================================================
# download_census_fine.R
# Download Census 2021 usual residents by region x ethnic group (6 categories)
# x sex x single year of age from the ONS Census API, and save one row per
# cell. Used by analysis/10_sensitivity_denominators.R.
#
# Source: ONS Census 2021, population type UR (usual residents)
#   https://api.beta.ons.gov.uk/v1/population-types/UR/census-observations
#   ?area-type=rgn&dimensions=ethnic_group_tb_6a,sex,resident_age_101a
# Retrieved: 13 October 2026 (the committed CSV was produced by this script)
#
# Run from the repository root:
#   Rscript data/download_census_fine.R
#
# Output: data/raw/census2021_region_ethnicity_sex_age.csv
# =============================================================================

library(jsonlite)

url <- paste0(
  "https://api.beta.ons.gov.uk/v1/population-types/UR/census-observations",
  "?area-type=rgn&dimensions=ethnic_group_tb_6a,sex,resident_age_101a"
)
out_file <- "data/raw/census2021_region_ethnicity_sex_age.csv"

message("Downloading ", url)
obs <- fromJSON(url, simplifyVector = FALSE)$observations

# Each observation lists its four dimensions in the order requested:
# region, ethnic group, sex, age
census <- do.call(rbind, lapply(obs, function(o) {
  d <- o$dimensions
  data.frame(
    region_code       = d[[1]]$option_id,
    region            = d[[1]]$option,
    ethnic_group_code = d[[2]]$option_id,
    ethnic_group      = d[[2]]$option,
    sex               = d[[3]]$option,
    age_code          = d[[4]]$option_id,
    age               = d[[4]]$option,
    population        = o$observation
  )
}))

# 10 regions (incl. Wales) x 6 ethnic group options x 2 sexes x 101 ages
stopifnot(nrow(census) == 10 * 6 * 2 * 101)

readr::write_csv(census, out_file)
message("Wrote ", nrow(census), " rows to ", out_file)
