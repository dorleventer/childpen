# Monte Carlo validation of TD_E_LOGS and TD_PR

Branch `proportional-td` (package commit 243ff7d). Scripts: `dev/sims/td_sim_module.R`, `td_sim_run.R`, `td_sim_summary.R`; raw output `dev/sims/out/full_*.rds`.

## DGP and targets

Balanced panel, ages 20-33, first-birth groups D in 24..33; Y = c_g exp(s_D(a)) (1 + tau_g(a-D) 1{a>=D}) U with group-specific slopes (parallel trends fails in levels and logs of means, holds in proportional form since c_f = 0.8, c_m = 1), tau_f(e) = -0.35 + 0.02e, tau_m = -0.02, E[U] = 1; iid = iid lognormal noise (var 0.25), panel = person effect (var 0.15) + AR(1) rho 0.6 (var 0.10). Truths: TD_E_LOGS = c_f(1+tau_f)/(c_m(1+tau_m)) - c_f/c_m; TD_PR = (tau_f - tau_m) exp(s_d(a) - s_d(d-1)); both 0 pre-treatment. Targets (d, a, dp): d26_e0 (26,26,27), d26_e2 (26,28,29), d26_e4 (26,30,31), d30_e1 (30,31,32), d26_pre_e-3 (26,23,29, placebo). Clustered SE = package default (by person); unclustered SE = each person-age row its own cluster.

Replications: R = 1000 (n = 2000, 8000), 500 (n = 32000) per cell. Point estimates with clustered and row-level id coincide in every cell: TRUE.

## Summary table

bias = mean(est - truth); bias_z = bias / (sd_mc / sqrt(R)); ratio_* = mean SE / sd_mc; cover_* = coverage of est +- 1.96 SE.

| n | corr | target | method | R | truth | bias | bias_z | sd_mc | ratio_cluster | ratio_row | cover_cluster | cover_row |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
|  2000 | iid | d26_e0 | TD_E_LOGS | 1000 | -0.2694 | -3.107e-03 | -0.89 | 1.102e-01 | 1.013 | 1.013 | 0.948 | 0.947 |
|  2000 | iid | d26_e0 | TD_PR | 1000 | -0.3419 | 1.247e-03 | 0.28 | 1.419e-01 | 1.011 | 1.011 | 0.952 | 0.949 |
|  2000 | iid | d26_e2 | TD_E_LOGS | 1000 | -0.2367 | -7.129e-04 | -0.20 | 1.111e-01 | 1.013 | 1.013 | 0.947 | 0.949 |
|  2000 | iid | d26_e2 | TD_PR | 1000 | -0.3197 | 5.308e-03 | 1.07 | 1.564e-01 | 1.002 | 1.002 | 0.942 | 0.945 |
|  2000 | iid | d26_e4 | TD_E_LOGS | 1000 | -0.2041 | 1.521e-03 | 0.43 | 1.110e-01 | 1.016 | 1.015 | 0.956 | 0.955 |
|  2000 | iid | d26_e4 | TD_PR | 1000 | -0.2897 | 9.247e-03 | 1.70 | 1.719e-01 | 1.003 | 1.002 | 0.957 | 0.953 |
|  2000 | iid | d30_e1 | TD_E_LOGS | 1000 | -0.2531 | 3.494e-03 | 0.98 | 1.131e-01 | 0.990 | 0.990 | 0.944 | 0.942 |
|  2000 | iid | d30_e1 | TD_PR | 1000 | -0.3345 | 1.226e-02 | 2.51 | 1.541e-01 | 0.981 | 0.980 | 0.945 | 0.944 |
|  2000 | iid | d26_pre_e-3 | TD_E_LOGS | 1000 | 0.0000 | 1.132e-03 | 0.30 | 1.176e-01 | 1.021 | 1.020 | 0.958 | 0.959 |
|  2000 | iid | d26_pre_e-3 | TD_PR | 1000 | 0.0000 | 5.429e-03 | 1.28 | 1.343e-01 | 1.023 | 1.022 | 0.960 | 0.958 |
|  8000 | iid | d26_e0 | TD_E_LOGS | 1000 | -0.2694 | -2.238e-03 | -1.23 | 5.756e-02 | 0.973 | 0.973 | 0.942 | 0.943 |
|  8000 | iid | d26_e0 | TD_PR | 1000 | -0.3419 | -1.431e-03 | -0.62 | 7.351e-02 | 0.980 | 0.980 | 0.945 | 0.945 |
|  8000 | iid | d26_e2 | TD_E_LOGS | 1000 | -0.2367 | 3.221e-04 | 0.18 | 5.691e-02 | 0.988 | 0.988 | 0.949 | 0.949 |
|  8000 | iid | d26_e2 | TD_PR | 1000 | -0.3197 | 1.901e-03 | 0.76 | 7.952e-02 | 0.988 | 0.988 | 0.950 | 0.952 |
|  8000 | iid | d26_e4 | TD_E_LOGS | 1000 | -0.2041 | -2.682e-04 | -0.15 | 5.632e-02 | 1.011 | 1.011 | 0.960 | 0.962 |
|  8000 | iid | d26_e4 | TD_PR | 1000 | -0.2897 | 1.120e-03 | 0.41 | 8.569e-02 | 1.012 | 1.012 | 0.958 | 0.958 |
|  8000 | iid | d30_e1 | TD_E_LOGS | 1000 | -0.2531 | -1.580e-03 | -0.87 | 5.769e-02 | 0.974 | 0.974 | 0.946 | 0.947 |
|  8000 | iid | d30_e1 | TD_PR | 1000 | -0.3345 | -6.069e-04 | -0.25 | 7.776e-02 | 0.974 | 0.975 | 0.944 | 0.945 |
|  8000 | iid | d26_pre_e-3 | TD_E_LOGS | 1000 | 0.0000 | 1.811e-03 | 0.94 | 6.114e-02 | 0.985 | 0.984 | 0.942 | 0.945 |
|  8000 | iid | d26_pre_e-3 | TD_PR | 1000 | 0.0000 | 3.534e-03 | 1.60 | 6.979e-02 | 0.983 | 0.983 | 0.940 | 0.940 |
| 32000 | iid | d26_e0 | TD_E_LOGS |  500 | -0.2694 | -2.021e-04 | -0.16 | 2.888e-02 | 0.969 | 0.968 | 0.952 | 0.952 |
| 32000 | iid | d26_e0 | TD_PR |  500 | -0.3419 | 2.963e-04 | 0.18 | 3.687e-02 | 0.976 | 0.976 | 0.952 | 0.954 |
| 32000 | iid | d26_e2 | TD_E_LOGS |  500 | -0.2367 | -3.493e-04 | -0.28 | 2.816e-02 | 1.002 | 1.002 | 0.930 | 0.932 |
| 32000 | iid | d26_e2 | TD_PR |  500 | -0.3197 | -1.713e-04 | -0.10 | 3.948e-02 | 0.997 | 0.997 | 0.938 | 0.938 |
| 32000 | iid | d26_e4 | TD_E_LOGS |  500 | -0.2041 | 4.612e-04 | 0.34 | 3.025e-02 | 0.938 | 0.939 | 0.920 | 0.920 |
| 32000 | iid | d26_e4 | TD_PR |  500 | -0.2897 | 9.975e-04 | 0.49 | 4.581e-02 | 0.946 | 0.946 | 0.928 | 0.928 |
| 32000 | iid | d30_e1 | TD_E_LOGS |  500 | -0.2531 | 1.334e-03 | 1.03 | 2.909e-02 | 0.962 | 0.962 | 0.944 | 0.942 |
| 32000 | iid | d30_e1 | TD_PR |  500 | -0.3345 | 1.521e-03 | 0.86 | 3.961e-02 | 0.955 | 0.955 | 0.942 | 0.944 |
| 32000 | iid | d26_pre_e-3 | TD_E_LOGS |  500 | 0.0000 | 1.381e-03 | 0.99 | 3.123e-02 | 0.966 | 0.965 | 0.940 | 0.940 |
| 32000 | iid | d26_pre_e-3 | TD_PR |  500 | 0.0000 | 1.935e-03 | 1.22 | 3.559e-02 | 0.967 | 0.966 | 0.942 | 0.940 |
|  2000 | panel | d26_e0 | TD_E_LOGS | 1000 | -0.2694 | -9.147e-04 | -0.57 | 5.110e-02 | 0.981 | 2.176 | 0.946 | 1.000 |
|  2000 | panel | d26_e0 | TD_PR | 1000 | -0.3419 | 3.567e-04 | 0.19 | 6.055e-02 | 0.990 | 2.359 | 0.940 | 1.000 |
|  2000 | panel | d26_e2 | TD_E_LOGS | 1000 | -0.2367 | -3.794e-03 | -1.76 | 6.819e-02 | 0.984 | 1.647 | 0.947 | 0.999 |
|  2000 | panel | d26_e2 | TD_PR | 1000 | -0.3197 | -3.618e-03 | -1.25 | 9.174e-02 | 0.992 | 1.704 | 0.948 | 1.000 |
|  2000 | panel | d26_e4 | TD_E_LOGS | 1000 | -0.2041 | -1.829e-03 | -0.79 | 7.315e-02 | 0.990 | 1.551 | 0.942 | 0.998 |
|  2000 | panel | d26_e4 | TD_PR | 1000 | -0.2897 | 1.402e-04 | 0.04 | 1.105e-01 | 0.982 | 1.561 | 0.943 | 0.995 |
|  2000 | panel | d30_e1 | TD_E_LOGS | 1000 | -0.2531 | -5.598e-03 | -2.81 | 6.309e-02 | 0.979 | 1.782 | 0.954 | 0.999 |
|  2000 | panel | d30_e1 | TD_PR | 1000 | -0.3345 | -6.319e-03 | -2.46 | 8.116e-02 | 0.986 | 1.865 | 0.958 | 1.000 |
|  2000 | panel | d26_pre_e-3 | TD_E_LOGS | 1000 | 0.0000 | -2.351e-03 | -1.18 | 6.323e-02 | 1.006 | 1.900 | 0.956 | 1.000 |
|  2000 | panel | d26_pre_e-3 | TD_PR | 1000 | 0.0000 | -9.746e-04 | -0.43 | 7.162e-02 | 1.008 | 1.906 | 0.954 | 1.000 |
|  8000 | panel | d26_e0 | TD_E_LOGS | 1000 | -0.2694 | -1.239e-03 | -1.50 | 2.617e-02 | 0.966 | 2.135 | 0.948 | 0.999 |
|  8000 | panel | d26_e0 | TD_PR | 1000 | -0.3419 | -6.271e-04 | -0.65 | 3.073e-02 | 0.983 | 2.336 | 0.945 | 1.000 |
|  8000 | panel | d26_e2 | TD_E_LOGS | 1000 | -0.2367 | -2.918e-03 | -2.64 | 3.495e-02 | 0.966 | 1.617 | 0.945 | 0.999 |
|  8000 | panel | d26_e2 | TD_PR | 1000 | -0.3197 | -2.734e-03 | -1.84 | 4.691e-02 | 0.977 | 1.675 | 0.941 | 0.999 |
|  8000 | panel | d26_e4 | TD_E_LOGS | 1000 | -0.2041 | -1.341e-03 | -1.17 | 3.621e-02 | 1.004 | 1.569 | 0.948 | 0.998 |
|  8000 | panel | d26_e4 | TD_PR | 1000 | -0.2897 | -7.131e-04 | -0.42 | 5.360e-02 | 1.018 | 1.614 | 0.951 | 1.000 |
|  8000 | panel | d30_e1 | TD_E_LOGS | 1000 | -0.2531 | -1.791e-03 | -1.79 | 3.164e-02 | 0.976 | 1.778 | 0.951 | 0.999 |
|  8000 | panel | d30_e1 | TD_PR | 1000 | -0.3345 | -1.370e-03 | -1.05 | 4.111e-02 | 0.976 | 1.844 | 0.953 | 1.000 |
|  8000 | panel | d26_pre_e-3 | TD_E_LOGS | 1000 | 0.0000 | -1.007e-03 | -0.99 | 3.218e-02 | 0.994 | 1.877 | 0.950 | 1.000 |
|  8000 | panel | d26_pre_e-3 | TD_PR | 1000 | 0.0000 | -7.005e-04 | -0.61 | 3.661e-02 | 0.993 | 1.877 | 0.947 | 1.000 |
| 32000 | panel | d26_e0 | TD_E_LOGS |  500 | -0.2694 | -5.197e-05 | -0.09 | 1.238e-02 | 1.021 | 2.263 | 0.954 | 1.000 |
| 32000 | panel | d26_e0 | TD_PR |  500 | -0.3419 | 3.219e-04 | 0.49 | 1.483e-02 | 1.022 | 2.430 | 0.954 | 1.000 |
| 32000 | panel | d26_e2 | TD_E_LOGS |  500 | -0.2367 | -5.457e-04 | -0.76 | 1.612e-02 | 1.045 | 1.750 | 0.960 | 1.000 |
| 32000 | panel | d26_e2 | TD_PR |  500 | -0.3197 | -4.833e-04 | -0.48 | 2.254e-02 | 1.018 | 1.744 | 0.950 | 0.998 |
| 32000 | panel | d26_e4 | TD_E_LOGS |  500 | -0.2041 | -1.398e-03 | -1.72 | 1.814e-02 | 1.003 | 1.569 | 0.958 | 1.000 |
| 32000 | panel | d26_e4 | TD_PR |  500 | -0.2897 | -1.773e-03 | -1.44 | 2.754e-02 | 0.992 | 1.573 | 0.958 | 0.998 |
| 32000 | panel | d30_e1 | TD_E_LOGS |  500 | -0.2531 | -2.265e-04 | -0.32 | 1.584e-02 | 0.974 | 1.774 | 0.952 | 1.000 |
| 32000 | panel | d30_e1 | TD_PR |  500 | -0.3345 | 4.550e-05 | 0.05 | 2.085e-02 | 0.962 | 1.818 | 0.956 | 1.000 |
| 32000 | panel | d26_pre_e-3 | TD_E_LOGS |  500 | 0.0000 | 2.128e-04 | 0.29 | 1.634e-02 | 0.978 | 1.846 | 0.938 | 1.000 |
| 32000 | panel | d26_pre_e-3 | TD_PR |  500 | 0.0000 | 3.280e-04 | 0.39 | 1.862e-02 | 0.978 | 1.845 | 0.938 | 1.000 |

## Verdict against pre-registered criteria

### (a) clustered SE / MC sd in [0.90, 1.10]

60 of 60 cells pass. Range of ratio_cluster: 0.938 to 1.045.
All cells pass.

### (b) clustered coverage within 0.95 +/- 2 sqrt(0.95*0.05/R)

Tolerance: +/- 0.0138 (R = 1000), +/- 0.0195 (R = 500). 57 of 60 cells pass. Range of cover_cluster: 0.920 to 0.960.

Failing cells:

- n=32000 iid d26_e2 TD_E_LOGS: cover_cluster = 0.930 (tolerance +/- 0.0195)
- n=32000 iid d26_e4 TD_E_LOGS: cover_cluster = 0.920 (tolerance +/- 0.0195)
- n=32000 iid d26_e4 TD_PR: cover_cluster = 0.928 (tolerance +/- 0.0195)

### (c) |bias| shrinks with n; |bias_z| < 2.5 at n = 32000

Per target x method x corr (strict: |bias| at 2000 > 8000 > 32000).

| corr | target | method | abs_bias_2000 | abs_bias_8000 | abs_bias_32000 | z_2000 | z_8000 | z_32000 | shrinks | abs_z32_lt_2.5 |
|---|---|---|---|---|---|---|---|---|---|---|
| iid | d26_e0 | TD_E_LOGS | 3.11e-03 | 2.24e-03 | 2.02e-04 | -0.89 | -1.23 | -0.16 | TRUE | TRUE |
| panel | d26_e0 | TD_E_LOGS | 9.15e-04 | 1.24e-03 | 5.20e-05 | -0.57 | -1.50 | -0.09 | FALSE | TRUE |
| iid | d26_e2 | TD_E_LOGS | 7.13e-04 | 3.22e-04 | 3.49e-04 | -0.20 | 0.18 | -0.28 | FALSE | TRUE |
| panel | d26_e2 | TD_E_LOGS | 3.79e-03 | 2.92e-03 | 5.46e-04 | -1.76 | -2.64 | -0.76 | TRUE | TRUE |
| iid | d26_e4 | TD_E_LOGS | 1.52e-03 | 2.68e-04 | 4.61e-04 | 0.43 | -0.15 | 0.34 | FALSE | TRUE |
| panel | d26_e4 | TD_E_LOGS | 1.83e-03 | 1.34e-03 | 1.40e-03 | -0.79 | -1.17 | -1.72 | FALSE | TRUE |
| iid | d26_pre_e-3 | TD_E_LOGS | 1.13e-03 | 1.81e-03 | 1.38e-03 | 0.30 | 0.94 | 0.99 | FALSE | TRUE |
| panel | d26_pre_e-3 | TD_E_LOGS | 2.35e-03 | 1.01e-03 | 2.13e-04 | -1.18 | -0.99 | 0.29 | TRUE | TRUE |
| iid | d30_e1 | TD_E_LOGS | 3.49e-03 | 1.58e-03 | 1.33e-03 | 0.98 | -0.87 | 1.03 | TRUE | TRUE |
| panel | d30_e1 | TD_E_LOGS | 5.60e-03 | 1.79e-03 | 2.27e-04 | -2.81 | -1.79 | -0.32 | TRUE | TRUE |
| iid | d26_e0 | TD_PR | 1.25e-03 | 1.43e-03 | 2.96e-04 | 0.28 | -0.62 | 0.18 | FALSE | TRUE |
| panel | d26_e0 | TD_PR | 3.57e-04 | 6.27e-04 | 3.22e-04 | 0.19 | -0.65 | 0.49 | FALSE | TRUE |
| iid | d26_e2 | TD_PR | 5.31e-03 | 1.90e-03 | 1.71e-04 | 1.07 | 0.76 | -0.10 | TRUE | TRUE |
| panel | d26_e2 | TD_PR | 3.62e-03 | 2.73e-03 | 4.83e-04 | -1.25 | -1.84 | -0.48 | TRUE | TRUE |
| iid | d26_e4 | TD_PR | 9.25e-03 | 1.12e-03 | 9.97e-04 | 1.70 | 0.41 | 0.49 | TRUE | TRUE |
| panel | d26_e4 | TD_PR | 1.40e-04 | 7.13e-04 | 1.77e-03 | 0.04 | -0.42 | -1.44 | FALSE | TRUE |
| iid | d26_pre_e-3 | TD_PR | 5.43e-03 | 3.53e-03 | 1.93e-03 | 1.28 | 1.60 | 1.22 | TRUE | TRUE |
| panel | d26_pre_e-3 | TD_PR | 9.75e-04 | 7.01e-04 | 3.28e-04 | -0.43 | -0.61 | 0.39 | TRUE | TRUE |
| iid | d30_e1 | TD_PR | 1.23e-02 | 6.07e-04 | 1.52e-03 | 2.51 | -0.25 | 0.86 | FALSE | TRUE |
| panel | d30_e1 | TD_PR | 6.32e-03 | 1.37e-03 | 4.55e-05 | -2.46 | -1.05 | 0.05 | TRUE | TRUE |

11 of 20 target x method x corr groups pass both parts (shrinks: 11; |bias_z| < 2.5 at 32000: 20).

Failing groups:

- panel d26_e0 TD_E_LOGS: |bias| = 9.147e-04 / 1.239e-03 / 5.197e-05 (n = 2000 / 8000 / 32000), bias_z = -0.57 / -1.50 / -0.09; shrinks = FALSE, |z32| < 2.5 = TRUE
- iid d26_e2 TD_E_LOGS: |bias| = 7.129e-04 / 3.221e-04 / 3.493e-04 (n = 2000 / 8000 / 32000), bias_z = -0.20 / 0.18 / -0.28; shrinks = FALSE, |z32| < 2.5 = TRUE
- iid d26_e4 TD_E_LOGS: |bias| = 1.521e-03 / 2.682e-04 / 4.612e-04 (n = 2000 / 8000 / 32000), bias_z = 0.43 / -0.15 / 0.34; shrinks = FALSE, |z32| < 2.5 = TRUE
- panel d26_e4 TD_E_LOGS: |bias| = 1.829e-03 / 1.341e-03 / 1.398e-03 (n = 2000 / 8000 / 32000), bias_z = -0.79 / -1.17 / -1.72; shrinks = FALSE, |z32| < 2.5 = TRUE
- iid d26_pre_e-3 TD_E_LOGS: |bias| = 1.132e-03 / 1.811e-03 / 1.381e-03 (n = 2000 / 8000 / 32000), bias_z = 0.30 / 0.94 / 0.99; shrinks = FALSE, |z32| < 2.5 = TRUE
- iid d26_e0 TD_PR: |bias| = 1.247e-03 / 1.431e-03 / 2.963e-04 (n = 2000 / 8000 / 32000), bias_z = 0.28 / -0.62 / 0.18; shrinks = FALSE, |z32| < 2.5 = TRUE
- panel d26_e0 TD_PR: |bias| = 3.567e-04 / 6.271e-04 / 3.219e-04 (n = 2000 / 8000 / 32000), bias_z = 0.19 / -0.65 / 0.49; shrinks = FALSE, |z32| < 2.5 = TRUE
- panel d26_e4 TD_PR: |bias| = 1.402e-04 / 7.131e-04 / 1.773e-03 (n = 2000 / 8000 / 32000), bias_z = 0.04 / -0.42 / -1.44; shrinks = FALSE, |z32| < 2.5 = TRUE
- iid d30_e1 TD_PR: |bias| = 1.226e-02 / 6.069e-04 / 1.521e-03 (n = 2000 / 8000 / 32000), bias_z = 2.51 / -0.25 / 0.86; shrinks = FALSE, |z32| < 2.5 = TRUE

### (d) unclustered vs clustered SE

**iid** (|ratio_row - ratio_cluster| <= 0.05): 30 of 30 cells pass; largest gap 0.001.


**panel** (report direction): ratio_row ranges 1.551 to 2.430 (ratio_cluster 0.962 to 1.045); ratio_row > ratio_cluster in 30 of 30 cells, so unclustered SEs are too LARGE (conservative). ratio_row / ratio_cluster: 1.56 to 2.38.
Unclustered coverage (panel): 0.995 to 1.000.

### Overall

(a) PASS; (b) FAIL (3 cells); (c) FAIL (9 groups); (d) iid PASS. **Overall: FAIL.**

## Run details

Six runs, `mclapply` with 4 cores each, two chains in parallel (iid and panel). Wall time per run (s): iid 166 / 463 / 837 and panel 154 / 459 / 836 for n = 2000 / 8000 / 32000; total wall time about 24.7 min (12:57:49 to 13:22:28 BST, 2026-10-21). No failed replications (10000, 10000, 5000 rows per corr = R x 5 targets x 2 methods). `est_equal` is TRUE in all 60 cells.

## Context for the failures (not part of the pre-registered verdict; the FAILs above stand)

Computed from the same `.rds` files, using the MC standard errors.

- **(b)** The three failing cells are all at n = 32000, iid (R = 500, tolerance +/- 0.0195): d26_e2 TD_E_LOGS 0.930, d26_e4 TD_E_LOGS 0.920, d26_e4 TD_PR 0.928. Their ratio_cluster is 1.002, 0.938, 0.946, i.e. the d26_e4 SEs are about 5-6% low, inside criterion (a). With 60 cells and a 2-sigma tolerance, 2.7 failures are expected if coverage were exactly 0.95 in every cell (cells share replications, so they are not independent). Coverage at n = 2000 and 8000 (R = 1000) is 0.940-0.960 in all 40 iid and panel cells, and the same two d26 targets are fine at the smaller n.
- **(c) strict shrinkage** fails in 9 of 20 groups. If the estimators were exactly unbiased, the strict ordering |bias_2000| > |bias_8000| > |bias_32000| would hold in only 37% of groups (7.3 of 20 expected, simulated with the observed MC standard errors), because at small bias the ordering is decided by MC noise. 11 of 20 pass. In all 9 failing groups |bias_z| at n = 32000 is below 2 (max 1.72).
- **(c) |bias_z| < 2.5 at n = 32000** passes in all 20 groups (largest |bias_z|: 1.72, panel d26_e4 TD_E_LOGS).
- **Pattern worth a look, not significant in any single cell at n = 32000:** panel TD_E_LOGS has a small negative bias in several targets. Inverse-variance pooling across the three n gives -0.0014 (z = -2.5) for d26_e2, -0.0014 (z = -2.2) for d26_e4 and -0.0011 (z = -2.0) for d30_e1; panel d26_e4 has |bias_z| rising with n (-0.79, -1.17, -1.72 for TD_E_LOGS; 0.04, -0.42, -1.44 for TD_PR). If the bias were O(1/n) it would be about a quarter as large at 32000 as at 8000, which holds for d26_e2 and d30_e1 but not for d26_e4. Magnitude is about 0.5-0.7% of the estimand (-0.20 to -0.25) and 0.08 sd at n = 32000. Four of 20 groups have |pooled z| > 2 (about 1 expected under zero bias, but TD_E_LOGS and TD_PR share draws and targets share replications, so the groups are correlated). The largest iid pooled z is 2.2 (d26_pre_e-3 TD_PR, +0.0027). A larger run (more reps at n = 32000, e.g. 2000) would settle whether the d26_e4 panel bias vanishes.
- **(d)** iid: ratio_row equals ratio_cluster to within 0.001 in all 30 cells. Panel: unclustered SEs are 1.56-2.38 times the clustered SE (ratio_row 1.55-2.43 against ratio_cluster 0.96-1.05) and unclustered coverage is 0.995-1.000, so unclustered SEs are conservative; clustering by person is what makes the SEs right.

## Follow-up (added after the verdict above; not pre-registered)

**(b) recheck.** The three coverage failures all sit in one batch (n = 32000, iid; the same 500
datasets), where targets d26_e2 and d26_e4 share data and the two methods are highly correlated.
The batch was re-run with 1000 fresh replications (`td_sim_run.R 32000 iid 1000 ... 8 500000`,
`dev/sims/out/recheck_iid_32000.rds`). Decision rule fixed before the re-run: coverage within
0.95 +/- 0.0138 and ratio_cluster in [0.90, 1.10] in every cell.

| target | method | ratio_cluster | cover_cluster | bias_z |
|---|---|---|---|---|
| d26_e0 | TD_E_LOGS | 0.982 | 0.940 | -0.40 |
| d26_e0 | TD_PR | 0.990 | 0.941 | -0.20 |
| d26_e2 | TD_E_LOGS | 0.984 | 0.951 | 0.24 |
| d26_e2 | TD_PR | 0.986 | 0.950 | 0.49 |
| d26_e4 | TD_E_LOGS | 1.002 | 0.956 | -1.01 |
| d26_e4 | TD_PR | 1.003 | 0.954 | -0.79 |
| d26_pre_e-3 | TD_E_LOGS | 0.973 | 0.948 | 0.17 |
| d26_pre_e-3 | TD_PR | 0.973 | 0.949 | 0.49 |
| d30_e1 | TD_E_LOGS | 1.002 | 0.947 | 1.05 |
| d30_e1 | TD_PR | 1.006 | 0.951 | 1.46 |

All 10 cells pass, including the three that failed (0.951, 0.956, 0.954). The original failures
are consistent with Monte Carlo noise in one batch.

**(c) criterion design.** "|bias| shrinks strictly with n" is not a valid test when the bias is
zero up to Monte Carlo noise: the estimated |bias| is then noise and need not fall. All nine
failing groups have |bias_z| < 2.6 at every n and |bias| <= 0.0018 at n = 32000. The second part
of (c), |bias_z| < 2.5 at n = 32000, passes in all 20 groups (max 1.72), and again in the
recheck (max 1.46).

**Reading.** Clustered SEs track the Monte Carlo sd (0.94-1.05; recheck 0.97-1.01) with coverage
at the nominal level; no detectable bias at n = 32000; unclustered SEs are too large under
within-person correlation (1.56-2.38x) and equal to the clustered ones without it.
