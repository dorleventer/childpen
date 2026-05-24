# validation_tests

> **Notation.** For symbol definitions, see the [notation
> vignette](https://dorleventer.github.io/childpen/articles/notation.md).

## Overview

The aim of this vignette is show how to perform correct validation tests
using closest-not-yet-treated control groups using `childpen`.

## Simulate data

The package has a built in simulation function to draw data resembling
child penalty studies.

``` r

library(childpen)

data <- simulate_data(n_individuals = 5000, treatment_groups = 25:26)
data |> tibble()
#> # A tibble: 105,000 × 6
#>       id female   age     D   Y_inf       Y
#>    <int>  <int> <int> <int>   <dbl>   <dbl>
#>  1     1      1    20    25  18881.  18881.
#>  2     1      1    21    25  20391.  20391.
#>  3     1      1    22    25  12439.  12439.
#>  4     1      1    23    25  52948.  52948.
#>  5     1      1    24    25 157316. 157316.
#>  6     1      1    25    25  49891.  51434.
#>  7     1      1    26    25  79663.  83720.
#>  8     1      1    27    25 170407. 182494.
#>  9     1      1    28    25 266446. 290674.
#> 10     1      1    29    25  89351.  99262.
#> # ℹ 104,990 more rows
```

## The correct validation tests

See the [estimation
vignette](https://dorleventer.github.io/childpen/articles/estimation.md)
for an explainer on the $`2\times2`$ comparisons in `childpen`. Recall
that $`d`$ is the treatment group, $`a`$ is the target age, and
$`d^\prime=a+1`$ is the closest not-yet-treated control group. Recall
that the control group is $`d' = a + 1`$, the cohort whose first birth
is one year after the target age.

Assume that when presenting results, post-treatment, you report
estimates for event times $`e=0,...,3`$. Then, for each treatment group
$`d`$ you use 4 different control groups in post-treatment estimation.
As the identification assumptions (e.g., parallel trends for DID) must
hold for each point-estimate separately, this implies that it must hold
within each treatment-control pair.

The above argument means that the validation tests should be done
separately by treatment-control combinations. Returning to the above
example, if you want to show results for $`e=0,...,3`$ then you need to
conduct pre-trend analysis for 4 different control groups. This is done
automatically in the `childpen` package, as we show below.

For completeness, the validation tests are:

1.  Difference-in-differences (DID) estimates the average treatment
    effect (ATE) in pre-periods
2.  Triple differences (TD) estimates the gender gap in the ATE in
    pre-periods
3.  Normalized triple differences (NTD) estimates the gender gap in
    normalized effects in pre-periods

## Multiple treatment group analysis

We will now do the main heavy lifting. We run the main estimation
function,
[`multiple_treatment_group_analysis()`](https://dorleventer.github.io/childpen/reference/multiple_treatment_group_analysis.md).
Set `periods_pre` to the number of pre-treatment periods for which you
want to conduct validation tests. As an example, we will examine three
periods pre-treatment. Since we set the number of periods in the
post-treatment to 3 using `periods_post`, this will report validation
tests separately for 4 control groups, as discussed above.

``` r

res = multiple_treatment_group_analysis(data = data,
                                  treatment_groups = 25:26, # which treatment groups to run in the analysis
                                  periods_post = 3, # estimate results for post periods 0:3
                                  periods_pre = 3, # estimate pre-trend diagnostics, set to NULL to omit from estimation
                                  max_age = 40, # dont estimate results if age is above 40
                                  min_age = 20, # dont estimate results if age is below 20
                                  pre = 1, # use 1 period before treatment, can make further away if anticipation is conern
                                  verbose = FALSE # set to TRUE to output progress (i like to time loops) set to FALSE to omit messages
                                  ) 
#>   Error for d=25, event_time=1: Empty subgroup: age=26, female=1, D=27
#>   Error for d=25, event_time=2: Empty subgroup: age=27, female=1, D=28
#>   Error for d=25, event_time=3: Empty subgroup: age=28, female=1, D=29
#>   Error for d=26, event_time=0: Empty subgroup: age=26, female=1, D=27
#>   Error for d=26, event_time=1: Empty subgroup: age=27, female=1, D=28
#>   Error for d=26, event_time=2: Empty subgroup: age=28, female=1, D=29
#>   Error for d=26, event_time=3: Empty subgroup: age=29, female=1, D=30
#>   Error for d=25, event_time=-4, dp=27: Empty subgroup: age=21, female=1, D=27
#>   Error for d=25, event_time=-4, dp=28: Empty subgroup: age=21, female=1, D=28
#>   Error for d=25, event_time=-4, dp=29: Empty subgroup: age=21, female=1, D=29
#>   Error for d=25, event_time=-3, dp=27: Empty subgroup: age=22, female=1, D=27
#>   Error for d=25, event_time=-3, dp=28: Empty subgroup: age=22, female=1, D=28
#>   Error for d=25, event_time=-3, dp=29: Empty subgroup: age=22, female=1, D=29
#>   Error for d=25, event_time=-2, dp=27: Empty subgroup: age=23, female=1, D=27
#>   Error for d=25, event_time=-2, dp=28: Empty subgroup: age=23, female=1, D=28
#>   Error for d=25, event_time=-2, dp=29: Empty subgroup: age=23, female=1, D=29
#>   Error for d=26, event_time=-4, dp=27: Empty subgroup: age=22, female=1, D=27
#>   Error for d=26, event_time=-4, dp=28: Empty subgroup: age=22, female=1, D=28
#>   Error for d=26, event_time=-4, dp=29: Empty subgroup: age=22, female=1, D=29
#>   Error for d=26, event_time=-4, dp=30: Empty subgroup: age=22, female=1, D=30
#>   Error for d=26, event_time=-3, dp=27: Empty subgroup: age=23, female=1, D=27
#>   Error for d=26, event_time=-3, dp=28: Empty subgroup: age=23, female=1, D=28
#>   Error for d=26, event_time=-3, dp=29: Empty subgroup: age=23, female=1, D=29
#>   Error for d=26, event_time=-3, dp=30: Empty subgroup: age=23, female=1, D=30
#>   Error for d=26, event_time=-2, dp=27: Empty subgroup: age=24, female=1, D=27
#>   Error for d=26, event_time=-2, dp=28: Empty subgroup: age=24, female=1, D=28
#>   Error for d=26, event_time=-2, dp=29: Empty subgroup: age=24, female=1, D=29
#>   Error for d=26, event_time=-2, dp=30: Empty subgroup: age=24, female=1, D=30
```

## Examining results of validation tests

As a first pass, lets see the results.

``` r

res |> tibble()
#> # A tibble: 60 × 16
#>        d    dp     a event_time estimand  method            est      se     ci_l
#>    <int> <dbl> <int>      <int> <chr>     <chr>           <dbl>   <dbl>    <dbl>
#>  1    25    26    25          0 APO       DID_Female    7.46e+4 2.29e+3  7.01e+4
#>  2    25    26    25          0 APO       DID_Male      6.78e+4 2.04e+3  6.38e+4
#>  3    25    26    25          0 ATE       DID_Female   -2.20e+4 2.30e+3 -2.65e+4
#>  4    25    26    25          0 ATE       DID_Male      3.75e+3 2.34e+3 -8.41e+2
#>  5    25    26    25          0 theta     DID_Female   -2.95e-1 2.44e-2 -3.43e-1
#>  6    25    26    25          0 theta     DID_Male      5.52e-2 3.56e-2 -1.45e-2
#>  7    25    26    25          0 ATE       TD           -2.58e+4 3.28e+3 -3.22e+4
#>  8    25    26    25          0 theta     NTD_Conv     -3.50e-1 4.32e-2 -4.35e-1
#>  9    25    26    25          0 Delta_rho NTD_New      -3.65e-1 4.70e-2 -4.58e-1
#> 10    25    26    25          0 APO       TD_Null       7.84e+4 3.27e+3  7.19e+4
#> # ℹ 50 more rows
#> # ℹ 7 more variables: ci_h <dbl>, t <dbl>, p <dbl>, n_female_treat <int>,
#> #   n_female_control <int>, n_male_treat <int>, n_male_control <int>
```

Focusing on $`d=25`$, lets examine pre-trends. We will start with DID of
females. Generally, valid pre-trend validation tests would behave such
that the confidence intervals include 0, and there is no obvious trend
in the pre-period, and there is no systematic difference between control
groups. A valid pre-trend test shows point estimates near zero with
confidence intervals covering zero and no systematic trend across
pre-treatment event times.

Note that in the plot below I define `control_offset` as the difference
between the control group $`d^\prime`$ and the treatment group $`d`$.
E.g., for $`d=25`$ and $`d^\prime=26`$, i.e., the closest
not-yet-treated control group at event time $`e=0`$, I set control
offset to 1.

Ribbons present 95% CI based on standard errors clustered at the
individual level.

``` r

res |> 
  filter(d == 25,
         a < d, 
         estimand == "ATE",
         method == "DID_Female") |> 
  mutate(control_offset = dp - d, 
         control_offset = factor(control_offset)) |> 
  ggplot(aes(x = event_time, y = est, ymin = ci_l, ymax = ci_h, color = control_offset, fill = control_offset)) +
  geom_ribbon(alpha = .15, color = NA) + geom_point() + geom_line() + 
  scale_x_continuous(breaks = -4:-2) + 
  facet_grid(cols = vars(control_offset))
```

![](validation_tests_files/figure-html/unnamed-chunk-1-1.png)

Although this would be hard to look at, we can put all control offsets
on same plot.

``` r

res |> 
  filter(d == 25,
         a < d, 
         estimand == "ATE",
         method == "DID_Female") |> 
  mutate(control_offset = dp - d, 
         control_offset = factor(control_offset)) |> 
  ggplot(aes(x = event_time, y = est, ymin = ci_l, ymax = ci_h, color = control_offset, fill = control_offset)) +
  geom_ribbon(alpha = .15, color = NA) + geom_point() + geom_line() + 
  scale_x_continuous(breaks = -4:-2)
```

![](validation_tests_files/figure-html/unnamed-chunk-2-1.png)

Can do this for multiple treatment groups at same time

``` r

res |> 
  filter(a < d, 
         estimand == "ATE",
         method == "DID_Female") |> 
  mutate(control_offset = dp - d, 
         control_offset = factor(control_offset)) |> 
  ggplot(aes(x = event_time, y = est, ymin = ci_l, ymax = ci_h, color = control_offset, fill = control_offset)) +
  geom_ribbon(alpha = .15, color = NA) + geom_point() + geom_line() + 
  scale_x_continuous(breaks = -4:-2) + 
  facet_grid(cols = vars(d))
```

![](validation_tests_files/figure-html/unnamed-chunk-3-1.png)

Finally, can do this for all methods.

``` r

res |> 
  filter(a < d, 
         estimand == "ATE" & (method == "DID_Female" | method == "DID_Male" | method == "TD") |
           estimand == "theta" & method == "NTD_Conv") |>
  mutate(control_offset = dp - d, 
         control_offset = factor(control_offset)) |> 
  ggplot(aes(x = event_time, y = est, ymin = ci_l, ymax = ci_h, color = control_offset, fill = control_offset)) +
  geom_ribbon(alpha = .15, color = NA) + geom_point() + geom_line() + 
  scale_x_continuous(breaks = -4:-2) + 
  facet_grid(cols = vars(d), rows = vars(method), scales = "free")
```

![](validation_tests_files/figure-html/unnamed-chunk-4-1.png)
