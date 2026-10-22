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
#>           est         se n_groups        ci_l       ci_h          t
#> 1  -0.2289949 0.01685930        3 -0.26203916 -0.1959507 -13.582709
#> 2  -0.2260591 0.01623418        3 -0.25787811 -0.1942401 -13.924888
#> 3  -0.1805275 0.01796581        2 -0.21574048 -0.1453145 -10.048389
#> 16  0.9373967 0.01977675        3  0.89863427  0.9761591  47.398927
#> 17 -0.2264505 0.01804710        3 -0.26182280 -0.1910782 -12.547753
#> 18  0.7109462 0.01019243        3  0.69096905  0.7309234  69.752393
#> 19  0.2110782 0.06672640        3  0.08029442  0.3418619   3.163338
#> 20  0.7889218 0.06672640        3  0.65813808  0.9197056  11.823233
#> 21  0.9311086 0.01842272        3  0.89500005  0.9672171  50.541308
#> 22 -0.2222094 0.01697487        3 -0.25548019 -0.1889387 -13.090495
#> 23  0.7088991 0.01058702        3  0.68814859  0.7296497  66.959288
#> 24  0.2340747 0.06100866        3  0.11449773  0.3536517   3.836745
#> 25  0.7659253 0.06100866        3  0.64634831  0.8855023  12.554369
#> 26  0.9038630 0.02004104        2  0.86458254  0.9431434  45.100608
#> 27 -0.1791240 0.01868540        2 -0.21574737 -0.1425006  -9.586304
#> 28  0.7247390 0.01271655        2  0.69981456  0.7496634  56.991800
#> 29  0.3480063 0.06841690        2  0.21390921  0.4821035   5.086555
#> 30  0.6519937 0.06841690        2  0.51789654  0.7860908   9.529717
#>               p
#> 1  5.071533e-42
#> 2  4.472410e-44
#> 3  9.338157e-24
#> 16 0.000000e+00
#> 17 4.089526e-36
#> 18 0.000000e+00
#> 19 1.559711e-03
#> 20 2.960656e-32
#> 21 0.000000e+00
#> 22 3.731659e-39
#> 23 0.000000e+00
#> 24 1.246756e-04
#> 25 3.761670e-36
#> 26 0.000000e+00
#> 27 9.129684e-22
#> 28 0.000000e+00
#> 29 3.646257e-07
#> 30 1.577132e-21
# }
```
