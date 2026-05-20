# Prepare analysis data.table with standard column names

Standardizes input column names to `id`, `age`, `D`, `female`, and `Y`;
coerces types; validates basic conditions; and returns a keyed
`data.table` ready for the estimators.

## Usage

``` r
prep_data_table(
  data,
  Y_name = "Y",
  age_name = "age",
  D_name = "D",
  id_name = "id",
  female_name = "female"
)
```

## Arguments

- data:

  A `data.frame` or `data.table`.

- Y_name:

  Character. Column in `data` holding the outcome. Default `"Y"`.

- age_name:

  Character. Column holding age. Default `"age"`.

- D_name:

  Character. Column holding the treatment group (e.g.,
  age-at-treatment). Will be renamed to `D`. Default `"D"`.

- id_name:

  Character. Column holding the cluster identifier. Default `"id"`.

- female_name:

  Character. Column holding the binary female indicator (1=female).
  Default `"female"`.

## Value

A `data.table` with columns `id`, `age`, `D`, `female`, `Y`, plus a
keyed `obs_id = paste0(id, "@", age)`.
