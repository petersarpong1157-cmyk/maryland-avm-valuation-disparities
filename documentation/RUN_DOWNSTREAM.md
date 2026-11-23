# Run a fresh downstream audit

This **single-command local audit** rebuilds eligibility, chronological splits, sparse frozen-model test predictions, predictive metrics, a new paired tract bootstrap, ACS linkage, and three tract-clustered regressions.

## Prerequisites

Install R with packages `data.table`, `Matrix`, `xgboost`, and `fixest`. Use compatible package versions (original verification used R 4.5.2, xgboost 3.2.1.1, Matrix 1.7-6, data.table 1.17.8, fixest 0.14.2). Store the following inputs **only locally**, outside GitHub:

1. `SDAT_2025_Market_Sales_With_Census_Tracts.csv` — the existing **processed and tract-assigned** SDAT extract, *not* the original API download;
2. `Phase4B_ACS_2023_Maryland_Tracts.csv` — the archived tract ACS extract;
3. `Frozen_AVM_Models.rds` — frozen fitted models;
4. `Verified_XGBoost_Encoding.rds` — original feature formula and levels.

In a fresh clone of this repository, from its root run:

```bash
Rscript R/reproduce_downstream.R "/private/path/SDAT_2025_Market_Sales_With_Census_Tracts.csv" "/private/path/Phase4B_ACS_2023_Maryland_Tracts.csv" "/private/path/Frozen_AVM_Models.rds" "/private/path/Verified_XGBoost_Encoding.rds"
```

The script performs read-only calculations and prints pass/fail results. It does not save data, row-level predictions or models, and it aborts if key source counts or model checks disagree. To retain a log locally, redirect the console output into a git-ignored `local_audits/` directory.

**Do not mistake this for independent raw-data reproduction.** The raw SDAT/API acquisition, upstream coordinate-to-tract assignment, generation of ACS fields from Census API, original training/hyperparameter search, SHAP, and maps are **not included**. Original saved model objects are required. The bootstrap audit uses a different seed and confirms a close but nonidentical 95% interval. Run and review in a separate clean environment before claiming this script was successfully tested there.


## Windows RStudio quick run (existing research session)

If `out_dir`, `sdat_path`, and `acs_path` already point to the verified local research inputs, open the newest repository ZIP in RStudio and execute the following in the Console (adjust `repo_dir` only):

```r
repo_dir <- "C:/Users/peter/OneDrive/Desktop/maryland-avm-valuation-disparities-main"
script <- file.path(repo_dir, "R", "reproduce_downstream.R")
model_rds <- file.path(out_dir, "Phase5P_Model_Freeze", "Frozen_AVM_Models.rds")
encoding_rds <- file.path(out_dir, "Phase5P_Model_Freeze", "Verified_XGBoost_Encoding.rds")
inputs <- c(sdat_path, acs_path, model_rds, encoding_rds)
stopifnot(file.exists(script), all(file.exists(inputs)))
rscript <- file.path(R.home("bin"), "Rscript.exe")
exit_code <- system2(rscript, args = shQuote(c(script, inputs)))
cat("Rscript exit code:", exit_code, "\n")
stopifnot(identical(as.integer(exit_code), 0L))
```

The script should end with `DOWNSTREAM REPRODUCTION PASSED`. A nonzero exit code means the fresh run has **not** passed; inspect the preceding error. Download the current repository version first: a previously downloaded ZIP will not contain the new runner.
