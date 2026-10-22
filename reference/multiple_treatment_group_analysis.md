# Child-penalty estimates for many treatment groups and event times

Runs
[`single_treatment_group_analysis`](https://dorleventer.github.io/childpen/reference/single_treatment_group_analysis.md)
over a grid of 2x2 comparisons. For each treatment group \\d\\ (age at
first birth) and event time \\e = 0, \dots, H\\, the target age \\a =
d + e\\ is compared with the closest not-yet-treated group \\d' = a +
1\\ (Leventer 2025, Section 1.3). Pre-treatment event times are
estimated against every control group used after treatment, because the
identifying assumptions must hold pair by pair (Section 2.3). Results
are stacked, and the person-level influence functions that
[`aggregate_estimands`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md)
and
[`bias_bounds`](https://dorleventer.github.io/childpen/reference/bias_bounds.md)
need are attached.

## Usage

``` r
multiple_treatment_group_analysis(
  data,
  treatment_groups,
  periods_post,
  periods_pre = 4,
  max_control_group = Inf,
  min_pre_age = 0,
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

  A data.frame or data.table in long format, one row per person and age;
  see
  [`single_treatment_group_analysis`](https://dorleventer.github.io/childpen/reference/single_treatment_group_analysis.md)
  for the requirements. It is not modified.

- treatment_groups:

  Integer vector of ages at first birth \\d\\ to estimate (the paper
  uses 24:34). Groups \\d + 1, \dots, d + H + 1\\ must be in `data` to
  serve as controls.

- periods_post:

  Whole number \\H \ge 0\\: post-treatment event times \\e = 0, \dots,
  H\\ (the paper uses 5).

- periods_pre:

  Whole number \\K \ge 0\\ (default 4), or `NULL`: number of
  pre-treatment event times for validation tests, \\e = -(pre + K),
  \dots, -(pre + 1)\\ (with the defaults \\-5, \dots, -2\\; \\e = -pre\\
  is the baseline). `0` or `NULL` skips them.

- max_control_group:

  Largest age at first birth allowed as a control group (the paper's
  \\D\_{max}\\; default `Inf`, no bound). Cells whose control group is
  above it are not estimated.

- min_pre_age:

  Smallest target age for pre-treatment cells (default 0, no bound).
  Post-treatment cells are not affected.

- pre:

  Whole number \\\ge 1\\ (default 1): the baseline age is \\d - pre\\.

- Y_name, age_name, D_name, id_name, female_name:

  Names of the columns holding earnings, age, age at first birth, the
  person id and the female indicator.

- verbose:

  Logical (default `TRUE`). Report progress, one line per treatment
  group.

## Value

A data.frame with one block of rows per estimated cell (`d`, `dp`, `a`),
sorted by `d`, `event_time` and `dp`; the columns are those of
[`single_treatment_group_analysis`](https://dorleventer.github.io/childpen/reference/single_treatment_group_analysis.md).
Attributes used by
[`aggregate_estimands`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md)
and
[`bias_bounds`](https://dorleventer.github.io/childpen/reference/bias_bounds.md):
`"if_data"` (person-level influence functions per cell), `"n_obs"` (rows
of the prepared data), `"n_ids"` (persons), `"id_info"` (`id`, `female`,
`D`). Attribute `"skipped"` lists cells that could not be estimated,
with the reason (e.g. an empty gender x group x age cell). Pass the
result to the aggregation functions unmodified.

## See also

[`single_treatment_group_analysis`](https://dorleventer.github.io/childpen/reference/single_treatment_group_analysis.md),
[`aggregate_estimands`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md),
[`bias_bounds`](https://dorleventer.github.io/childpen/reference/bias_bounds.md)

## Examples

``` r
# \donttest{
sim <- simulate_data(n_individuals = 2000)
res <- multiple_treatment_group_analysis(sim, treatment_groups = 24:26,
  periods_post = 1, periods_pre = 2, verbose = FALSE)
# The new estimand, by treatment group and event time
subset(res, method == "NTD" & estimand == "rho_effect" & event_time >= 0,
       c(d, event_time, dp, est, se))
#>      d event_time dp        est         se
#> 85  24          0 25 -0.3488283 0.03273725
#> 104 24          1 26 -0.3312687 0.02878966
#> 199 25          0 26 -0.3474838 0.02865365
#> 218 25          1 27 -0.2493495 0.02378134
#> 313 26          0 27 -0.3369988 0.02773765
#> 332 26          1 28 -0.3083804 0.02364997
# Pre-treatment validation tests of NTD, one row per control group
subset(res, method == "Conventional" & event_time < 0,
       c(d, event_time, control_offset, est, se))
#>      d event_time control_offset         est         se
#> 8   24         -3              1 -0.01457375 0.04330571
#> 27  24         -3              2  0.01314518 0.03743401
#> 46  24         -2              1 -0.03754368 0.03958102
#> 65  24         -2              2  0.03862179 0.03559579
#> 122 25         -3              1  0.06846944 0.03595722
#> 141 25         -3              2  0.04753514 0.03251608
#> 160 25         -2              1 -0.00211053 0.03565733
#> 179 25         -2              2  0.01133560 0.03342872
#> 236 26         -3              1 -0.04052352 0.03803836
#> 255 26         -3              2 -0.06175024 0.03378960
#> 274 26         -2              1 -0.05097870 0.03568219
#> 293 26         -2              2 -0.07219692 0.03168115
# }
```
