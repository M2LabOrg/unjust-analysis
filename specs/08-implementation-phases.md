# 08 -- Implementation Phases

## Phase 0: Setup (Day 1)
- [ ] Create the new `unjust` monorepo with the directory structure from spec 01
- [ ] Initialize `renv` for R package management
- [ ] Initialize the React app with Vite + TypeScript + Tailwind
- [ ] Set up `.gitignore` properly
- [ ] Migrate relevant code and data from the two existing repos
- [ ] Confirm the repo builds cleanly (empty report, empty dashboard)

## Phase 1: Data (Days 2--3)
- [ ] Write `data/download_data.sh` -- download new ODS files from GOV.UK
- [ ] Download March 2024 and March 2025 open data tables
- [ ] Download Ethnicity Facts and Figures CSVs (for QA)
- [ ] Write `analysis/01_load_and_clean.R` -- ingest and harmonize all years
- [ ] Output cleaned datasets to `data/processed/`
- [ ] Run `qa/check_totals.R` -- validate totals against published figures
- [ ] Document any data issues or exclusions

## Phase 2: Analysis (Days 4--7)
- [ ] `analysis/02_eda.R` -- descriptive stats and visualizations for 5 years
- [ ] `analysis/03_model_poisson.R` -- fit Poisson GLM on pooled data
- [ ] `analysis/04_model_rf.R` -- Random Forest for variable importance
- [ ] `analysis/05_new_insights.R`:
  - Trend analysis (is disparity improving?)
  - Outcome disparity (NFA rates by ethnicity)
  - Regional force rankings
  - Interaction effects
  - Hit rate analysis (if data allows)
- [ ] `qa/check_rates.R` and `qa/check_consistency.R` -- full QA pass
- [ ] Render `qa/qa_report.qmd`

## Phase 3: Report (Days 8--11)
- [ ] Migrate and update chapters from existing report
- [ ] Write new sections: trend analysis, outcome analysis, force rankings
- [ ] Update all figures to include 5-year data
- [ ] Update discussion and conclusion with new findings
- [ ] Update bibliography with 2024/2025 sources
- [ ] Render Quarto book (HTML + PDF)
- [ ] Self-review: check every number against analysis output

## Phase 4: Dashboard (Days 12--16)
- [ ] `analysis/06_export_for_dashboard.R` -- export JSON data files
- [ ] Build React components:
  - Hero section
  - Key findings cards
  - Trend chart (Recharts)
  - Regional map (D3 / react-simple-maps)
  - Outcome chart
  - Force rankings
  - Scrollytelling section
  - Footer with report link
- [ ] Style with Tailwind (Apple-inspired theme)
- [ ] Add Framer Motion animations
- [ ] Responsive testing (mobile, tablet, desktop)
- [ ] Accessibility pass

## Phase 5: Deploy (Days 17--18)
- [ ] Write `build.sh` and `netlify.toml`
- [ ] Test local build (dashboard + report)
- [ ] Deploy to Netlify (private)
- [ ] Test all pages and links
- [ ] Final QA: dashboard numbers match report numbers

## Phase 6: Review & Polish (Days 19--20)
- [ ] Run the full peer review checklist (spec 04)
- [ ] Fix any issues
- [ ] Final commit and tag (v1.0)
- [ ] Share with UNJUST for review

## Dependencies Between Phases

```
Phase 0 (Setup)
    ↓
Phase 1 (Data)
    ↓
Phase 2 (Analysis)
    ↓
Phase 3 (Report)  ←──→  Phase 4 (Dashboard)
    ↓                        ↓
         Phase 5 (Deploy)
              ↓
         Phase 6 (Review)
```

Phases 3 and 4 can run in parallel once Phase 2 is complete.

## Effort Estimates

These are rough -- the "days" are working sessions, not full days. The user will work incrementally ("little by little") so calendar time will be longer.

| Phase | Effort |
|-------|--------|
| 0. Setup | 1 session |
| 1. Data | 2 sessions |
| 2. Analysis | 4 sessions |
| 3. Report | 4 sessions |
| 4. Dashboard | 5 sessions |
| 5. Deploy | 2 sessions |
| 6. Review | 2 sessions |
| **Total** | **~20 sessions** |
