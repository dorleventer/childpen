# Simulate panel data for child-penalty estimators

Generates a panel of individuals over ages with gender, treatment group,
and earnings. The data-generating process uses a male baseline earnings
profile, female penalty parameters with partial recovery, and AR(1)
shocks in logs.

## Usage

``` r
simulate_data(n_individuals = 10000, seed = 42)
```

## Arguments

- n_individuals:

  Integer. Number of individuals to simulate (default `10000`).

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
if (FALSE) { # \dontrun{
set.seed(1)
sim <- simulate_data(n_individuals = 2000)
head(sim)
} # }
```
