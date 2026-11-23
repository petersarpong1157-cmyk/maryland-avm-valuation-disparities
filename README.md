# Maryland 2025 AVM — Reproducibility Materials

Study: **Explainable Automated Valuation Models and Neighborhood Valuation Disparities: Evidence from Maryland Property Transactions**

**Status: partial aggregate-results reproducibility package — NOT a complete, independently rerun replication release.**

This repository contains research documentation, R scripts to check the consistency of reported aggregate results, and a small set of aggregate reference CSVs. **No figures, manuscripts, raw transaction records, row-level predictions, individual property records, or fitted model files are included.**

## Study overview
The research compares hedonic regression with XGBoost for retrospective transaction-price prediction across 58,958 eligible Maryland residential sales in 2025. The temporal split comprises 38,917 training, 10,671 validation, and 9,370 reserved-test observations. On the test period, the reported hedonic MAE was approximately $125,280 versus $103,332 for XGBoost, a 17.52% reduction. The adjusted signed-log-error gradient difference associated with each 10-percentage-point increase in neighborhood minority share was -1.321.

## Run the aggregate consistency check
Start R from the repository root, then run:

```r
source("R/verify_reported_results.R")
```

This verifies *internal numerical consistency of reported summary values only*, **not** the original source extraction, model fitting, statistical inference, or independent end-to-end reproduction. The reference CSVs were transcribed from the author's verified RStudio outputs; they are not substitutes for original source-generated export files.

## Verified local audit status
In the author's RStudio session, the reference summary check passed; **10/10** original aggregate-export MD5 hashes matched the staging manifest; original MAEs agreed with the repository references within rounding; **18/18** Phase 7B numerical comparisons passed; and Phase 7D SHAP group-sum and complete-case accounting tests passed. The ten locally staged original CSV files contain small aggregate tables, based on the user's printed inspection, without apparent direct individual identifiers. These checks were reported from the original research environment; **they do not represent an independent clean-clone rerun** and do not establish that source data or every cell are safe to distribute.

## Stage original result exports locally (do not upload without review)
In the author's original RStudio project, where `out_dir` points to `AVM_New_Research`:

```r
source("R/stage_local_exports.R")
stage_local_exports(out_dir)
```

This copies selected aggregate CSV exports into `results/source_exports/` in your local clone. They are deliberately excluded from Git by `.gitignore`. Inspect complete contents, geographic identifiers, filenames, and source-provider rights before release.

## Data provenance
See `documentation/DATA_PROVENANCE.md`. Source data include Maryland SDAT 2025 property sales and the 2019–2023 ACS five-year tract-level tables. Local model audits used R 4.5.2 and xgboost 3.2.1.1. Original SDAT completeness and point-in-time availability of property characteristics are not independently established.

## Release limitations and next steps
See `documentation/RELEASE_GATES.md`. Full independent replication requires executable data ingestion, filtering, chronological split, feature engineering, model training, error analyses, SHAP, and mapping scripts, together with an independently verified clean-clone run. None is claimed here.

## Related but distinct research
The existing repository `maryland-hmda-sdat-linkage` addresses mortgage-to-property statistical linkage and is **not** the full replication source for this AVM study.

## Journal confidentiality
The repository is publicly associated with its GitHub account. Do not link it in a double-anonymous journal submission without checking journal policy and reviewer anonymity requirements.

## Interpreting findings
Results concern retrospective transaction-price prediction; they do not establish prospectively available property features. Correlation between neighborhood demographics and signed prediction error is not evidence of causal discrimination.
