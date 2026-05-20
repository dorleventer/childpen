test_that("multiple_treatment_group_analysis returns expected columns", {
  sim <- simulate_data(n_individuals = 300, seed = 30)
  res <- multiple_treatment_group_analysis(
    sim,
    treatment_groups = 25:26,
    periods_post     = 1L,
    periods_pre      = NULL,
    verbose          = FALSE
  )
  expected_cols <- c("d", "dp", "a", "event_time",
                     "estimand", "method", "est", "se",
                     "ci_l", "ci_h", "t", "p")
  expect_true(all(expected_cols %in% names(res)))
})

test_that("multiple_treatment_group_analysis returns a data.frame", {
  sim <- simulate_data(n_individuals = 200, seed = 31)
  res <- multiple_treatment_group_analysis(
    sim,
    treatment_groups = 25L,
    periods_post     = 0L,
    periods_pre      = NULL,
    verbose          = FALSE
  )
  expect_s3_class(res, "data.frame")
})

test_that("multiple_treatment_group_analysis ci_l and ci_h are 1.96 * se wide", {
  sim <- simulate_data(n_individuals = 300, seed = 32)
  res <- multiple_treatment_group_analysis(
    sim,
    treatment_groups = 25:26,
    periods_post     = 1L,
    periods_pre      = NULL,
    verbose          = FALSE
  )
  expect_equal(res$ci_l, res$est - 1.96 * res$se, tolerance = 1e-10)
  expect_equal(res$ci_h, res$est + 1.96 * res$se, tolerance = 1e-10)
})

test_that("multiple_treatment_group_analysis event_time equals a minus d", {
  sim <- simulate_data(n_individuals = 300, seed = 33)
  res <- multiple_treatment_group_analysis(
    sim,
    treatment_groups = 25:26,
    periods_post     = 1L,
    periods_pre      = NULL,
    verbose          = FALSE
  )
  expect_equal(res$event_time, res$a - res$d)
})

test_that("multiple_treatment_group_analysis correct row count for post-only run", {
  # 2 groups x 2 event_times (0,1) x 15 estimands = 60 rows
  sim <- simulate_data(n_individuals = 300, seed = 34)
  res <- multiple_treatment_group_analysis(
    sim,
    treatment_groups = 25:26,
    periods_post     = 1L,
    periods_pre      = NULL,
    verbose          = FALSE
  )
  expect_equal(nrow(res), 60L)
})

test_that("multiple_treatment_group_analysis correct row count for single group", {
  # 1 group x 1 event_time (0) x 15 estimands = 15 rows
  sim <- simulate_data(n_individuals = 300, seed = 35)
  res <- multiple_treatment_group_analysis(
    sim,
    treatment_groups = 25L,
    periods_post     = 0L,
    periods_pre      = NULL,
    verbose          = FALSE
  )
  expect_equal(nrow(res), 15L)
})

test_that("periods_pre = NULL skips pre-treatment event times", {
  sim <- simulate_data(n_individuals = 300, seed = 36)
  res <- multiple_treatment_group_analysis(
    sim,
    treatment_groups = 25:26,
    periods_post     = 1L,
    periods_pre      = NULL,
    verbose          = FALSE
  )
  expect_true(all(res$event_time >= 0))
})

test_that("multiple_treatment_group_analysis includes pre-treatment event times when requested", {
  # periods_pre=2, pre=1, d=25 => event_times in (-3):(-2)
  sim <- simulate_data(n_individuals = 300, seed = 37)
  res <- multiple_treatment_group_analysis(
    sim,
    treatment_groups = 25:26,
    periods_post     = 1L,
    periods_pre      = 2L,
    verbose          = FALSE
  )
  expect_true(any(res$event_time < 0))
  expect_true(any(res$event_time >= 0))
})

test_that("multiple_treatment_group_analysis correct row count with pre-treatment periods", {
  # Post: 2 groups x 2 event_times x 15 = 60
  # Pre:  2 groups x 2 pre event_times x 2 control offsets x 15 = 120
  # Total = 180
  sim <- simulate_data(n_individuals = 300, seed = 38)
  res <- multiple_treatment_group_analysis(
    sim,
    treatment_groups = 25:26,
    periods_post     = 1L,
    periods_pre      = 2L,
    verbose          = FALSE
  )
  expect_equal(nrow(res), 180L)
})

test_that("verbose = FALSE produces no console output", {
  sim <- simulate_data(n_individuals = 200, seed = 39)
  # Assign result inside capture.output to prevent auto-printing of the return value
  output <- capture.output(
    res <- multiple_treatment_group_analysis(
      sim,
      treatment_groups = 25L,
      periods_post     = 0L,
      periods_pre      = NULL,
      verbose          = FALSE
    )
  )
  expect_length(output, 0L)
})

test_that("multiple_treatment_group_analysis results align with single_treatment_group_analysis", {
  # The multi-group wrapper should give the same estimates as calling single directly
  sim <- simulate_data(n_individuals = 300, seed = 40)
  res_multi <- multiple_treatment_group_analysis(
    sim,
    treatment_groups = 25L,
    periods_post     = 0L,
    periods_pre      = NULL,
    verbose          = FALSE
  )
  # d=25, dp=26 (a + 1 = 25 + 0 + 1), a=25, event_time=0
  res_single <- single_treatment_group_analysis(sim, d = 25L, dp = 26L, a = 25L, pre = 1L)

  # Sort both by method+estimand for comparison
  res_multi_sub <- res_multi[order(res_multi$estimand, res_multi$method), ]
  res_single_sub <- res_single[order(res_single$estimand, res_single$method), ]

  expect_equal(res_multi_sub$est, res_single_sub$est, tolerance = 1e-10)
  expect_equal(res_multi_sub$se,  res_single_sub$se,  tolerance = 1e-10)
})

test_that("multiple_treatment_group_analysis t statistic equals est / se", {
  sim <- simulate_data(n_individuals = 300, seed = 41)
  res <- multiple_treatment_group_analysis(
    sim,
    treatment_groups = 25L,
    periods_post     = 0L,
    periods_pre      = NULL,
    verbose          = FALSE
  )
  expect_equal(res$t, res$est / res$se, tolerance = 1e-10)
})

test_that("multiple_treatment_group_analysis p values are in [0, 1]", {
  sim <- simulate_data(n_individuals = 300, seed = 42)
  res <- multiple_treatment_group_analysis(
    sim,
    treatment_groups = 25:26,
    periods_post     = 1L,
    periods_pre      = NULL,
    verbose          = FALSE
  )
  expect_true(all(res$p >= 0 & res$p <= 1))
})
