test_that("prep_data_table renames and coerces", {
  DF <- data.frame(person=1:4, a=c(24,25,25,26), D=25, sex=c(1,0,1,0), earn=rnorm(4))
  DT <- prep_data_table(DF, Y_name="earn", age_name="a", D_name="D",
                        id_name="person", female_name="sex")
  expect_true(all(c("id","age","D","female","Y","obs_id") %in% names(DT)))
  expect_type(DT$age, "integer")
  expect_type(DT$D, "integer")
  expect_true(all(DT$female %in% c(0,1)))
})
