# Estimators and standard errors

This page writes out every estimator the package returns and the
influence function its standard error is built from. Section, theorem
and appendix numbers refer to Leventer (2025), *Identification of Child
Penalties*; appendices are referred to by name, because their letters
differ between the arXiv and journal versions: *Estimation appendix* is
the appendix on estimation and inference, *Proportional appendix* the
online appendix on proportional DID and TD. Formulas that are not in the
paper are marked **not in the paper**.

## Setup

Data are one row per person $`i`$ and age $`t`$, with earnings $`Y`$,
gender $`g \in \{f, m\}`$ and age at first birth $`D`$. A 2x2 comparison
has a treatment group $`d`$, a control group $`d' > a`$, a target age
$`a`$ and a baseline age $`b = d - \text{pre}`$ (default $`b = d - 1`$).

**Cell means.** For a cell $`(g, k, t)`$, with indicator
$`S_{it} = 1\{G_i = g, D_i = k, \text{age} = t\}`$,
``` math
\hat\mu(g,k,t) = \frac{\sum_{i,t'} S_{it'} Y_{it'}}{\sum_{i,t'} S_{it'}},
\qquad
\psi_{\mu(g,k,t)} = \frac{S}{\hat P(S)}\,\big(Y - \hat\mu(g,k,t)\big),
```
where $`\hat P(S)`$ is the share of person-age rows in the cell
(Estimation appendix). Every estimator below is a smooth function of
eight cell means,
``` math
\mu_1 = \mu(g,d,b),\quad \mu_2 = \mu(g,d',a),\quad \mu_3 = \mu(g,d',b),\quad \mu_4 = \mu(g,d,a),
\qquad g \in \{f, m\},
```
and its influence function $`\psi`$ follows from theirs by the chain
rule.

**Standard errors.** For an estimator with influence function $`\psi`$,
with $`n`$ person-age rows, $`G`$ persons and clusters $`c`$ = persons,
``` math
\widehat{\mathrm{Var}} = \frac{1}{n^2}\sum_{c}\Big(\sum_{i \in c}\psi_i\Big)^2\,\frac{G}{G-1}.
```
Confidence intervals are $`\text{est} \pm 1.96\,\text{se}`$.

## Rows of `single_treatment_group_analysis()`

**Imputations of counterfactual earnings.** Additive (DID) and
multiplicative:
``` math
\hat\delta_{APO}(g) = \mu_1 + \mu_2 - \mu_3,
\qquad
\psi_{\delta_{APO}(g)} = \psi_1 + \psi_2 - \psi_3;
```
``` math
\hat\delta^{\times}_{APO}(g) = \frac{\mu_1\,\mu_2}{\mu_3},
\qquad
\psi_{\delta^{\times}_{APO}(g)} = \hat\delta^{\times}_{APO}(g)\Big(\frac{\psi_1}{\mu_1} + \frac{\psi_2}{\mu_2} - \frac{\psi_3}{\mu_3}\Big).
```

| method | estimand | estimator | influence function | in the paper |
|----|----|----|----|----|
| `DID_Female`, `DID_Male` | `APO` | $`\hat\delta_{APO}(g)`$ | $`\psi_{\delta_{APO}(g)}`$ | eq. (3), Estimation app. |
| `DID_Female`, `DID_Male` | `ATE` | $`\hat\delta_{ATE}(g) = \mu_4 - \hat\delta_{APO}(g)`$ | $`\psi_4 - \psi_{\delta_{APO}(g)}`$ | eq. (3), Estimation app. |
| `DID_Female`, `DID_Male` | `theta` | $`\hat\delta_\theta(g) = \hat\delta_{ATE}(g)/\hat\delta_{APO}(g)`$ | $`\dfrac{\psi_{\delta_{ATE}}}{\delta_{APO}} - \dfrac{\delta_{ATE}\,\psi_{\delta_{APO}}}{\delta_{APO}^2}`$ | eq. (3), Estimation app. |
| `TD` | `gap_ATE` | $`\hat\delta_{ATE}(f) - \hat\delta_{ATE}(m)`$ | $`\psi_{\delta_{ATE}(f)} - \psi_{\delta_{ATE}(m)}`$ | Estimation app. |
| `Conventional` | `gap_theta` | $`\hat\delta_\theta(f) - \hat\delta_\theta(m)`$ | $`\psi_{\delta_\theta(f)} - \psi_{\delta_\theta(m)}`$ | Thm. 1, Estimation app. |
| `NTD` | `rho_obs` | $`\hat\rho_{obs} = \mu_4(f)/\mu_4(m)`$ | $`\dfrac{\psi_4(f)}{\mu_4(m)} - \dfrac{\mu_4(f)\,\psi_4(m)}{\mu_4(m)^2}`$ | Estimation app. |
| `NTD` | `rho_cf` | $`\hat\rho_{cf} = \hat\delta_{APO}(f)/\hat\delta_{APO}(m)`$ | $`\dfrac{\psi_{\delta_{APO}(f)}}{\delta_{APO}(m)} - \dfrac{\delta_{APO}(f)\,\psi_{\delta_{APO}(m)}}{\delta_{APO}(m)^2}`$ | Estimation app. |
| `NTD` | `rho_effect` | $`\hat\rho_{obs} - \hat\rho_{cf}`$ | $`\psi_{\rho_{obs}} - \psi_{\rho_{cf}}`$ | Thm. 2, Estimation app. |
| `TD_E_LOGS` | `rho_cf` | $`\hat\rho^{\times}_{cf} = \hat\delta^{\times}_{APO}(f)/\hat\delta^{\times}_{APO}(m)`$ | as `NTD` `rho_cf`, with $`\delta^{\times}_{APO}`$ | Proportional app.; IF **not in the paper** |
| `TD_E_LOGS` | `rho_obs`, `rho_effect` | as `NTD`, with $`\hat\rho^{\times}_{cf}`$ | as `NTD`, with $`\psi_{\rho^{\times}_{cf}}`$ | Proportional app.; IF **not in the paper** |
| `TD_PR` | `gap_theta_pre` | $`\hat\theta_{pre}(f) - \hat\theta_{pre}(m)`$, $`\hat\theta_{pre}(g) = \dfrac{\mu_4 - \hat\delta^{\times}_{APO}(g)}{\mu_1}`$ | $`\psi_{\theta_{pre}(f)} - \psi_{\theta_{pre}(m)}`$, $`\psi_{\theta_{pre}(g)} = \dfrac{\psi_4 - \psi_{\delta^{\times}_{APO}(g)}}{\mu_1} - \dfrac{\theta_{pre}(g)\,\psi_1}{\mu_1}`$ | Proportional app.; IF **not in the paper** |
| `NTD`, `TD_E_LOGS` | `share_parenthood` | $`\hat s = \dfrac{\hat\rho_{cf} - \hat\rho_{obs}}{1 - \hat\rho_{obs}}`$ | $`\dfrac{\psi_{\rho_{cf}} - \psi_{\rho_{obs}}}{1 - \rho_{obs}} + \dfrac{(\rho_{cf} - \rho_{obs})\,\psi_{\rho_{obs}}}{(1 - \rho_{obs})^2}`$ | Sec. 4.2 (estimate); **not in the paper** (IF) |
| `NTD`, `TD_E_LOGS` | `share_other` | $`1 - \hat s`$ | $`-\psi_s`$ | **not in the paper** |

What each row identifies, and under which assumption, is in
[`?single_treatment_group_analysis`](https://dorleventer.github.io/childpen/reference/single_treatment_group_analysis.md)
(Details). For `TD_E_LOGS` the counterfactual ratio uses
$`\hat\delta^{\times}_{APO}`$; the `share_parenthood` row of `TD_E_LOGS`
uses $`\hat\rho^{\times}_{cf}`$ in place of $`\hat\rho_{cf}`$.

**Accounting (not in the paper).** The paper splits the observed gender
gap $`1 - \rho(d)`$ into parenthood, $`\rho(\infty) - \rho(d)`$, and
other factors, $`1 - \rho(\infty)`$, and reports parenthood’s share
(Section 4.2) as a point estimate. The package also reports its standard
error, from the influence function above. Derivation: write $`s = N/M`$
with $`N = \rho_{cf} - \rho_{obs}`$ and $`M = 1 - \rho_{obs}`$; then
$`\psi_s = \psi_N/M - N\psi_M/M^2`$, with $`\psi_N = \psi_{\rho_{cf}} -
\psi_{\rho_{obs}}`$ and $`\psi_M = -\psi_{\rho_{obs}}`$, which gives the
formula in the table.

## `bias_bounds()`

The bias-corrected conventional gap at an assumed fathers’ effect
$`\theta(m)`$ (Proposition 2, in the form of the Estimation appendix),
with $`\hat\Delta`$ the `NTD` `rho_effect` estimate:
``` math
\hat B(\theta(m)) = \hat\Delta\,\frac{\hat\delta_{APO}(m)}{\hat\delta_{APO}(f)}\,\big(1 + \theta(m)\big),
```
``` math
\psi_{B} = \big(1 + \theta(m)\big)\Big[\frac{\delta_{APO}(m)}{\delta_{APO}(f)}\psi_{\Delta}
 + \frac{\Delta}{\delta_{APO}(f)}\psi_{\delta_{APO}(m)}
 - \frac{\Delta\,\delta_{APO}(m)}{\delta_{APO}(f)^2}\psi_{\delta_{APO}(f)}\Big].
```
The estimator is in the paper; its influence function is **not in the
paper**. The standard error scales with $`1 + \theta(m)`$.

## `aggregate_estimands()`

For event time $`e`$, the treatment groups $`\mathcal D(e)`$ with an
estimate, group estimates $`B_d`$ and group shares $`p_d`$ (within
gender for `DID_Female` / `DID_Male`, across genders otherwise),
$`P_e = \sum_{d \in \mathcal D(e)} p_d`$ and $`w_d = p_d / P_e`$:

- `weighted_avg`: $`\hat A(e) = \sum_d w_d \hat B_d`$, with (Estimation
  appendix, aggregate estimator)
  ``` math
  \psi_{A(e)} = \frac{1}{P_e}\sum_{d \in \mathcal D(e)}\Big[(B_d - A(e))\,\psi_{p_d} + p_d\,\psi_{B_d}\Big],
  \qquad \psi_{p_d} = 1\{D = d\} - p_d
  ```
  ($`1\{G = g, D = d\} - p_{g,d}`$ for within-gender shares). With fixed
  or uniform weights the first term drops out. For `share_other` the
  influence function is minus that of `share_parenthood`.
- `ratio_of_avgs` (`DID_Female`, `DID_Male`):
  $`\hat\theta_{Agg,2} = \sum_d w_d \hat\delta_{ATE,d} \big/ \sum_d w_d \hat\delta_{APO,d}`$,
  with influence function $`\psi_{num}/den - num\,\psi_{den}/den^2`$,
  where $`\psi_{num} = \sum_d w_d \psi_{\delta_{ATE,d}}`$ and
  $`\psi_{den} = \sum_d w_d \psi_{\delta_{APO,d}}`$; the weights are
  treated as fixed.

Group influence functions are summed per person across treatment groups
before squaring, so the standard errors account for persons who are
controls for several treatment groups.

## Where this lives in the code

| quantity | code |
|----|----|
| cell means and their IF; clustered variance | `R/utility.R`: `compute_mean_if()`, `se_cluster()` |
| all rows of the table above | `R/single_treatment_group_analysis.R` |
| aggregation | `R/aggregate_estimands.R` |
| bias-corrected gap | `R/bias_bounds.R` |

Standard errors checked against a person-level (cluster) bootstrap in
`tests/testthat/`: `TD_E_LOGS` and `TD_PR` `rho_effect` /
`gap_theta_pre`, `NTD` `share_parenthood`, and
[`bias_bounds()`](https://dorleventer.github.io/childpen/reference/bias_bounds.md).
`TD_E_LOGS` and `TD_PR` are also checked by Monte Carlo
(`dev/sims/td_sim_results.md` in the source repository).
