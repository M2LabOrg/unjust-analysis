# =============================================================================
# 04_model_rf.R
# Random Forest for variable importance and interaction detection.
#
# Complements the Poisson GLM by capturing non-linear relationships and ranking
# predictors by their contribution to explaining search volume variance.
#
# Input:  data/processed/stop_search_clean.csv, census_clean.csv
# Output: analysis/output/rf_importance.csv
#         analysis/output/rf_oob_summary.txt
# =============================================================================

library(tidyverse)
library(randomForest)

out_dir <- "analysis/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

message("=== 04_model_rf.R: Random Forest ===\n")

# --- Load and prepare dataset ------------------------------------------------

ss     <- read_csv("data/processed/stop_search_clean.csv", show_col_types = FALSE)
census <- read_csv("data/processed/census_clean.csv", show_col_types = FALSE)

model_data <- ss |>
  filter(
    !is.na(ethnicity),
    !is.na(age_under25),
    sex %in% c("Male", "Female")
  ) |>
  group_by(financial_year, region_clean, ethnicity, sex, age_under25, reason_drugs) |>
  summarise(
    total_searches = sum(n_searches, na.rm = TRUE),
    .groups = "drop"
  ) |>
  left_join(census, by = c("region_clean", "ethnicity")) |>
  filter(!is.na(population), population > 0) |>
  mutate(
    financial_year = factor(financial_year),
    region_clean   = factor(region_clean),
    ethnicity      = relevel(factor(ethnicity), ref = "White"),
    sex            = relevel(factor(sex), ref = "Female"),
    age_under25    = factor(age_under25, labels = c("25+", "Under 25")),
    reason_drugs   = factor(reason_drugs, labels = c("Other", "Drugs"))
  )

message("  Dataset: ", format(nrow(model_data), big.mark = ","), " rows")
message("  Total searches: ", format(sum(model_data$total_searches), big.mark = ","))

# --- Fit Random Forest -------------------------------------------------------

message("\n--- Fitting Random Forest (ntree = 500) ---")
set.seed(42)

rf_fit <- randomForest(
  total_searches ~ financial_year + region_clean + ethnicity +
                   sex + age_under25 + reason_drugs + population,
  data       = model_data,
  importance = TRUE,
  ntree      = 500
)

message("  OOB % Var explained: ", round(rf_fit$rsq[500] * 100, 1), "%")

# --- Variable importance -----------------------------------------------------

message("\n--- Variable importance (%IncMSE) ---")

imp <- importance(rf_fit, type = 1)  # %IncMSE
importance_df <- tibble(
  variable    = rownames(imp),
  pct_inc_mse = round(imp[, "%IncMSE"], 3)
) |>
  arrange(desc(pct_inc_mse))

print(as.data.frame(importance_df))

write_csv(importance_df, file.path(out_dir, "rf_importance.csv"))
message("  Saved: rf_importance.csv")

# --- OOB error summary -------------------------------------------------------

sink(file.path(out_dir, "rf_oob_summary.txt"))
cat("=== Random Forest OOB Summary ===\n\n")
cat("ntree              :", rf_fit$ntree, "\n")
cat("mtry               :", rf_fit$mtry, "\n")
cat("% Var explained    :", round(rf_fit$rsq[500] * 100, 1), "%\n\n")
cat("Variable importance (%IncMSE):\n")
print(as.data.frame(importance_df))
sink()

message("  Saved: rf_oob_summary.txt")

# --- Per-year variable importance (trend) ------------------------------------

message("\n--- Per-year importance (is ethnicity rank stable?) ---")

yearly_imp <- map_dfr(levels(model_data$financial_year), function(yr) {
  d <- model_data |> filter(financial_year == yr)
  set.seed(42)
  fit <- randomForest(
    total_searches ~ region_clean + ethnicity + sex + age_under25 + reason_drugs + population,
    data = d, importance = TRUE, ntree = 300
  )
  imp_yr <- importance(fit, type = 1)
  tibble(
    financial_year = yr,
    variable       = rownames(imp_yr),
    pct_inc_mse    = round(imp_yr[, "%IncMSE"], 3)
  )
})

message("  Ethnicity importance by year:")
yearly_imp |>
  filter(variable == "ethnicity") |>
  select(financial_year, pct_inc_mse) |>
  print()

write_csv(yearly_imp, file.path(out_dir, "rf_importance_by_year.csv"))
message("  Saved: rf_importance_by_year.csv")

message("\n=== 04_model_rf.R: COMPLETE ===")
