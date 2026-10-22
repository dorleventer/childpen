# childpen: Identification and Estimation of Child Penalties

Estimators from Leventer (2025), "Identification of Child Penalties"
([doi:10.48550/arXiv.2602.07486](https://doi.org/10.48550/arXiv.2602.07486)
), for event-study comparisons of parents by age at first birth.

## Details

The workflow:

1.  [`multiple_treatment_group_analysis`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)
    estimates every 2x2 comparison (treatment group \\d\\, closest
    not-yet-treated control \\d' = a + 1\\, target age \\a\\) for a set
    of treatment groups and event times, plus pre-treatment validation
    tests;
    [`single_treatment_group_analysis`](https://dorleventer.github.io/childpen/reference/single_treatment_group_analysis.md)
    does one comparison.

2.  [`aggregate_estimands`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md)
    averages across treatment groups by event time.

3.  [`bias_bounds`](https://dorleventer.github.io/childpen/reference/bias_bounds.md)
    runs the bias-bounding exercise for the conventional estimator.

[`simulate_data`](https://dorleventer.github.io/childpen/reference/simulate_data.md)
generates a panel with known true values to try them out.
[`vignette("estimators")`](https://dorleventer.github.io/childpen/articles/estimators.md)
writes out every estimator and its influence function.

## See also

Useful links:

- <https://github.com/dorleventer/childpen>

- <https://dorleventer.github.io/childpen/>

- Report bugs at <https://github.com/dorleventer/childpen/issues>

## Author

**Maintainer**: Dor Leventer <leventerdor@gmail.com>
