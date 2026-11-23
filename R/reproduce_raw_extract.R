# Author-verified workflow consolidated into one read-only script.
# Input: RETAINED ORIGINAL raw SDAT CSV, archived tract-assigned CSV,
#        encoding metadata RDS, frozen models RDS.
# This is NOT a fresh independent download of the SDAT source.
# Requires data.table, sf, Matrix, xgboost.
# Usage:
# Rscript R/reproduce_raw_extract.R RAW.csv ARCHIVED_TRACT.csv ENCODING.rds MODELS.rds
suppressPackageStartupMessages({
  library(data.table)
  library(sf)
  library(Matrix)
  library(xgboost)
})
a <- commandArgs(trailingOnly = TRUE)
if (length(a) != 4L || !all(file.exists(a)))
  stop("Supply existing RAW.csv ARCHIVED_TRACT.csv ENCODING.rds MODELS.rds")
raw <- fread(file=a[1]); archive <- fread(file=a[2])
enc <- readRDS(a[3]); models <- readRDS(a[4])
stopifnot(nrow(raw)==128746L, nrow(archive)==63304L)
col <- list(
  convey="sales_segment_1_how_conveyed_ind_mdp_field_convey1_sdat_field_87",
  price="sales_segment_1_consideration_mdp_field_considr1_sdat_field_90",
  lon="mdp_longitude_mdp_field_digxcord_converted_to_wgs84",
  lat="mdp_latitude_mdp_field_digycord_converted_to_wgs84",
  dwelling="additional_c_a_m_a_data_dwelling_type_mdp_field_strubldg_sdat_field_265",
  land="land_use_code_mdp_field_lu_desclu_sdat_field_50",
  area="c_a_m_a_system_data_structure_area_sq_ft_mdp_field_sqftstrc_sdat_field_241",
  built="c_a_m_a_system_data_year_built_yyyy_mdp_field_yearblt_sdat_field_235",
  units="c_a_m_a_system_data_number_of_dwelling_units_mdp_field_bldg_units_sdat_field_239",
  date="sales_segment_1_transfer_date_yyyy_mm_dd_mdp_field_tradate_sdat_field_89",
  county="jurisdiction_code_mdp_field_jurscode"
)
stopifnot(all(unlist(col) %in% names(raw)),
          all(c(":id","GEOID") %in% names(archive)))
x <- copy(raw)[get(col$convey)=="Private arms-length transfer, Improved (1)"]
stopifnot(nrow(x)==65754L)
x[, `:=`(price=as.numeric(get(col$price)),
          lon=as.numeric(get(col$lon)),
          lat=as.numeric(get(col$lat)))]
x <- x[!is.na(price) & price>=10000 & price<=10000000]
stopifnot(nrow(x)==65578L)
x <- x[is.finite(lon) & is.finite(lat) &
       lon>=-180 & lon<=180 & lat>=-90 & lat<=90]
stopifnot(nrow(x)==63396L)
x <- x[!grepl("Boat Slip|Parking Space|Storage Unit|COMMUNITY Church",
              get(col$dwelling), ignore.case=TRUE)]
stopifnot(nrow(x)==63318L)
cat("Raw filtering: PASSED (128746 -> 65754 -> 65578 -> 63396 -> 63318)\n")

# Official cartographic 1:500,000 tracts; not TIGER/Line 2024.
work <- tempfile("md_cb_"); dir.create(work)
zipfile <- file.path(work,"tracts.zip")
on.exit <- NULL
download.file("https://www2.census.gov/geo/tiger/GENZ2024/shp/cb_2024_24_tract_500k.zip",
              zipfile, mode="wb", quiet=TRUE)
unzip(zipfile, exdir=work)
shp <- list.files(work,pattern="\\.shp$",full.names=TRUE)
stopifnot(length(shp)==1L)
tracts <- sf::st_transform(sf::st_read(shp,quiet=TRUE),4326)
stopifnot(nrow(tracts)==1464L)
points <- sf::st_as_sf(x,coords=c("lon","lat"),crs=4326,remove=FALSE)
hits <- sf::st_within(points, tracts)
stopifnot(all(lengths(hits)<=1L),sum(lengths(hits)==1L)==63304L)
idx <- which(lengths(hits)==1L)
x <- x[idx]
x[, GEOID := as.character(tracts$GEOID[vapply(hits[idx],`[`,integer(1),1L)])]
ids <- as.character(x[[":id"]])
ref_index <- match(ids,as.character(archive[[":id"]]))
stopifnot(!anyNA(ref_index), !anyDuplicated(ids),
          setequal(ids,as.character(archive[[":id"]])),
          identical(as.character(x$GEOID),as.character(archive$GEOID[ref_index])))
common <- setdiff(intersect(names(raw),names(archive)),"GEOID")
agrees <- vapply(common,function(nm) {
  p <- as.character(x[[nm]])
  q <- as.character(archive[[nm]][ref_index])
  identical(p,q)
},logical(1))
stopifnot(all(agrees))
cat("2024 cartographic tract assignment: PASSED (63304 IDs, 0 GEOID differences)\n")

x[, `:=`(area=as.numeric(get(col$area)),
          built=as.numeric(get(col$built)),
          units=as.numeric(get(col$units)),
          transfer_date=as.IDate(as.character(get(col$date)),format="%Y.%m.%d"))]
x <- x[!is.na(price) & price>=50000 & price<=5000000]
stopifnot(nrow(x)==62568L)
x <- x[!is.na(area) & area>=300 & area<=15000]
stopifnot(nrow(x)==60177L)
x <- x[!is.na(built) & built>=1700 & built<=2025]
stopifnot(nrow(x)==59504L)
x <- x[!is.na(units) & units==1L]
stopifnot(nrow(x)==58958L)
x <- x[!is.na(transfer_date) & transfer_date>=as.IDate("2025-01-01") &
       transfer_date<=as.IDate("2025-12-31")]
stopifnot(nrow(x)==58958L)
mapping <- c("Residential (R)"="Residential",
             "Residential Condominium (U)"="Condominium",
             "Town House (TH)"="Townhouse")
x[, dwelling_group := factor(unname(mapping[as.character(get(col$land))]),
                             levels=enc$dwelling_levels)]
x[, county := factor(as.character(get(col$county)),levels=enc$county_levels)]
x[, `:=`(transfer_month=as.integer(format(transfer_date,"%m")),
          log_price=log(price))]
stopifnot(!anyNA(x$dwelling_group),!anyNA(x$county))
train <- x[transfer_date<=as.IDate("2025-08-31")]
valid <- x[transfer_date>as.IDate("2025-08-31") &
           transfer_date<=as.IDate("2025-10-31")]
test <- x[transfer_date>as.IDate("2025-10-31")]
stopifnot(nrow(train)==38917L,nrow(valid)==10671L,nrow(test)==9370L)
cat("Model eligibility and temporal splits: PASSED\n")

hedonic_new <- lm(log_price~log(area)+built+dwelling_group+county+transfer_month,
                  data=train)
h_coef <- coef(hedonic_new); h_ref <- coef(models$hedonic)
stopifnot(setequal(names(h_coef),names(h_ref)),
          max(abs(h_coef-h_ref[names(h_coef)]))<1e-8)
hedonic_mae <- mean(abs(exp(predict(hedonic_new,newdata=test))-test$price))
stopifnot(abs(hedonic_mae-125279.97013)<0.01)
cat("Independent hedonic retraining: PASSED\n")

make_mat <- function(d) {
  m <- Matrix::sparse.model.matrix(enc$formula,data=d)
  stopifnot(identical(colnames(m),enc$feature_names))
  m
}
dtrain <- xgboost::xgb.DMatrix(make_mat(train),label=train$log_price)
dvalid <- xgboost::xgb.DMatrix(make_mat(valid),label=valid$log_price)
dtest <- xgboost::xgb.DMatrix(make_mat(test))
params <- list(objective="reg:squarederror",eval_metric="rmse",
               eta=0.05,max_depth=5,min_child_weight=10,
               subsample=0.85,colsample_bytree=0.90,gamma=0,
               lambda=1,alpha=0,tree_method="hist",max_bin=256,
               seed=2026,nthread=4)
set.seed(2026)
xgb_new <- xgboost::xgb.train(params=params,data=dtrain,nrounds=1200L,
                              evals=list(validation=dvalid),verbose=0)
validation_log <- predict(xgb_new,dvalid,iterationrange=c(1L,1195L))
test_log <- predict(xgb_new,dtest,iterationrange=c(1L,1195L))
archive_log <- predict(models$xgboost,dtest,iterationrange=c(1L,1195L))
validation_rmse <- sqrt(mean((validation_log-valid$log_price)^2))
test_mae <- mean(abs(exp(test_log)-test$price))
stopifnot(length(test_log)==9370L,
          max(abs(test_log-archive_log))<1e-8,
          abs(validation_rmse-0.2901576)<1e-6,
          abs(test_mae-103331.97923)<0.01)
cat(sprintf("Independent XGBoost retraining: PASSED; MAE %.8f; max log difference %.3g\n",
            test_mae,max(abs(test_log-archive_log))))
cat("LOCAL RAW-EXTRACT-TO-MODEL REPRODUCTION: PASSED (not a fresh SDAT download)\n")
