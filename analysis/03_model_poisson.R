# =============================================================================
# 03_model_poisson.R
# Quasi-Poisson GLM with population offset for rate modelling.
#
# This is the SINGLE source of truth for all regression results used in the
# report (results.qmd, discussion.qmd, conclusion.qmd) and the dashboard.
#
# Models fitted:
#   1. Pooled main-effects model (all years)
#   2. Pooled interaction model with ethnicity × financial_year
#   3. Per-year models for the IRR time-series
#
# Input:  data/processed/stop_search_clean.csv, data/processed/census_clean.csv
# Output: analysis/output/irr_table.csv          – pooled main-effects IRRs
#         analysis/output/irr_interaction_table.csv – interaction model IRRs
#         analysis/output/yearly_irr.csv          – per-year ethnicity IRRs
#         analysis/output/model_summary.txt       – printed model summary
#         analysis/output/model_pooled.rds        – serialised pooled model
#         analysis/output/model_interaction.rds   – serialised interaction model
#         analysis/output/model_diagnostics.csv   – key diagnostics
#         analysis/output/combined_effects.csv    – combined coef predictions
# =============================================================================

library(tidyverse)
library(broom)

out_dir <- "analysis/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

message("=== 03_model_poisson.R: Quasi-Poisson GLM ===\n")

# --- Load and prepare modelling dataset ---------------------------------------

ss     <- read_csv("data/processed/stop_search_clean.csv", show_col_types = FALSE)
census <- read_csv("data/processed/census_clean.csv", show_col_types = FALSE)

# Aggregate by: year × region × ethnicity × sex × age_binary × reason_binary
model_data <- ss |>
  filter(
    !is.na(ethnicity),
    !is.na(age_under25),
    sex %in% c("Male", "Female")
  ) |>
  group_by(financial_year, region_clean, ethnicity, sex, age_under25, reason_drugs) |>
  summarise(
    count = sum(n_searches, na.rm = TRUE),
    .groups = "drop"
  ) |>
  # Join census population (by region + ethnicity only — population offset)
  left_join(census, by = c("region_clean", "ethnicity")) |>
  filter(!is.na(population), population > 0) |>
  # Convert to factors with explicit reference levels
  mutate(
    financial_year = factor(financial_year),
    region_clean   = factor(region_clean),
    ethnicity      = relevel(factor(ethnicity), ref = "White"),
    sex            = relevel(factor(sex), ref = "Female"),
    age_under25    = factor(age_under25, labels = c("25+", "Under 25")),
    reason_drugs   = factor(reason_drugs, labels = c("Other", "Drugs"))
  )

message("  Model dataset: ", format(nrow(model_data), big.mark = ","), " rows")
message("  Total searches: ", format(sum(model_data$count), big.mark = ","))

# =============================================================================
# MODEL 1: Pooled main-effects model (all years, no interaction)
# =============================================================================

message("\n--- Fitting main-effects Poisson GLM ---")

fit_poisson <- glm(
  count ~ financial_year + region_clean + ethnicity + sex + age_under25 + reason_drugs,
  family = poisson(link = "log"),
  offset = log(population),
  data = model_data
)

# --- Overdispersion check ----------------------------------------------------

dispersion <- sum(residuals(fit_poisson, type = "pearson")^2) / fit_poisson$df.residual
message("  Dispersion parameter: ", round(dispersion, 2))

if (dispersion > 2) {
  message("  Overdispersion detected (", round(dispersion, 1), "). Using Quasi-Poisson.")
  fit_pooled <- glm(
    count ~ financial_year + region_clean + ethnicity + sex + age_under25 + reason_drugs,
    family = quasipoisson(link = "log"),
    offset = log(population),
    data = model_data
  )
  model_type <- "Quasi-Poisson"
} else {
  fit_pooled <- fit_poisson
  model_type <- "Poisson"
}

message("  Using: ", model_type)

# --- Extract IRR (Incidence Rate Ratios) for pooled model --------------------

message("\n--- Extracting pooled IRRs ---")

coef_summary <- summary(fit_pooled)$coefficients
irr_table <- tibble(
  term = rownames(coef_summary),
  estimate = coef_summary[, "Estimate"],
  std_error = coef_summary[, "Std. Error"],
  irr = exp(coef_summary[, "Estimate"]),
  irr_lower = exp(coef_summary[, "Estimate"] - 1.96 * coef_summary[, "Std. Error"]),
  irr_upper = exp(coef_summary[, "Estimate"] + 1.96 * coef_summary[, "Std. Error"])
)

message("\n  Key IRRs (Incidence Rate Ratios):")
key_terms <- irr_table |>
  filter(grepl("ethnicity|sex|age|reason", term, ignore.case = TRUE)) |>
  mutate(across(c(irr, irr_lower, irr_upper), \(x) round(x, 3)))
print(as.data.frame(key_terms |> select(term, irr, irr_lower, irr_upper)))

write_csv(irr_table, file.path(out_dir, "irr_table.csv"))
saveRDS(fit_pooled, file.path(out_dir, "model_pooled.rds"))
message("  Saved: irr_table.csv, model_pooled.rds")

# =============================================================================
# MODEL 2: Interaction model — ethnicity × financial_year
# =============================================================================

message("\n--- Fitting interaction model: ethnicity × financial_year ---")

fit_interaction <- glm(
  count ~ financial_year * ethnicity + region_clean + sex + age_under25 + reason_drugs,
  family = quasipoisson(link = "log"),
  offset = log(population),
  data = model_data
)

dispersion_int <- sum(residuals(fit_interaction, type = "pearson")^2) / fit_interaction$df.residual
message("  Interaction model dispersion: ", round(dispersion_int, 2))

# Compare models via F-test (valid for quasi-Poisson nested models)
anova_test <- anova(fit_pooled, fit_interaction, test = "F")
f_pval <- anova_test$`Pr(>F)`[2]
message("  F-test (main vs interaction): p = ", signif(f_pval, 4))

# Extract interaction IRRs
coef_int <- summary(fit_interaction)$coefficients
irr_interaction <- tibble(
  term = rownames(coef_int),
  estimate = coef_int[, "Estimate"],
  std_error = coef_int[, "Std. Error"],
  irr = exp(coef_int[, "Estimate"]),
  irr_lower = exp(coef_int[, "Estimate"] - 1.96 * coef_int[, "Std. Error"]),
  irr_upper = exp(coef_int[, "Estimate"] + 1.96 * coef_int[, "Std. Error"])
)

write_csv(irr_interaction, file.path(out_dir, "irr_interaction_table.csv"))
saveRDS(fit_interaction, file.path(out_dir, "model_interaction.rds"))
message("  Saved: irr_interaction_table.csv, model_interaction.rds")

# =============================================================================
# MODEL 3: Per-year models (disparity trend — independent confirmation)
# =============================================================================

message("\n--- Fitting per-year models (disparity trend) ---")

yearly_irr <- map_dfr(levels(model_data$financial_year), function(yr) {
  d <- model_data |> filter(financial_year == yr)
  fit <- glm(
    count ~ region_clean + ethnicity + sex + age_under25 + reason_drugs,
    family = quasipoisson(link = "log"),
    offset = log(population),
    data = d
  )
  coefs <- summary(fit)$coefficients
  tibble(
    financial_year = yr,
    term = rownames(coefs),
    irr = exp(coefs[, "Estimate"]),
    irr_lower = exp(coefs[, "Estimate"] - 1.96 * coefs[, "Std. Error"]),
    irr_upper = exp(coefs[, "Estimate"] + 1.96 * coefs[, "Std. Error"])
  ) |>
    filter(grepl("ethnicity", term))
})

message("\n  Black IRR trend across years:")
yearly_irr |>
  filter(term == "ethnicityBlack") |>
  mutate(across(c(irr, irr_lower, irr_upper), \(x) round(x, 2))) |>
  select(financial_year, irr, irr_lower, irr_upper) |>
  print()

write_csv(yearly_irr, file.path(out_dir, "yearly_irr.csv"))

# =============================================================================
# DIAGNOSTICS & COMBINED EFFECTS
# =============================================================================

message("\n--- Computing diagnostics and combined effects ---")

# Pseudo R² (McFadden / Cohen)
pseudoR2_pooled <- 1 - (fit_pooled$deviance / fit_pooled$null.deviance)
pseudoR2_interaction <- 1 - (fit_interaction$deviance / fit_interaction$null.deviance)

diagnostics <- tibble(
  model = c("pooled_main_effects", "interaction_ethnicity_year"),
  model_family = model_type,
  dispersion = c(round(dispersion, 2), round(dispersion_int, 2)),
  pseudo_r2 = c(round(pseudoR2_pooled, 4), round(pseudoR2_interaction, 4)),
  null_deviance = c(fit_pooled$null.deviance, fit_interaction$null.deviance),
  residual_deviance = c(fit_pooled$deviance, fit_interaction$deviance),
  df_residual = c(fit_pooled$df.residual, fit_interaction$df.residual),
  n_obs = c(nrow(model_data), nrow(model_data)),
  interaction_f_pval = c(NA, f_pval)
)
write_csv(diagnostics, file.path(out_dir, "model_diagnostics.csv"))

# Combined effects from the pooled model:
# Black male under-25 drug stop (all relative to White female 25+ non-drug)
raw_coefs <- tidy(fit_pooled, exponentiate = FALSE)

get_coef <- function(term_name) {
  val <- raw_coefs |> filter(term == term_name) |> pull(estimate)
  if (length(val) == 0) 0 else val
}

# Combined effect: Black + Male + Drugs (London is NOT reference here, so no
# region term needed — the combined effect is relative to the reference cell)
combined_black_male_drug <- round(exp(
  get_coef("ethnicityBlack") + get_coef("sexMale") + get_coef("reason_drugsDrugs")
), 2)

# Combined effect: Black + Male + Under 25 + Drugs
combined_black_male_u25_drug <- round(exp(
  get_coef("ethnicityBlack") + get_coef("sexMale") +
  get_coef("age_under25Under 25") + get_coef("reason_drugsDrugs")
), 2)

# Effect: Black + Drugs only (for comparison with white non-drug)
combined_black_drug <- round(exp(
  get_coef("ethnicityBlack") + get_coef("reason_drugsDrugs")
), 2)

combined_effects <- tibble(
  effect = c(
    "black_male_drug",
    "black_male_u25_drug",
    "black_drug"
  ),
  description = c(
    "Black male drug stop vs White female 25+ non-drug",
    "Black male under-25 drug stop vs White female 25+ non-drug",
    "Black drug stop vs White non-drug (sex/age at reference)"
  ),
  rate_ratio = c(
    combined_black_male_drug,
    combined_black_male_u25_drug,
    combined_black_drug
  )
)

message("\n  Combined effects (rate ratios vs reference cell):")
print(as.data.frame(combined_effects))

write_csv(combined_effects, file.path(out_dir, "combined_effects.csv"))

# =============================================================================
# SAVE MODEL SUMMARY
# =============================================================================

sink(file.path(out_dir, "model_summary.txt"))
cat("=== ", model_type, " GLM Summary (Pooled Main Effects) ===\n\n")
cat("Dispersion parameter:", round(dispersion, 2), "\n\n")
print(summary(fit_pooled))
cat("\n\n=== Interaction Model: ethnicity × financial_year ===\n\n")
cat("Dispersion parameter:", round(dispersion_int, 2), "\n\n")
print(summary(fit_interaction))
cat("\n\n=== F-test: Main Effects vs Interaction ===\n\n")
print(anova_test)
cat("\n\nPseudo R² (pooled):", round(pseudoR2_pooled, 4), "\n")
cat("Pseudo R² (interaction):", round(pseudoR2_interaction, 4), "\n")
sink()

message("\n=== 03_model_poisson.R: COMPLETE ===")
