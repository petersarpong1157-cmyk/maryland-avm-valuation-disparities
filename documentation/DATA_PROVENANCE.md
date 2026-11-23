# Research data provenance and limitations

## Maryland SDAT
- Source: Maryland property-record data, Socrata dataset `ed4q-f8tm`.
- Author's 2025 residential-category downloaded sample: 128,746 records.
- Original local raw extract 128,746 records → improved arm's-length transfers 65,754 → consideration $10,000–$10 million 65,578 → valid coordinates 63,396 → non-dwelling exclusion 63,318 → tract-assigned 63,304; transactions use dates formatted `YYYY.MM.DD`.
- Independently recreated geographic assignment with the **2024 Maryland Census cartographic 1:500,000 tract polygons** (1,464 geometries). All 63,304 raw-record IDs and tract GEOIDs agreed with the original processed source (zero disagreements; 23/23 overlapping source columns identical). A test with standard TIGER/Line boundaries did not reproduce identical assignments and should not be substituted.
- Locally reconstructed sequential restrictions: sale price $50,000–$5,000,000 (736 excluded), structure area 300–15,000 square feet (2,391 excluded), build year 1700–2025 (673 excluded), single dwelling unit (546 excluded), valid 2025 date (0), tract assignment (0). **Remaining 58,958**, split chronologically 38,917 / 10,671 / 9,370.
- Source SDAT extraction completeness has **not** been independently certified against contemporaneous statewide totals.
- Property records can reflect changes after sale; prospective point-in-time availability of CAMA characteristics *as of transaction date* is not established.

## ACS
- Source: 2019–2023 ACS five-year detailed tables, Maryland tract geography; endpoint `https://api.census.gov/data/2023/acs/acs5`.
- `B03002_001E`: total population; `B03002_003E`: non-Hispanic White-alone population; `B19013_001E`: median household income; `B17001_001E`: poverty universe; `B17001_002E`: below poverty.
- Minority share = `100 * (1 - B03002_003E/B03002_001E)` for positive denominator; poverty rate = `100 * B17001_002E/B17001_001E` for positive denominator. Both are stored as **0–100 percent values**; `minority_10pp = minority_share / 10`, `poverty_10pp = poverty_rate / 10`.
- Prior independent Census API value verification matched comparable archived values: total population 1,475/1,475; minority share 1,460/1,460; median household income 1,450/1,450; poverty 1,456/1,456.
- Archived ACS tract source comprises 1,475 unique 11-digit GEOIDs; 11 zero-population special-series tracts absent from 1,464 archived cartographic tract boundaries; four mapped zero-population tracts have missing minority share.
- In a new **local join to the archived tract source**, all 9,370 held-out 2025 sales matched a GEOID (none unmatched). Minority share and poverty available for 9,370/9,370, household income for 9,362/9,370; eight records in two tracts excluded, leaving 9,362 and 1,371 tracts. Archived source-aligned actual prices and predictions matched exactly; linked covariates matched to floating-point precision.

## Model and validation
- Hedonic: `log_price ~ log(area) + built + dwelling_group + county + transfer_month`.
- Land-use category mapping: `Residential (R)` to Residential, `Residential Condominium (U)` to Condominium, `Town House (TH)` to Townhouse; 100% agreement in 38,734 uniquely matchable training transactions, with all 38,917 full training group totals also matching.
- XGBoost: **sparse** model matrix with 29 features in saved order; stored `best_iteration=1194` (0-based), prediction `iterationrange=c(1L,1195L)`. Using a dense matrix with explicit zeros caused large prediction errors and is **not equivalent** to the saved sparse-matrix feature semantics.
- Both frozen models' 9,370-test observation N, MAE, RMSE, median APE, WAPE and mean signed log prediction error matched archived aggregates to numerical precision.
- **November 23, 2026 independent local retraining:** A separate Rscript process successfully recreated raw-source filtering, geographic linkage, the 58,958-row modeling cohort, the hedonic model (exact coefficient agreement) and XGBoost training (exact 9,370 held-out log predictions, validation RMSE 0.2901576, test MAE $103,331.97923281); process exit code **0**. Archived frozen objects were used only to compare results. Archived observed MAE improvement $21,947.99 and archived tract-cluster bootstrap percentile CI [$18,753.05, $25,181.68]. A separate 2,000-replicate, 1,373-tract verification bootstrap with seed 20261122 yielded [$18,801.18, $25,254.95]; Monte Carlo intervals corroborate but are not identical.
- Three tract-clustered `fixest` regressions from archived 9,362-row data (1,371 tracts) with county/month fixed effects, property controls and neighborhood income/poverty controls were locally refitted; their complete coefficient vectors and minority-gradient SEs reproduced exactly to numerical precision.
- Runtime used in prior audits: R 4.5.2; xgboost 3.2.1.1; Matrix 1.7-6; data.table 1.17.8; fixest 0.14.2; sf 1.1-2. Frozen local model bundle MD5 `a9391c0075d95198e5676b7b12f2b456` (not publicly uploaded).

## Data-sharing and scope
This public repository does not contain transaction-level records, individual property identifiers, row-level predictions, trained model files, figures or manuscripts. Reproductions described were run by the author in the existing local research environment. The separate raw-extract runner reconstructed and retrained both models from the original **locally retained raw SDAT extract**, while the downstream runner used processed SDAT/ACS sources and frozen models for accuracy, bootstrap, linkage and regression checks. The repository is not a public stand-alone complete raw-to-all-results release; original SDAT re-download and third-party clean-environment reproduction remain unverified.

Signed-error relationships with neighborhood demographics are observational associations, not estimates of causal discrimination. Retrospective accuracy is not established prospective deployment performance.
