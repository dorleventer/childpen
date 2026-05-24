test_that("simulate_data returns a data.frame with the expected columns", {
  sim <- simulate_data(n_individuals = 200, seed = 1)
  expect_s3_class(sim, "data.frame")
  expect_equal(sort(names(sim)), sort(c("id", "female", "age", "D", "Y")))
})

test_that("simulate_data returns the correct number of rows", {
  # Default treatment_groups = 24:28, age range = 20:(28-1) = 20:27, so 8 ages
  n_ind <- 200
  sim <- simulate_data(n_individuals = n_ind, seed = 1)
  expect_equal(nrow(sim), n_ind * 8L)
})

test_that("simulate_data produces approximately 50% female", {
  sim <- simulate_data(n_individuals = 10000, seed = 7)
  prop_female <- mean(sim$female == 1)
  expect_equal(prop_female, 0.5, tolerance = 0.01)
})

test_that("simulate_data D values are within the default treatment groups", {
  sim <- simulate_data(n_individuals = 300, seed = 2)
  expect_true(all(sim$D %in% 24:28))
})

test_that("simulate_data produces positive Y", {
  sim <- simulate_data(n_individuals = 200, seed = 3)
  expect_true(all(sim$Y > 0))
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

test_that("simulate_data males pre-treatment have positive mean Y", {
  # Males have a smaller penalty but Y should remain positive in the pre-period
  sim <- simulate_data(n_individuals = 500, seed = 5)
  males_pre <- sim[sim$female == 0 & sim$age < sim$D, ]
  expect_true(mean(males_pre$Y) > 0)
})

test_that("simulate_data females post-treatment earn less than pre-treatment on average", {
  # Female penalty is -0.30 in logs, so post-treatment mean should be below pre-treatment mean
  sim <- simulate_data(n_individuals = 2000, seed = 42)
  fem_post <- sim[sim$female == 1 & sim$age >= sim$D, ]
  fem_pre  <- sim[sim$female == 1 & sim$age <  sim$D, ]
  expect_true(mean(fem_post$Y) < mean(fem_pre$Y))
})

test_that("simulate_data id column is a sequential integer from 1 to n_individuals", {
  n_ind <- 200
  sim <- simulate_data(n_individuals = n_ind, seed = 1)
  expect_equal(sort(unique(sim$id)), seq_len(n_ind))
})

test_that("simulate_data age column spans 20:27 for every individual with default groups", {
  sim <- simulate_data(n_individuals = 100, seed = 1)
  ages_per_id <- tapply(sim$age, sim$id, function(x) setequal(x, 20:27))
  expect_true(all(ages_per_id))
})

test_that("simulate_data treatment_groups parameter changes age range and D values", {
  sim <- simulate_data(n_individuals = 100, treatment_groups = 26:30, seed = 10)
  # age range should be 20:(30-1) = 20:29
  expect_true(all(sim$age %in% 20:29))
  ages_per_id <- tapply(sim$age, sim$id, function(x) setequal(x, 20:29))
  expect_true(all(ages_per_id))
  expect_true(all(sim$D %in% 26:30))
  # row count: 100 individuals * 10 ages
  expect_equal(nrow(sim), 100L * 10L)
})
