# =============================================================================
# 09_ipw.R
# Inverse propensity weighted (IPW) estimates of ethnic disparity in
# stop and search rates.
#
# Approach:
#   1. Fit a multinomial logistic model for P(ethnicity | covariates) in the
#      searched population, weighted by search count.
#   2. Compute stabilised IPW weights for each modelling stratum.
#   3. Derive IPW-weighted stop rates and rate ratios (vs White).
#   4. Compare IPW rate ratios with the GLM IRRs from the main analysis.
#   5. Bootstrap 200 replicates to produce 95% CIs for the IPW estimates.
#
# The IPW approach models the treatment (ethnicity assignment) rather than the
# outcome (search count), providing an estimate that does not rely on the
# GLM's Poisson link or linearity assumptions.
#
# Run from the repository root:
#   Rscript analysis/09_ipw.R
#
# Input:  analysis/output/model_pooled.rds
#         analysis/output/irr_table.csv
# Output: analysis/output/ipw_rates.csv
#         analysis/output/ipw_comparison.csv
#         analysis/output/ipw_propensity_summary.csv
#         analysis/output/figures/ipw_comparison.png
#         analysis/output/figures/ipw_weights_distribution.png
# =============================================================================

library(tidyverse)
library(nnet)
library(ggplot2)

out_dir <- "analysis/output"
fig_dir <- "analysis/output/figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

message("=== 09_ipw.R: Inverse Propensity Weighting ===\n")

# --- Load data from saved model -----------------------------------------------

fit_pooled <- readRDS(file.path(out_dir, "model_pooled.rds"))
model_data <- fit_pooled$model
model_data$log_pop   <- fit_pooled$offset
model_data$population <- exp(model_data$log_pop)

message("  Modelling strata: ", format(nrow(model_data), big.mark = ","))
message("  Total searches:   ", format(sum(model_data$count), big.mark = ","))

# =============================================================================
# STEP 1: Multinomial propensity model
# P(ethnicity | financial_year, region, sex, age, reason)
# Weighted by search count so the model reflects the searched population.
# =============================================================================

message("\n--- Step 1: Multinomial propensity model ---")

set.seed(2024)
prop_model <- multinom(
  ethnicity ~ financial_year + region_clean + sex + age_under25 + reason_drugs,
  data    = model_data,
  weights = count,
  trace   = FALSE,
  maxit   = 500
)

message("  Convergence code: ", prop_model$convergence)
message("  Residual deviance: ", round(deviance(prop_model), 1))

# =============================================================================
# STEP 2: Propensity scores and stabilised weights
# =============================================================================

message("\n--- Step 2: Computing propensity scores and IPW weights ---")

pred_probs <- fitted(prop_model)       # n x 5 matrix of P(g | X)
eth_levels <- levels(model_data$ethnicity)

# Marginal probabilities: weighted proportion of each ethnicity in all searches
marginal_probs <- colSums(sweep(pred_probs, 1, model_data$count, "*")) /
                  sum(model_data$count)
message("  Marginal proportions (searched population):")
print(round(marginal_probs, 4))

# For each stratum: propensity of the observed ethnicity, and its marginal prob
obs_eth   <- as.character(model_data$ethnicity)
pscore    <- pred_probs[cbind(seq_len(nrow(model_data)), match(obs_eth, eth_levels))]
marg_p    <- marginal_probs[obs_eth]

model_data$pscore   <- pscore
model_data$marg_p   <- marg_p
model_data$ipw_raw  <- marg_p / pscore

# Trim weights at the 99th percentile to limit influence of extreme values
p99 <- quantile(model_data$ipw_raw, 0.99)
model_data$ipw <- pmin(model_data$ipw_raw, p99)

message("  Raw IPW weight range: [",
        round(min(model_data$ipw_raw), 3), ", ",
        round(max(model_data$ipw_raw), 3), "]")
message("  Trimmed at 99th pctile: ", round(p99, 3),
        " (", sum(model_data$ipw_raw > p99), " strata trimmed)")
message("  Trimmed weight range: [",
        round(min(model_data$ipw), 3), ", ",
        round(max(model_data$ipw), 3), "]")

# Propensity score summary by ethnicity
pscore_summary <- model_data |>
  group_by(ethnicity) |>
  summarise(
    n_strata      = n(),
    mean_pscore   = round(mean(pscore), 4),
    sd_pscore     = round(sd(pscore), 4),
    mean_ipw      = round(mean(ipw), 4),
    max_ipw       = round(max(ipw), 4),
    .groups = "drop"
  )
print(as.data.frame(pscore_summary))
write_csv(pscore_summary, file.path(out_dir, "ipw_propensity_summary.csv"))
message("  Saved: ipw_propensity_summary.csv")

# --- Plot: IPW weight distribution by ethnicity -------------------------------

p_weights <- ggplot(model_data, aes(x = ipw, fill = ethnicity)) +
  geom_histogram(bins = 40, colour = "white", alpha = 0.8) +
  facet_wrap(~ethnicity, scales = "free_y", ncol = 2) +
  scale_fill_brewer(palette = "Set2", guide = "none") +
  labs(
    title    = "Distribution of Stabilised IPW Weights by Ethnicity",
    subtitle = "Weights trimmed at the 99th percentile. Values near 1 indicate good covariate balance.",
    x        = "IPW weight",
    y        = "Number of strata"
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"))

ggsave(file.path(fig_dir, "ipw_weights_distribution.png"),
       p_weights, width = 8, height = 7, dpi = 150)
message("  Saved: ipw_weights_distribution.png")

# =============================================================================
# STEP 3: IPW-weighted stop rates and rate ratios
# =============================================================================

message("\n--- Step 3: IPW-weighted rates and rate ratios ---")

compute_ipw_rates <- function(data) {
  rates <- data |>
    group_by(ethnicity) |>
    summarise(
      ipw_count = sum(count * ipw),
      ipw_pop   = sum(population * ipw),
      ipw_rate  = ipw_count / ipw_pop * 1000,
      .groups   = "drop"
    )
  white_rate <- rates |> filter(ethnicity == "White") |> pull(ipw_rate)
  rates |> mutate(ipw_rr = ipw_rate / white_rate)
}

ipw_rates <- compute_ipw_rates(model_data)

message("  IPW-weighted rates per 1,000 population:")
print(as.data.frame(ipw_rates |> mutate(across(where(is.numeric), \(x) round(x, 3)))))

# =============================================================================
# STEP 4: Bootstrap 95% CIs for IPW rate ratios (B = 200)
# =============================================================================

message("\n--- Step 4: Bootstrap CIs for IPW RRs (B = 200) ---")
set.seed(2025)
B   <- 200
n   <- nrow(model_data)
eth_non_white <- c("Asian", "Black", "Mixed", "Other")

boot_rr <- matrix(NA_real_, nrow = B, ncol = length(eth_non_white),
                  dimnames = list(NULL, eth_non_white))

for (b in seq_len(B)) {
  if (b %% 50 == 0) message("  Bootstrap iteration ", b, " / ", B)
  tryCatch({
    idx  <- sample(n, n, replace = TRUE)
    bdat <- model_data[idx, ]

    bfit <- multinom(
      ethnicity ~ financial_year + region_clean + sex + age_under25 + reason_drugs,
      data = bdat, weights = count, trace = FALSE, maxit = 500
    )
    bp    <- fitted(bfit)
    beth  <- as.character(bdat$ethnicity)
    blevs <- levels(bdat$ethnicity)
    bps   <- bp[cbind(seq_len(nrow(bdat)), match(beth, blevs))]
    bmar  <- colSums(sweep(bp, 1, bdat$count, "*")) / sum(bdat$count)
    bmp   <- bmar[beth]
    bdat$ipw_raw <- bmp / bps
    bp99  <- quantile(bdat$ipw_raw, 0.99)
    bdat$ipw     <- pmin(bdat$ipw_raw, bp99)

    br <- compute_ipw_rates(bdat)
    for (g in eth_non_white) {
      boot_rr[b, g] <- br |> filter(ethnicity == g) |> pull(ipw_rr)
    }
  }, error = function(e) NULL)
}

boot_rr_clean <- boot_rr[complete.cases(boot_rr), ]
message("  Successful bootstrap iterations: ", nrow(boot_rr_clean))

# =============================================================================
# STEP 5: Comparison table: IPW vs GLM
# =============================================================================

message("\n--- Step 5: IPW vs GLM comparison ---")

irr_table <- read_csv(file.path(out_dir, "irr_table.csv"), show_col_types = FALSE)

glm_eth <- irr_table |>
  filter(grepl("^ethnicity", term)) |>
  mutate(
    ethnicity = sub("^ethnicity", "", term),
    glm_irr    = round(irr, 3),
    glm_ci_lo  = round(irr_lower, 3),
    glm_ci_hi  = round(irr_upper, 3)
  ) |>
  select(ethnicity, glm_irr, glm_ci_lo, glm_ci_hi)

ipw_point <- ipw_rates |>
  filter(ethnicity != "White") |>
  mutate(ipw_rr_pt = round(ipw_rr, 3)) |>
  select(ethnicity, ipw_rr_pt)

ipw_ci <- tibble(
  ethnicity  = eth_non_white,
  ipw_ci_lo  = round(apply(boot_rr_clean, 2, quantile, 0.025, na.rm = TRUE), 3),
  ipw_ci_hi  = round(apply(boot_rr_clean, 2, quantile, 0.975, na.rm = TRUE), 3)
)

comparison <- glm_eth |>
  left_join(ipw_point, by = "ethnicity") |>
  left_join(ipw_ci,    by = "ethnicity") |>
  arrange(desc(glm_irr))

message("\n  Comparison table:")
print(as.data.frame(comparison))

write_csv(ipw_rates,   file.path(out_dir, "ipw_rates.csv"))
write_csv(comparison,  file.path(out_dir, "ipw_comparison.csv"))
message("  Saved: ipw_rates.csv, ipw_comparison.csv")

# --- Plot: IPW vs GLM comparison forest plot ----------------------------------

plot_data <- comparison |>
  pivot_longer(
    cols      = c(glm_irr, ipw_rr_pt),
    names_to  = "method",
    values_to = "rr"
  ) |>
  mutate(
    ci_lo  = if_else(method == "glm_irr", glm_ci_lo, ipw_ci_lo),
    ci_hi  = if_else(method == "glm_irr", glm_ci_hi, ipw_ci_hi),
    method = recode(method,
      "glm_irr"    = "Quasi-Poisson GLM",
      "ipw_rr_pt"  = "IPW rate ratio"
    ),
    ethnicity = factor(ethnicity, levels = rev(eth_non_white))
  )

p_comp <- ggplot(plot_data, aes(x = rr, y = ethnicity, colour = method)) +
  geom_vline(xintercept = 1, linetype = "dashed", colour = "grey50") +
  geom_errorbarh(aes(xmin = ci_lo, xmax = ci_hi),
                 height = 0.2, linewidth = 0.8,
                 position = position_dodge(width = 0.5)) +
  geom_point(size = 3, position = position_dodge(width = 0.5)) +
  scale_colour_manual(
    values = c("Quasi-Poisson GLM" = "steelblue4", "IPW rate ratio" = "darkorange"),
    name   = "Method"
  ) +
  labs(
    title    = "GLM IRRs vs IPW Rate Ratios",
    subtitle = "Both relative to White. Bars: 95% CIs. IPW CIs from 200 bootstrap replicates.",
    x        = "Rate ratio (vs White)",
    y        = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title      = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave(file.path(fig_dir, "ipw_comparison.png"),
       p_comp, width = 7, height = 5, dpi = 150)
message("  Saved: ipw_comparison.png")

message("\n=== 09_ipw.R: COMPLETE ===")
