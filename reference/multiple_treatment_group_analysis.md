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
  verbose = T
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
res <- multiple_treatment_group_analysis(sim, treatment_groups = 26:28, periods_post = 2)
#> 
#> Running analysis for 3 treatment groups...
#> Post-treatment event times: 0 to 2
#> Pre-treatment event times: -5 to -2 (testing 3 control groups: d+1 to d+3)
#> Total estimations: 45 (9 post + 36 pre)
#> 
#> Progress: 1/45 (2.2%) | Elapsed: 0.0 min | Remaining: ~0.1 min
#> Progress: 2/45 (4.4%) | Elapsed: 0.0 min | Remaining: ~0.1 min
#>   Error for d=26, event_time=2: Empty subgroup: age=28, female=1, D=29
#> Progress: 3/45 (6.7%) | Elapsed: 0.0 min | Remaining: ~0.1 min
#>   Error for d=27, event_time=1: Empty subgroup: age=28, female=1, D=29
#>   Error for d=27, event_time=2: Empty subgroup: age=29, female=1, D=30
#>   Error for d=28, event_time=0: Empty subgroup: age=28, female=1, D=29
#>   Error for d=28, event_time=1: Empty subgroup: age=29, female=1, D=30
#>   Error for d=28, event_time=2: Empty subgroup: age=30, female=1, D=31
#> Progress: 4/45 (8.9%) | Elapsed: 0.0 min | Remaining: ~0.1 min
#> Progress: 5/45 (11.1%) | Elapsed: 0.0 min | Remaining: ~0.1 min
#>   Error for d=26, event_time=-5, dp=29: Empty subgroup: age=21, female=1, D=29
#> Progress: 6/45 (13.3%) | Elapsed: 0.0 min | Remaining: ~0.1 min
#> Progress: 7/45 (15.6%) | Elapsed: 0.0 min | Remaining: ~0.1 min
#>   Error for d=26, event_time=-4, dp=29: Empty subgroup: age=22, female=1, D=29
#> Progress: 8/45 (17.8%) | Elapsed: 0.0 min | Remaining: ~0.1 min
#> Progress: 9/45 (20.0%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#>   Error for d=26, event_time=-3, dp=29: Empty subgroup: age=23, female=1, D=29
#> Progress: 10/45 (22.2%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#> Progress: 11/45 (24.4%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#>   Error for d=26, event_time=-2, dp=29: Empty subgroup: age=24, female=1, D=29
#> Progress: 12/45 (26.7%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#>   Error for d=27, event_time=-5, dp=29: Empty subgroup: age=22, female=1, D=29
#>   Error for d=27, event_time=-5, dp=30: Empty subgroup: age=22, female=1, D=30
#> Progress: 13/45 (28.9%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#>   Error for d=27, event_time=-4, dp=29: Empty subgroup: age=23, female=1, D=29
#>   Error for d=27, event_time=-4, dp=30: Empty subgroup: age=23, female=1, D=30
#> Progress: 14/45 (31.1%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#>   Error for d=27, event_time=-3, dp=29: Empty subgroup: age=24, female=1, D=29
#>   Error for d=27, event_time=-3, dp=30: Empty subgroup: age=24, female=1, D=30
#> Progress: 15/45 (33.3%) | Elapsed: 0.0 min | Remaining: ~0.0 min
#>   Error for d=27, event_time=-2, dp=29: Empty subgroup: age=25, female=1, D=29
#>   Error for d=27, event_time=-2, dp=30: Empty subgroup: age=25, female=1, D=30
#>   Error for d=28, event_time=-5, dp=29: Empty subgroup: age=23, female=1, D=29
#>   Error for d=28, event_time=-5, dp=30: Empty subgroup: age=23, female=1, D=30
#>   Error for d=28, event_time=-5, dp=31: Empty subgroup: age=23, female=1, D=31
#>   Error for d=28, event_time=-4, dp=29: Empty subgroup: age=24, female=1, D=29
#>   Error for d=28, event_time=-4, dp=30: Empty subgroup: age=24, female=1, D=30
#>   Error for d=28, event_time=-4, dp=31: Empty subgroup: age=24, female=1, D=31
#>   Error for d=28, event_time=-3, dp=29: Empty subgroup: age=25, female=1, D=29
#>   Error for d=28, event_time=-3, dp=30: Empty subgroup: age=25, female=1, D=30
#>   Error for d=28, event_time=-3, dp=31: Empty subgroup: age=25, female=1, D=31
#>   Error for d=28, event_time=-2, dp=29: Empty subgroup: age=26, female=1, D=29
#>   Error for d=28, event_time=-2, dp=30: Empty subgroup: age=26, female=1, D=30
#>   Error for d=28, event_time=-2, dp=31: Empty subgroup: age=26, female=1, D=31
#> 
#> Completed 15 estimations in 0.0 minutes
#> 
head(res)
#>    d dp  a event_time estimand     method           est           se
#> 1 26 27 26          0      APO DID_Female  8.882936e+04 1.005623e+04
#> 2 26 27 26          0      APO   DID_Male  7.736541e+04 1.037913e+04
#> 3 26 27 26          0      ATE DID_Female -2.901315e+04 9.543213e+03
#> 4 26 27 26          0      ATE   DID_Male  6.871255e+03 9.053936e+03
#> 5 26 27 26          0    theta DID_Female -3.266167e-01 7.907950e-02
#> 6 26 27 26          0    theta   DID_Male  8.881560e-02 1.233063e-01
#>            ci_l          ci_h          t            p n_female_treat
#> 1  6.911914e+04  1.085396e+05  8.8332621 1.016665e-18             76
#> 2  5.702232e+04  9.770850e+04  7.4539426 9.059142e-14             76
#> 3 -4.771784e+04 -1.030845e+04 -3.0401866 2.364316e-03             76
#> 4 -1.087446e+04  2.461697e+04  0.7589246 4.478977e-01             76
#> 5 -4.816125e-01 -1.716208e-01 -4.1302318 3.623976e-05             76
#> 6 -1.528648e-01  3.304960e-01  0.7202843 4.713500e-01             76
#>   n_female_control n_male_treat n_male_control
#> 1               45           73             62
#> 2               45           73             62
#> 3               45           73             62
#> 4               45           73             62
#> 5               45           73             62
#> 6               45           73             62
# }
```
