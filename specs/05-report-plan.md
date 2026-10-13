# 05 -- Report Plan (Quarto Book)

## Format

Quarto book rendered to HTML (primary) and PDF (secondary). The existing report structure from `RSS_UNJUST_Report` is a strong foundation -- we will migrate and extend it.

## Chapter Outline

### Front Matter
- **Title:** Statistical Analysis of Stop and Search Practices on Black Communities in the UK
- **Author:** Michel Mesquita, Ph.D., CStat (M2Lab CSDS)
- **For:** UNJUST / Royal Statistical Society -- Statisticians for Society
- **Date:** 2026

### index.qmd -- Executive Summary
- Project overview and objectives
- Key headline findings (updated with 2024/25 data)
- Link to interactive dashboard

### 01-introduction.qmd
- Historical context of stop and search in England & Wales
- PACE 1984, Section 60, and relevant legislation
- The problem: ethnic disproportionality in policing
- Research questions (updated):
  1. Do Black individuals in metropolitan areas experience higher rates of drug-related stop and searches?
  2. How do stop and search rates vary for young individuals (under 25)?
  3. **NEW:** Has the disparity changed over the 5-year period 2020/21 -- 2024/25?
  4. **NEW:** Do outcome patterns differ by ethnicity, suggesting differential thresholds for suspicion?

### 02-literature.qmd
- Existing research: Vomfell & Stewart (2021), EHRC, Home Office reports
- Update with any new publications since 2023
- Discuss the "Statistics on Ethnicity and the Criminal Justice System 2024" report

### 03-methodology.qmd
- Data sources and coverage period
- Cleaning and exclusion criteria (with rationale)
- Population offset approach using Census 2021
- Poisson GLM specification
- Random Forest specification
- New analyses: trend, outcome disparity, hit rate
- QA approach (reference the QA report)

### 04-results.qmd
- Descriptive statistics (tables and figures)
- Census demographics by region
- Stop and search volumes and trends (5-year series)
- Poisson GLM results: IRRs with CIs
- **NEW:** Year-on-year trend in disparity ratios
- **NEW:** Outcome analysis by ethnicity (NFA rates, arrest rates)
- **NEW:** Regional force rankings by disparity
- **NEW:** Interaction effects (age x ethnicity, region x ethnicity)
- Random Forest variable importance

### 05-discussion.qmd
- Comparison with official GOV.UK statistics
- Comparison with Vomfell & Stewart findings
- **NEW:** Discussion of trend -- is it improving?
- **NEW:** Implications of outcome disparities
- **NEW:** Regional variation and policy implications
- Limitations (missing data, Census denominator lag, ecological fallacy)

### 06-conclusion.qmd
- Summary of findings
- Updated policy recommendations
- Future research directions

### references.qmd
- Auto-generated from bibliography.bib

### Appendix: QA Report
- Link to or embed the rendered QA report

## Quarto Configuration

```yaml
# _quarto.yml
project:
  type: book
  output-dir: _book

book:
  title: "Statistical Analysis of Stop and Search Practices on Black Communities in the UK"
  author: "Michel Mesquita, Ph.D., CStat"
  date: "2026"
  chapters:
    - index.qmd
    - 01-introduction.qmd
    - 02-literature.qmd
    - 03-methodology.qmd
    - 04-results.qmd
    - 05-discussion.qmd
    - 06-conclusion.qmd
    - references.qmd

bibliography: bibliography.bib
csl: harvard.csl

format:
  html:
    theme: cosmo
    toc: true
    number-sections: true
  pdf:
    documentclass: scrreprt
    papersize: a4
```

## What Carries Over from the Existing Report

- Most of the literature review content
- The Poisson GLM methodology description
- Census demographic analysis
- Bibliography entries
- The overall narrative structure

## What's New in the Report

- Extended time series (2 additional years of data)
- Trend analysis section
- Outcome disparity analysis
- Regional force rankings
- Interaction effect analysis
- Updated discussion reflecting 5 years of data
- Link to the interactive dashboard
