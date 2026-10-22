# Bias-corrected conventional estimates for assumed fathers' effects

The bias-bounding exercise of Leventer (2025, Section 3.3). Under NTD
the conventional estimator (the gender gap in normalized DID) is biased
for the gender gap in normalized effects \\\theta(f) - \theta(m)\\ when
parallel trends fails (Theorem 1). If fathers' normalized effect
\\\theta(m)\\ were known, the gap would be identified (Proposition 2).
This function computes the bias-corrected gap for each assumed value of
\\\theta(m)\\, for every post-treatment cell of `results` (Proposition 2
applies after treatment, \\d' \> a \ge d\\); comparing it with the
conventional estimate bounds the bias.

## Usage

``` r
bias_bounds(results, theta_m = c(-0.1, 0.1))
```

## Arguments

- results:

  The data.frame returned by
  [`multiple_treatment_group_analysis`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md),
  unmodified.

- theta_m:

  Numeric vector of assumed fathers' normalized effects (default
  `c(-0.1, 0.1)`, the paper's range).

## Value

A data.frame with one row per cell and value of `theta_m`: `d`, `dp`,
`a`, `event_time`, `theta_m`, `est` (the bias-corrected gap), `se`,
`ci_l`, `ci_h`.

## Details

For a post-treatment cell \\(d, d', a)\\, with \\\hat\Delta\\ the `NTD`
`rho_effect` estimate (the effect of parenthood on the gender earnings
ratio) and \\\hat\delta\_{APO}(g)\\ the DID-imputed counterfactual mean
of gender \\g\\ (rows `APO`, `DID_Female` / `DID_Male`), the
bias-corrected gap is (Proposition 2, in the form of the appendix on
estimation and inference) \$\$\hat\Delta \\
\frac{\hat\delta\_{APO}(m)}{\hat\delta\_{APO}(f)} \\ (1 +
\theta(m)).\$\$ It is linear in \\\theta(m)\\, so the values at the ends
of an interval bound it over the whole interval. Standard errors come
from the delta method on the stored person-level influence functions,
clustered by person.

## See also

[`multiple_treatment_group_analysis`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)

## Examples

``` r
# \donttest{
sim <- simulate_data(n_individuals = 2000)
res <- multiple_treatment_group_analysis(sim, treatment_groups = 24:26,
  periods_post = 2, periods_pre = NULL, verbose = FALSE)
#> 1 cells could not be estimated (see attr(result, "skipped")), e.g.: No women with age at first birth 26 observed at age 28.
bb <- bias_bounds(res)
# Conventional estimate and the bias-corrected band, d = 25
subset(res, method == "Conventional" & d == 25, c(event_time, est))
#>     event_time        est
#> 65           0 -0.3594221
#> 84           1 -0.2410713
#> 103          2 -0.2355921
subset(bb, d == 25, c(event_time, theta_m, est, se))
#>    event_time theta_m        est         se
#> 7           0    -0.1 -0.3267637 0.01833033
#> 8           0     0.1 -0.3993778 0.02240374
#> 9           1    -0.1 -0.2419381 0.01831832
#> 10          1     0.1 -0.2957022 0.02238905
#> 11          2    -0.1 -0.2329846 0.01721372
#> 12          2     0.1 -0.2847590 0.02103900
# }
```
