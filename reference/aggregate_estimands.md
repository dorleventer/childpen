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

  Logical (default `FALSE`). Also aggregate pre-treatment event times. A
  pre-treatment event time has one cell per control group
  (`control_offset` = \\d' - d\\), and each offset is aggregated
  separately, so each row is the validation test of one
  treatment-control distance.

## Value

A data.frame with one row per event time, estimand, method and
aggregation type: `event_time`, `control_offset` (\\d' - d\\; after
treatment it is `event_time` + 1), `estimand`, `method`, `agg_type`,
`est`, `se`, `n_groups` (treatment groups with positive weight), `ci_l`,
`ci_h` (est -/+ 1.96 se), `t`, `p`.

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
p_d\psi\_{B_d}\]\\, \\\psi\_{p_d} = 1\\D = d\\ - p_d\\, where \\p_d\\ is
the share of persons in group \\d\\ (\\1\\G = g, D = d\\ - p\_{g,d}\\
with the joint share of gender \\g\\ and group \\d\\ for the
within-gender DID rows) and \\P_e\\ the summed share of the aggregated
groups. For `ratio_of_avgs` the chain rule is applied to the ratio of
the two weighted averages, each with its share term. Standard errors are
clustered by person. The share term is put on the person-age scale with
the average number of ages per person, exact for a balanced panel.

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
#>    event_time control_offset         estimand       method     agg_type
#> 1           0              1        gap_theta Conventional weighted_avg
#> 2           1              2        gap_theta Conventional weighted_avg
#> 3           2              3        gap_theta Conventional weighted_avg
#> 16          0              1           rho_cf          NTD weighted_avg
#> 17          0              1       rho_effect          NTD weighted_avg
#> 18          0              1          rho_obs          NTD weighted_avg
#> 19          0              1      share_other          NTD weighted_avg
#> 20          0              1 share_parenthood          NTD weighted_avg
#> 21          1              2           rho_cf          NTD weighted_avg
#> 22          1              2       rho_effect          NTD weighted_avg
#> 23          1              2          rho_obs          NTD weighted_avg
#> 24          1              2      share_other          NTD weighted_avg
#> 25          1              2 share_parenthood          NTD weighted_avg
#> 26          2              3           rho_cf          NTD weighted_avg
#> 27          2              3       rho_effect          NTD weighted_avg
#> 28          2              3          rho_obs          NTD weighted_avg
#> 29          2              3      share_other          NTD weighted_avg
#> 30          2              3 share_parenthood          NTD weighted_avg
#>            est         se n_groups        ci_l       ci_h          t
#> 1  -0.35228101 0.01846831        3 -0.38847889 -0.3160831 -19.074892
#> 2  -0.28818667 0.01468495        3 -0.31696917 -0.2594042 -19.624629
#> 3  -0.25167927 0.01580489        2 -0.28265686 -0.2207017 -15.924137
#> 16  0.97467151 0.02229332        3  0.93097660  1.0183664  43.720335
#> 17 -0.34374469 0.02015653        3 -0.38325149 -0.3042379 -17.053762
#> 18  0.63092682 0.01025809        3  0.61082096  0.6510327  61.505306
#> 19  0.06674581 0.05981580        3 -0.05049315  0.1839848   1.115856
#> 20  0.93325419 0.05981580        3  0.81601523  1.0504932  15.602136
#> 21  0.95749105 0.01833598        3  0.92155253  0.9934296  52.219244
#> 22 -0.29420296 0.01625368        3 -0.32606018 -0.2623457 -18.100694
#> 23  0.66328809 0.01063222        3  0.64244894  0.6841272  62.384715
#> 24  0.12866886 0.05246129        3  0.02584473  0.2314930   2.452644
#> 25  0.87133114 0.05246129        3  0.76850701  0.9741553  16.609030
#> 26  0.92385644 0.01798716        2  0.88860161  0.9591113  51.361999
#> 27 -0.25571216 0.01592663        2 -0.28692835 -0.2244960 -16.055638
#> 28  0.66814429 0.01397540        2  0.64075250  0.6955361  47.808588
#> 29  0.22851674 0.04993499        2  0.13064416  0.3263893   4.576285
#> 30  0.77148326 0.04993499        2  0.67361067  0.8693558  15.449752
#>               p
#> 1  4.082663e-81
#> 2  9.527014e-86
#> 3  4.309213e-57
#> 16 0.000000e+00
#> 17 3.277414e-65
#> 18 0.000000e+00
#> 19 2.644838e-01
#> 20 7.039867e-55
#> 21 0.000000e+00
#> 22 3.146755e-73
#> 23 0.000000e+00
#> 24 1.418107e-02
#> 25 5.995464e-62
#> 26 0.000000e+00
#> 27 5.219961e-58
#> 28 0.000000e+00
#> 29 4.733065e-06
#> 30 7.573427e-54
# }
```
