# Maryland 2025 AVM — Reproducibility Materials

Study: **Explainable Automated Valuation Models and Neighborhood Valuation Disparities: Evidence from Maryland Property Transactions**

**Status: locally verified downstream reproduction from processed research inputs and frozen model objects; NOT a full independent, clean-environment, source-to-results replication.**

This public repository contains documentation, R scripts for checking reported *aggregate* results, and small aggregate reference tables. **No figures, manuscripts, individual property records, source transaction extracts, row-level predictions, or fitted model files are included.**

## Study overview

The study compares hedonic regression and XGBoost for retrospective transaction-price prediction for 58,958 eligible Maryland 2025 residential sales (38,917 train; 10,671 validation; 9,370 held-out test). Recalculated held-out MAE is $125,279.97 for the hedonic model and $103,331.98 for XGBoost, an improvement of $21,947.99 (17.52%).

Adjusted association with each 10-percentage-point increase in neighborhood minority share: hedonic signed-log-error gradient +4.325953 percentage points; XGBoost +3.004657; XGBoost minus hedonic -1.321296. These are observational associations, not causal or discrimination findings.

## Downstream reproduction completed locally

The author executed read-only reproduction checks in RStudio against locally retained *processed* SDAT data, archived ACS tract data, and frozen AVM model objects:

- Reconstructed sequential eligibility: 63,304 tract-assigned source observations to 58,958 eligible sales (exclusions: price 736, size 2,391, build year 673, dwelling units 546; no additional exclusions for date or tract assignment).
- Reproduced temporal counts: train 38,917; validation 10,671; reserved test 9,370.
- Recovered dwelling-group encoding from SDAT land-use categories: Residential (R) → Residential; Residential Condominium (U) → Condominium; Town House (TH) → Townhouse. The mapping agreed for all 38,734 uniquely matchable training observations (99.53% of training) and group totals agreed across all 38,917 training observations.
- Reconstructed the 29-column **sparse** XGBoost feature matrix in the saved feature order and used the frozen 1,195-round prediction protocol. Both held-out models' N, MAE, RMSE, MdAPE, WAPE, and signed-log-error metrics matched archived results to numerical precision.
- Independently recomputed a 2,000-replication tract-cluster bootstrap using 1,373 tracts and verification seed `20261122`. Observed MAE improvement reproduced exactly to numerical precision. Audit 95% percentile CI [$18,801.18, $25,254.95] closely corroborated, but did **not exactly reproduce**, archived CI [$18,753.05, $25,181.68]. Original RNG protocol not recovered.
- Linked all 9,370 test observations to 1,475-row archived ACS tract source by 11-digit GEOID (0 unmatched); missing income excluded 8 observations from 2 tracts, leaving 9,362 observations in 1,371 tracts. Archived row order, actual prices, and predictions matched exactly; ACS covariates matched to numerical precision.
- Refit three `fixest::feols` disparity regressions from the archived 9,362-row analysis dataset with county and month fixed effects and tract-clustered standard errors. All coefficient vectors and minority-gradient standard errors matched archived estimates to numerical precision; minority and poverty percent variables are divided by 10 to express ten-percentage-point units.

See [local reproduction audit](documentation/LOCAL_REPRODUCTION_AUDIT.md) for specific results and limits. These tests were **performed in the author's original RStudio environment**, not with executable end-to-end replication scripts included in this repository.

## One-command local downstream rerun (new; not yet fresh-run verified)

The repository now includes [`R/reproduce_downstream.R`](R/reproduce_downstream.R), which attempts to rebuild the sample, frozen-model test accuracy, independent audit bootstrap, ACS link, and three neighborhood regressions from four **private processed inputs**. See [run instructions](documentation/RUN_DOWNSTREAM.md). The script has not yet been executed in a fresh R environment, and it does **not** independently retrieve raw data or retrain the models.

## Public aggregate consistency check

From repository root:

```r
source("R/verify_reported_results.R")
```

This checks the consistency of *published repository reference aggregates*. It **does not rerun the local downstream verification** above or independently reproduce source extraction, model fitting, bootstrap, ACS linkage, or statistical inference. The reference CSVs were transcribed from author-verified output.

## Stage original result exports locally (do not upload without review)

In the author's research project, where `out_dir` points to the local `AVM_New_Research` directory:

```r
source("R/stage_local_exports.R")
stage_local_exports(out_dir)
```

This stages original aggregate tables in `results/source_exports/` locally, excluded by `.gitignore`. Ten original CSVs' MD5 checks matched their staging manifest. Previous local checks found 18/18 aggregate numerical comparisons and matching grouped SHAP summaries. Review source-provider terms and complete disclosure risk before releasing original exports.

## Provenance, limitations, and release status

See [data provenance](documentation/DATA_PROVENANCE.md) and [release gates](documentation/RELEASE_GATES.md). Original acquisition completeness, point-in-time availability of property features, a clean independent model-training rerun, and full upstream-to-downstream replication remain unverified. The use of post-transaction feature snapshots limits prospective interpretation.

This is an **author-executed downstream verification**, not independent third-party audit. The repository does not ship the datasets or saved models needed to run those checks end-to-end.

## Related research and confidentiality

The `maryland-hmda-sdat-linkage` repository is a different study, not the complete reproduction source for this AVM paper. This GitHub repository is publicly associated with its owner's identity; review double-anonymous journal requirements before citing the repository in a blind manuscript.
