# childpen: findings to address in the UX sweep (T1737)

Collected while adding the proportional-TD estimators (T1735) and running their simulations
(T1736). Each item is a behaviour change or a bug; the UX sweep decides the fix and the
golden-master gate (dev/snapshot_compare.R) confirms estimates do not move.

1. **`aggregate_estimands(include_pre = TRUE)` errors** (v0.2.3). Pre-treatment rows have
   several control groups per (d, event_time, method); the `ratio_of_avgs` merge on
   (d, event_time, method) is then a cartesian join and data.table stops. Recorded as an error
   string in dev/snapshots/baseline_v0.2.3.rds.
2. **`single_treatment_group_analysis()` modifies a data.table input in place.** When `data`
   is a data.table it is used as is: no column renaming, type coercion or validation
   (`prep_data_table()` is skipped), and about 40 influence-function columns are added to the
   caller's table by reference.
3. **Speed.** Every (d, dp, a) call computes cell means and influence functions over all rows,
   although only groups d and dp at ages d - pre and a enter. About 0.85 s per call on 28k
   rows; `multiple_treatment_group_analysis()` repeats this for every triplet, so on the
   paper's data (13.7M rows) a run is very slow. Subsetting the rows changes nothing in the
   estimates; the SE is unchanged if the cluster count G in G / (G - 1) is kept as the total.

## For the site review (T1738), from the v0.3.0 vignette label sweep
1. estimation.Rmd: "five estimators"; TD_E_LOGS, TD_PR and the accounting rows (rho_obs, rho_cf,
   share_parenthood, share_other) are not described; "## NTD" section vs "### NTD" method.
2. validation_tests.Rmd: the "all methods" plot shows DID_Female, DID_Male, TD, Conventional only;
   NTD / TD_E_LOGS / TD_PR pre-treatment rows not shown.
3. aggregate-estimands.Rmd: "three aggregate estimands"; Conventional aggregate labelled
   theta_Agg,1 (it is the gap Delta theta_Agg); min_pre_age only affects pre cells (excluded by
   default); t and p columns and the five weighted_avg estimands per NTD / TD_E_LOGS undescribed;
   cites "Appendix G" (should be C.1).
4. NTD-identification.Rmd: no pointer to bias_bounds().
5. No accounting-exercise walk-through anywhere; no function reference index in _pkgdown.yml.
