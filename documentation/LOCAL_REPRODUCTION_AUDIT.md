# Local downstream reproduction audit

**Study:** Explainable Automated Valuation Models and Neighborhood Valuation Disparities: Evidence from Maryland Property Transactions

**Audit type:** Author-executed reconstruction using retained processed SDAT transactions, archived ACS tract CSV, saved hedonic/XGBoost objects, saved disparity analysis data, and saved regression models, performed in the original RStudio research environment. This document records the originally verified downstream audit results. A subsequent, separate raw-extract-to-model reproduction, including model retraining, also PASSED in a standalone Rscript process on November 23, 2026; see the appendix below. No third-party independent clean rerun is claimed.

## Phase 7M: cohort and periods
Reconstructed original sequential eligibility flow:

| Stage | Remaining | Newly excluded |
| --- | ---: | ---: |
| Tract-assigned SDAT source | 63,304 | — |
| Price $50k–$5m | 62,568 | 736 |
| Area 300–15,000 sqft | 60,177 | 2,391 |
| Year built 1700–2025 | 59,504 | 673 |
| Single dwelling unit | 58,958 | 546 |
| Valid 2025 sale date | 58,958 | 0 |
| Tract assigned | 58,958 | 0 |

All seven archived stage counts matched. Reconstructed January–August training 38,917; September–October validation 10,671; November–December test 9,370.

## Phases 7R–7T: encoding and frozen held-out prediction
Archived hedonic model training frame had 38,917 observations. A five-field match (price, area, built, county, month) uniquely linked 38,734 training records (99.53%); in those, original model dwelling groups agreed 100% with SDAT land-use mapping:

| SDAT land use | Model class | Uniquely matched training observations |
| --- | --- | ---: |
| Residential (R) | Residential | 30,185 |
| Residential Condominium (U) | Condominium | 4,240 |
| Town House (TH) | Townhouse | 4,309 |

Full training category totals also matched: Residential 30,275; Condominium 4,265; Townhouse 4,377. Note: totals alone do not prove all 183 ambiguously matchable records have matching row-level category assignments.

The XGBoost design uses a 9,370 × 29 **sparse** matrix with saved column order and frozen `iterationrange=c(1L,1195L)`. A dense matrix with the same displayed numerical entries produced substantially different scores because unrepresented sparse entries differ from explicit zero entries to the booster.

Reconstructed frozen-model metrics matched archived figures to machine numerical precision:

| Metric (test N=9,370) | Hedonic | XGBoost |
| --- | ---: | ---: |
| MAE ($) | 125,279.97 | 103,331.98 |
| RMSE ($) | 216,191.8 | 192,477.9 |
| MdAPE (%) | 18.73402 | 14.24990 |
| WAPE (%) | 24.41966 | 20.14155 |
| Mean signed log error (%) | +6.681383 | +2.389248 |

The observed MAE improvement is $21,947.99, or 17.52% relative to the hedonic MAE.

## Phases 7U–7V: tract cluster bootstrap
- Original sample: 9,370 sales in 1,373 tracts; 2,000 bootstrap replications.
- Archived observed improvement $21,947.99; archived percentile 95% interval [$18,753.05, $25,181.68].
- Independent verification: same cluster-level sampling approach, 2,000 replications, verification seed 20261122; calculated observed improvement $21,947.99 (machine-level match); verification interval [$18,801.18, $25,254.95].
- Verification CI lower/upper differences versus archive: +$48.13 and +$73.27. All 2,000 verification replicates had positive differences; verification bootstrap SD $1,634.851.
- Interpretation: **independently corroborated uncertainty, not exact recovery of original RNG or archived percentile limits.**

## Phases 7X–7Z: neighborhood regressions
The archived `Final_Disparity_Analysis_Data.rds` has 9,362 complete cases, 21 columns, 1,371 distinct tracts. Three `fixest::feols` formulas use the same right-hand side, differing only by dependent variable:

```r
outcome ~ minority_10pp + log_area + age_2025 +
  i(property_group) + income_10k + poverty_10pp |
  county + transfer_month
```

Outcomes: `hedonic_signed_log_pct`, `xgb_signed_log_pct`, and `model_difference_pct`. Refit with `vcov=~tract`. Complete saved versus refitted coefficient vectors matched exactly (maximum absolute difference 0); clustered SEs matched within about 3.4e-16.

| Outcome | Minority-share coefficient per 10pp | Tract-cluster SE | 95% normal CI |
| --- | ---: | ---: | --- |
| Hedonic | +4.325953 | 0.4294612 | [3.484209, 5.167697] |
| XGBoost | +3.004657 | 0.3175400 | [2.382279, 3.627035] |
| XGBoost minus hedonic | -1.321296 | 0.2163723 | [-1.745386, -0.897206] |

Verified original variables store `minority_share` and `poverty_rate` as 0–100 percentages, and regression covariates divide each by 10; income is divided by 10,000. Age, log-area and signed-log-error transformations also reproduced exactly.

## Phase 8B: independent ACS-to-test linkage
Loaded locally retained ACS tract table with 1,475 unique 11-digit GEOIDs and joined to 9,370 reconstructed held-out transactions by GEOID, preserving row order.

- GEOID matches 9,370/9,370; 0 unmatched.
- Minority shares 9,370/9,370; poverty rates 9,370/9,370; median household income 9,362/9,370.
- Exactly 8 observations from 2 tracts missing household income; complete cases 9,362 from 1,371 tracts.
- Archived regression analysis `row_order` contains valid indices with no duplicates and exactly the same complete-case row set.
- Reconstructed actual and both predicted prices agreed with archived aligned values exactly (maximum difference 0).
- ACS covariate maximum absolute differences: minority share ~7.11e-14; household income 0; poverty rate ~5.68e-14.

## Scope and safeguards
- The downstream checks documented in Phases 7–8 use **already processed** SDAT and ACS extracts and saved model artifacts. **Separately**, Phase 9 subsequently reproduced original local raw-extract filtering, tract assignment and model retraining (details below). Historical raw acquisition, third-party rerunning and one single complete raw-to-all-results script have not been verified.
- The local Phase 7 SHAP aggregate and reference consistency checks are separate from full SHAP re-execution.
- Test-set predictions were not used to determine the dwelling-group rule; it was recovered by joining the original **training frame** to source training observations and checked against SDAT land-use classes.
- All transaction-level data, individual property fields, private model binaries, original aggregate exports, manuscript and figures remain outside this GitHub release.
- This is a report of locally executed verification steps, not third-party independently validated findings. Statistical disparity gradients are conditional associations and should not be represented as proof of discrimination.

## Phase 9: raw-extract-to-model independently retrained locally — November 23, 2026

The author executed [`R/reproduce_raw_extract.R`](../R/reproduce_raw_extract.R) using a separate `Rscript.exe` subprocess. **Exit code: 0**. The script uses the retained original raw 128,746-row SDAT extract; archived tract-assigned CSV and frozen models serve only as comparison benchmarks, **not** as training data or fitted coefficients/trees.

- Reconstructed sequential upstream transaction counts: **128,746 → 65,754 → 65,578 → 63,396 → 63,318 → 63,304**.
- Identified **2024 Maryland cartographic 1:500,000** tract boundaries (1,464 polygons), reproducing all 63,304 archived transaction IDs and tract GEOIDs, with **zero disagreements**; all 23 overlapping original source columns matched.
- Rebuilt eligibility **58,958** and train/validation/test splits **38,917 / 10,671 / 9,370**.
- Fitted a new hedonic model independently: full coefficient match (max absolute difference **0**), test MAE $125,279.97.
- Trained XGBoost anew with archived recorded hyperparameters: all 9,370 held-out log predictions matched exactly (max difference **0**); validation log RMSE **0.2901576**; test MAE **$103,331.97923281**.
- No original model objects, raw source files, manuscripts, property records, or figures were modified or uploaded.

This is **author-executed local reproduction**, not a new public SDAT download, independent snapshot reconciliation, prospective performance evaluation, third-party replication, or complete reconstruction of all SHAP/figures/outputs.
