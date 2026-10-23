library(data.table)

# v0.3.0: input validation, argument checks, new rows (accounting shares),
# bias_bounds(), aggregation of the new rows, weights checks.

sim0 <- simulate_data(n_individuals = 600, treatment_groups = 24:28, seed = 70)

# ---- input validation ---------------------------------------------------------

test_that("text gender codes outside the recognised labels are an error", {
  s <- sim0; s$female <- ifelse(s$female == 1, "2", "1")   # register coding 1 = male, 2 = female
  expect_error(single_treatment_group_analysis(s, 25, 26, 25), "not a recognised gender label")
  s$female <- ifelse(sim0$female == 1, "Kvinde", "Mand")
  expect_error(single_treatment_group_analysis(s, 25, 26, 25), "not a recognised gender label")
  s$female <- ifelse(sim0$female == 1, "female", "male")
  expect_equal(single_treatment_group_analysis(s, 25, 26, 25)$est,
               single_treatment_group_analysis(sim0, 25, 26, 25)$est)
})

test_that("missing outcomes are dropped with a message, not propagated", {
  s <- sim0; s$Y[which(s$D == 28)[1:3]] <- NA
  expect_message(r <- single_treatment_group_analysis(s, 25, 26, 25), "Dropping 3 rows")
  expect_true(all(is.finite(r$est)))
})

test_that("a missing age at first birth means never treated", {
  s <- sim0; s$D[s$id %in% 1:10] <- NA
  expect_message(r <- single_treatment_group_analysis(s, 25, 26, 25), "never having a child")
  expect_true(all(is.finite(r$est)))
})

test_that("panel-structure errors stop with a message", {
  s <- rbind(sim0, sim0[1, ])
  expect_error(single_treatment_group_analysis(s, 25, 26, 25), "repeat an \\(id, age\\) pair")
  s <- sim0; s$female[s$id == 1 & s$age == 20] <- 1 - s$female[s$id == 1 & s$age == 20]
  expect_error(single_treatment_group_analysis(s, 25, 26, 25), "varies within person")
  expect_error(single_treatment_group_analysis(sim0, 25, 26, 25, Y_name = "earnings"),
               "argument `Y_name`")
})

test_that("a data.table input is not modified, and the *_name arguments work for it", {
  dt <- data.table::as.data.table(sim0)
  before <- data.table::copy(dt)
  single_treatment_group_analysis(dt, 25, 26, 25)
  expect_identical(dt, before)
  data.table::setnames(dt, c("id", "Y"), c("pid", "earn"))
  r <- single_treatment_group_analysis(dt, 25, 26, 25, id_name = "pid", Y_name = "earn")
  expect_equal(r$est, single_treatment_group_analysis(sim0, 25, 26, 25)$est)
})

# ---- argument checks -------------------------------------------------------------

test_that("invalid 2x2 comparisons are rejected", {
  expect_error(single_treatment_group_analysis(sim0, 25, 26, 26), "not yet be treated")
  expect_error(single_treatment_group_analysis(sim0, 26, 25, 24), "after the treatment group")
  expect_error(single_treatment_group_analysis(sim0, 25, 27, 24, pre = 0), "at least 1")
  expect_error(single_treatment_group_analysis(sim0, 25, 27, 24), "baseline age")
})

test_that("multiple_treatment_group_analysis checks periods and reports skipped cells", {
  expect_error(multiple_treatment_group_analysis(sim0, 24:25, periods_post = 0:2, verbose = FALSE),
               "one whole number")
  r <- multiple_treatment_group_analysis(sim0, 24:25, periods_post = 1, periods_pre = 0,
                                         verbose = FALSE)
  expect_true(all(r$event_time >= 0))
  expect_true(is.data.frame(attr(r, "skipped")))
  expect_error(multiple_treatment_group_analysis(sim0, 30:31, periods_post = 0, verbose = FALSE),
               "No cell could be estimated")
})

# ---- accounting rows ---------------------------------------------------------------

test_that("accounting shares are consistent with the ratio rows", {
  r <- single_treatment_group_analysis(sim0, 25, 27, 26)
  for (m in c("NTD", "TD_E_LOGS")) {
    g <- function(e) r$est[r$method == m & r$estimand == e]
    expect_equal(g("share_parenthood"), (g("rho_cf") - g("rho_obs")) / (1 - g("rho_obs")),
                 tolerance = 1e-12)
    expect_equal(g("share_other"), 1 - g("share_parenthood"), tolerance = 1e-12)
    expect_equal(g("rho_effect"), g("rho_obs") - g("rho_cf"), tolerance = 1e-12)
  }
})

# ---- bias_bounds ---------------------------------------------------------------------

test_that("bias_bounds equals Proposition 2 in cell means and is linear in theta_m", {
  res <- multiple_treatment_group_analysis(sim0, 24:25, periods_post = 1, periods_pre = NULL,
                                           verbose = FALSE)
  bb <- bias_bounds(res, theta_m = c(-0.1, 0, 0.1))
  r <- res[res$d == 25 & res$event_time == 1, ]
  g <- function(m, e) r$est[r$method == m & r$estimand == e]
  mu_f <- g("NTD", "rho_obs")                      # mu_f / mu_m at age a
  apo_f <- g("DID_Female", "APO"); apo_m <- g("DID_Male", "APO")
  # Prop. 2 at theta(m) = 0: theta(f) - theta(m) = mu_f/mu_m * apo_m/apo_f - 1
  b0 <- bb$est[bb$d == 25 & bb$event_time == 1 & bb$theta_m == 0]
  expect_equal(b0, mu_f * apo_m / apo_f - 1, tolerance = 1e-12)
  b <- bb[bb$d == 25 & bb$event_time == 1, ]
  expect_equal(b$est, b0 * (1 + b$theta_m), tolerance = 1e-12)
})

test_that("standard errors of the share and of bias_bounds match a cluster bootstrap", {
  skip_on_cran()
  sim <- simulate_data(n_individuals = 1500, treatment_groups = 24:27, seed = 71)
  stat <- function(dat) {
    r <- multiple_treatment_group_analysis(dat, 25, periods_post = 0, periods_pre = NULL,
                                           verbose = FALSE)
    c(share = r$est[r$method == "NTD" & r$estimand == "share_parenthood"],
      bb = bias_bounds(r, theta_m = 0)$est)
  }
  r <- multiple_treatment_group_analysis(sim, 25, periods_post = 0, periods_pre = NULL,
                                         verbose = FALSE)
  se_if <- c(r$se[r$method == "NTD" & r$estimand == "share_parenthood"],
             bias_bounds(r, theta_m = 0)$se)
  DT <- data.table::as.data.table(sim); ids <- unique(DT$id)
  set.seed(2)
  boot <- replicate(250, {
    draw <- data.table::data.table(id = sample(ids, replace = TRUE))
    draw[, new_id := .I]
    bs <- DT[draw, on = "id", allow.cartesian = TRUE]
    bs[, id := new_id][, new_id := NULL]
    suppressMessages(stat(bs))
  })
  expect_true(all(abs(se_if / apply(boot, 1, stats::sd) - 1) < 0.2))
})

# ---- aggregation ------------------------------------------------------------------------

test_that("aggregate_estimands: TD aggregates, uniform alias, weight-name checks", {
  res <- multiple_treatment_group_analysis(sim0, 24:26, periods_post = 1, periods_pre = NULL,
                                           verbose = FALSE)
  agg <- aggregate_estimands(res)
  expect_true(any(agg$method == "TD" & agg$estimand == "gap_ATE"))
  expect_true(all(c("share_parenthood", "share_other", "rho_obs", "rho_cf") %in% agg$estimand))
  expect_equal(aggregate_estimands(res, weights = "uniform"), aggregate_estimands(res, weights = NULL))
  expect_error(aggregate_estimands(res, weights = c(a = 1)), "No name of `weights`")
  expect_warning(aggregate_estimands(res, weights = c(`24` = 1, `25` = 1)), "weight zero")
  expect_error(aggregate_estimands(res, methods = "NTD_New"), "None of `methods`")
})

test_that("aggregate_estimands() and bias_bounds() require the influence functions", {
  sim <- simulate_data(n_individuals = 600, treatment_groups = 24:27)
  res <- multiple_treatment_group_analysis(sim, treatment_groups = 24:25, periods_post = 1,
                                           periods_pre = NULL, verbose = FALSE)
  bare <- as.data.frame(as.list(res))   # same table, attributes dropped
  expect_error(aggregate_estimands(bare), "no influence functions")
  expect_error(bias_bounds(bare), "no influence functions")
})
