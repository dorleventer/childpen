# Speed / memory check for the row-subsetting change (T1737, PR "perf").
#
#   Rscript dev/perf_check.R <ref_checkout> <new_checkout>
#
# Runs the same multiple_treatment_group_analysis() call (20k persons, groups 24:28,
# event times 0..5, 4 pre periods) with both checkouts and reports run time, size of the
# stored influence functions, and the largest differences in estimates and SEs of the cell,
# aggregate and bias_bounds() rows (rounding only is expected: the subset version sums the
# same terms in a different order).
args <- commandArgs(trailingOnly = TRUE)
run <- function(path) {
  callr::r(function(path) {
    suppressMessages(pkgload::load_all(path, quiet = TRUE)); data.table::setDTthreads(1)
    s <- simulate_data(20000, 24:34, seed = 1)
    t0 <- Sys.time()
    r <- suppressMessages(multiple_treatment_group_analysis(s, 24:28, periods_post = 5,
                                                            periods_pre = 4, verbose = FALSE))
    list(secs = as.numeric(difftime(Sys.time(), t0, units = "secs")),
         mb = as.numeric(object.size(attr(r, "if_data"))) / 2^20,
         cells = r, agg = aggregate_estimands(r), bb = bias_bounds(r))
  }, args = list(path))
}
a <- run(args[1]); b <- run(args[2])
cat(sprintf("time %.1f s -> %.1f s; if_data %.1f MB -> %.1f MB\n", a$secs, b$secs, a$mb, b$mb))
cmp <- function(x, y, keys, what) {
  m <- merge(x, y, by = keys)
  cat(sprintf("%-11s rows %d/%d | max |diff| est %.1e, se %.1e | max |diff|/max(|est|, 1e-3) %.1e\n",
              what, nrow(m), nrow(x), max(abs(m$est.x - m$est.y)), max(abs(m$se.x - m$se.y)),
              max(abs(m$est.x - m$est.y) / pmax(abs(m$est.x), 1e-3))))
}
cmp(a$cells, b$cells, c("d", "dp", "a", "estimand", "method"), "cells")
cmp(a$agg, b$agg, c("event_time", "control_offset", "estimand", "method", "agg_type"), "aggregate")
cmp(a$bb, b$bb, c("d", "dp", "a", "theta_m"), "bias_bounds")
