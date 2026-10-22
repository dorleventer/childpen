# Simulate panel data for child-penalty estimation

Generates a balanced panel of annual earnings designed to show the
patterns the paper discusses: selection on the timing of first birth
that makes parallel trends fail in the paper's direction, effects of
parenthood that differ by age at first birth and fade with time since
birth, and a gender earnings ratio that falls with age. The true values
are attached, so estimates can be compared with them.

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
(earnings, positive). Attribute `"truth"`: the population values for
every treatment group `d` and age `a >= d` (`event_time` = a - d):
`APO_f`, `APO_m` (mean earnings absent children), `ATE_f`, `ATE_m`,
`theta_f`, `theta_m`, `gap_theta`, `rho_cf` (\\\rho(\infty)\\),
`rho_obs` (\\\rho(d)\\), `rho_effect` (\\\rho(d) - \rho(\infty)\\),
`share_parenthood`. Attribute `"params"`: the parameter values.

## Details

Earnings of person \\i\\ with age at first birth \\D_i\\ at age \\a\\
are \$\$\log Y\_{i,a} = h\_{D_i}(a) + \kappa(a) F_i + \tau\_{F_i}(D_i,
a - D_i)\\1\\a \ge D_i\\ + \alpha_i + \varepsilon\_{i,a},\$\$ with \\F_i
= 1\\ for women and:

- **Career entry and growth** (selection on timing): \\h_D(a) = 9.6 +
  0.02 (a - 20) + \beta(D) x - 0.0015 x^2\\, with experience \\x =
  \max(a - s(D), 0)\\, entry age \\s(D) = 20 + 0.7 (D - 24)\\ and slope
  \\\beta(D) = 0.09 + 0.008 (D - 28)\\. Later first births enter the
  labor market later (more schooling) and then grow faster. Before
  treatment, distant control groups are not yet working and grow more
  slowly, so pre-treatment DID estimates grow in magnitude with the
  distance to the control group and are negative for distant control
  groups (for the closest ones they are small and can be positive);
  after treatment, the later control groups grow faster, so parallel
  trends fails with a negative violation for earlier treatment groups.

- **Gender gap by age**: \\\kappa(a) = -0.04 - 0.015 \max(a - 25, 0)\\,
  so the female/male ratio absent children is \\e^{\kappa(a)}\\: 0.96 up
  to age 25, then falling.

- **Effects of parenthood**: mothers \\\tau_f(D, e) = -0.45 + 0.02
  (D - 24) + 0.04 \min(e, 5)\\ (smaller for later first births, fading
  with event time \\e\\); fathers \\\tau_m = -0.02\\. In normalized
  terms \\\theta(g) = e^{\tau_g} - 1\\.

- **Noise**: \\\alpha_i \sim N(0, 0.20^2)\\ (permanent),
  \\\varepsilon\_{i,a} \sim N(0, 0.15^2)\\ (transitory), independent of
  everything else.

- **Age at first birth**: drawn from `treatment_groups` with
  probabilities proportional to a normal density with mean 29 and
  standard deviation 4, independently of gender.

Under this design DID-PT and TD-PT fail; TD-E-LOGS holds exactly (the
gender terms cancel in log means); NTD-PT and TD-PR hold only
approximately, because the gender ratio changes with age between the
baseline and the target age. The NTD estimator therefore differs
slightly from the true effect on the gender earnings ratio (by up to
about 0.01 in this design); the attached true values show by how much.

## See also

[`multiple_treatment_group_analysis`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)

## Examples

``` r
# \donttest{
sim <- simulate_data(n_individuals = 2000)
head(sim)
#>   id female age  D        Y
#> 1  1      1  20 24 20377.01
#> 2  1      1  21 24 21646.62
#> 3  1      1  22 24 24685.25
#> 4  1      1  23 24 23699.54
#> 5  1      1  24 24 22705.80
#> 6  1      1  25 24 18687.18
head(attr(sim, "truth"))
#>    d  a event_time    APO_f    APO_m    theta_f     theta_m     ATE_f     ATE_m
#> 1 24 24          0 19521.08 20317.75 -0.3623718 -0.01980133 -7073.889 -402.3183
#> 2 24 25          1 20821.68 21671.43 -0.3363497 -0.01980133 -7003.367 -429.1230
#> 3 24 26          2 21812.75 23046.06 -0.3092657 -0.01980133 -6745.935 -456.3425
#> 4 24 27          3 22782.55 24434.47 -0.2810763 -0.01980133 -6403.633 -483.8349
#> 5 25 25          0 20896.04 21748.82 -0.3494909 -0.01980133 -7302.976 -430.6556
#> 6 25 26          1 22112.87 23363.14 -0.3229431 -0.01980133 -7141.199 -462.6212
#>    gap_theta    rho_cf   rho_obs rho_effect share_parenthood
#> 1 -0.3425705 0.9607894 0.6250023 -0.3357872        0.8954379
#> 2 -0.3165484 0.9607894 0.6505091 -0.3102803        0.8878066
#> 3 -0.2894643 0.9464851 0.6669768 -0.2795083        0.8393059
#> 4 -0.2612749 0.9323938 0.6838614 -0.2485324        0.7861502
#> 5 -0.3296896 0.9607894 0.6376282 -0.3231613        0.8917947
#> 6 -0.3031418 0.9464851 0.6537698 -0.2927154        0.8454356
# }
```
