library(data.table)

# ---------------------------------------------------------------------------
# Helper: build a noiseless panel for analytical tests
# ---------------------------------------------------------------------------
# Groups: treatment (D = d_val), control (D = dp_val)
# 50 males + 50 females per group, ages given by age_vec
# Male earnings:   1000 + 50 * age  (no noise, no penalty)
# Female earnings: 900  + 45 * age  pre-treatment, minus 200 post-treatment
make_noiseless_panel <- function(d_val, dp_val,
                                 age_vec = 22:28,
                                 n_per_cell = 50L) {
  make_group <- function(id_offset, female_val, D_val) {
    ids <- id_offset + seq_len(n_per_cell)
    rows <- lapply(ids, function(i) {
      data.frame(id = i, female = female_val, age = age_vec, D = D_val,
                 stringsAsFactors = FALSE)
    })
    do.call(rbind, rows)
  }

  dt <- rbind(
    make_group(0L,             1L, d_val),
    make_group(n_per_cell,     0L, d_val),
    make_group(2L * n_per_cell, 1L, dp_val),
    make_group(3L * n_per_cell, 0L, dp_val)
  )

  # Male earnings (no penalty)
  dt$Y <- ifelse(dt$female == 0L,
                 1000 + 50 * dt$age,
                 900  + 45 * dt$age)

  # Female post-treatment penalty
  dt$Y[dt$female == 1L & dt$age >= dt$D] <-
    dt$Y[dt$female == 1L & dt$age >= dt$D] - 200

  dt$D <- as.integer(dt$D)
  dt
}

# ---------------------------------------------------------------------------

test_that("single_treatment_group_analysis returns 15 rows", {
  sim <- simulate_data(n_individuals = 300, seed = 10)
  res <- single_treatment_group_analysis(sim, d = 25L, dp = 27L, a = 26L, pre = 1L)
  expect_equal(nrow(res), 15L)
})

test_that("single_treatment_group_analysis returns expected columns", {
  sim <- simulate_data(n_individuals = 300, seed = 11)
  res <- single_treatment_group_analysis(sim, d = 25L, dp = 27L, a = 26L, pre = 1L)
  expected_cols <- c("estimand", "method", "est", "se",
                     "n_female_treat", "n_female_control",
                     "n_male_treat",   "n_male_control")
  expect_true(all(expected_cols %in% names(res)))
})

test_that("single_treatment_group_analysis estimand and method values are correct", {
  sim <- simulate_data(n_individuals = 300, seed = 12)
  res <- single_treatment_group_analysis(sim, d = 25L, dp = 27L, a = 26L, pre = 1L)

  expect_true(all(res$estimand %in% c("APO", "ATE", "theta", "Delta_rho")))
  expect_true(all(res$method   %in%
                    c("DID_Female", "DID_Male", "TD", "NTD_Conv", "NTD_New",
                      "TD_Null", "NTD_Conv_Null")))
})

test_that("single_treatment_group_analysis produces positive standard errors", {
  sim <- simulate_data(n_individuals = 300, seed = 13)
  res <- single_treatment_group_analysis(sim, d = 25L, dp = 27L, a = 26L, pre = 1L)
  expect_true(all(res$se > 0))
})

test_that("single_treatment_group_analysis sample counts are correct", {
  sim <- simulate_data(n_individuals = 300, seed = 14)

  n_ft <- sum(sim$female == 1L & sim$D == 25L) / 8L  # divide by 8 ages (20:27, default groups 24:28)
  n_fc <- sum(sim$female == 1L & sim$D == 27L) / 8L
  n_mt <- sum(sim$female == 0L & sim$D == 25L) / 8L
  n_mc <- sum(sim$female == 0L & sim$D == 27L) / 8L

  res <- single_treatment_group_analysis(sim, d = 25L, dp = 27L, a = 26L, pre = 1L)

  # All rows share the same counts
  expect_true(all(res$n_female_treat   == n_ft))
  expect_true(all(res$n_female_control == n_fc))
  expect_true(all(res$n_male_treat     == n_mt))
  expect_true(all(res$n_male_control   == n_mc))
})

test_that("single_treatment_group_analysis APO estimates match analytical formula", {
  # Noiseless data: ages 22:28, d=25, dp=27, a=26, pre=1
  # pre anchor age = d - pre = 24
  # Y(24, F, 25) = 900 + 45*24 = 1980; Y(24, F, 27) = 1980 (same, no penalty at 24 < 27)
  # Y(26, F, 27) = 900 + 45*26 = 2070 (age 26 < 27, no penalty)
  # APO(F) = 1980 + 2070 - 1980 = 2070
  # Y(24, M, 25) = 2200; Y(24, M, 27) = 2200; Y(26, M, 27) = 2300
  # APO(M) = 2200 + 2300 - 2200 = 2300
  dt <- make_noiseless_panel(d_val = 25L, dp_val = 27L)
  res <- single_treatment_group_analysis(dt, d = 25L, dp = 27L, a = 26L, pre = 1L)

  apo_f_row <- res[res$estimand == "APO" & res$method == "DID_Female", ]
  apo_m_row <- res[res$estimand == "APO" & res$method == "DID_Male",   ]

  expect_equal(apo_f_row$est, 2070, tolerance = 1e-6)
  expect_equal(apo_m_row$est, 2300, tolerance = 1e-6)
})

test_that("single_treatment_group_analysis ATE estimates match analytical formula", {
  # Y(26, F, 25) = 900 + 45*26 - 200 = 1870 (post-treatment: age 26 >= 25)
  # ATE(F) = Y(26,F,25) - APO(F) = 1870 - 2070 = -200
  # Y(26, M, 25) = 1000 + 50*26 = 2300; ATE(M) = 2300 - 2300 = 0
  dt <- make_noiseless_panel(d_val = 25L, dp_val = 27L)
  res <- single_treatment_group_analysis(dt, d = 25L, dp = 27L, a = 26L, pre = 1L)

  ate_f_row <- res[res$estimand == "ATE" & res$method == "DID_Female", ]
  ate_m_row <- res[res$estimand == "ATE" & res$method == "DID_Male",   ]

  expect_equal(ate_f_row$est, -200, tolerance = 1e-6)
  expect_equal(ate_m_row$est,    0, tolerance = 1e-6)
})

test_that("single_treatment_group_analysis theta estimates match analytical formula", {
  # theta(F) = ATE(F) / APO(F) = -200 / 2070
  # theta(M) = ATE(M) / APO(M) = 0 / 2300 = 0
  dt <- make_noiseless_panel(d_val = 25L, dp_val = 27L)
  res <- single_treatment_group_analysis(dt, d = 25L, dp = 27L, a = 26L, pre = 1L)

  theta_f_row <- res[res$estimand == "theta" & res$method == "DID_Female", ]
  theta_m_row <- res[res$estimand == "theta" & res$method == "DID_Male",   ]

  expect_equal(theta_f_row$est, -200 / 2070, tolerance = 1e-6)
  expect_equal(theta_m_row$est, 0,            tolerance = 1e-6)
})

test_that("single_treatment_group_analysis SEs are near zero for noiseless data", {
  # With no noise, cluster-level IFs are identical → very small SE
  dt <- make_noiseless_panel(d_val = 25L, dp_val = 27L)
  res <- single_treatment_group_analysis(dt, d = 25L, dp = 27L, a = 26L, pre = 1L)
  expect_true(all(res$se < 1e-6))
})

test_that("single_treatment_group_analysis column name mapping works", {
  sim <- simulate_data(n_individuals = 200, seed = 20)
  # Rename all standard columns
  names(sim)[names(sim) == "Y"]      <- "earn"
  names(sim)[names(sim) == "age"]    <- "yr"
  names(sim)[names(sim) == "D"]      <- "cohort"
  names(sim)[names(sim) == "id"]     <- "person"
  names(sim)[names(sim) == "female"] <- "sex"

  res <- single_treatment_group_analysis(
    sim, d = 25L, dp = 27L, a = 26L, pre = 1L,
    Y_name = "earn", age_name = "yr", D_name = "cohort",
    id_name = "person", female_name = "sex"
  )
  expect_equal(nrow(res), 15L)
})

test_that("single_treatment_group_analysis accepts a data.table input", {
  sim <- simulate_data(n_individuals = 300, seed = 21)
  DT  <- data.table::as.data.table(sim)
  res <- single_treatment_group_analysis(DT, d = 25L, dp = 27L, a = 26L, pre = 1L)
  expect_equal(nrow(res), 15L)
})
