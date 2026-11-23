# Research data provenance and limitations

## Maryland SDAT
- Source: Maryland property-record data, Socrata dataset `ed4q-f8tm`.
- Author's retrospective residential-category downloaded sample: 128,746 2025-dated transactions.
- After sequential restrictions and tract linkage: 63,304 tract-assigned transactions.
- Eligible AVM sample: 58,958, split chronologically into 38,917 train / 10,671 validation / 9,370 reserved test.
- Complete independence of the source API extraction from contemporaneous statewide totals **has not been certified**.
- Property-record updates occurred after sales; availability of CAMA characteristics *as of transaction date* is not established.

## ACS
- Source: 2019–2023 ACS five-year detailed tables, state Maryland, tract geography; endpoint `https://api.census.gov/data/2023/acs/acs5`.
- `B03002_001E`: total population.
- `B03002_003E`: non-Hispanic White-alone population.
- `B19013_001E`: median household income.
- `B17001_001E`: population for whom poverty status is determined.
- `B17001_002E`: population below poverty.
- Minority share = `100 * (1 - B03002_003E/B03002_001E)`, valid when population is positive.
- Poverty rate = `100 * B17001_002E/B17001_001E`, valid when denominator is positive.
- Independent Census API verification matched all comparable saved values: total population 1,475/1,475; minority share 1,460/1,460; median income 1,450/1,450; poverty 1,456/1,456.
- 1,475 ACS tract IDs included 11 zero-population special-series tracts absent from the archived 1,464-tract cartographic boundaries. Four mapped tracts have zero population and missing minority share.

## Model and validation
- Hedonic formula: `log_price ~ log(area) + built + dwelling_group + county + transfer_month`.
- XGBoost model input: 29 encoded features; stored best_iteration attribute 1194; frozen prediction protocol `iterationrange=c(1L,1195L)`.
- Original 10,671 validation predictions reproduced with maximum dollar difference of zero.
- Environment: R 4.5.2; xgboost 3.2.1.1; Matrix 1.7-6; data.table 1.17.8; fixest 0.14.2; sf 1.1-2.
- Frozen model archive checksum (not included): MD5 `a9391c0075d95198e5676b7b12f2b456`.

## Public-data safety
This repository does not include transaction-level source files, raw personal or property identifiers, row-level model predictions, trained model binaries, manuscripts or figures.

The signed-error demographic gradients are associations, not causal discrimination estimates; test accuracy is retrospective rather than demonstrated prospective deployment performance.
