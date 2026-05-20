library(data.table)

# ---------------------------------------------------------------------------
# Helper: produce a tidy multiple_treatment_group_analysis result for tests
# ---------------------------------------------------------------------------
make_multi_result <- function(n = 300L, groups = 25:27, periods_post = 1L,
                              periods_pre = NULL, seed = 50L) {
  sim <- simulate_data(n_individuals = n, seed = seed)
  multiple_treatment_group_analysis(
    sim,
    treatment_groups = groups,
    periods_post     = periods_post,
    periods_pre      = periods_pre,
    verbose          = FALSE
  )
}

# ---------------------------------------------------------------------------

test_that("aggregate_estimands returns expected columns", {
  res <- make_multi_result()
  agg <- aggregate_estimands(res)
  expected_cols <- c("event_time", "estimand", "method", "agg_type",
                     "est", "se", "ci_l", "ci_h", "n_groups")
  expect_true(all(expected_cols %in% names(agg)))
})

test_that("aggregate_estimands returns a data.frame", {
  res <- make_multi_result()
  agg <- aggregate_estimands(res)
  expect_s3_class(agg, "data.frame")
})

test_that("aggregate_estimands ci_l and ci_h are 1.96 * se wide", {
  res <- make_multi_result()
  agg <- aggregate_estimands(res)
  expect_equal(agg$ci_l, agg$est - 1.96 * agg$se, tolerance = 1e-10)
  expect_equal(agg$ci_h, agg$est + 1.96 * agg$se, tolerance = 1e-10)
})

test_that("aggregate_estimands agg_type values are in the expected set", {
  res <- make_multi_result()
  agg <- aggregate_estimands(res)
  expect_true(all(agg$agg_type %in% c("avg_of_ratios", "ratio_of_avgs", "gender_ineq")))
})

test_that("aggregate_estimands n_groups reflects number of treatment groups", {
  res <- make_multi_result(groups = 25:27)  # 3 groups
  agg <- aggregate_estimands(res)
  # Each post-period cell should aggregate over 3 groups
  post_agg <- agg[agg$event_time >= 0, ]
  expect_true(all(post_agg$n_groups <= 3L))
  expect_true(all(post_agg$n_groups >= 1L))
})

test_that("aggregate_estimands avg_of_ratios equals single group estimate with 1 treatment group", {
  # With only one treatment group and uniform (default) weights, avg_of_ratios
  # must equal the group-specific theta estimate exactly.
  sim <- simulate_data(n_individuals = 300, seed = 51)
  res1 <- multiple_treatment_group_analysis(
    sim,
    treatment_groups = 25L,
    periods_post     = 0L,
    periods_pre      = NULL,
    verbose          = FALSE
  )
  agg1 <- aggregate_estimands(res1)

  # Pull theta DID_Female at event_time = 0 from single and aggregate
  theta_single <- res1[res1$estimand == "theta" & res1$method == "DID_Female" &
                         res1$event_time == 0L, "est"]
  theta_agg    <- agg1[agg1$agg_type == "avg_of_ratios" &
                         agg1$method == "DID_Female" &
                         agg1$event_time == 0L, "est"]

  expect_equal(theta_agg, theta_single, tolerance = 1e-10)
})

test_that("aggregate_estimands ratio_of_avgs equals single group estimate with 1 treatment group", {
  sim <- simulate_data(n_individuals = 300, seed = 52)
  res1 <- multiple_treatment_group_analysis(
    sim,
    treatment_groups = 25L,
    periods_post     = 0L,
    periods_pre      = NULL,
    verbose          = FALSE
  )
  agg1 <- aggregate_estimands(res1)

  theta_single <- res1[res1$estimand == "theta" & res1$method == "DID_Female" &
                         res1$event_time == 0L, "est"]
  theta_roa    <- agg1[agg1$agg_type == "ratio_of_avgs" &
                         agg1$method == "DID_Female" &
                         agg1$event_time == 0L, "est"]

  expect_equal(theta_roa, theta_single, tolerance = 1e-10)
})

test_that("aggregate_estimands custom weights produce different estimates from uniform weights", {
  res <- make_multi_result(groups = 25:27, seed = 53)

  # Strongly concentrate weight on group 25
  w_skewed  <- c("25" = 0.98, "26" = 0.01, "27" = 0.01)
  agg_skewed  <- aggregate_estimands(res, weights = w_skewed)
  agg_uniform <- aggregate_estimands(res)

  # The two aggregations should differ (unless estimates happen to be equal — very unlikely)
  skewed_est  <- agg_skewed$est[agg_skewed$agg_type  == "avg_of_ratios" &
                                  agg_skewed$method  == "DID_Female" &
                                  agg_skewed$event_time == 0L]
  uniform_est <- agg_uniform$est[agg_uniform$agg_type == "avg_of_ratios" &
                                   agg_uniform$method  == "DID_Female" &
                                   agg_uniform$event_time == 0L]

  expect_false(isTRUE(all.equal(skewed_est, uniform_est, tolerance = 1e-6)))
})

test_that("aggregate_estimands custom weights must be named numeric", {
  res <- make_multi_result()
  expect_error(aggregate_estimands(res, weights = c(0.5, 0.3, 0.2)),
               regexp = "named numeric")
})

test_that("aggregate_estimands custom weights must be non-negative", {
  res <- make_multi_result()
  expect_error(aggregate_estimands(res, weights = c("25" = -1, "26" = 1, "27" = 1)),
               regexp = "non-negative")
})

test_that("aggregate_estimands include_pre = FALSE excludes negative event times", {
  res <- make_multi_result(periods_pre = 2L)
  agg <- aggregate_estimands(res, include_pre = FALSE)
  expect_true(all(agg$event_time >= 0L))
})

test_that("aggregate_estimands include_pre = TRUE includes negative event times", {
  res <- make_multi_result(periods_pre = 2L)
  agg <- aggregate_estimands(res, include_pre = TRUE)
  expect_true(any(agg$event_time < 0L))
})

test_that("aggregate_estimands errors on empty data.frame", {
  expect_error(aggregate_estimands(data.frame()),
               regexp = "non-empty data.frame")
})

test_that("aggregate_estimands errors on non-data.frame input", {
  expect_error(aggregate_estimands(list(a = 1)),
               regexp = "non-empty data.frame")
})

test_that("aggregate_estimands errors when required columns are missing", {
  res <- make_multi_result()
  incomplete <- res[, setdiff(names(res), c("se", "est"))]
  expect_error(aggregate_estimands(incomplete),
               regexp = "Missing required columns")
})

test_that("aggregate_estimands methods argument filters output correctly", {
  res <- make_multi_result()
  agg <- aggregate_estimands(res, methods = "DID_Female")
  # Only DID_Female-related agg types should appear (avg_of_ratios, ratio_of_avgs)
  expect_true(all(agg$method %in% c("DID_Female", "NTD_Alt")))
  # NTD, NTD_Alt (as its own method row via gender_ineq) should not appear unless
  # NTD_Alt is passed; only the DID_Female slice of avg_of_ratios and ratio_of_avgs remains
  agg_ntd <- agg[agg$agg_type %in% c("avg_of_ratios", "ratio_of_avgs"), ]
  expect_true(all(agg_ntd$method == "DID_Female"))
})

test_that("aggregate_estimands se is positive for all rows", {
  res <- make_multi_result(groups = 25:26, seed = 55)
  agg <- aggregate_estimands(res)
  expect_true(all(agg$se > 0))
})
