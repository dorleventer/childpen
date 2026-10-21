library(data.table)

# Aggregate SEs with estimated (sample) weights: Appendix C.1. With heterogeneous group
# effects and little noise, the estimated-share term dominates the variance.
make_het <- function(n, seed) {
  set.seed(seed)
  ids <- seq_len(n); female <- rep(c(1L, 0L), length.out = n)
  D <- sample(24:28, n, replace = TRUE, prob = c(.3, .25, .2, .15, .1))
  dt <- data.table::CJ(id = ids, age = 20:27)
  dt[, `:=`(female = female[id], D = D[id])]
  tau_f <- -0.15 - 0.10 * (dt$D - 24)
  dt[, Y := exp(10 + 0.05 * (age - 20) - 0.1 * female +
                ifelse(age >= D, ifelse(female == 1, tau_f, -0.02), 0) + rnorm(.N, 0, 0.02))]
  as.data.frame(dt)
}

test_that("aggregate SE with sample weights matches a person bootstrap", {
  skip_on_cran()
  stat <- function(dat) {
    r <- suppressMessages(multiple_treatment_group_analysis(dat, 24:26, periods_post = 0,
                                                            periods_pre = NULL, verbose = FALSE))
    a <- aggregate_estimands(r, methods = "NTD")
    a[a$estimand == "rho_effect", c("est", "se")]
  }
  dat <- make_het(3000, 1)
  s0 <- stat(dat)
  DT <- data.table::as.data.table(dat); ids <- unique(DT$id)
  set.seed(9)
  b <- replicate(200, {
    draw <- data.table::data.table(id = sample(ids, replace = TRUE)); draw[, nid := .I]
    bs <- DT[draw, on = "id", allow.cartesian = TRUE][, id := nid][, nid := NULL]
    stat(as.data.frame(bs))$est
  })
  expect_lt(abs(s0$se / stats::sd(b) - 1), 0.15)
})

test_that("fixed weights give a smaller SE than estimated weights when effects differ", {
  dat <- make_het(2000, 2)
  r <- suppressMessages(multiple_treatment_group_analysis(dat, 24:26, periods_post = 0,
                                                          periods_pre = NULL, verbose = FALSE))
  n_d <- table(unique(dat[, c("id", "D")])$D)[c("24", "25", "26")]
  w <- stats::setNames(as.numeric(n_d), names(n_d))
  a_s <- aggregate_estimands(r, methods = "NTD")
  a_f <- aggregate_estimands(r, methods = "NTD", weights = w)
  k <- function(a) a$estimand == "rho_effect"
  expect_equal(a_s$est[k(a_s)], a_f$est[k(a_f)], tolerance = 1e-12)
  expect_gt(a_s$se[k(a_s)], a_f$se[k(a_f)])
})

test_that("include_pre aggregates pre-treatment cells by control offset", {
  sim <- simulate_data(n_individuals = 1500, treatment_groups = 24:29, seed = 3)
  r <- multiple_treatment_group_analysis(sim, 25:27, periods_post = 1, periods_pre = 2,
                                         verbose = FALSE)
  agg <- aggregate_estimands(r, include_pre = TRUE)
  pre <- agg[agg$event_time < 0, ]
  expect_true(all(c(1, 2) %in% pre$control_offset))
  expect_true(all(pre$n_groups <= 3))
  expect_false(anyDuplicated(agg[, c("event_time", "control_offset", "method", "estimand",
                                      "agg_type")]) > 0)
  # one pre cell by hand: NTD rho_effect at e = -3, offset 1, weighted by group size
  sub <- r[r$method == "NTD" & r$estimand == "rho_effect" & r$event_time == -3 &
             r$control_offset == 1, ]
  n_d <- table(unique(sim[, c("id", "D")])$D)[as.character(sub$d)]
  w <- as.numeric(n_d) / sum(n_d)
  got <- agg$est[agg$method == "NTD" & agg$estimand == "rho_effect" & agg$event_time == -3 &
                   agg$control_offset == 1]
  expect_equal(got, sum(w * sub$est), tolerance = 1e-12)
})
