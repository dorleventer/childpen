# Simulate panel data for child-penalty estimators

Generates a panel of individuals over ages with gender, treatment group,
and earnings. The data-generating process uses a male baseline earnings
profile, female penalty parameters with partial recovery, and AR(1)
shocks in logs.

## Usage

``` r
simulate_data(n_individuals = 10000, treatment_groups = 25:28, seed = 42)
```

## Arguments

- n_individuals:

  Integer. Number of individuals to simulate (default `10000`).

- treatment_groups:

  Integer vector. Which treatment groups (ages at first birth) to
  include. Default `25:28`. Available values: 25 through 40.

- seed:

  Integer. RNG seed.

## Value

A `data.frame` with columns:

- `id` (individual id),

- `female` (0/1),

- `age` (integer),

- `D` (treatment age group; renamed from `age_d` for consistency),

- `Y_inf` (counterfactual earnings absent penalties),

- `Y` (observed earnings).

## Examples

``` r
# \donttest{
set.seed(1)
sim <- simulate_data(n_individuals = 2000)
head(sim)
#>   id female age  D     Y_inf         Y
#> 1  1      1  20 25  32193.39  32193.39
#> 2  1      1  21 25  46159.01  46159.01
#> 3  1      1  22 25  79431.86  79431.86
#> 4  1      1  23 25  75702.57  75702.57
#> 5  1      1  24 25 291366.27 291366.27
#> 6  1      1  25 25 139285.60  94345.07
# }
```
