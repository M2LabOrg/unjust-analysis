# UNJUST Project -- Specifications & Plan

## Overview

This document describes the plan to revive, extend, and publish the UNJUST project: a statistical analysis of police stop-and-search practices on Black communities in England & Wales.

### Current State

| Repo | Purpose | Data Coverage | Status |
|------|---------|---------------|--------|
| `RSS_UNJUST_Report` | Quarto book report + Poisson GLM + Random Forest | FY 2020/21 -- 2022/23 | ~90% complete draft |
| `RSS_UNJUST_Project` | EDA, data loading scripts, bookdown skeleton | FY 2006/07 -- 2021/22 | Exploratory / partial |

**Key findings already established:**
- Black individuals 2.9x more likely to be stopped (adjusted); 5.4-6.9x raw disparity
- Males 8.6x more likely than females
- 71% of searches result in "no further action"
- Young people (<25) 2.1x more likely for drug-related stops

### What's New

- **March 2024 data** and **March 2025 data** are now published on GOV.UK
- The 2025 release shows disparity rate of 3.8x for Black individuals (official figure)
- Total searches fell to ~403,000 in 2024/25 (down from 547,000 in 2022/23)
- "Statistics on Ethnicity and the Criminal Justice System, 2024" report is also available
- Missing ethnicity data improved from 20.6% (2023) to 18.4% (2025)

### Goals

1. **Update the dataset** with 2023/24 and 2024/25 data
2. **Re-run and extend analysis** -- Poisson GLM + new insights
3. **QA everything** -- reproducible pipeline with validation checks
4. **Write the report** using Quarto (professional, citable)
5. **Build a React dashboard** -- Apple-inspired design, dynamic charts
6. **Publish on Netlify** -- dashboard + report, private initially
7. **Find new insights** beyond what the government already publishes

### Deliverables

| # | Deliverable | Tech |
|---|-------------|------|
| 1 | Reproducible data pipeline | R or Python scripts |
| 2 | Statistical analysis & modelling | R (Poisson GLM, RF) or Python |
| 3 | QA validation suite | Automated checks against official totals |
| 4 | Quarto report (HTML + PDF) | Quarto book |
| 5 | Interactive dashboard | React + Tailwind + Recharts/D3 |
| 6 | Netlify deployment | Monorepo with build scripts |
