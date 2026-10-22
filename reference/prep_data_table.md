# Prepare analysis data.table with standard column names

Standardizes input column names to `id`, `age`, `D`, `female`, and `Y`;
coerces types; validates the panel; and returns a keyed `data.table`
ready for the estimators. The input is never modified (a data.table is
copied).

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

  Character. Column holding the age at first birth (treatment group).
  Will be renamed to `D`. Default `"D"`.

- id_name:

  Character. Column holding the person identifier (clustering unit).
  Default `"id"`.

- female_name:

  Character. Column holding the female indicator (1 = female). Default
  `"female"`.

## Value

A `data.table` with columns `id`, `age`, `D`, `female`, `Y`, plus a
keyed `obs_id = paste0(id, "@", age)`.

## Details

Validation: every column must exist; `female` must be 0/1, logical, or a
recognised label (female: "1", "f", "female", "w", "woman", "women",
"t", "true", "y", "yes"; male: "0", "m", "male", "man", "men", "false",
"n", "no"); any other value is an error. Rows with a missing outcome are
dropped with a message. A missing or non-finite `D` marks a person who
never has a child (kept, with a message). `id` must not be missing;
(`id`, `age`) must be unique; `female` and `D` must be constant within
`id`; both genders must be present.
