# Data Licences

The datasets in this directory are derived from publicly available UK government sources. Each is redistributed here under its original licence terms.

## Home Office — Stop and Search Open Data

- **Source:** [Police Powers and Procedures, England and Wales](https://www.gov.uk/government/collections/police-powers-and-procedures-england-and-wales)
- **Licence:** [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/)
- **Files:** Downloaded via `download_data.sh` (not committed; the raw `.ods` file is gitignored due to size)

## Ethnicity Facts and Figures — Stop and Search Rates

- **Source:** [Ethnicity Facts and Figures — Stop and Search](https://www.ethnicity-facts-figures.service.gov.uk/crime-justice-and-the-law/policing/stop-and-search/latest/)
- **Licence:** [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/)
- **Files:** `raw/ethnicity-stop-search-by-area.csv`, `raw/ethnicity-stop-search-by-ethnicity.csv`

## ONS Census 2021 — Population by Ethnicity and Region

- **Source:** [ONS Census 2021](https://www.ons.gov.uk/census)
- **Licence:** [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/) / [ONS Open Licence](https://www.ons.gov.uk/methodology/geography/licences)
- **Files:** `raw/population-by-ethnicity-and-region-2021.csv`

## ONS Boundary Data (Shapefile)

- **Source:** [ONS Open Geography Portal](https://geoportal.statistics.gov.uk/)
- **Licence:** [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/)
- **Files:** `raw/shapefile/`

## Derived Data

All files in `processed/` and `../analysis/output/` are derived from the sources above using the scripts in `analysis/`. They inherit the same licence terms as their source datasets.

---

Crown copyright materials are reproduced under the Open Government Licence v3.0. Contains public sector information licensed under the Open Government Licence v3.0.
