# Check aggregate reference consistency only; no original models are rerun.
root <- getwd()
if (!file.exists(file.path(root, "results", "reference_accuracy.csv")))
  stop("Set the R working directory to the repository root.")

a <- read.csv(file.path(root, "results", "reference_accuracy.csv"))
g <- read.csv(file.path(root, "results", "reference_gradients.csv"))
b <- read.csv(file.path(root, "results", "reference_bootstrap.csv"))
s <- read.csv(file.path(root, "results", "reference_shap_additivity.csv"))

stopifnot(
  nrow(a) == 2L,
  setequal(a$model, c("Hedonic", "XGBoost")),
  all(a$n == 9370L),
  nrow(g) == 3L,
  all(g$n == 9362L),
  nrow(b) == 1L,
  b$tracts == 1373L,
  b$B == 2000L,
  s$validation_rows == 2000L,
  s$features == 29L,
  s$selected_round == 1195L,
  s$max_additivity_error < 1e-3
)

h <- a[a$model == "Hedonic", ]
x <- a[a$model == "XGBoost", ]
gd <- setNames(g$estimate, g$model)

stopifnot(
  abs((h$mae - x$mae) - b$mae_advantage) < 1,
  abs(100 * (h$mae - x$mae) / h$mae - 17.51915) < 0.01,
  abs((gd[["XGBoost"]] - gd[["Hedonic"]]) -
       gd[["XGBoost minus Hedonic"]]) < 1e-5,
  b$ci_lower > 0 && b$ci_upper > b$ci_lower,
  g$ci_lower[g$model == "XGBoost minus Hedonic"] < 0,
  g$ci_upper[g$model == "XGBoost minus Hedonic"] < 0
)

cat("Aggregate reference consistency: PASSED\n")
cat("Original model/data independent re-execution: NOT PERFORMED\n")
