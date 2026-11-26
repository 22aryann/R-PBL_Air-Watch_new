# AIRWATCH 2026 - Air Quality Intelligence & Analytics Platform

Breathe Smarter. Analyze Better. An R Shiny project for BTech CSE (AI & ML).

## Run it
1. Install R (4.2 or newer) and RStudio.
2. In the R console:
   ```r
   install.packages(c("shiny","bslib","dplyr","tidyr","readr","readxl","lubridate","plotly","DT","tibble"))
   ```
3. Open `app.R` in RStudio (set the working directory to this folder) and click **Run App**.
   Or: `shiny::runApp("path/to/AIRWATCH-2026")`.

The app loads `data/air_quality_2026.csv` automatically. Use **Dataset Management** to upload another file.
An internet connection is needed for the Inter font and Lucide icons.

## Your dataset (what was actually found)
- `Raw_Data_2026_site_5393_chandni_chowk_delhi_iitm_1Hr.csv`: 6,552 hourly rows, 1 Jan 2026 00:00 to 30 Sep 2026 23:00 (Oct-Dec not present).
- Station: site 5393, Chandni Chowk, Delhi (IITM). Single location.
- **No AQI column.** AQI is computed from PM2.5, PM10, NO2, SO2, CO, O3, NH3 with the Indian CPCB method (24 h averages; 8 h for CO and O3; needs 3+ pollutants including PM). See `R/analysis.R`. Call it "computed AQI" in your report.
- Missing values are the text `NA` (read as missing, never as 0). `O Xylene`, `SR`, `VWS` are 100% empty and are dropped.
- The 2025 file is kept as `data/air_quality_2025_reference.csv`; the app does not use it yet.

## Status
- Phase 1 (architecture, theme, sidebar, header, layout): done.
- Phase 2 (upload, validation, cleaning, time parsing, AQI computation): written.
- Phases 3-7 (analysis pages, statistics, prediction, alerts, reports): pages exist as labelled shells.
- **Not yet run:** the build environment had no R installed, so the code has not been executed. Expect to fix small errors on first run and report them.

## Structure
`app.R` entry point | `R/` data and analysis functions | `modules/` one file per page | `www/` CSS and JS
