## code to prepare `DATASET` dataset goes here
male_profiles   <- readRDS("data-raw/male_profiles.rds")
female_params   <- readRDS("data-raw/female_params.rds")
variance_params <- readRDS("data-raw/variance_params.rds")
usethis::use_data(male_profiles, female_params, variance_params, overwrite = TRUE)

