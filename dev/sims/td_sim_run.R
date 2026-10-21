# Monte Carlo validation of the proportional-TD estimators (TD_E_LOGS, TD_PR).
#
#   Rscript dev/sims/td_sim_run.R <n> <corr> <reps> <out.rds> [cores] [seed_offset]
#
# corr in {iid, panel}; see dev/sims/td_sim_module.R for the DGP, truths and targets.
# Seeds: replication r uses set.seed(1e6 * corr_code + 1e3 * n_code + r), so any replication can
# be re-run on its own; seed_offset (default 0) shifts r to draw fresh replications.
# Output: one row per replication x target x method (see one_rep()).
args <- commandArgs(trailingOnly = TRUE)
n <- as.integer(args[1]); corr <- args[2]; reps <- as.integer(args[3]); out <- args[4]
cores <- if (length(args) >= 5) as.integer(args[5]) else 4L
seed_offset <- if (length(args) >= 6) as.integer(args[6]) else 0L
source(here::here("dev", "sims", "td_sim_module.R"))

corr_code <- match(corr, c("iid", "panel"))
res <- parallel::mclapply(seq_len(reps), function(r) {
  set.seed(1e6 * corr_code + 1e3 * (n %/% 1000) + r + seed_offset)
  x <- one_rep(n, corr)
  x$rep <- r
  x
}, mc.cores = cores)
bad <- vapply(res, inherits, logical(1), "try-error")
if (any(bad)) warning(sum(bad), " replications failed")
res <- do.call(rbind, res[!bad])
res$n <- n; res$corr <- corr
saveRDS(res, out)
cat("wrote", out, "with", nrow(res), "rows\n")
