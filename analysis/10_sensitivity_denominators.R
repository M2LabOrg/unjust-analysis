# =============================================================================
# 10_sensitivity_denominators.R
# Sensitivity analysis: finer population denominators.
#
# The main models (03_model_poisson.R) use Census 2021 population by region
# and ethnic group as the offset. This script refits the pooled and per-year
# quasi-Poisson models with population by region x ethnic group x sex x age
# band (under 25 / 25 and over) as the offset, so that the ethnicity rate
# ratios compare searches per resident of the same sex and age band.
# Reason for search has no population equivalent and stays a count split.
#
# It also tests the change in the Black/White rate ratio between the first
# and last years (2020/21 and 2024/25) under each offset, using the per-year
# fits: z = (log IRR_last - log IRR_first) / sqrt(se_first^2 + se_last^2).
#
# Run from the repository root:
#   Rscript data/download_census_fine.R      (only if the CSV is missing)
#   Rscript analysis/10_sensitivity_denominators.R
#
# Input:  analysis/output/model_pooled.rds (the cells of the pooled model)
#         data/processed/census_clean.csv
#         data/raw/census2021_region_ethnicity_sex_age.csv
# Output: analysis/output/sensitivity_denominators.csv
#         analysis/output/sensitivity_denominators_population.csv
#         analysis/output/sensitivity_denominators_yearly.csv
#         analysis/output/sensitivity_denominators_trend.csv
# =============================================================================

library(tidyverse)

out_dir <- "analysis/output"

message("=== 10_sensitivity_denominators.R ===\n")

# --- Census by region x ethnicity x sex x age band ---------------------------
# Ethnic groups mapped to the five categories used in 01_load_and_clean.R;
# "Does not apply" is dropped. Under 25 = single years of age 0 to 24,
# matching the "Under 10", "10-17" and "18-24" search categories.

eth_map <- c(
  "Asian, Asian British or Asian Welsh"                      = "Asian",
  "Black, Black British, Black Welsh, Caribbean or African"  = "Black",
  "Mixed or Multiple ethnic groups"                          = "Mixed",
  "Other ethnic group"                                       = "Other",
  "White"                                                    = "White"
)

census_fine <- read_csv("data/raw/census2021_region_ethnicity_sex_age.csv",
                        show_col_types = FALSE) |>
  filter(ethnic_group %in% names(eth_map)) |>
  mutate(
    region_clean = region,
    ethnicity    = unname(eth_map[ethnic_group]),
    age_under25  = as.integer(age_code) < 25
  ) |>
  group_by(region_clean, ethnicity, sex, age_under25) |>
  summarise(population_fine = sum(population), .groups = "drop")

# Check against the region x ethnicity table used in the main models. The two
# ONS tables are published separately and differ slightly (statistical
# disclosure control), so report the differences rather than require equality.
census <- read_csv("data/processed/census_clean.csv", show_col_types = FALSE)
check <- census |>
  left_join(census_fine |>
              group_by(region_clean, ethnicity) |>
              summarise(fine_total = sum(population_fine), .groups = "drop"),
            by = c("region_clean", "ethnicity")) |>
  mutate(diff = fine_total - population)
stopifnot(!anyNA(check$fine_total))
message("  Region x ethnicity totals: all ", nrow(check), " cells present; ",
        sum(check$diff != 0), " differ, by at most ", max(abs(check$diff)),
        " residents (at most ",
        signif(100 * max(abs(check$diff) / check$population), 2), "% of a cell)")

# --- Modelling data: the 1,971 cells of the pooled model ---------------------
# Taken from the saved model, so the baseline is exactly the reported fit
# (data/processed/stop_search_clean.csv is not kept in the repository).

model_data <- readRDS(file.path(out_dir, "model_pooled.rds"))$data |>
  mutate(age_under25_lgl = age_under25 == "Under 25") |>
  left_join(census_fine |> mutate(sex = as.character(sex)),
            by = c("region_clean", "ethnicity", "sex",
                   "age_under25_lgl" = "age_under25")) |>
  mutate(
    financial_year = factor(financial_year),
    region_clean   = factor(region_clean),
    ethnicity      = relevel(factor(ethnicity), ref = "White"),
    sex            = relevel(factor(sex), ref = "Female")
  )
stopifnot(!anyNA(model_data$population_fine), all(model_data$population_fine > 0))

# Offsets split by sex only and by age band only, to separate the two parts
census_sex <- census_fine |>
  group_by(region_clean, ethnicity, sex) |>
  summarise(population_sex = sum(population_fine), .groups = "drop")
census_age <- census_fine |>
  group_by(region_clean, ethnicity, age_under25) |>
  summarise(population_age = sum(population_fine), .groups = "drop")
model_data <- model_data |>
  left_join(census_sex |> mutate(sex = as.character(sex)),
            by = c("region_clean", "ethnicity", "sex")) |>
  left_join(census_age, by = c("region_clean", "ethnicity",
                               "age_under25_lgl" = "age_under25")) |>
  mutate(ethnicity = relevel(factor(as.character(ethnicity)), ref = "White"))
stopifnot(!anyNA(model_data$population_sex), !anyNA(model_data$population_age))

message("  Model dataset: ", nrow(model_data), " cells")

# --- Fit both offsets --------------------------------------------------------

offsets <- c("population"      = "region x ethnicity",
             "population_fine" = "region x ethnicity x sex x age")
offsets_parts <- c(offsets,
                   "population_sex" = "region x ethnicity x sex",
                   "population_age" = "region x ethnicity x age")

rhs <- "financial_year + region_clean + ethnicity + sex + age_under25 + reason_drugs"

fit_offset <- function(d, offset_var, formula_rhs) {
  glm(as.formula(paste("count ~", formula_rhs)),
      family = quasipoisson(link = "log"),
      offset = log(d[[offset_var]]), data = d)
}

irr_tbl <- function(fit) {
  cs <- summary(fit)$coefficients
  tibble(
    term      = rownames(cs),
    log_irr   = cs[, "Estimate"],
    se        = cs[, "Std. Error"],
    irr       = exp(cs[, "Estimate"]),
    irr_lower = exp(cs[, "Estimate"] - 1.96 * cs[, "Std. Error"]),
    irr_upper = exp(cs[, "Estimate"] + 1.96 * cs[, "Std. Error"])
  )
}

disp <- function(fit) sum(residuals(fit, type = "pearson")^2) / fit$df.residual

pooled <- imap_dfr(offsets_parts, function(label, off) {
  fit <- fit_offset(model_data, off, rhs)
  irr_tbl(fit) |>
    filter(term != "(Intercept)") |>
    bind_rows(tibble(term = "dispersion", irr = disp(fit))) |>
    mutate(offset = label)
}) |>
  select(term, offset, irr, irr_lower, irr_upper) |>
  # 6 decimals, so that rounding to 2 later is not a double rounding
  mutate(across(c(irr, irr_lower, irr_upper), \(x) round(x, 6)))

print(as.data.frame(pooled |>
  filter(grepl("ethnicity|sex|age|reason|dispersion", term))), row.names = FALSE)

write_csv(pooled, file.path(out_dir, "sensitivity_denominators.csv"))

# Sex and age structure of each ethnic group (England and Wales)
population_structure <- census_fine |>
  group_by(ethnicity) |>
  summarise(
    share_male    = sum(population_fine[sex == "Male"]) / sum(population_fine),
    share_under25 = sum(population_fine[age_under25]) / sum(population_fine)
  ) |>
  mutate(across(starts_with("share"), \(x) round(x, 3)))
print(as.data.frame(population_structure), row.names = FALSE)
write_csv(population_structure,
          file.path(out_dir, "sensitivity_denominators_population.csv"))

# --- Per-year models ---------------------------------------------------------

rhs_year <- "region_clean + ethnicity + sex + age_under25 + reason_drugs"

yearly_full <- map_dfr(levels(model_data$financial_year), function(yr) {
  d <- model_data |> filter(financial_year == yr)
  imap_dfr(offsets, function(label, off) {
    irr_tbl(fit_offset(d, off, rhs_year)) |> mutate(offset = label)
  }) |>
    filter(grepl("ethnicity", term)) |>
    mutate(financial_year = yr)
})

yearly <- yearly_full |>
  select(term, irr, irr_lower, irr_upper, offset, financial_year) |>
  mutate(across(c(irr, irr_lower, irr_upper), \(x) round(x, 6)))

message("\n  Black/White by year:")
print(as.data.frame(yearly |> filter(term == "ethnicityBlack") |>
  select(financial_year, offset, irr, irr_lower, irr_upper)), row.names = FALSE)

write_csv(yearly, file.path(out_dir, "sensitivity_denominators_yearly.csv"))

# --- Change between the first and last years ---------------------------------
# Separate per-year fits are independent, so the variance of the difference
# in log IRRs is the sum of the two variances.

years <- levels(model_data$financial_year)
first_year <- years[1]
last_year  <- years[length(years)]

trend <- yearly_full |>
  filter(term == "ethnicityBlack", financial_year %in% c(first_year, last_year)) |>
  select(offset, financial_year, log_irr, se, irr) |>
  pivot_wider(names_from = financial_year, values_from = c(log_irr, se, irr)) |>
  transmute(
    offset,
    year_first = first_year,
    year_last  = last_year,
    irr_first  = .data[[paste0("irr_", first_year)]],
    irr_last   = .data[[paste0("irr_", last_year)]],
    ratio      = irr_last / irr_first,
    z          = (.data[[paste0("log_irr_", last_year)]] -
                    .data[[paste0("log_irr_", first_year)]]) /
                 sqrt(.data[[paste0("se_", first_year)]]^2 +
                        .data[[paste0("se_", last_year)]]^2),
    p_value    = 2 * pnorm(-abs(z))
  ) |>
  mutate(across(c(irr_first, irr_last, ratio, z), \(x) round(x, 6)),
         p_value = round(p_value, 6))

message("\n  Black/White change, ", first_year, " to ", last_year, ":")
print(as.data.frame(trend), row.names = FALSE)

write_csv(trend, file.path(out_dir, "sensitivity_denominators_trend.csv"))

message("\n=== 10_sensitivity_denominators.R: COMPLETE ===")
