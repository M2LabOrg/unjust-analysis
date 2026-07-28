.PHONY: data analysis qa report dashboard build clean

# Download raw data from GOV.UK
data:
	bash data/download_data.sh

# Run the full analysis pipeline
analysis: data
	Rscript analysis/01_load_and_clean.R
	Rscript analysis/02_eda.R
	Rscript analysis/03_model_poisson.R
	Rscript analysis/04_model_rf.R
	Rscript analysis/05_new_insights.R
	Rscript analysis/06_export_for_dashboard.R
	Rscript analysis/07_model_diagnostics.R
	Rscript analysis/08_sensitivity.R
	Rscript analysis/09_ipw.R

# Run QA checks
qa: analysis
	Rscript qa/check_totals.R
	Rscript qa/check_rates.R
	Rscript qa/check_consistency.R
	cd qa && quarto render qa_report.qmd

# Build the Quarto report
report: analysis
	cd report && quarto render

# Build the React dashboard
dashboard: analysis
	cd dashboard && npm ci && npm run build

# Full build: assemble everything into dist/
build: report dashboard
	bash build.sh

# Clean generated files
clean:
	rm -rf data/processed/*
	rm -rf report/_book
	rm -rf dashboard/dist
	rm -rf dist
