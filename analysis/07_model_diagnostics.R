# =============================================================================
# 07_model_diagnostics.R
# Regression diagnostics for the Quasi-Poisson GLM (pooled main-effects model).
#
# Produces four diagnostic plots and a summary table for Appendix A of the
# report. All plots are saved as PNG files in analysis/output/figures/.
#
# Run from the repository root:
#   Rscript analysis/07_model_diagnostics.R
#
# Input:  analysis/output/model_pooled.rds
# Output: analysis/output/figures/diag_pearson_vs_fitted.png
#         analysis/output/figures/diag_qq_pearson.png
#         analysis/output/figures/diag_cooks_distance.png
#         analysis/output/figures/diag_obs_vs_expected.png
#         analysis/output/diag_summary.csv
# =============================================================================

library(tidyverse)
library(ggplot2)

fig_dir <- "analysis/output/figures"
out_dir <- "analysis/output"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

message("=== 07_model_diagnostics.R: Quasi-Poisson GLM Diagnostics ===\n")

# --- Load fitted model --------------------------------------------------------

fit <- readRDS(file.path(out_dir, "model_pooled.rds"))

n_obs        <- nrow(fit$model)
df_resid     <- fit$df.residual
dispersion   <- sum(residuals(fit, type = "pearson")^2) / df_resid
cooks_thresh <- 4 / df_resid

message("  Observations: ", n_obs)
message("  df residual:  ", df_resid)
message("  Dispersion:   ", round(dispersion, 2))
message("  Cook's threshold (4/df): ", round(cooks_thresh, 5))

# --- Residuals and fitted values ----------------------------------------------

pearson_r <- residuals(fit, type = "pearson")
deviance_r <- residuals(fit, type = "deviance")
fitted_v  <- fitted(fit)
observed  <- fit$y

df_diag <- tibble(
  obs      = seq_along(pearson_r),
  pearson  = pearson_r,
  deviance = deviance_r,
  fitted   = fitted_v,
  observed = observed
)

# =============================================================================
# PLOT 1: Pearson residuals vs fitted values
# =============================================================================

message("\n--- Plot 1: Pearson residuals vs fitted ---")

p1 <- ggplot(df_diag, aes(x = fitted, y = pearson)) +
  geom_point(alpha = 0.35, size = 1.2, colour = "steelblue4") +
  geom_hline(yintercept = 0, colour = "firebrick", linetype = "dashed", linewidth = 0.7) +
  geom_smooth(method = "loess", se = TRUE, colour = "darkorange",
              fill = "darkorange", alpha = 0.15, linewidth = 0.8) +
  scale_x_log10(labels = scales::comma) +
  labs(
    title = "Pearson Residuals vs Fitted Values",
    subtitle = paste0("Quasi-Poisson GLM, n = ", format(n_obs, big.mark = ","),
                      ", dispersion = ", round(dispersion, 1)),
    x = "Fitted values (log scale)",
    y = "Pearson residuals"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

ggsave(file.path(fig_dir, "diag_pearson_vs_fitted.png"),
       p1, width = 8, height = 5, dpi = 150)
message("  Saved: diag_pearson_vs_fitted.png")

# =============================================================================
# PLOT 2: Normal Q-Q plot of Pearson residuals
# =============================================================================

message("\n--- Plot 2: QQ plot of Pearson residuals ---")

df_qq <- df_diag |>
  arrange(pearson) |>
  mutate(theoretical = qnorm(ppoints(n())))

p2 <- ggplot(df_qq, aes(x = theoretical, y = pearson)) +
  geom_point(alpha = 0.35, size = 1.2, colour = "steelblue4") +
  geom_abline(intercept = 0, slope = 1,
              colour = "firebrick", linetype = "dashed", linewidth = 0.7) +
  labs(
    title = "Normal Q-Q Plot of Pearson Residuals",
    subtitle = "Dashed line: perfect normal alignment",
    x = "Theoretical quantiles",
    y = "Sample quantiles (Pearson residuals)"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

ggsave(file.path(fig_dir, "diag_qq_pearson.png"),
       p2, width = 6, height = 6, dpi = 150)
message("  Saved: diag_qq_pearson.png")

# =============================================================================
# PLOT 3: Cook's distance
# =============================================================================

message("\n--- Plot 3: Cook's distance ---")

cooks_d <- cooks.distance(fit)

df_cooks <- tibble(
  obs     = seq_along(cooks_d),
  cooks_d = cooks_d,
  flagged = cooks_d > cooks_thresh
)

n_flagged <- sum(df_cooks$flagged)
message("  Observations above Cook's threshold: ", n_flagged,
        " (", round(100 * n_flagged / n_obs, 1), "%)")

p3 <- ggplot(df_cooks, aes(x = obs, y = cooks_d)) +
  geom_segment(aes(xend = obs, yend = 0, colour = flagged),
               alpha = 0.5, linewidth = 0.5) +
  geom_point(aes(colour = flagged), size = 1, alpha = 0.7) +
  geom_hline(yintercept = cooks_thresh,
             colour = "firebrick", linetype = "dashed", linewidth = 0.7) +
  scale_colour_manual(
    values = c("FALSE" = "steelblue4", "TRUE" = "firebrick"),
    labels = c("FALSE" = "Below threshold", "TRUE" = "Above threshold"),
    name   = NULL
  ) +
  labs(
    title = "Cook's Distance",
    subtitle = paste0("Threshold: 4 / df = ", round(cooks_thresh, 4),
                      ";  flagged observations: ", n_flagged,
                      " (", round(100 * n_flagged / n_obs, 1), "%)"),
    x = "Observation index",
    y = "Cook's distance"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave(file.path(fig_dir, "diag_cooks_distance.png"),
       p3, width = 8, height = 5, dpi = 150)
message("  Saved: diag_cooks_distance.png")

# =============================================================================
# PLOT 4: Observed vs expected counts (log scale)
# =============================================================================

message("\n--- Plot 4: Observed vs expected counts ---")

# Pearson correlation between observed and expected
r_oe <- cor(observed, fitted_v)
message("  Correlation (observed, expected): ", round(r_oe, 4))

p4 <- ggplot(df_diag, aes(x = fitted, y = observed)) +
  geom_point(alpha = 0.35, size = 1.2, colour = "steelblue4") +
  geom_abline(intercept = 0, slope = 1,
              colour = "firebrick", linetype = "dashed", linewidth = 0.7) +
  scale_x_log10(labels = scales::comma) +
  scale_y_log10(labels = scales::comma) +
  labs(
    title = "Observed vs Expected Counts",
    subtitle = paste0("Pearson r = ", round(r_oe, 3),
                      ";  dashed line: perfect agreement"),
    x = "Expected counts (log scale)",
    y = "Observed counts (log scale)"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

ggsave(file.path(fig_dir, "diag_obs_vs_expected.png"),
       p4, width = 6, height = 6, dpi = 150)
message("  Saved: diag_obs_vs_expected.png")

# =============================================================================
# SUMMARY TABLE
# =============================================================================

message("\n--- Diagnostic summary table ---")

# Dispersion-scaled Pearson residuals: divide by sqrt(phi) so the threshold
# of ±2 is meaningful under Quasi-Poisson. Raw Pearson residuals are expected
# to be far outside ±2 when phi >> 1, so the raw proportion carries no
# diagnostic information.
scaled_pearson_r  <- pearson_r / sqrt(dispersion)
pct_large_pearson <- mean(abs(scaled_pearson_r) > 2) * 100

diag_summary <- tibble(
  metric              = c(
    "Observations (strata)",
    "Degrees of freedom (residual)",
    "Dispersion parameter",
    "Pearson chi-squared / df",
    "Residual deviance",
    "Null deviance",
    "Pseudo R-squared (McFadden)",
    "Cook's threshold (4/df)",
    "Observations above Cook's threshold",
    "Observations above Cook's threshold (%)",
    "Dispersion-scaled Pearson residuals > 2 (%)",
    "Obs vs expected Pearson r"
  ),
  value = c(
    n_obs,
    df_resid,
    round(dispersion, 2),
    round(dispersion, 2),
    round(fit$deviance, 0),
    round(fit$null.deviance, 0),
    round(1 - fit$deviance / fit$null.deviance, 4),
    round(cooks_thresh, 5),
    n_flagged,
    round(100 * n_flagged / n_obs, 1),
    round(pct_large_pearson, 1),
    round(r_oe, 4)
  )
)

print(as.data.frame(diag_summary))
write_csv(diag_summary, file.path(out_dir, "diag_summary.csv"))
message("  Saved: diag_summary.csv")

message("\n=== 07_model_diagnostics.R: COMPLETE ===")
