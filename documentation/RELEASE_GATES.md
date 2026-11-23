# Reproducibility release checklist

- [x] New AVM repository separated from the earlier HMDA–SDAT linkage project.
- [x] Reference aggregate metrics and read-only consistency check staged.
- [x] Research provenance and known data-timing limitations documented.
- [x] No figures or manuscripts in repository.
- [ ] Copy original Phase 5S, 5U, 6A and 6C *aggregate* exports into a **local** clone; inspect each file before publication.
- [ ] Recover / construct and independently verify standalone scripts for source extraction, cohort construction, feature encoding, training, predictions, regressions, SHAP, and mapping.
- [ ] Document source download timestamps, data access, packages, file hashes, and portable working-directory inputs.
- [ ] Reproduce the study from a fresh clone using independently obtained original data, without reading previously fitted session objects.
- [ ] Review all files for individual data, proprietary constraints, confidential records, access credentials, or row-level disclosure risks.
- [ ] Confirm journal double-anonymity requirements before citing this author-named public repository.
- [ ] Only then tag and archive a separately documented complete reproducibility release, as appropriate.

Do not describe this preliminary package as complete end-to-end reproduction.
