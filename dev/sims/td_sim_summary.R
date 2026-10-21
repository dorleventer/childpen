# Summarise Monte Carlo output of dev/sims/td_sim_run.R.
#
#   Rscript dev/sims/td_sim_summary.R <out1.rds> [out2.rds ...]
#
# Per (n, corr, target, method): mean bias and its MC standard error, the MC sd of the estimates,
# the mean clustered and unclustered SE, their ratio to the MC sd, and 95% coverage of
# est +- 1.96 se for both SEs (MC standard error of a coverage near 0.95 with R reps:
# sqrt(0.95 * 0.05 / R)).
files <- commandArgs(trailingOnly = TRUE)
x <- do.call(rbind, lapply(files, readRDS))
key <- interaction(x$n, x$corr, x$target, x$method, drop = TRUE, lex.order = TRUE)
s <- do.call(rbind, lapply(split(x, key), function(g) {
  R <- nrow(g); sd_mc <- stats::sd(g$est)
  data.frame(n = g$n[1], corr = g$corr[1], target = g$target[1], method = g$method[1], R = R,
             truth = g$truth[1],
             bias = mean(g$est - g$truth), bias_mcse = sd_mc / sqrt(R),
             sd_mc = sd_mc,
             ratio_cluster = mean(g$se_cluster) / sd_mc,
             ratio_row = mean(g$se_row) / sd_mc,
             cover_cluster = mean(abs(g$est - g$truth) <= 1.96 * g$se_cluster),
             cover_row = mean(abs(g$est - g$truth) <= 1.96 * g$se_row),
             est_equal = isTRUE(all.equal(g$est, g$est_row)))
}))
rownames(s) <- NULL
s$bias_z <- s$bias / s$bias_mcse
print(s[, c("n", "corr", "target", "method", "R", "truth", "bias", "bias_z", "sd_mc",
            "ratio_cluster", "ratio_row", "cover_cluster", "cover_row", "est_equal")],
      digits = 3, row.names = FALSE)
invisible(s)
