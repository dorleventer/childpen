# Aggregate estimates across treatment groups

Averages the treatment-group-specific estimates from
[`multiple_treatment_group_analysis`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)
across treatment groups, by event time (Leventer 2025, Section 5). The
default weights are the treatment-group shares in the sample. Standard
errors account for persons who serve as controls for several treatment
groups.

## Usage

``` r
aggregate_estimands(
  results,
  weights = "sample",
  methods = c("DID_Female", "DID_Male", "TD", "Conventional", "NTD", "TD_E_LOGS",
    "TD_PR"),
  include_pre = FALSE
)
```

## Arguments

- results:

  The data.frame returned by
  [`multiple_treatment_group_analysis`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md),
  unmodified (its attributes carry the influence functions). A table
  without them is accepted, with standard errors under an independence
  approximation and a warning.

- weights:

  How to weight treatment groups:

  - `"sample"` (default): treatment-group shares. Within gender,
    \\w\_{g,d} = n\_{g,d} / \sum\_{k} n\_{g,k}\\, for `DID_Female` and
    `DID_Male`; across genders, \\w_d = n_d / \sum\_{k} n\_{k}\\, for
    all other methods.

  - `"uniform"` or `NULL`: equal weight per treatment group.

  - A named numeric vector (names = treatment groups): fixed weights,
    renormalized to sum to one over the groups present at each event
    time. Groups missing from the vector get weight zero, with a
    warning.

- methods:

  Methods to aggregate (default: all). `DID_Female`, `DID_Male`:
  `weighted_avg` and `ratio_of_avgs` of `theta`; `Conventional`:
  `weighted_avg` of `gap_theta`; `NTD` and `TD_E_LOGS`: `weighted_avg`
  of `rho_effect` and of the accounting rows `rho_obs`, `rho_cf`,
  `share_parenthood`, `share_other`; `TD`: `weighted_avg` of `gap_ATE`;
  `TD_PR`: `weighted_avg` of `gap_theta_pre`.

- include_pre:

  Logical (default `FALSE`). Also aggregate pre-treatment event times.

## Value

A data.frame with one row per event time, estimand, method and
aggregation type: `event_time`, `estimand`, `method`, `agg_type`, `est`,
`se`, `n_groups` (treatment groups with positive weight), `ci_l`, `ci_h`
(est -/+ 1.96 se), `t`, `p`.

## Details

`agg_type = "weighted_avg"` is \\\sum_d w_d B_d\\ over the
treatment-group estimates \\B_d\\. For `DID_Female` / `DID_Male` this is
\\\theta\_{Agg,1}(g, e)\\; for `Conventional` it is the conventional
aggregate gap \\\Delta\theta\_{Agg}(e)\\, which under NTD is biased for
the gap in normalized effects (Theorem 1); for `NTD` it is
\\\rho\_{Agg}(e)\\, the aggregate effect of parenthood on the gender
earnings ratio. `agg_type = "ratio_of_avgs"` (DID rows only) is
\\\theta\_{Agg,2}(g, e)\\, the ratio of the weighted average ATE to the
weighted average APO; it puts more weight on higher-earning groups,
which is why the paper prefers \\\theta\_{Agg,1}\\ (Section 5.1).

**Standard errors.** The influence function of an aggregate (aggregate
estimator section of the appendix on estimation and inference) sums the
treatment-group influence functions with the weights; with
`weights = "sample"` it adds the term for the estimated shares,
\\\psi\_{A(e)} = P_e^{-1}\sum_d \[(B_d - A(e))\psi\_{p_d} +
p_d\psi\_{B_d}\]\\, \\\psi\_{p_d} = 1\\D = d\\ - p_d\\ (\\1\\G = g, D =
d\\ - p\_{g,d}\\ for within-gender shares). For `ratio_of_avgs` the
chain rule is applied to the ratio, with the weights treated as fixed.
Standard errors are clustered by person.

Not every treatment group has an estimate at every event time; each
event time uses the groups present, and `n_groups` reports how many.

## See also

[`multiple_treatment_group_analysis`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md),
[`bias_bounds`](https://dorleventer.github.io/childpen/reference/bias_bounds.md)

## Examples

``` r
# \donttest{
sim <- simulate_data(n_individuals = 2000)
res <- multiple_treatment_group_analysis(sim, treatment_groups = 24:26,
  periods_post = 2, periods_pre = NULL, verbose = FALSE)
#> 1 cells could not be estimated (see attr(result, "skipped")), e.g.: No women with age at first birth 26 observed at age 28.
agg <- aggregate_estimands(res)
agg[agg$method %in% c("NTD", "Conventional"), ]
#>    event_time         estimand       method     agg_type        est         se
#> 1           0        gap_theta Conventional weighted_avg -0.2289949 0.01685878
#> 2           1        gap_theta Conventional weighted_avg -0.2260591 0.01622344
#> 3           2        gap_theta Conventional weighted_avg -0.1805275 0.01796477
#> 16          0           rho_cf          NTD weighted_avg  0.9373967 0.01976108
#> 17          0       rho_effect          NTD weighted_avg -0.2264505 0.01804575
#> 18          0          rho_obs          NTD weighted_avg  0.7109462 0.01017532
#> 19          0      share_other          NTD weighted_avg  0.2110782 0.06668928
#> 20          0 share_parenthood          NTD weighted_avg  0.7889218 0.06668928
#> 21          1           rho_cf          NTD weighted_avg  0.9311086 0.01840458
#> 22          1       rho_effect          NTD weighted_avg -0.2222094 0.01696201
#> 23          1          rho_obs          NTD weighted_avg  0.7088991 0.01057655
#> 24          1      share_other          NTD weighted_avg  0.2340747 0.06095593
#> 25          1 share_parenthood          NTD weighted_avg  0.7659253 0.06095593
#> 26          2           rho_cf          NTD weighted_avg  0.9038630 0.02003697
#> 27          2       rho_effect          NTD weighted_avg -0.1791240 0.01868496
#> 28          2          rho_obs          NTD weighted_avg  0.7247390 0.01270538
#> 29          2      share_other          NTD weighted_avg  0.3480063 0.06841233
#> 30          2 share_parenthood          NTD weighted_avg  0.6519937 0.06841233
#>    n_groups        ci_l       ci_h          t            p
#> 1         3 -0.26203814 -0.1959517 -13.583127 5.042671e-42
#> 2         3 -0.25785707 -0.1942612 -13.934102 3.931151e-44
#> 3         2 -0.21573844 -0.1453165 -10.048971 9.283150e-24
#> 16        3  0.89866497  0.9761284  47.436503 0.000000e+00
#> 17        3 -0.26182017 -0.1910808 -12.548687 4.041575e-36
#> 18        3  0.69100257  0.7308898  69.869643 0.000000e+00
#> 19        3  0.08036718  0.3417892   3.165099 1.550303e-03
#> 20        3  0.65821084  0.9196328  11.829814 2.737462e-32
#> 21        3  0.89503561  0.9671816  50.591130 0.000000e+00
#> 22        3 -0.25545498 -0.1889639 -13.100421 3.274364e-39
#> 23        3  0.68816911  0.7296292  67.025585 0.000000e+00
#> 24        3  0.11460110  0.3535483   3.840065 1.230018e-04
#> 25        3  0.64645167  0.8853989  12.565231 3.279160e-36
#> 26        2  0.86459051  0.9431354  45.109759 0.000000e+00
#> 27        2 -0.21574649 -0.1425015  -9.586534 9.109414e-22
#> 28        2  0.69983646  0.7496415  57.041913 0.000000e+00
#> 29        2  0.21391816  0.4820945   5.086895 3.639737e-07
#> 30        2  0.51790549  0.7860818   9.530353 1.567495e-21
# }
```
