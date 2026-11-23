# Reproducibility release checklist

## Completed local verification (author's RStudio session)
- [x] Dedicated AVM repository separated from earlier HMDA–SDAT linkage project.
- [x] Reference aggregate results and read-only consistency-check scripts uploaded.
- [x] Ten original Phase 5S, 5U, 6A and 6C aggregate CSVs **staged locally**, with an 11th MD5 manifest file; all 10 original MD5 checks matched.
- [x] Original versus GitHub-reference MAEs checked: both match within rounding tolerances.
- [x] Phase 7B: **18/18** numerical comparisons passed (bootstrap, coefficient, SE, sample sizes, SHAP additivity).
- [x] Phase 7C: manually inspected printed aggregate CSV tables; no row-level observations or apparent direct personal identifiers in the displayed cells. This is not a comprehensive disclosure-risk certification.
- [x] Phase 7D: all five recomputed SHAP group totals matched original reported aggregates; 29 feature rankings accounted for; N=9,370 test and 9,362 complete-case/1,371-tract sample accounting checked.
- [x] No figures, manuscripts, individual property rows, individual prediction rows, or model binaries uploaded.
- [x] Local audit directory excluded from Git via `.gitignore`.

## Outstanding release gates
- [ ] Independently review provider terms and full contents of each original export before any public publication. Original exports remain **local**, excluded by `.gitignore`.
- [ ] Recover / document the complete scripts for SDAT download, cohort selection, geospatial assignment, ACS linkage, feature encoding, model training, predictions, inference, bootstrap, SHAP, and geography analyses.
- [ ] Document input source versions, download dates, machine-independent configuration, dependencies, and original output checksums.
- [ ] Reproduce the original study **end to end** from independently sourced data in a fresh environment, compare all deliverables, and record any differences.
- [ ] Confirm double-anonymous review and AI-use publication policies before linking this author-identified public repository in a submitted manuscript.
- [ ] Decide on a tagged release/Zenodo archive only after a clearly labeled release scope and validation checks.

**Current scope:** summary-value consistency against author-generated outputs; **not** an independent full replication. No claim that the statistical estimation or original source processing was independently rerun.
