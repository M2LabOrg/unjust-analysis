# =============================================================================
# 08_sensitivity.R
# Sensitivity analysis: stability of ethnicity IRRs across model specifications.
#
# Three checks:
#   1. Leave-one-covariate-out: drop each non-ethnicity covariate in turn and
#      compare Black/White, Asian/White, Mixed/White, Other/White IRRs.
#   2. Bootstrap 95% confidence intervals (B = 500) for ethnicity IRRs from
#      the full model, as a non-parametric alternative to the normal approximation.
#   3. Poisson vs Quasi-Poisson: compare point estimates and SEs to confirm
#      that the dispersion correction does not alter conclusions.
#
# Run from the repository root:
#   Rscript analysis/08_sensitivity.R
#
# Input:  data/processed/stop_search_clean.csv
#         data/processed/census_clean.csv
# Output: analysis/output/sensitivity_loocv.csv
#         analysis/output/sensitivity_bootstrap.csv
#         analysis/output/sensitivity_poisson_vs_qp.csv
#         analysis/output/figures/sensitivity_irr_stability.png
#         analysis/output/figures/sensitivity_bootstrap_ci.png
# =============================================================================

library(tidyverse)
library(ggplot2)

out_dir <- "analysis/output"
fig_dir <- "analysis/output/figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

message("=== 08_sensitivity.R: Sensitivity Analysis ===\n")

# --- Load modelling dataset from the saved model object ----------------------
# stop_search_clean.csv is gitignored (large). The fitted model stored in
# model_pooled.rds contains the complete model frame and offset, so we
# extract from there rather than rebuilding from raw data.

fit_pooled <- readRDS(file.path(out_dir, "model_pooled.rds"))

model_data        <- fit_pooled$model
model_data$log_pop <- fit_pooled$offset    # log(population) used as offset

message("  Modelling dataset: ", format(nrow(model_data), big.mark = ","), " rows")

# Ethnicity terms we track across all specifications
eth_terms <- c("ethnicityAsian", "ethnicityBlack", "ethnicityMixed", "ethnicityOther")
eth_labels <- c("Asian", "Black", "Mixed", "Other")

fit_and_extract <- function(formula, family, data, spec_label) {
  fit <- glm(formula, family = family, offset = log_pop, data = data)
  coefs <- summary(fit)$coefficients
  tibble(
    specification = spec_label,
    term          = rownames(coefs),
    irr           = exp(coefs[, "Estimate"]),
    irr_lower     = exp(coefs[, "Estimate"] - 1.96 * coefs[, "Std. Error"]),
    irr_upper     = exp(coefs[, "Estimate"] + 1.96 * coefs[, "Std. Error"])
  ) |> filter(term %in% eth_terms)
}

# =============================================================================
# CHECK 1: Leave-one-covariate-out
# =============================================================================

message("\n--- Check 1: Leave-one-covariate-out ---")

base_formula  <- count ~ financial_year + region_clean + ethnicity + sex + age_under25 + reason_drugs
qp            <- quasipoisson(link = "log")

specs <- list(
  "Full model (reference)"        = base_formula,
  "Drop financial_year"           = count ~ region_clean + ethnicity + sex + age_under25 + reason_drugs,
  "Drop region"                   = count ~ financial_year + ethnicity + sex + age_under25 + reason_drugs,
  "Drop sex"                      = count ~ financial_year + region_clean + ethnicity + age_under25 + reason_drugs,
  "Drop age group"                = count ~ financial_year + region_clean + ethnicity + sex + reason_drugs,
  "Drop reason (drugs)"           = count ~ financial_year + region_clean + ethnicity + sex + age_under25
)

loocv_results <- map_dfr(names(specs), function(nm) {
  message("  Fitting: ", nm)
  fit_and_extract(specs[[nm]], qp, model_data, nm)
})

loocv_results <- loocv_results |>
  mutate(
    ethnicity_group = recode(term,
      "ethnicityAsian" = "Asian",
      "ethnicityBlack" = "Black",
      "ethnicityMixed" = "Mixed",
      "ethnicityOther" = "Other"
    ),
    across(c(irr, irr_lower, irr_upper), \(x) round(x, 3))
  )

message("\n  Black/White IRR across specifications:")
loocv_results |>
  filter(ethnicity_group == "Black") |>
  select(specification, irr, irr_lower, irr_upper) |>
  print(n = Inf)

write_csv(loocv_results, file.path(out_dir, "sensitivity_loocv.csv"))
message("  Saved: sensitivity_loocv.csv")

# --- Plot 1: IRR stability forest plot ----------------------------------------

spec_order <- rev(names(specs))

p1 <- loocv_results |>
  mutate(specification = factor(specification, levels = spec_order)) |>
  ggplot(aes(x = irr, y = specification, colour = ethnicity_group,
             xmin = irr_lower, xmax = irr_upper)) +
  geom_vline(xintercept = 1, linetype = "dashed", colour = "grey50") +
  geom_errorbarh(height = 0.3, alpha = 0.7, linewidth = 0.6,
                 position = position_dodge(width = 0.5)) +
  geom_point(size = 2, position = position_dodge(width = 0.5)) +
  scale_colour_brewer(palette = "Set1", name = "Ethnicity group") +
  scale_x_continuous(breaks = seq(0, ceiling(max(loocv_results$irr_upper)), by = 1)) +
  labs(
    title    = "Ethnicity IRRs across Model Specifications",
    subtitle = "Points: IRR relative to White. Horizontal bars: 95% confidence intervals.",
    x        = "Incidence rate ratio (vs White)",
    y        = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title    = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave(file.path(fig_dir, "sensitivity_irr_stability.png"),
       p1, width = 9, height = 6, dpi = 150)
message("  Saved: sensitivity_irr_stability.png")

# =============================================================================
# CHECK 2: Bootstrap confidence intervals (B = 500)
# =============================================================================

message("\n--- Check 2: Bootstrap CIs (B = 500) ---")
set.seed(2024)
B <- 500
n <- nrow(model_data)

boot_coefs <- matrix(NA_real_, nrow = B, ncol = length(eth_terms),
                     dimnames = list(NULL, eth_terms))

for (b in seq_len(B)) {
  if (b %% 100 == 0) message("  Bootstrap iteration ", b, " / ", B)
  boot_idx  <- sample(n, n, replace = TRUE)
  boot_data <- model_data[boot_idx, ]
  # Drop any stratum combinations that have zero variance in outcome after
  # resampling (very rare but prevents GLM warnings)
  tryCatch({
    fit_b <- glm(base_formula, family = qp, offset = log_pop,
                 data = boot_data)
    coefs_b <- coef(fit_b)
    for (term in eth_terms) {
      if (term %in% names(coefs_b)) {
        boot_coefs[b, term] <- coefs_b[term]
      }
    }
  }, error = function(e) NULL)
}

# Remove any failed iterations (NA rows)
boot_coefs <- boot_coefs[complete.cases(boot_coefs), ]
message("  Successful bootstrap iterations: ", nrow(boot_coefs))

# Full-model point estimates for comparison
fit_full <- glm(base_formula, family = qp, offset = log_pop, data = model_data)
full_coefs <- coef(fit_full)

bootstrap_ci <- tibble(
  term          = eth_terms,
  ethnicity     = eth_labels,
  irr_point     = round(exp(full_coefs[eth_terms]), 3),
  irr_normal_lo = round(exp(full_coefs[eth_terms] -
                             1.96 * summary(fit_full)$coefficients[eth_terms, "Std. Error"]), 3),
  irr_normal_hi = round(exp(full_coefs[eth_terms] +
                             1.96 * summary(fit_full)$coefficients[eth_terms, "Std. Error"]), 3),
  irr_boot_lo   = round(exp(apply(boot_coefs, 2, quantile, 0.025, na.rm = TRUE)[eth_terms]), 3),
  irr_boot_hi   = round(exp(apply(boot_coefs, 2, quantile, 0.975, na.rm = TRUE)[eth_terms]), 3)
)

message("\n  Bootstrap vs normal-approximation CIs:")
print(as.data.frame(bootstrap_ci))

write_csv(bootstrap_ci, file.path(out_dir, "sensitivity_bootstrap.csv"))
message("  Saved: sensitivity_bootstrap.csv")

# --- Plot 2: Bootstrap vs normal CI comparison --------------------------------

p2_data <- bootstrap_ci |>
  pivot_longer(
    cols      = c(irr_normal_lo, irr_normal_hi, irr_boot_lo, irr_boot_hi),
    names_to  = c("ci_type", "bound"),
    names_pattern = "irr_(normal|boot)_(lo|hi)"
  ) |>
  pivot_wider(names_from = bound, values_from = value) |>
  mutate(
    ci_type   = recode(ci_type, "normal" = "Normal approximation", "boot" = "Bootstrap (B = 500)"),
    ethnicity = factor(ethnicity, levels = rev(eth_labels))
  )

p2 <- ggplot(p2_data, aes(y = ethnicity, colour = ci_type)) +
  geom_vline(xintercept = 1, linetype = "dashed", colour = "grey50") +
  geom_errorbarh(aes(xmin = lo, xmax = hi),
                 height = 0.25, linewidth = 0.8,
                 position = position_dodge(width = 0.5)) +
  geom_point(aes(x = irr_point),
             size = 3, shape = 18,
             position = position_dodge(width = 0.5)) +
  scale_colour_manual(
    values = c("Normal approximation" = "steelblue4", "Bootstrap (B = 500)" = "darkorange"),
    name   = "CI method"
  ) +
  labs(
    title    = "Bootstrap vs Normal-Approximation Confidence Intervals",
    subtitle = "Diamond: point estimate. Bars: 95% CIs by two methods.",
    x        = "Incidence rate ratio (vs White)",
    y        = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title      = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave(file.path(fig_dir, "sensitivity_bootstrap_ci.png"),
       p2, width = 7, height = 5, dpi = 150)
message("  Saved: sensitivity_bootstrap_ci.png")

# =============================================================================
# CHECK 3: Poisson vs Quasi-Poisson SEs
# =============================================================================

message("\n--- Check 3: Poisson vs Quasi-Poisson ---")

fit_pois <- glm(base_formula, family = poisson(link = "log"),
                offset = log_pop, data = model_data)

coefs_pois <- summary(fit_pois)$coefficients
coefs_qp   <- summary(fit_full)$coefficients

pois_vs_qp <- tibble(
  term          = eth_terms,
  ethnicity     = eth_labels,
  irr           = round(exp(coefs_qp[eth_terms, "Estimate"]), 3),
  se_poisson    = round(coefs_pois[eth_terms, "Std. Error"], 4),
  se_quasipoisson = round(coefs_qp[eth_terms, "Std. Error"], 4),
  se_ratio      = round(
    coefs_qp[eth_terms, "Std. Error"] / coefs_pois[eth_terms, "Std. Error"], 2
  ),
  ci_pois_lo    = round(exp(coefs_pois[eth_terms, "Estimate"] -
                             1.96 * coefs_pois[eth_terms, "Std. Error"]), 3),
  ci_pois_hi    = round(exp(coefs_pois[eth_terms, "Estimate"] +
                             1.96 * coefs_pois[eth_terms, "Std. Error"]), 3),
  ci_qp_lo      = round(exp(coefs_qp[eth_terms, "Estimate"] -
                             1.96 * coefs_qp[eth_terms, "Std. Error"]), 3),
  ci_qp_hi      = round(exp(coefs_qp[eth_terms, "Estimate"] +
                             1.96 * coefs_qp[eth_terms, "Std. Error"]), 3)
)

message("\n  Poisson vs Quasi-Poisson comparison:")
print(as.data.frame(pois_vs_qp))

write_csv(pois_vs_qp, file.path(out_dir, "sensitivity_poisson_vs_qp.csv"))
message("  Saved: sensitivity_poisson_vs_qp.csv")

message("\n=== 08_sensitivity.R: COMPLETE ===")
