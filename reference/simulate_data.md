# Simulate panel data for child-penalty estimation

Generates a balanced panel of annual earnings with life-cycle growth, a
gender gap, selection on the timing of first birth, and gendered effects
of parenthood, for trying out the estimators.

## Usage

``` r
simulate_data(n_individuals = 10000, treatment_groups = 24:28, seed = 42)
```

## Arguments

- n_individuals:

  Whole number \\\ge 2\\. Number of individuals (default 10 000), half
  of them women (rounded).

- treatment_groups:

  Whole numbers \\\ge 21\\: ages at first birth (default `24:28`). Ages
  run from 20 to `max(treatment_groups) - 1`, so the largest group is
  never observed treated and serves only as a control.

- seed:

  Whole number or `NULL`. RNG seed (default 42). The caller's RNG state
  is saved and restored on exit, so calling this function does not alter
  the global random stream;
  [`set.seed()`](https://rdrr.io/r/base/Random.html) before the call has
  no effect unless `seed = NULL`, which draws from the current RNG
  state.

## Value

A balanced long panel (data.frame), `n_individuals` x
(`max(treatment_groups)` - 20) rows sorted by id and age, with columns
`id`, `female` (1 = female), `age`, `D` (age at first birth) and `Y`
(earnings, positive).

## Details

Earnings of person \\i\\ at age \\a\\ are \$\$\log Y\_{i,a} = \mu_0 +
\lambda D_i + \alpha_i + \beta_1 (a - 20) + \beta_2 (a - 20)^2 + \kappa
F_i + \tau_f F_i 1\\a \ge D_i\\ + \tau_m (1 - F_i) 1\\a \ge D_i\\ +
\varepsilon\_{i,a},\$\$ with \\F_i = 1\\ for women, \\\mu_0 = 10\\,
\\\lambda = 0.03\\, \\\beta_1 = 0.08\\, \\\beta_2 = -0.003\\, \\\kappa =
-0.10\\, \\\tau_f = -0.30\\, \\\tau_m = -0.05\\, a permanent effect
\\\alpha_i \sim N(0, 0.20^2)\\ and a transitory shock
\\\varepsilon\_{i,a} \sim N(0, 0.15^2)\\. The age at first birth \\D_i\\
is drawn uniformly from `treatment_groups`, independently of gender and
\\\alpha_i\\; \\\lambda D_i\\ makes later first births earn more at
every age (selection on timing).

True values, the same for every treatment group and age after first
birth: \\\theta(f) = e^{-0.30} - 1 = -0.259\\, \\\theta(m) = e^{-0.05} -
1 = -0.049\\, gap \\-0.210\\; counterfactual gender earnings ratio
\\\rho(\infty) = e^{-0.10} = 0.905\\, observed ratio \\\rho(d) =
0.705\\, effect of parenthood on the ratio \\\rho(d) - \rho(\infty) =
-0.200\\; parenthood's share of the gender gap 0.678. Because \\\lambda
D_i\\ scales earnings levels by group, parallel trends in levels
(DID-PT) and TD-PT fail, while NTD-PT, TD-PR and TD-E-LOGS hold.

## See also

[`multiple_treatment_group_analysis`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)

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
range(sim$age)
#> [1] 20 27
# }
```
