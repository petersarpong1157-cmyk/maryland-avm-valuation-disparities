# Reproducibility release checklist

## Completed locally (author's existing RStudio environment)
- [x] Separate public AVM repository with reference aggregate consistency script, aggregate tables, documentation, and exclusion rules.
- [x] Ten original aggregate exports staged **locally**; 10/10 staged MD5 matches; 18/18 earlier aggregate comparison checks passed; grouped SHAP sum/accounting checks passed.
- [x] Reconstructed original SDAT eligibility flow: 63,304 tract-assigned records to 58,958 eligible transactions; all seven stage counts matched.
- [x] Reproduced 38,917 training / 10,671 validation / 9,370 reserved-test counts.
- [x] Recovered SDAT land-use to dwelling-group mapping from uniquely matched **training** observations (38,734/38,917). Full training group totals match frozen training frame.
- [x] Reconstructed 29-feature sparse XGBoost encoding, frozen 1,195-round prediction protocol, and both models' held-out test aggregate metrics to numerical precision.
- [x] Independently reran a 2,000-replication tract-cluster bootstrap: observed $21,947.99 improvement reproduced, independently generated CI [$18,801.18, $25,254.95] close to archived [$18,753.05, $25,181.68]. **Exact archived percentile endpoints not reproduced**, original seed/protocol not known.
- [x] Independently matched all 9,370 held-out transactions to archived ACS tract source and reconstructed 9,362 complete cases / 1,371 tracts; confirmed eight exclusions solely from missing median household income in two tracts.
- [x] Verified archived analysis data row alignment: actual sales and both predictions matched exactly; three ACS regressors matched to numerical precision.
- [x] Refit three disparity regressions with `fixest`, county/month fixed effects, and tract-clustered standard errors; coefficient vectors and clustered SEs matched archive to numerical precision.
- [x] Verified minority-share and poverty-rate scaling from 0–100 percent values to units of ten percentage points.
- [x] No figures, manuscript, row-level transactions, individual predictions, or saved models uploaded.

## Outstanding release gates
- [ ] Independently review source-provider terms and full contents of all original exports before any publication; staged CSV exports remain local and git-ignored.
- [ ] Recover and publish a carefully redacted, runnable full pipeline for SDAT download/extraction, tract assignment, ACS construction and linkage, eligibility, encoding, model training, inference, SHAP, mapping, and outputs, with permitted data access instructions.
- [ ] Document independently verifiable source acquisition completeness and date-stamped point-in-time property-feature availability (not yet certified).
- [ ] Record exact original bootstrap RNG settings to reproduce percentile endpoints bit-for-bit, if available.
- [ ] Perform an independent fresh-environment end-to-end rerun including full model training and upstream raw data retrieval.
- [ ] Confirm journal confidentiality/double-anonymous rules before citing this identity-linked repository; confirm publication/AI-use policies where relevant.
- [ ] Review public-release scope and only then consider tagged release or archive.

**Scope:** substantial *author-executed local downstream reproduction* from processed inputs and frozen models. This public repository alone is **not** an executable complete replication package, and no external independent rerun is claimed. See [LOCAL_REPRODUCTION_AUDIT.md](LOCAL_REPRODUCTION_AUDIT.md).
