# Child penalty analysis over multiple treatment groups

Child penalty analysis over multiple treatment groups

## Usage

``` r
multiple_treatment_group_analysis(
  data,
  treatment_groups,
  periods_post,
  periods_pre = 4,
  max_age = 999,
  min_age = 0,
  pre = 1,
  Y_name = "Y",
  age_name = "age",
  D_name = "D",
  id_name = "id",
  female_name = "female",
  verbose = TRUE
)
```

## Arguments

- data:

  A data.frame or data.table with the needed columns. Names can be
  mapped via `Y_name`, `age_name`, `D_name`, `id_name`, `female_name`.

- treatment_groups:

  Integer vector of treatment groups (e.g., 24:34).

- periods_post:

  Integer H \>= 0. Post-treatment horizons; evaluates event times e = 0,
  1, ..., H with target age a = d + e and control dp = a + 1.

- periods_pre:

  Integer K \>= 0 (default 4). Number of pre-treatment horizons.
  Evaluates e = -K, ..., -pre with a = d + e. For each pre period, tests
  the same control offsets used post, i.e., dp = d + 1, 2, ..., H + 1.
  Set `NULL` to skip pre-trends.

- max_age:

  Integer (default 999). Upper bound; cells with dp \> max_age are
  skipped.

- min_age:

  Integer (default 0). Lower bound; cells with a \< min_age are skipped.

- pre:

  Integer (default 1). Pre-treatment anchor used in APO (uses d - pre).

- Y_name, age_name, D_name, id_name, female_name:

  Column name mappings passed to
  [`prep_data_table()`](https://dorleventer.github.io/childpen/reference/prep_data_table.md).

- verbose:

  Logical (default `TRUE`). Print progress messages.

## Value

A `data.frame` stacking results from
[`single_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/single_treatment_group_analysis.md).

## Examples

``` r
# \donttest{
set.seed(1)
sim <- simulate_data(n_individuals = 500)
res <- multiple_treatment_group_analysis(sim, treatment_groups = 24:25, periods_post = 2,
                                         verbose = FALSE)
head(res)
#>    d dp  a event_time estimand     method           est           se
#> 1 24 25 24          0      APO DID_Female  5.463737e+04 2.307267e+03
#> 2 24 25 24          0      APO   DID_Male  6.284255e+04 3.145783e+03
#> 3 24 25 24          0      ATE DID_Female -1.642360e+04 2.166833e+03
#> 4 24 25 24          0      ATE   DID_Male -2.242722e+03 2.907059e+03
#> 5 24 25 24          0    theta DID_Female -3.005928e-01 2.908327e-02
#> 6 24 25 24          0    theta   DID_Male -3.568795e-02 4.517505e-02
#>            ci_l          ci_h           t             p n_female_treat
#> 1  5.011513e+04  5.915962e+04  23.6805595 5.719504e-124             60
#> 2  5.667682e+04  6.900829e+04  19.9767619  8.773309e-89             60
#> 3 -2.067060e+04 -1.217661e+04  -7.5795413  3.467788e-14             60
#> 4 -7.940557e+03  3.455113e+03  -0.7714747  4.404256e-01             60
#> 5 -3.575961e-01 -2.435896e-01 -10.3355914  4.864022e-25             60
#> 6 -1.242310e-01  5.285514e-02  -0.7899926  4.295321e-01             60
#>   n_female_control n_male_treat n_male_control
#> 1               58           40             59
#> 2               58           40             59
#> 3               58           40             59
#> 4               58           40             59
#> 5               58           40             59
#> 6               58           40             59
# }
```
