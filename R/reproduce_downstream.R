# Reproduce the downstream AVM study from LOCAL PROCESSED inputs.
# Usage:
# Rscript R/reproduce_downstream.R SDAT_2025_Market_Sales_With_Census_Tracts.csv \
#   Phase4B_ACS_2023_Maryland_Tracts.csv Frozen_AVM_Models.rds \
#   Verified_XGBoost_Encoding.rds
#
# Requires R packages: data.table, Matrix, xgboost, fixest
# This does NOT independently reproduce raw SDAT acquisition, tract construction,
# original model fitting, hyperparameter tuning, or archived bootstrap RNG draws.
# No raw data, predictions, property records or model objects are written to disk.

suppressPackageStartupMessages({
  library(data.table)
  library(Matrix)
  library(xgboost)
  library(fixest)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4L || !all(file.exists(args))) {
  stop("Pass four existing paths: processed_SDAT.csv ACS_tracts.csv Frozen_AVM_Models.rds Verified_XGBoost_Encoding.rds")
}
sdat <- fread(file = args[1])
acs <- fread(file = args[2])
models <- readRDS(args[3])
enc <- readRDS(args[4])

date_col <- "sales_segment_1_transfer_date_yyyy_mm_dd_mdp_field_tradate_sdat_field_89"
land_col <- "land_use_code_mdp_field_lu_desclu_sdat_field_50"
county_col <- "jurisdiction_code_mdp_field_jurscode"
required_sdat <- c(date_col, land_col, county_col, "GEOID",
                   "sale_price_clean", "sqft_clean", "year_built_clean",
                   "dwelling_units")
required_acs <- c("GEOID", "minority_share", "poverty_rate",
                  "median_household_income")
stopifnot(all(required_sdat %in% names(sdat)),
          all(required_acs %in% names(acs)),
          all(c("hedonic", "xgboost") %in% names(models)),
          all(c("formula", "feature_names", "dwelling_levels",
                "county_levels") %in% names(enc)))

x <- copy(sdat)
x[, transfer_date := as.IDate(as.character(get(date_col)), format = "%Y.%m.%d")]
x[, price := suppressWarnings(as.numeric(sale_price_clean))]
x[, area := suppressWarnings(as.numeric(sqft_clean))]
x[, built := suppressWarnings(as.numeric(year_built_clean))]
x[, units := suppressWarnings(as.numeric(dwelling_units))]
flow <- data.table(stage = "tract_assigned_source", remaining = nrow(x))
filter_step <- function(name, keep) {
  x <<- x[which(keep)]
  flow <<- rbind(flow, data.table(stage = name, remaining = nrow(x)))
}
filter_step("price_50k_to_5m", !is.na(x$price) & x$price >= 50000 & x$price <= 5000000)
filter_step("sqft_300_to_15000", !is.na(x$area) & x$area >= 300 & x$area <= 15000)
filter_step("built_1700_to_2025", !is.na(x$built) & x$built >= 1700 & x$built <= 2025)
filter_step("single_dwelling_unit", !is.na(x$units) & x$units == 1)
filter_step("valid_2025_sale_date", !is.na(x$transfer_date) &
              x$transfer_date >= as.IDate("2025-01-01") &
              x$transfer_date <= as.IDate("2025-12-31"))
filter_step("tract_assigned", !is.na(x$GEOID) & nzchar(trimws(as.character(x$GEOID))))
stopifnot(identical(flow$remaining, as.integer(c(63304,62568,60177,59504,58958,58958,58958))))
x[, split := fifelse(transfer_date <= as.IDate("2025-08-31"), "Training",
                     fifelse(transfer_date <= as.IDate("2025-10-31"),
                             "Validation", "Reserved test"))]
splits <- x[, .N, by = split]
expected_splits <- c(Training = 38917L, Validation = 10671L, `Reserved test` = 9370L)
stopifnot(setequal(splits$split, names(expected_splits)),
          all(splits$N == unname(expected_splits[splits$split])))
cat("Eligibility and splits: PASSED\n")

land_mapping <- c("Residential (R)" = "Residential",
                  "Residential Condominium (U)" = "Condominium",
                  "Town House (TH)" = "Townhouse")
x[, dwelling_group := factor(unname(land_mapping[as.character(get(land_col))]),
                             levels = enc$dwelling_levels)]
x[, county := factor(as.character(get(county_col)), levels = enc$county_levels)]
x[, transfer_month := as.integer(format(transfer_date, "%m"))]
stopifnot(!anyNA(x$dwelling_group), !anyNA(x$county),
          !anyNA(x$transfer_month))
training_counts <- table(x[split == "Training"]$dwelling_group)
saved_counts <- table(models$hedonic$model$dwelling_group)
stopifnot(identical(as.integer(training_counts), as.integer(saved_counts)))

te <- x[split == "Reserved test"]
mat <- Matrix::sparse.model.matrix(enc$formula, data = te)
stopifnot(identical(dim(mat), c(9370L, 29L)),
          identical(colnames(mat), enc$feature_names))
hedonic_price <- exp(as.numeric(predict(models$hedonic, newdata = te)))
xgb_price <- exp(as.numeric(predict(models$xgboost,
  xgboost::xgb.DMatrix(mat), iterationrange = c(1L,1195L))))
stopifnot(all(is.finite(hedonic_price)), all(is.finite(xgb_price)))
calc_metrics <- function(pred) {
  err <- abs(pred - te$price)
  c(MAE = mean(err), RMSE = sqrt(mean((pred-te$price)^2)),
    MdAPE_pct = median(err/te$price)*100,
    WAPE_pct = sum(err)/sum(te$price)*100,
    signed_log_pct = mean(log(pred/te$price))*100)
}
results <- rbind(Hedonic = calc_metrics(hedonic_price),
                 XGBoost = calc_metrics(xgb_price))
reference <- rbind(Hedonic = c(125279.97013, 216191.8, 18.73402, 24.41966, 6.681383),
                   XGBoost = c(103331.97923,192477.9,14.24990,20.14155,2.389248))
stopifnot(all(abs(results[, "MAE"] - reference[,1]) < .05),
          all(abs(results[, "RMSE"] - reference[,2]) < .2),
          all(abs(results[,3:5] - reference[,3:5]) < .002))
cat("Frozen-model test metrics: PASSED\n")
print(round(results, 4))

# A NEW verification bootstrap: same cluster approach, a different documented seed.
te[, tract := trimws(as.character(GEOID))]
err <- data.table(tract = te$tract, n = 1L,
                  gain = abs(te$price-hedonic_price)-abs(te$price-xgb_price))
by_tract <- err[, .(n=.N, gain=sum(gain)), by=tract]
stopifnot(nrow(by_tract) == 1373L)
set.seed(20261122)
b <- replicate(2000L, {
  chosen <- sample.int(nrow(by_tract), nrow(by_tract), replace=TRUE)
  sum(by_tract$gain[chosen])/sum(by_tract$n[chosen])
})
gain <- mean(err$gain)
ci <- unname(quantile(b,c(.025,.975),type=7))
stopifnot(abs(gain-21947.9909) < .05, ci[1]>0, ci[2]>ci[1])
cat("Observed improvement and new cluster bootstrap: PASSED\n")
print(data.frame(observed_MAE_gain=gain, audit_CI_low=ci[1], audit_CI_high=ci[2]))

# Re-link 2023 ACS tract data without changing or outputting individual records.
acs[, tract := trimws(as.character(GEOID))]
stopifnot(nrow(acs)==1475L, !anyDuplicated(acs$tract))
i <- match(te$tract, acs$tract)
stopifnot(!anyNA(i))
linked <- copy(te)
for (field in required_acs[-1]) linked[, (field) := acs[[field]][i]]
acs_fields <- required_acs[-1]
complete <- complete.cases(linked[, ..acs_fields])
stopifnot(sum(complete)==9362L,
          sum(!complete)==8L,
          uniqueN(linked$tract[complete])==1371L,
          all(!is.na(linked$minority_share)),
          all(!is.na(linked$poverty_rate)),
          all(is.na(linked$median_household_income[!complete])))
cat("ACS linkage / eight missing-income exclusions: PASSED\n")

# Re-estimate three disparity models from re-linked ACS and new frozen predictions.
z <- linked[complete]
idx <- which(complete)
# Create base columns before deriving errors; data.table evaluates := RHS
# expressions before columns created in the same call become accessible.
z[, `:=`(
  actual = price,
  hedonic_pred = hedonic_price[idx],
  xgb_pred = xgb_price[idx],
  property_group = factor(as.character(dwelling_group), levels=enc$dwelling_levels),
  minority_10pp = minority_share/10,
  poverty_10pp = poverty_rate/10,
  income_10k = median_household_income/10000,
  log_area = log(area),
  age_2025 = 2025-built
)]
z[, `:=`(
  hedonic_signed_log_pct = 100*log(hedonic_pred/actual),
  xgb_signed_log_pct = 100*log(xgb_pred/actual)
)]
z[, model_difference_pct := xgb_signed_log_pct - hedonic_signed_log_pct]
rhs <- "~ minority_10pp + log_area + age_2025 + i(property_group) + income_10k + poverty_10pp | county + transfer_month"
ys <- c(Hedonic="hedonic_signed_log_pct", XGBoost="xgb_signed_log_pct",
        Difference="model_difference_pct")
target_coef <- c(Hedonic=4.325953, XGBoost=3.004657, Difference=-1.321296)
target_se <- c(Hedonic=.4294612, XGBoost=.3175400, Difference=.2163723)
for (name in names(ys)) {
  f <- as.formula(paste(ys[[name]],rhs))
  fit <- fixest::feols(f, data=z, vcov=~tract, notes=FALSE)
  tab <- summary(fit, vcov=~tract)$coeftable
  beta <- unname(tab["minority_10pp","Estimate"])
  se <- unname(tab["minority_10pp","Std. Error"])
  cat(sprintf("%s gradient: %.6f; tract SE: %.7f\n", name,beta,se))
  stopifnot(nobs(fit)==9362L,
            abs(beta-target_coef[[name]])<.0001,
            abs(se-target_se[[name]])<.0001)
}
cat("Disparity regression coefficients and cluster SEs: PASSED\n")
cat("DOWNSTREAM REPRODUCTION PASSED (processed inputs and frozen models only).\n")
