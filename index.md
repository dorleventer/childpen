# childpen

> This package accompanies the paper **Leventer, Dor.** *Identification
> of Child Penalties.*
> [arXiv:2602.07486](https://arxiv.org/abs/2602.07486).

`childpen` estimates the paper’s 2x2 comparisons of parents by age at
first birth (a treatment group against the closest not-yet-treated
group, by gender), with standard errors clustered by person:

- within-gender DID and the triple difference;
- the conventional normalized estimator of child penalties, with the
  paper’s bias-bounding exercise
  ([`bias_bounds()`](https://dorleventer.github.io/childpen/reference/bias_bounds.md));
- the effect of parenthood on the gender earnings ratio (identified
  under NTD) and the accounting of the gender gap into parenthood and
  other factors;
- the proportional triple-difference versions of the online appendix;
- aggregates across treatment groups
  ([`aggregate_estimands()`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md)),
  and pair-by-pair validation tests.

[`simulate_data()`](https://dorleventer.github.io/childpen/reference/simulate_data.md)
generates a panel with the paper’s patterns and known true values.

## Installation

Install the released version from CRAN:

``` r

install.packages("childpen")
```

Or the development version from GitHub:

``` r

# install.packages("remotes")
remotes::install_github("dorleventer/childpen")
```

## Example

The effect of parenthood on the gender earnings ratio and the
conventional estimator, by treatment group and event time (the paper’s
Figure 6b), on simulated data:

``` r

library(childpen)
library(ggplot2)
sim <- simulate_data(n_individuals = 20000, treatment_groups = 24:32)
res <- multiple_treatment_group_analysis(sim, treatment_groups = 25:28, periods_post = 3,
                                         periods_pre = NULL, verbose = FALSE)
est <- subset(res, (method == "NTD" & estimand == "rho_effect") |
                   (method == "Conventional" & estimand == "gap_theta"))
ggplot(est, aes(event_time, est, ymin = ci_l, ymax = ci_h, colour = method, fill = method)) +
  geom_ribbon(alpha = 0.2, colour = NA) + geom_line() + geom_point() +
  facet_wrap(~ d, nrow = 1) + labs(x = "Event time", y = "Estimate (95% CI)")
```

![](reference/figures/README-example-1.png)

## Articles

1.  [Notation and
    output](https://dorleventer.github.io/childpen/articles/notation.html):
    the 2x2, the estimands, and what each output row is.
2.  [Identification](https://dorleventer.github.io/childpen/articles/identification.html):
    parallel trends, the validation test and NTD, the non-identification
    of the conventional target, bias bounding, and the effect on the
    gender earnings ratio.
3.  [Estimation](https://dorleventer.github.io/childpen/articles/estimators.html):
    the grid of comparisons, every estimator and its influence function.
4.  [Aggregation](https://dorleventer.github.io/childpen/articles/aggregation.html):
    estimands across treatment groups, weights and standard errors.
5.  [Replicating the
    paper](https://dorleventer.github.io/childpen/articles/replication.html):
    the paper’s figures, one by one, on simulated data.
