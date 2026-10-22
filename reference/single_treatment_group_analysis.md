# Child-penalty estimates for one 2x2 comparison

For one treatment group \\d\\ (age at first birth), control group \\d'\\
and target age \\a\\, estimates the descriptive estimands of Leventer
(2025): within-gender DID, the gender gaps under TD, the conventional
estimator, the effect of parenthood on the gender earnings ratio (NTD
and proportional TD), and the accounting of the gender gap. Returns 19
rows with standard errors clustered by person.

## Usage

``` r
single_treatment_group_analysis(
  data,
  d,
  dp,
  a,
  pre = 1,
  Y_name = "Y",
  age_name = "age",
  D_name = "D",
  id_name = "id",
  female_name = "female"
)
```

## Arguments

- data:

  A data.frame (or data.table) in long format: one row per person and
  age, with the person id, age, age at first birth, a female indicator
  and earnings. The panel need not be balanced. Each person's female
  indicator and age at first birth must be constant; a missing age at
  first birth means the person never has a child. Rows with missing
  earnings are dropped (with a message). Earnings may be zero, but the
  ratio rows need positive cell means. `data` is not modified.

- d:

  Whole number. Treatment group: age at first birth.

- dp:

  Whole number. Control group \\d'\\: an age at first birth that is not
  yet treated at the target age, `dp > a` (and `dp > d`). The paper uses
  the closest not-yet-treated group, `dp = a + 1` (Section 1.3), as
  [`multiple_treatment_group_analysis`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)
  does.

- a:

  Whole number. Target age; event time is \\e = a - d\\. With `a >= d`
  the rows are post-birth estimates; with `a < d - pre` they are
  pre-treatment validation (placebo) estimates (Sections 2.3, 4.2).

- pre:

  Whole number \\\ge 1\\ (default 1). The baseline age is \\d - pre\\.
  The default, \\d - 1\\, is the paper's choice; larger values move the
  baseline earlier in case earnings at \\d - 1\\ reflect anticipation
  (Section 3.1).

- Y_name, age_name, D_name, id_name, female_name:

  Names of the columns holding earnings, age, age at first birth, the
  person id (clustering unit) and the female indicator (1 / `TRUE` =
  female; also accepted: labels such as "female"/"male", "f"/"m",
  "woman"/"man"; any other label is an error).

## Value

A data.frame with 19 rows and columns `d`, `dp`, `a`, `event_time`
(\\a - d\\), `control_offset` (\\d' - d\\), `estimand`, `method`, `est`,
`se`, `ci_l`, `ci_h` (est -/+ 1.96 se), `t`, `p` (two-sided, normal),
and `n_female_treat`, `n_female_control`, `n_male_treat`,
`n_male_control` (persons with \\D = d\\ and \\D = d'\\). Attribute
`"if_scores"`: person-level sums of the influence functions, used by
[`aggregate_estimands`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md)
and
[`bias_bounds`](https://dorleventer.github.io/childpen/reference/bias_bounds.md).

## Details

Let \\\mu(g, k, t)\\ be the mean earnings of gender \\g \in \\f, m\\\\
with age at first birth \\k\\ at age \\t\\, estimated by the cell mean,
and \\b = d - pre\\ the baseline age. The additive (DID) and
multiplicative imputations of counterfactual earnings at age \\a\\ are
\$\$\delta\_{APO}(g) = \mu(g,d,b) + \mu(g,d',a) - \mu(g,d',b), \qquad
\delta^{\times}\_{APO}(g) = \mu(g,d,b)\\\mu(g,d',a) / \mu(g,d',b).\$\$
The rows, with the assumption under which each identifies its target
(all also need no anticipation):

|  |  |  |
|----|----|----|
| **method** | **estimand** | **estimator; target** |
| DID_Female, DID_Male | APO | \\\delta\_{APO}(g)\\; \\APO(g, \infty)\\ under DID-PT |
| DID_Female, DID_Male | ATE | \\\mu(g,d,a) - \delta\_{APO}(g)\\; \\ATE(g)\\ under DID-PT |
| DID_Female, DID_Male | theta | ATE row / APO row; \\\theta(g)\\ under DID-PT |
| TD | gap_ATE | ATE row f minus m; \\ATE(f) - ATE(m)\\ under TD-PT |
| Conventional | gap_theta | theta row f minus m; \\\theta(f) - \theta(m)\\ under DID-PT only (under NTD-PT it is biased, Theorem 1) |
| NTD | rho_effect | \\\mu(f,d,a)/\mu(m,d,a) - \delta\_{APO}(f)/\delta\_{APO}(m)\\; \\\rho(d) - \rho(\infty)\\ under NTD-PT (Theorem 2) |
| TD_E_LOGS | rho_effect | as NTD with \\\delta^{\times}\_{APO}\\; \\\rho(d) - \rho(\infty)\\ under TD-E-LOGS (proposition in the online appendix on proportional DID and TD) |
| TD_PR | gap_theta_pre | \\\[\mu(g,d,a) - \delta^{\times}\_{APO}(g)\] / \mu(g,d,b)\\, f minus m; \\ATE(g)/APO(g,d,\infty,b)\\, f minus m, under TD-PR (same proposition) |
| NTD, TD_E_LOGS | rho_obs | \\\mu(f,d,a)/\mu(m,d,a)\\; the observed gender earnings ratio \\\rho(d)\\ |
| NTD, TD_E_LOGS | rho_cf | \\\delta\_{APO}(f)/\delta\_{APO}(m)\\ (NTD) or with \\\delta^{\times}\_{APO}\\ (TD_E_LOGS); \\\rho(\infty)\\ under NTD-PT (NTD) or TD-E-LOGS (TD_E_LOGS) |
| NTD, TD_E_LOGS | share_parenthood | \\(\rho\_{cf} - \rho\_{obs}) / (1 - \rho\_{obs})\\; parenthood's share of the observed gender gap (Section 4.2), under the same assumption as rho_cf |
| NTD, TD_E_LOGS | share_other | \\1 -\\ share_parenthood; the share of other factors |

Gaps are female minus male. The conventional estimator is the 2x2
version of the normalized event-study child penalty; under NTD it equals
the target gap times a gender-invariant bias factor (Theorem 1), see
[`bias_bounds`](https://dorleventer.github.io/childpen/reference/bias_bounds.md)
for the paper's bias-bounding exercise. The accounting rows and their
standard errors are an extension of the paper's Section 4.2 accounting
exercise.

**Standard errors.** Each row is a smooth function of the eight cell
means; its influence function follows by the chain rule from those of
the cell means, \\\psi\_{\mu} = S (Y - \mu) / P(S)\\ with \\S\\ the cell
indicator (the appendix on estimation and inference). The variance is
\\n^{-2} \sum_c (\sum\_{i \in c} \psi_i)^2 \\ G / (G - 1)\\, clustering
by person (\\n\\ person-age rows, \\G\\ persons).
[`vignette("estimators")`](https://dorleventer.github.io/childpen/articles/estimators.md)
writes out every estimator and influence function.

## See also

[`multiple_treatment_group_analysis`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)
for the grid of comparisons the paper uses,
[`aggregate_estimands`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md),
[`bias_bounds`](https://dorleventer.github.io/childpen/reference/bias_bounds.md),
[`vignette("estimators")`](https://dorleventer.github.io/childpen/articles/estimators.md)

## Examples

``` r
# \donttest{
sim <- simulate_data(n_individuals = 2000)
# Treatment group d = 25 one year after first birth (a = 26),
# closest not-yet-treated control group d' = a + 1 = 27
res <- single_treatment_group_analysis(sim, d = 25, dp = 27, a = 26)
res[res$method %in% c("Conventional", "NTD"), c("method", "estimand", "est", "se")]
#>          method         estimand        est         se
#> 8  Conventional        gap_theta -0.2537118 0.02607871
#> 9           NTD       rho_effect -0.2506474 0.02690808
#> 12          NTD          rho_obs  0.6988298 0.01846319
#> 13          NTD           rho_cf  0.9494772 0.02979282
#> 14          NTD share_parenthood  0.8322449 0.09465011
#> 15          NTD      share_other  0.1677551 0.09465011
# Pre-treatment validation (placebo) test: a < d - 1
val <- single_treatment_group_analysis(sim, d = 25, dp = 27, a = 22)
val[val$method %in% c("Conventional", "NTD") & val$estimand %in% c("gap_theta", "rho_effect"),
    c("method", "estimand", "est", "se")]
#>         method   estimand         est         se
#> 8 Conventional  gap_theta -0.09041602 0.03431302
#> 9          NTD rho_effect -0.08514425 0.03320915
# }
```
