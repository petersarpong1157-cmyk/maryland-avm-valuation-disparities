# Local staging only: no file uploads performed.
stage_local_exports <- function(out_dir) {
  stopifnot(dir.exists(out_dir))
  dest <- file.path(getwd(), "results", "source_exports")
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  source_rel <- c(
    "Phase5S_Final_Test/Final_Test_Accuracy.csv",
    "Phase5S_Final_Test/Final_Test_Improvement.csv",
    "Phase5S_Final_Test/Final_Test_Tract_Bootstrap.csv",
    "Phase5U_Test_Disparity/Final_Disparity_Coefficients.csv",
    "Phase5U_Test_Disparity/Final_Disparity_ACS_Coverage.csv",
    "Phase5U_Test_Disparity/Final_Disparity_Sample_Summary.csv",
    "Phase6A_Explainability/SHAP_Additivity_Check.csv",
    "Phase6A_Explainability/SHAP_Feature_Importance.csv",
    "Phase6A_Explainability/SHAP_Grouped_Importance.csv",
    "Phase6C_Manuscript_Evidence/Manuscript_Evidence_Checks.csv"
  )
  src <- file.path(out_dir, source_rel)
  if (any(!file.exists(src))) {
    print(data.frame(file=source_rel, exists=file.exists(src)))
    stop("Some source exports are unavailable. No files copied.")
  }
  target <- file.path(dest, basename(src))
  if (any(file.exists(target))) stop("Target files already exist; no overwrite.")
  ok <- file.copy(src, target, overwrite = FALSE)
  if (!all(ok)) stop("Some aggregate exports could not be copied.")
  manifest <- data.frame(
    file = basename(src),
    bytes = file.info(target)$size,
    md5 = unname(tools::md5sum(target))
  )
  write.csv(manifest, file.path(dest, "SOURCE_EXPORT_MANIFEST.csv"),
            row.names = FALSE)
  cat("Staged aggregate CSV exports locally:", length(src), "\n")
  cat("Do not publish them without content and disclosure review.\n")
  invisible(manifest)
}
