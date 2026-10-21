# Monte Carlo validation of the proportional-TD estimators (TD_E_LOGS, TD_PR): shared module.
# Sourced by dev/sims/td_sim_run.R. Defines the DGP, the true estimands, and one replication.
#
# DGP (balanced panel, one row per person and age)
#   Y_ia = c_g * exp(s_D(a)) * (1 + tau_g(a - D) * 1{a >= D}) * U_ia
#   s_D(a) = 10 + (0.06 + 0.004 (D - 28)) (a - 20) - 0.0015 (a - 20)^2     group-specific slope:
#            later first births have steeper counterfactual trajectories, so parallel trends
#            fails within gender in levels and in logs of means.
#   c_f = 0.8, c_m = 1: gender scales counterfactual earnings proportionally, so the trend gaps in
#            proportional form are equal across gender: TD-E-LOGS and TD-PR hold (so does NTD).
#   tau_f(e) = -0.35 + 0.02 e, tau_m(e) = -0.02                         effects by event time e
#   U_ia = exp(alpha_i + eps_ia - (sd_alpha^2 + sd_eps^2) / 2), so E[U] = 1
#     corr = "iid":   alpha_i = 0, eps iid N(0, 0.25)
#     corr = "panel": alpha_i ~ N(0, 0.15), eps AR(1) with rho = 0.6, stationary variance 0.10
#                     (same total variance; outcomes are correlated within person across ages)
#
# True estimands (treatment group d, target age a, event time e = a - d)
#   Delta_rho     = c_f (1 + tau_f(e)) / (c_m (1 + tau_m(e))) - c_f / c_m          (TD_E_LOGS)
#   theta_pre gap = (tau_f(e) - tau_m(e)) * exp(s_d(a) - s_d(d - 1))              (TD_PR)
#   Pre-treatment target ages (a < d - 1): both are zero.
suppressMessages(pkgload::load_all(here::here(), quiet = TRUE))
data.table::setDTthreads(1)

par <- list(c_f = 0.8, c_m = 1, groups = 24:33, ages = 20:33,
            tau_f = function(e) -0.35 + 0.02 * e, tau_m = function(e) rep(-0.02, length(e)))
s_D <- function(D, a) 10 + (0.06 + 0.004 * (D - 28)) * (a - 20) - 0.0015 * (a - 20)^2

make_data <- function(n, corr = c("iid", "panel")) {
  corr <- match.arg(corr)
  ages <- par$ages; T <- length(ages)
  female <- rep(c(1L, 0L), length.out = n)
  D <- sample(par$groups, n, replace = TRUE)
  if (corr == "iid") {
    v_a <- 0; v_e <- 0.25
    eps <- matrix(stats::rnorm(n * T, 0, sqrt(v_e)), n, T)
  } else {
    v_a <- 0.15; v_e <- 0.10; rho <- 0.6
    eps <- matrix(0, n, T)
    eps[, 1] <- stats::rnorm(n, 0, sqrt(v_e))
    for (t in 2:T) eps[, t] <- rho * eps[, t - 1] + stats::rnorm(n, 0, sqrt(v_e * (1 - rho^2)))
  }
  alpha <- stats::rnorm(n, 0, sqrt(v_a))
  U <- exp(alpha + eps - (v_a + v_e) / 2)
  dt <- data.table::data.table(id = rep(seq_len(n), times = T), age = rep(ages, each = n),
                               female = rep(female, times = T), D = rep(D, times = T),
                               U = as.vector(U))
  dt[, e := age - D]
  dt[, cg := data.table::fifelse(female == 1L, par$c_f, par$c_m)]
  dt[, tau := data.table::fifelse(e >= 0,
                                  data.table::fifelse(female == 1L, par$tau_f(e), par$tau_m(e)), 0)]
  dt[, Y := cg * exp(s_D(D, age)) * (1 + tau) * U]
  dt[, .(id, age, female, D, Y)]
}

truth <- function(d, a) {
  e <- a - d
  if (a < d) return(c(TD_E_LOGS = 0, TD_PR = 0))
  c(TD_E_LOGS = par$c_f * (1 + par$tau_f(e)) / (par$c_m * (1 + par$tau_m(e))) - par$c_f / par$c_m,
    TD_PR = (par$tau_f(e) - par$tau_m(e)) * exp(s_D(d, a) - s_D(d, d - 1)))
}

# Targets: (d, a, dp). Post-treatment uses the closest not-yet-treated control dp = a + 1;
# pre-treatment placebos use dp = d + 3.
targets <- data.frame(
  d  = c(26, 26, 26, 30, 26),
  a  = c(26, 28, 30, 31, 23),
  dp = c(27, 29, 31, 32, 29),
  label = c("d26_e0", "d26_e2", "d26_e4", "d30_e1", "d26_pre_e-3")
)

# One replication: clustered SEs (by person, the package default) and unclustered SEs (each
# person-age row its own cluster, obtained by passing the row index as `id`; point estimates are
# unchanged because `id` only enters the SEs and the counts).
# Speed: each call gets only the rows that enter the estimator (groups d and dp, ages d - 1 and
# a). This leaves the estimates unchanged; the SE changes only through the small-sample factor
# G / (G - 1), where G becomes the number of persons in groups d and dp (thousands here).
one_rep <- function(n, corr) {
  dat <- make_data(n, corr)
  out <- vector("list", nrow(targets))
  for (k in seq_len(nrow(targets))) {
    tg <- targets[k, ]
    sub <- dat[D %in% c(tg$d, tg$dp) & age %in% c(tg$d - 1, tg$a)]
    sub_row <- data.table::copy(sub)[, id := .I]
    rc <- single_treatment_group_analysis(sub, d = tg$d, dp = tg$dp, a = tg$a)
    ru <- single_treatment_group_analysis(sub_row, d = tg$d, dp = tg$dp, a = tg$a)
    keep <- c("TD_E_LOGS", "TD_PR")
    rc <- rc[rc$method %in% keep, ]; ru <- ru[ru$method %in% keep, ]
    tr <- truth(tg$d, tg$a)
    out[[k]] <- data.frame(target = tg$label, d = tg$d, a = tg$a, dp = tg$dp, method = rc$method,
                           truth = unname(tr[rc$method]), est = rc$est,
                           se_cluster = rc$se, se_row = ru$se[match(rc$method, ru$method)],
                           est_row = ru$est[match(rc$method, ru$method)])
  }
  do.call(rbind, out)
}
