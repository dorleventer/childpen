# Unconditional estimands for a single treatment group

Estimates 15 descriptive estimands for triplet (treatment group, control
group and target age). SEs are calcualted using influence-function (IF)
calculations with clustering within `id`.

## Usage

``` r
single_treatment_group_analysis(
  data,
  d,
  dp,
  a,
  pre = 1,
  Y_name = "Y",
  age_name = "age",
  D_name = "D",
  id_name = "id",
  female_name = "female"
)
```

## Arguments

- data:

  A `data.table` with columns:

  - `id` — cluster identifier (i.e., person)

  - `age` — integer age

  - `female` — 0/1 indicator (1 = females)

  - `D` — treatment group

  - `Y` — numeric outcome

- d:

  Integer. Treatment group (age at first childbirth)

- dp:

  Integer. Control group (closest not-yet-treated group)

- a:

  Integer. Target age.

- pre:

  Integer, default `1`. Offset used for the pre-treatment anchor.

- Y_name, age_name, D_name, id_name, female_name:

  Column name mappings passed to
  [`prep_data_table()`](https://dorleventer.github.io/childpen/reference/prep_data_table.md).

## Value

A `data.frame` with one row per estimand/method combination:

- `estimand` — one of `"APO"`, `"ATE"`, `"theta"`, `"Delta_rho"`

- `method` — one of `"DID_Female"`, `"DID_Male"`, `"TD"`, `"NTD_Conv"`,
  `"NTD_New"`, `"TD_Null"`, `"NTD_Conv_Null"`

- `est` — estimate

- `se` — cluster-robust standard error

- `n_female_treat`, `n_female_control`, `n_male_treat`, `n_male_control`
  — sample counts

## Details

Let \\Y(a, g, d^\star)\\ denote the mean outcome at age \\a\\ for gender
\\g \in \\0,1\\\\ (1 = female) when assigned to group \\d^\star\\. The
core components are:

- **APO**(g; d, d', a) \\= Y(d-\mathrm{pre}, g, d) + Y(a, g, d') -
  Y(d-\mathrm{pre}, g, d')\\

- **ATE**(g; d, d', a) \\= Y(a, g, d) - \mathrm{APO}(g; d, d', a)\\

- **\\\theta\\(g)** \\= \mathrm{ATE}(g) / \mathrm{APO}(g)\\

From these, the cross-gender contrasts are formed:

- **TD** \\= \mathrm{ATE}(F) - \mathrm{ATE}(M)\\

- **NTD_Conv** \\= \theta(F) - \theta(M)\\

- **NTD_New** \\= \frac{Y(a,F,d)}{Y(a,M,d)} -
  \frac{\mathrm{APO}(F)}{\mathrm{APO}(M)}\\

- **TD Null** and **NTD_Conv_Null** variants are defined analogously
  under a null-effect-for-fathers bias-correction.

Internally, influence functions for all pieces are written into
temporary columns of a `data.table` via `compute_mean_if()`, and
cluster-robust standard errors are computed by summing the IFs at the
`id` level via `se_cluster()`.

## Note

Requires helper functions `compute_mean_if()` and `se_cluster()`.

## Examples

``` r
# \donttest{
set.seed(1)
sim <- simulate_data(n_individuals = 500)
res <- single_treatment_group_analysis(sim, d = 27, dp = 28, a = 28, pre = 1)
head(res)
#>   estimand     method           est           se n_female_treat
#> 1      APO DID_Female  9.740796e+04 1.177499e+04             45
#> 2      APO   DID_Male  1.005088e+05 1.143599e+04             45
#> 3      ATE DID_Female -1.297154e+04 1.221918e+04             45
#> 4      ATE   DID_Male  3.688769e+03 1.213416e+04             45
#> 5    theta DID_Female -1.331671e-01 1.160218e-01             45
#> 6    theta   DID_Male  3.670096e-02 1.228974e-01             45
#>   n_female_control n_male_treat n_male_control
#> 1               61           62             49
#> 2               61           62             49
#> 3               61           62             49
#> 4               61           62             49
#> 5               61           62             49
#> 6               61           62             49
# }
```
