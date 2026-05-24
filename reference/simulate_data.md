# Simulate panel data for child-penalty estimation

Generates a balanced panel with lifecycle earnings, a gender gap,
selection on treatment timing, and gendered treatment effects. The DGP
is:

## Usage

``` r
simulate_data(n_individuals = 10000, treatment_groups = 24:28, seed = 42)
```

## Arguments

- n_individuals:

  Integer. Number of individuals (default 10 000).

- treatment_groups:

  Integer vector. Treatment groups to include (default `24:28`).

- seed:

  Integer. RNG seed (default 42).

## Value

A `data.frame` with columns `id`, `female`, `age`, `D`, `Y`.

## Details

\$\$\log Y\_{it} = \mu_0 + \lambda D_i + \alpha_i + \beta_1 (a - 20) +
\beta_2 (a - 20)^2 + \gamma \cdot \mathbf{1}\[f\] + \theta_f \cdot
\mathbf{1}\[f, a \ge D\] + \theta_m \cdot \mathbf{1}\[m, a \ge D\] +
\varepsilon\_{it}\$\$

where \\\alpha_i \sim N(0,\sigma\_\alpha^2)\\ is a permanent individual
effect and \\\varepsilon\_{it} \sim N(0,\sigma\_\varepsilon^2)\\ is a
transitory shock. The term \\\lambda D_i\\ generates positive selection
on treatment timing: individuals who have children later earn more, on
average, than those who have children earlier.

## Examples

``` r
# \donttest{
sim <- simulate_data(n_individuals = 2000)
head(sim)
#>   id female age  D        Y
#> 1  1      1  20 24 40643.68
#> 2  1      1  21 24 36525.46
#> 3  1      1  22 24 39327.60
#> 4  1      1  23 24 34390.98
#> 5  1      1  24 24 46404.27
#> 6  1      1  25 24 46884.98
# }
```
