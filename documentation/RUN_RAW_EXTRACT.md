# Raw-extract to model reproduction

This read-only script consolidates the author's independently retrained raw-extract-to-model pipeline. **The author executed the consolidated script in a separate `Rscript.exe` process on November 23, 2026: all stages passed, exit code 0.** This is not an external fresh-environment reproduction.

## Inputs (do not commit them)
1. Original locally saved 2025 **128,746-row** SDAT residential transactions CSV, not the 63,304-row processed extract.
2. Original archived **63,304-row** SDAT-with-tracts CSV, used **only for checking identities, source columns and tract assignments**.
3. Locally saved encoding metadata RDS (`formula`, `feature_names`, `dwelling_levels`, `county_levels`).
4. Locally saved fitted model bundle RDS, used **only for post-training comparisons**, never to supply trained coefficients or trees.

Install R packages `data.table`, `sf`, `Matrix`, `xgboost`. The script downloads the official **2024 Maryland tract cartographic 1:500k** ZIP from the Census website.

From your project folder:

```r
raw <- "C:/Users/peter/OneDrive/Desktop/Research Publications/SDAT_2025_Residential_Transactions_Raw.csv"
archived <- sdat_path
encoding <- encoding_rds
frozen <- model_rds

stopifnot(all(file.exists(c(raw, archived, encoding, frozen))))

# Download latest script from GitHub if not already in the local clone.
script_url <- paste0(
  "https://raw.githubusercontent.com/petersarpong1157-cmyk/",
  "maryland-avm-valuation-disparities/main/R/reproduce_raw_extract.R"
)
local_script <- file.path(out_dir, "reproduce_raw_extract.R")
download.file(script_url, local_script, method="libcurl", mode="wb")

exit_code <- system2(
  file.path(R.home("bin"), "Rscript.exe"),
  args = shQuote(c(local_script, raw, archived, encoding, frozen))
)
cat("RAW-EXTRACT RUN EXIT CODE:", exit_code, "\n")
```

**The verified run returned exit code 0** and printed `LOCAL RAW-EXTRACT-TO-MODEL REPRODUCTION: PASSED`. Nonfatal package-built-under-R-4.5.3 warnings were reported. For future runs, if an error appears, preserve the console error and correct the script. Use a commit-specific raw URL when historical script immutability matters.

Both the original interactive verification and subsequent consolidated script run established: 128,746→65,754→65,578→63,396→63,318→63,304; 1,464 Census cartographic tracts; 0 archived ID/GEOID disagreements; 23/23 original source fields match; eligible N 58,958; chronological splits 38,917/10,671/9,370; hedonic coefficient difference 0; 9,370 independent XGBoost test log predictions match exactly; new XGBoost MAE $103,331.97923281.

**Not reproduced**: a second, contemporaneously comparable independent extraction of original 2025 SDAT data; historical point-in-time property feature snapshots; third-party clean-environment rerun; complete SHAP and mapping generation from raw records. The public repository includes no row-level source data, individual property information, manuscript, figures, or fitted models.
