library(data.table)

# Proportional TD estimators (TD_E_LOGS, TD_PR): Leventer (2025), online
# appendix "Proportional DID and TD".

# ---------------------------------------------------------------------------
# Helper: noiseless panel with a multiplicative counterfactual
# ---------------------------------------------------------------------------
# Y(inf) = c_g * k_D * h(age); childbirth multiplies earnings by (1 + tau_g)
# from age D on. Then TD-E-LOGS and TD-PR hold exactly, and
#   Delta_rho = c_f (1 + tau_f) / (c_m (1 + tau_m)) - c_f / c_m
#   theta_pre gap = (tau_f - tau_m) * h(a) / h(d - 1)
mult_panel <- function(d_val, dp_val, ages = 20:30, n_per_cell = 20L,
                       c_f = 0.8, c_m = 1, tau_f = -0.4, tau_m = -0.05) {
  h <- function(a) 100 + 8 * (a - 20) - 0.2 * (a - 20)^2
  k <- function(D) exp(0.05 * D)
  cells <- expand.grid(D = c(d_val, dp_val), female = c(1L, 0L))
  out <- list(); id0 <- 0L
  for (j in seq_len(nrow(cells))) {
    D <- cells$D[j]; g <- cells$female[j]
    ids <- id0 + seq_len(n_per_cell); id0 <- id0 + n_per_cell
    df <- expand.grid(age = ages, id = ids)
    cg <- if (g == 1L) c_f else c_m
    tau <- if (g == 1L) tau_f else tau_m
    df$Y <- cg * k(D) * h(df$age) * ifelse(df$age >= D, 1 + tau, 1)
    df$female <- g; df$D <- as.integer(D)
    out[[j]] <- df
  }
  list(data = do.call(rbind, out), h = h,
       truth_rho = c_f * (1 + tau_f) / (c_m * (1 + tau_m)) - c_f / c_m,
       truth_theta_pre = function(a, d) (tau_f - tau_m) * h(a) / h(d - 1))
}

# Cell mean of Y
cm <- function(df, age, g, D) mean(df$Y[df$age == age & df$female == g & df$D == D])

# ---------------------------------------------------------------------------

test_that("TD_E_LOGS and TD_PR rows are returned with their estimands", {
  sim <- simulate_data(n_individuals = 300, seed = 50)
  res <- single_treatment_group_analysis(sim, d = 25L, dp = 27L, a = 26L)
  expect_equal(res$estimand[res$method == "TD_E_LOGS"][1], "rho_effect")
  expect_equal(res$estimand[res$method == "TD_PR"], "gap_theta_pre")
})

test_that("TD_E_LOGS and TD_PR equal their formulas in cell means", {
  sim <- simulate_data(n_individuals = 400, seed = 51)
  d <- 25L; dp <- 27L; a <- 26L
  res <- single_treatment_group_analysis(sim, d = d, dp = dp, a = a)

  x <- function(g) cm(sim, d - 1, g, d) * cm(sim, a, g, dp) / cm(sim, d - 1, g, dp)
  rho_obs <- cm(sim, a, 1, d) / cm(sim, a, 0, d)
  e_logs  <- rho_obs - x(1) / x(0)
  pr      <- (cm(sim, a, 1, d) - x(1)) / cm(sim, d - 1, 1, d) -
             (cm(sim, a, 0, d) - x(0)) / cm(sim, d - 1, 0, d)

  expect_equal(res$est[res$method == "TD_E_LOGS" & res$estimand == "rho_effect"], e_logs,
               tolerance = 1e-12)
  expect_equal(res$est[res$method == "TD_PR"], pr, tolerance = 1e-12)
})

test_that("with a multiplicative counterfactual both estimators recover their estimands", {
  p <- mult_panel(d_val = 25L, dp_val = 28L)
  for (a in 25:27) {
    res <- single_treatment_group_analysis(p$data, d = 25L, dp = 28L, a = a)
    expect_equal(res$est[res$method == "TD_E_LOGS" & res$estimand == "rho_effect"], p$truth_rho,
                 tolerance = 1e-10)
    expect_equal(res$est[res$method == "TD_PR"], p$truth_theta_pre(a, 25L), tolerance = 1e-10)
  }
  # pre-treatment target ages: both are zero
  res <- single_treatment_group_analysis(p$data, d = 25L, dp = 28L, a = 22L)
  expect_equal(res$est[res$method == "TD_E_LOGS" & res$estimand == "rho_effect"], 0, tolerance = 1e-10)
  expect_equal(res$est[res$method == "TD_PR"], 0, tolerance = 1e-10)
})

test_that("TD_E_LOGS and TD_PR standard errors match a cluster bootstrap", {
  skip_on_cran()
  sim <- simulate_data(n_individuals = 1500, seed = 52)
  d <- 25L; dp <- 27L; a <- 26L
  res <- single_treatment_group_analysis(sim, d = d, dp = dp, a = a)

  DT <- data.table::as.data.table(sim)
  ids <- unique(DT$id)
  set.seed(1)
  boot <- replicate(300, {
    draw <- data.table::data.table(id = sample(ids, replace = TRUE))
    draw[, new_id := .I]
    bs <- DT[draw, on = "id", allow.cartesian = TRUE]
    bs[, id := new_id][, new_id := NULL]
    r <- single_treatment_group_analysis(bs, d = d, dp = dp, a = a)
    c(r$est[r$method == "TD_E_LOGS" & r$estimand == "rho_effect"], r$est[r$method == "TD_PR"])
  })
  ratio <- c(res$se[res$method == "TD_E_LOGS" & res$estimand == "rho_effect"],
             res$se[res$method == "TD_PR"]) /
           apply(boot, 1, stats::sd)
  expect_true(all(abs(ratio - 1) < 0.2))
})

test_that("if_scores carry the new influence functions", {
  sim <- simulate_data(n_individuals = 300, seed = 53)
  res <- single_treatment_group_analysis(sim, d = 25L, dp = 27L, a = 26L)
  expect_true(all(c("if_td_e_logs", "if_td_pr") %in% names(attr(res, "if_scores"))))
})

test_that("aggregate_estimands aggregates TD_E_LOGS and TD_PR by default", {
  sim <- simulate_data(n_individuals = 600, seed = 54)
  res <- multiple_treatment_group_analysis(sim, treatment_groups = 24:26,
                                           periods_post = 1L, periods_pre = NULL,
                                           verbose = FALSE)
  agg <- aggregate_estimands(res)
  rho <- agg[agg$method == "TD_E_LOGS" & agg$estimand == "rho_effect", ]
  pr  <- agg[agg$method == "TD_PR", ]
  expect_equal(unique(rho$agg_type), "weighted_avg")
  expect_equal(unique(rho$estimand), "rho_effect")
  expect_equal(unique(pr$agg_type), "weighted_avg")
  expect_equal(unique(pr$estimand), "gap_theta_pre")
  expect_true(all(rho$se > 0) && all(pr$se > 0))

  # point estimate = sample-weighted average of the single-group estimates
  n_d <- table(unique(sim[, c("id", "D")])$D)
  sub <- res[res$method == "TD_E_LOGS" & res$estimand == "rho_effect" & res$event_time == 0, ]
  w <- as.numeric(n_d[as.character(sub$d)]); w <- w / sum(w)
  expect_equal(rho$est[rho$event_time == 0], sum(w * sub$est), tolerance = 1e-12)
})
