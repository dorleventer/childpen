test_that("simulate_data returns a data.frame with the expected columns", {
  sim <- simulate_data(n_individuals = 200, seed = 1)
  expect_s3_class(sim, "data.frame")
  expect_true(all(c("id", "female", "age", "D", "Y_inf", "Y") %in% names(sim)))
})

test_that("simulate_data returns the correct number of rows", {
  # age_range is 20:40, which is 21 ages
  n_ind <- 200
  sim <- simulate_data(n_individuals = n_ind, seed = 1)
  expect_equal(nrow(sim), n_ind * 21L)
})

test_that("simulate_data produces approximately 50% female", {
  sim <- simulate_data(n_individuals = 10000, seed = 7)
  prop_female <- mean(sim$female == 1)
  expect_equal(prop_female, 0.5, tolerance = 0.01)
})

test_that("simulate_data D values are within the expected treatment groups", {
  expected_groups <- sort(unique(childpen::male_profiles$age_d))
  sim <- simulate_data(n_individuals = 300, seed = 2)
  expect_true(all(sim$D %in% expected_groups))
})

test_that("simulate_data produces positive Y and Y_inf", {
  sim <- simulate_data(n_individuals = 200, seed = 3)
  expect_true(all(sim$Y > 0))
  expect_true(all(sim$Y_inf > 0))
})

test_that("simulate_data is reproducible with the same seed", {
  sim1 <- simulate_data(n_individuals = 200, seed = 99)
  sim2 <- simulate_data(n_individuals = 200, seed = 99)
  expect_equal(sim1, sim2)
})

test_that("simulate_data produces different output for different seeds", {
  sim1 <- simulate_data(n_individuals = 200, seed = 1)
  sim2 <- simulate_data(n_individuals = 200, seed = 2)
  expect_false(identical(sim1$Y, sim2$Y))
})

test_that("simulate_data males have Y == Y_inf (no child penalty)", {
  # Males have penalty_pct = 0 by construction, so Y = Y_inf * (1 + 0) = Y_inf
  sim <- simulate_data(n_individuals = 500, seed = 5)
  males <- sim[sim$female == 0, ]
  expect_equal(males$Y, males$Y_inf, tolerance = 1e-9)
})

test_that("simulate_data females post-treatment earn less than counterfactual on average", {
  # Post-treatment: age >= D, mean penalty_pct drawn from N(-0.30, 0.15)
  # So on average females earn ~30% less than Y_inf post-treatment
  sim <- simulate_data(n_individuals = 2000, seed = 42)
  fem_post <- sim[sim$female == 1 & sim$age >= sim$D, ]
  expect_true(mean(fem_post$Y) < mean(fem_post$Y_inf))
})

test_that("simulate_data females pre-treatment have Y == Y_inf", {
  # Before treatment (age < D), penalty_pct is 0, so Y = Y_inf
  sim <- simulate_data(n_individuals = 500, seed = 8)
  fem_pre <- sim[sim$female == 1 & sim$age < sim$D, ]
  expect_equal(fem_pre$Y, fem_pre$Y_inf, tolerance = 1e-9)
})

test_that("simulate_data id column is a sequential integer from 1 to n_individuals", {
  n_ind <- 200
  sim <- simulate_data(n_individuals = n_ind, seed = 1)
  expect_equal(sort(unique(sim$id)), seq_len(n_ind))
})

test_that("simulate_data age column spans 20:40 for every individual", {
  sim <- simulate_data(n_individuals = 100, seed = 1)
  ages_per_id <- tapply(sim$age, sim$id, function(x) setequal(x, 20:40))
  expect_true(all(ages_per_id))
})
