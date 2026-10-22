# Golden-master snapshot of every exported function.
#
#   Rscript dev/snapshot_all.R dev/snapshots/<name>.rds        # record
#   Rscript dev/snapshot_compare.R <baseline.rds> <new.rds>    # compare (exit 1 on any change)
#
# Every exported function is called on seeded data under the options it accepts, and the full
# return object (including attributes) is stored. dev/snapshot_compare.R requires every value in
# the baseline to be identical() in the new object; result rows are matched by their key columns,
# so new rows (e.g. a new method) and new columns are allowed, changed or missing ones fail.
#
# v0.3.0 renamed arguments and labels without aliases (max_age -> max_control_group, min_age ->
# min_pre_age; method/estimand labels): this script uses the new names, and
# dev/snapshot_compare.R maps the v0.2.x labels of an older baseline with dev/label_map_v030.R.
suppressMessages(pkgload::load_all(".", quiet = TRUE))
data.table::setDTthreads(1)
out_path <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(out_path)) stop("usage: Rscript dev/snapshot_all.R <out.rds>")

snap <- list()

# ---- simulate_data ----------------------------------------------------------------------------
sim <- simulate_data(n_individuals = 3000, treatment_groups = 24:30, seed = 11)
snap$simulate_data <- sim
snap$simulate_data_small <- simulate_data(n_individuals = 200, treatment_groups = 25:27, seed = 3)

# ---- single_treatment_group_analysis ------------------------------------------------------------
# post-treatment, pre-treatment, and a non-default pre offset; renamed columns via the *_name args
sim_renamed <- sim
names(sim_renamed) <- c("pid", "woman", "age_years", "D_first", "earnings")
snap$single <- list(
  post      = single_treatment_group_analysis(sim, d = 25, dp = 27, a = 26),
  post_e0   = single_treatment_group_analysis(sim, d = 26, dp = 27, a = 26),
  pre       = single_treatment_group_analysis(sim, d = 27, dp = 29, a = 23),
  pre2      = single_treatment_group_analysis(sim, d = 27, dp = 28, a = 26, pre = 2),
  renamed   = single_treatment_group_analysis(sim_renamed, d = 25, dp = 27, a = 26,
                                              Y_name = "earnings", age_name = "age_years",
                                              D_name = "D_first", id_name = "pid",
                                              female_name = "woman")
)

# ---- multiple_treatment_group_analysis ------------------------------------------------------------
multi <- multiple_treatment_group_analysis(sim, treatment_groups = 24:27, periods_post = 2,
                                           periods_pre = 2, verbose = FALSE)
snap$multiple <- list(
  default  = multi,
  no_pre   = multiple_treatment_group_analysis(sim, treatment_groups = 24:26, periods_post = 1,
                                               periods_pre = NULL, verbose = FALSE),
  bounded  = multiple_treatment_group_analysis(sim, treatment_groups = 24:27, periods_post = 3,
                                               periods_pre = 2, max_control_group = 29,
                                               min_pre_age = 21, verbose = FALSE)
)

# ---- aggregate_estimands --------------------------------------------------------------------------
fixed_w <- c("24" = 1, "25" = 2, "26" = 1, "27" = 3)
snap$aggregate <- list(
  sample      = aggregate_estimands(multi),
  uniform     = aggregate_estimands(multi, weights = NULL),
  fixed       = aggregate_estimands(multi, weights = fixed_w),
  # v0.2.3: errors (cartesian merge on pre-treatment rows with several controls); the error
  # message is recorded so a later fix shows up as a change here.
  with_pre    = tryCatch(aggregate_estimands(multi, include_pre = TRUE),
                         error = function(e) paste("ERROR:", conditionMessage(e))),
  some_method = aggregate_estimands(multi, methods = c("NTD", "DID_Female"))
)

saveRDS(snap, out_path)
cat("Snapshot written to", out_path, "\n")
