# Response to Mid-Way Reviewer

**Project:** Analysis of data on policing (UNJUST CIC)
**Volunteer:** Michel Mesquita
**Reviewer:** Prajamitra Bhuyan (Royal Statistical Society)
**Date:** July 2026

---

We thank the reviewer for the positive assessment of the analysis and for the
constructive suggestions made in both the written review form and the
follow-up meeting. Below we address each point in turn, noting the specific
changes made to the report and the underlying codebase.

---

## Comments from the Written Review Form

### 1. Model diagnostics

**Reviewer comment:** Model diagnostics were identified as an addition that
would lead to a more comprehensive understanding of the effects of race on
policing and associated uncertainty quantification.

**Response:** A full set of regression diagnostics for the pooled
Quasi-Poisson GLM has been added as **Appendix A** of the report
(`report/appendix_diagnostics.qmd`; analysis script
`analysis/07_model_diagnostics.R`). The appendix presents four diagnostic
figures: Pearson residuals vs fitted values, a normal Q-Q plot of Pearson
residuals, Cook's distance for each modelling stratum, and an
observed-vs-expected count plot. A summary table of key diagnostic statistics
is also included. The heavy tails in the Q-Q plot and the presence of
influential strata are interpreted in context: both are expected consequences
of the extreme overdispersion in the data ($\hat{\phi} \approx 182$) and of
regional heterogeneity in policing intensity. The Quasi-Poisson correction
already addresses the dispersion, and the sensitivity analysis (Appendix B)
confirms that the influential strata do not alter the main ethnicity findings.

### 2. Sensitivity analysis of estimated effects

**Reviewer comment:** A sensitivity analysis of the estimated effects was
recommended to strengthen confidence in the reported incidence rate ratios.

**Response:** A three-part sensitivity analysis has been added as **Appendix B**
(`report/appendix_sensitivity.qmd`; analysis script `analysis/08_sensitivity.R`).
The three checks are:

- **Leave-one-covariate-out:** the model is re-estimated five times, each
  time dropping one non-ethnicity covariate. The Black/White IRR is stable
  at 3.02 across all specifications except when the regional fixed effect is
  removed (where it rises to 4.35, reflecting regional confounding that the
  main model correctly controls for).
- **Bootstrap confidence intervals (B = 500):** non-parametric percentile
  intervals are compared with the normal-approximation intervals used in the
  main text. Both methods confirm the Black/White IRR is well above 1; the
  bootstrap interval is somewhat wider (2.53, 3.46), representing a
  conservative alternative.
- **Poisson vs Quasi-Poisson:** the SE ratio between the two families is 13.5
  (equal to $\sqrt{\hat{\phi}}$), confirming that using a standard Poisson
  model without the dispersion correction would produce confidence intervals
  roughly 14 times too narrow, conveying false precision.

### 3. Comparison with inverse propensity weighted estimates

**Reviewer comment:** A comparison with inverse propensity weighted (IPW)
estimates was suggested as a complementary causal-inference approach.

**Response:** An IPW analysis is being added as **Appendix C**
(`report/appendix_ipw.qmd`; analysis script `analysis/09_ipw.R`). This
approach models the probability of each ethnic group assignment given all
observed covariates (via multinomial logistic regression), computes stabilised
inverse propensity weights, and derives weighted stop rates and rate ratios.
Comparing these with the regression-based IRRs assesses whether the disparity
estimates depend on the linearity assumptions of the GLM.

---

## Points Raised in the Follow-Up Meeting

### Confounding factors and goodness-of-fit

The diagnostics appendix (Appendix A) and the sensitivity appendix (Appendix B)
together address this point. The leave-one-covariate-out analysis identifies
region as the principal confounder. The pseudo-R² of 0.884 and the
observed-vs-expected correlation of 0.93 confirm that the model captures the
systematic variation in search counts well, despite the high overdispersion.
Any deviations from ideal fit are noted in the main methodology chapter
(see the cross-reference added to @sec-quasipoisson) and interpreted in
Appendix A.

### Structure: appendices with disclaimers in the main text

As suggested, all three additions are presented as appendices rather than
modifications to the main chapters. The methodology chapter has been updated
with a single sentence cross-referencing Appendices A, B, and C. No other
changes have been made to the main text narrative.

### Modelling the effect without modelling the outcome directly

The IPW approach in Appendix C addresses this: rather than modelling the
search count (the outcome), it models the probability of group membership
(the treatment) and derives disparity estimates from re-weighted observed
rates. This provides a complementary estimate that does not rely on the GLM's
parametric assumptions.

### Awareness campaigns and regional interventions

This point is noted as a future direction. A paragraph for the Discussion
chapter documenting known national and regional policy interventions during
the 2020/21 to 2024/25 study period (including the Beating Crime Plan 2021,
the Baroness Casey Review 2023, and Violence Reduction Unit programmes) is
being prepared separately, pending literature review and source verification.

---

## Summary of Changes

| Change | Location |
|---|---|
| Model diagnostics (4 figures, summary table) | `analysis/07_model_diagnostics.R`, `report/appendix_diagnostics.qmd` |
| Sensitivity analysis (3 checks, 2 figures, 3 tables) | `analysis/08_sensitivity.R`, `report/appendix_sensitivity.qmd` |
| IPW comparison (in progress) | `analysis/09_ipw.R`, `report/appendix_ipw.qmd` |
| Cross-reference sentence in methodology | `report/methodology.qmd` |
| Appendices wired into book structure | `report/_quarto.yml` |
| Makefile updated for reproducibility | `Makefile` |
