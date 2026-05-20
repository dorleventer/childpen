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
