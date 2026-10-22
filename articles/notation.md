# Notation and output

This page maps the notation of Leventer (2025), [*Identification of
Child Penalties*](https://arxiv.org/abs/2602.07486), to the rows and
columns the package returns. Section, theorem, proposition and equation
numbers refer to the main text; appendices are referred to by name. The
articles that follow are
[Identification](https://dorleventer.github.io/childpen/articles/identification.md),
[Estimation](https://dorleventer.github.io/childpen/articles/estimators.md),
[Aggregation](https://dorleventer.github.io/childpen/articles/aggregation.md)
and [Replicating the
paper](https://dorleventer.github.io/childpen/articles/replication.md).

## 1. The 2x2

A single comparison involves a gender $`g \in \{f, m\}`$, a treatment
group $`d`$, a control group $`d'`$, a target age $`a`$ and a baseline
age $`b`$.

| symbol | meaning | in the package |
|----|----|----|
| $`d`$ | treatment group: age at first birth | `d`, `treatment_groups` |
| $`d'`$ | control group: an age at first birth not yet reached at the target age, $`d' > a`$. Here the closest not-yet-treated group, $`d' = a + 1`$ (Section 1.3) | `dp` |
| $`a`$ | target age | `a` |
| $`b = d - \text{pre}`$ | baseline age; $`b = d - 1`$ by default | `pre` |
| $`e = a - d`$ | event time | `event_time` |
| $`d' - d`$ | control offset | `control_offset` |
| $`D_{\max}`$ | largest age at first birth allowed as a control group | `max_control_group` |

With $`d' = a + 1`$, a post-treatment cell at event time $`e`$ has
control offset $`e + 1`$. For $`d = 26`$:

| event time $`e`$ | target age $`a`$ | control group $`d'`$ | control offset $`d' - d`$ |
|----|----|----|----|
| 0 | 26 | 27 | 1 |
| 1 | 27 | 28 | 2 |
| 2 | 28 | 29 | 3 |

[`single_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/single_treatment_group_analysis.md)
accepts any `dp` with `dp > a` and `dp > d`;
[`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)
uses $`d' = a + 1`$. A pre-treatment cell has a target age $`a < b`$.
The assumptions concern each treatment-control pair separately (Section
2.3), so
[`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md)
estimates a pre-treatment cell for each control group used after
treatment, $`d' = d + 1, \dots, d + H + 1`$, where $`H`$ is
`periods_post`.

## 2. Potential outcomes and causal estimands

Let $`Y_{i,a}(d)`$ be the potential earnings of person $`i`$ at age
$`a`$ if the first birth occurs at age $`d`$, and $`Y_{i,a}(\infty)`$
the potential earnings if $`i`$ never has a child. Observed earnings are
$`Y_{i,a} = Y_{i,a}(D_i)`$ (consistency). The average potential outcome
(APO) is
``` math
\mathrm{APO}(g, d, d', a) = \mathbb{E}\big[Y_a(d') \mid G = g,\, D = d\big],
```
the mean earnings at age $`a`$ of gender $`g`$ and treatment group $`d`$
had the first birth been at age $`d'`$ (here $`d'`$ is a counterfactual
birth age, not the control group of Section 1). For a single $`(d, a)`$
the paper writes $`\mathrm{APO}(g, d) \equiv \mathrm{APO}(g, d, d, a)`$,
the mean observed earnings
$`\mu_{g,d,a} = \mathbb{E}[Y_a \mid G = g, D = d]`$, and
$`\mathrm{APO}(g, \infty) \equiv \mathrm{APO}(g, d, \infty, a)`$. The
causal estimands of Section 1.3 are

| estimand | definition |
|----|----|
| $`\mathrm{ATE}(g)`$ | $`\mathrm{APO}(g, d) - \mathrm{APO}(g, \infty)`$ |
| $`\theta(g)`$ | $`\mathrm{ATE}(g) / \mathrm{APO}(g, \infty)`$: the effect relative to counterfactual earnings |
| $`\theta(f) - \theta(m)`$ | gender gap in normalized effects, the target of normalized event studies |
| $`\rho(d')`$ | $`\mathrm{APO}(f, d, d', a) / \mathrm{APO}(m, d, d', a)`$: the gender earnings ratio; $`\rho(d)`$ is the realized ratio and $`\rho(\infty)`$ the counterfactual ratio absent a child |
| $`\rho(d) - \rho(\infty)`$ | effect of parenthood on the gender earnings ratio |

The two gender-gap estimands are related by (eq. (9))
``` math
\rho(d) - \rho(\infty) = \frac{\rho(\infty)}{1 + \theta(m)}\,\big[\theta(f) - \theta(m)\big].
```
The observed gender gap splits as
$`1 - \rho(d) = [\rho(\infty) - \rho(d)] + [1 - \rho(\infty)]`$,
parenthood and other factors (Section 4.2).

## 3. Descriptive estimands

The descriptive estimands are functions of observed means,
$`\mu_{g,k,t} = \mathbb{E}[Y_t \mid G = g, D = k]`$. With baseline age
$`b`$ (the paper uses $`b = d - 1`$), eq. (3) reads
``` math
\delta_{\mathrm{APO}}(g) = \mu_{g,d,b} + \mu_{g,d',a} - \mu_{g,d',b}, \qquad
\delta_{\mathrm{ATE}}(g) = \mu_{g,d,a} - \delta_{\mathrm{APO}}(g), \qquad
\delta_\theta(g) = \frac{\delta_{\mathrm{ATE}}(g)}{\delta_{\mathrm{APO}}(g)}.
```
The multiplicative counterpart of $`\delta_{\mathrm{APO}}(g)`$ (the
online appendix on proportional DID and TD) is
``` math
\delta^{\times}_{\mathrm{APO}}(g) = \mu_{g,d,b}\,\frac{\mu_{g,d',a}}{\mu_{g,d',b}}.
```
The gender gaps of the appendix on estimation and inference are
$`\delta_{\Delta\mathrm{ATE}} = \delta_{\mathrm{ATE}}(f) - \delta_{\mathrm{ATE}}(m)`$,
$`\delta_{\Delta\theta} = \delta_\theta(f) - \delta_\theta(m)`$ and
$`\delta_{\Delta\rho} = \mu_{f,d,a}/\mu_{m,d,a} - \delta_{\mathrm{APO}}(f)/\delta_{\mathrm{APO}}(m)`$.
The package returns their sample analogues.

Let $`\gamma_{\mathrm{PT}}(g)`$ be the difference in counterfactual
trends from age $`b`$ to age $`a`$ between the treatment group and the
control group,
``` math
\gamma_{\mathrm{PT}}(g) = \big[\mathrm{APO}(g, d, \infty, a) - \mathrm{APO}(g, d, \infty, b)\big] - \big[\mathrm{APO}(g, d', \infty, a) - \mathrm{APO}(g, d', \infty, b)\big].
```
Under no anticipation, Lemma 1 (eqs. (6)-(7)) gives
$`\delta_{\mathrm{APO}}(g) = \mathrm{APO}(g, \infty) - \gamma_{\mathrm{PT}}(g)`$
and
$`\delta_{\mathrm{ATE}}(g) = \mathrm{ATE}(g) + \gamma_{\mathrm{PT}}(g)`$.
The assumptions that appear below, each for a triplet $`(d, d', a)`$
with $`d \le a < d'`$:

| label | statement |
|----|----|
| NA | no anticipation: $`\mathrm{APO}(g, d) = \mathrm{APO}(g, \infty)`$ at ages $`a < d`$ |
| DID-PT | $`\gamma_{\mathrm{PT}}(g) = 0`$ for each $`g`$ |
| TD-PT | $`\gamma_{\mathrm{PT}}(f) = \gamma_{\mathrm{PT}}(m)`$ |
| NTD-PT | $`\gamma_{\mathrm{PT}}(f) / \mathrm{APO}(f, \infty) = \gamma_{\mathrm{PT}}(m) / \mathrm{APO}(m, \infty)`$ |
| TD-E-LOGS | $`\log\!\big[\mathrm{APO}(g, \infty) / \delta^{\times}_{\mathrm{APO}}(g)\big]`$ is equal across genders |
| TD-PR | $`\big[\mathrm{APO}(g, \infty) - \delta^{\times}_{\mathrm{APO}}(g)\big] / \mu_{g,d,b}`$ is equal across genders |

## 4. Output rows of `single_treatment_group_analysis()`

The function returns 19 rows for one cell $`(d, d', a)`$: `d`, `dp`,
`a`, `event_time`, `control_offset`, `estimand`, `method`, `est`, `se`,
`ci_l`, `ci_h` ($`\text{est} \mp 1.96\,\text{se}`$), `t`, `p`
(two-sided, normal), and the number of persons in the treatment and
control group by gender (`n_female_treat`, `n_female_control`,
`n_male_treat`, `n_male_control`). Gaps are female minus male, and
standard errors are clustered by person. Every row below also relies on
NA. The figure column refers to the figures of the paper in which the
row’s estimate is plotted.

| `method` | `estimand` | paper symbol | what it estimates, and under which assumption | paper figure |
|----|----|----|----|----|
| `DID_Female`, `DID_Male` | `APO` | $`\delta_{\mathrm{APO}}(g)`$ | $`\mathrm{APO}(g, \infty)`$ under DID-PT |  |
| `DID_Female`, `DID_Male` | `ATE` | $`\delta_{\mathrm{ATE}}(g)`$ | $`\mathrm{ATE}(g)`$ under DID-PT | Figure 3 (pre-treatment rows) |
| `DID_Female`, `DID_Male` | `theta` | $`\delta_\theta(g)`$ | $`\theta(g)`$ under DID-PT |  |
| `TD` | `gap_ATE` | $`\delta_{\Delta\mathrm{ATE}}`$ | $`\mathrm{ATE}(f) - \mathrm{ATE}(m)`$ under TD-PT |  |
| `Conventional` | `gap_theta` | $`\delta_{\Delta\theta}`$ | $`\theta(f) - \theta(m)`$ under DID-PT for both genders; under NTD-PT it equals $`\mathrm{Bias} \times [\theta(f) - \theta(m)]`$ with $`\mathrm{Bias} = \mathrm{APO}(g, \infty) / [\mathrm{APO}(g, \infty) - \gamma_{\mathrm{PT}}(g)]`$, equal across genders (Theorem 1) | Figure 4 (with [`bias_bounds()`](https://dorleventer.github.io/childpen/reference/bias_bounds.md)), Figure 5 (pre-treatment rows), Figure 6b |
| `NTD` | `rho_effect` | $`\delta_{\Delta\rho}`$ | $`\rho(d) - \rho(\infty)`$ under NTD-PT (Theorem 2) | Figure 6b; the online appendix’s validation figure (pre-treatment rows) |
| `NTD` | `rho_obs` | $`\mu_{f,d,a} / \mu_{m,d,a}`$ | $`\rho(d)`$, the observed gender earnings ratio (consistency) | Figure 6a |
| `NTD` | `rho_cf` | $`\delta_{\mathrm{APO}}(f) / \delta_{\mathrm{APO}}(m)`$ | $`\rho(\infty)`$ under NTD-PT | Figure 6a |
| `NTD` | `share_parenthood` | $`(\rho_{cf} - \rho_{obs}) / (1 - \rho_{obs})`$ | parenthood’s share of the observed gender gap $`1 - \rho(d)`$, under the assumption of `rho_cf` (Section 4.2) | Figure 6c |
| `NTD` | `share_other` | $`1 -`$`share_parenthood` | the share due to other factors | Figure 6c |
| `TD_E_LOGS` | `rho_effect` | $`\delta_{\Delta\rho}`$ with $`\delta^{\times}_{\mathrm{APO}}`$ in place of $`\delta_{\mathrm{APO}}`$ | $`\rho(d) - \rho(\infty)`$ under TD-E-LOGS (proposition in the online appendix on proportional DID and TD) | the online appendix’s validation figure (pre-treatment rows) and estimate figure |
| `TD_E_LOGS` | `rho_obs`, `rho_cf`, `share_parenthood`, `share_other` | as for `NTD`, with $`\delta^{\times}_{\mathrm{APO}}`$ in `rho_cf` | as for `NTD`, with `rho_cf` identifying $`\rho(\infty)`$ under TD-E-LOGS |  |
| `TD_PR` | `gap_theta_pre` | $`\big[\mu_{f,d,a} - \delta^{\times}_{\mathrm{APO}}(f)\big]/\mu_{f,d,b} - \big[\mu_{m,d,a} - \delta^{\times}_{\mathrm{APO}}(m)\big]/\mu_{m,d,b}`$ | $`\mathrm{ATE}(g) / \mathrm{APO}(g, d, \infty, b)`$, female minus male, under TD-PR (same proposition) | the online appendix’s validation figure (pre-treatment rows) |

The conventional estimator is the 2x2 version of the normalized
event-study child penalty. The accounting rows (`rho_obs`, `rho_cf`,
`share_parenthood`, `share_other`) and their standard errors extend the
accounting exercise of Section 4.2;
[Estimation](https://dorleventer.github.io/childpen/articles/estimators.md)
writes out the influence functions.

A cell of simulated data, treatment group $`d = 26`$ one year after the
first birth ($`a = 27`$, $`e = 1`$) against the control group
$`d' = 28`$, with baseline age $`b = 25`$:

``` r

library(childpen)
sim <- simulate_data(2000, 24:30)
res <- single_treatment_group_analysis(sim, d = 26, dp = 28, a = 27)

names(res)
#>  [1] "d"                "dp"               "a"                "event_time"      
#>  [5] "control_offset"   "estimand"         "method"           "est"             
#>  [9] "se"               "ci_l"             "ci_h"             "t"               
#> [13] "p"                "n_female_treat"   "n_female_control" "n_male_treat"    
#> [17] "n_male_control"
res[1, c("d", "dp", "a", "event_time", "control_offset",
         "n_female_treat", "n_female_control", "n_male_treat", "n_male_control")]
#>    d dp  a event_time control_offset n_female_treat n_female_control
#> 1 26 28 27          1              2            125              169
#>   n_male_treat n_male_control
#> 1          138            159
shown <- res[res$method %in% c("DID_Female", "Conventional", "NTD"),
             c("method", "estimand", "est", "se", "ci_l", "ci_h")]
shown[3:6] <- round(shown[3:6], 3)
shown
#>          method         estimand       est      se      ci_l      ci_h
#> 1    DID_Female              APO 24627.903 592.097 23467.393 25788.413
#> 3    DID_Female              ATE -8230.964 515.899 -9242.125 -7219.803
#> 5    DID_Female            theta    -0.334   0.015    -0.364    -0.304
#> 8  Conventional        gap_theta    -0.279   0.027    -0.332    -0.226
#> 9           NTD       rho_effect    -0.284   0.029    -0.340    -0.228
#> 12          NTD          rho_obs     0.676   0.022     0.634     0.719
#> 13          NTD           rho_cf     0.960   0.032     0.897     1.023
#> 14          NTD share_parenthood     0.876   0.096     0.688     1.065
#> 15          NTD      share_other     0.124   0.096    -0.065     0.312
```

## 5. Pre-treatment rows

At a pre-treatment target age the same 19 rows are returned, one set per
control offset. Under NA, $`\mathrm{ATE}(g) = 0`$ at such an age, so
Lemma 1 gives
$`\delta_{\mathrm{ATE}}(g) = \gamma_{\mathrm{PT}}(g, d, d', a)`$: the
pre-treatment `ATE` row of `DID_Female` and `DID_Male` estimates the
difference in counterfactual trends between $`d`$ and $`d'`$ from $`b`$
to $`a`$ (with $`b`$ in place of $`d - 1`$ when `pre` $`> 1`$). These
are the pre-trends of Figure 3, one per treatment-control pair.

For the gender gap in normalized DID, Proposition 1 states that under NA
``` math
\delta_\theta(f) = \delta_\theta(m) \quad\Longleftrightarrow\quad \frac{\gamma_{\mathrm{PT}}(f)}{\mathrm{APO}(f, \infty)} = \frac{\gamma_{\mathrm{PT}}(m)}{\mathrm{APO}(m, \infty)},
```
so a zero pre-treatment `Conventional` `gap_theta` is equivalent to the
NTD-PT restriction at that age (Figure 5). A non-zero value is read as a
failure of NA, of the restriction, or of both. The same algebra applies
to the `NTD` `rho_effect` row: under NA the observed ratio at a
pre-treatment age equals $`\rho(\infty)`$, and the row is zero exactly
when the restriction holds. Likewise, the pre-treatment `TD_E_LOGS` and
`TD_PR` rows are read against TD-E-LOGS and TD-PR. The pre-treatment
`NTD` `rho_effect`, `TD_E_LOGS` `rho_effect` and `TD_PR` `gap_theta_pre`
rows are the three validation tests of the online appendix on
proportional DID and TD.

## 6. Aggregate rows

[`aggregate_estimands()`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md)
averages the group-level rows over treatment groups by event time. Its
`agg_type` column takes two values: `weighted_avg`, $`\sum_d w_d B_d`$
for a group-level row $`B_d`$, and `ratio_of_avgs`, the ratio of the
weighted average of the `ATE` rows to the weighted average of the `APO`
rows.

| `method` | `estimand` | `agg_type` | paper symbol |
|----|----|----|----|
| `DID_Female`, `DID_Male` | `theta` | `weighted_avg` | $`\theta_{\mathrm{Agg},1}(g, e)`$ |
| `DID_Female`, `DID_Male` | `theta` | `ratio_of_avgs` | $`\theta_{\mathrm{Agg},2}(g, e)`$ |
| `Conventional` | `gap_theta` | `weighted_avg` | $`\Delta\theta_{\mathrm{Agg}}(e)`$, eq. (11) |
| `NTD` | `rho_effect` | `weighted_avg` | $`\rho_{\mathrm{Agg}}(e)`$, eq. (10) |
| `TD_E_LOGS` | `rho_effect` | `weighted_avg` | $`\rho_{\mathrm{Agg}}(e)`$ under TD-E-LOGS |
| `TD`, `TD_PR`, accounting rows | `gap_ATE`, `gap_theta_pre`, `rho_obs`, `rho_cf`, `share_parenthood`, `share_other` | `weighted_avg` | weighted average of the group-level row; no symbol in the paper |

Aggregate rows carry `event_time`, `control_offset` (the offset
$`d' - d`$, equal to $`e + 1`$ after treatment), `n_groups` (treatment
groups with positive weight), `est`, `se`, `ci_l`, `ci_h`, `t` and `p`.
Weights, standard errors and pre-treatment aggregation are in
[Aggregation](https://dorleventer.github.io/childpen/articles/aggregation.md).

## 7. Using your own data

`data` is a data.frame or data.table in long format, one row per person
and age; the panel need not be balanced. The columns are located by
name:

| argument | default | content |
|----|----|----|
| `id_name` | `"id"` | person identifier (the clustering unit) |
| `age_name` | `"age"` | age, numeric |
| `D_name` | `"D"` | age at first birth, constant within person; a missing (or infinite) value means the person never has a child |
| `female_name` | `"female"` | gender, constant within person; `1` / `TRUE` is female and `0` / `FALSE` male; labels such as `"female"` / `"male"`, `"f"` / `"m"`, `"woman"` / `"man"` are also accepted |
| `Y_name` | `"Y"` | earnings, numeric; zeros are allowed, while the ratio rows need positive cell means |

Rows with a missing outcome are dropped with a message. The function
stops with an error if a person-age pair is repeated, if `female` or `D`
varies within a person, if a gender label is not recognised, or if only
one gender is present. `data` is not modified. Persons with a missing
`D` stay in the data and belong to no treatment or control group.

``` r

own <- data.frame(
  person   = sim$id,
  years    = sim$age,
  births   = ifelse(sim$D == 30, NA, sim$D),   # missing: never has a child
  sex      = ifelse(sim$female == 1, "female", "male"),
  earnings = sim$Y
)
res_own <- single_treatment_group_analysis(own, d = 26, dp = 28, a = 27,
  id_name = "person", age_name = "years", D_name = "births",
  female_name = "sex", Y_name = "earnings")
#> 338 persons have a missing or infinite `births`; they are treated as never having a child.
all.equal(res_own[c("est", "se")], res[c("est", "se")])
#> [1] TRUE
```

The columns are only relabelled here, and persons of group 30 are
neither in group 26 nor in group 28, so the estimates equal those of the
previous example.

## 8. Label map

The paper’s replication files (the results file
`unconditional_results.csv` computed on the CBS data) and `childpen`
0.2.x use older labels. In `childpen` 0.3 the method and estimand follow
the paper:

| replication files (`method` / `estimand`) | `childpen` 0.2.x | `childpen` 0.3 |
|----|----|----|
| `NTD` / `theta` | `NTD_Conv` / `theta` | `Conventional` / `gap_theta` |
| `NTD_Alt` / `theta` | `NTD_New` / `Delta_rho` | `NTD` / `rho_effect` |
| `TD` / `ATE` | `TD` / `ATE` | `TD` / `gap_ATE` |
|  | `TD_E_LOGS` / `Delta_rho` | `TD_E_LOGS` / `rho_effect` |
|  | `TD_PR` / `theta_pre` | `TD_PR` / `gap_theta_pre` |
| `TD_Null`, `NTD_Null` | `TD_Null`, `NTD_Conv_Null` | no rows; [`bias_bounds()`](https://dorleventer.github.io/childpen/reference/bias_bounds.md) |

`TD_Null` and `NTD_Null` impose a null effect for fathers.
[`bias_bounds()`](https://dorleventer.github.io/childpen/reference/bias_bounds.md)
reports the bias-corrected conventional gap at any assumed value of
$`\theta(m)`$, a null effect ($`\theta(m) = 0`$) included. In
[`aggregate_estimands()`](https://dorleventer.github.io/childpen/reference/aggregate_estimands.md),
the 0.2.x `agg_type` values `avg_of_ratios` and `gender_ineq` are
`weighted_avg` in 0.3.
