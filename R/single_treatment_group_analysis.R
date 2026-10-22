#' Child-penalty estimates for one 2x2 comparison
#'
#' For one treatment group \eqn{d} (age at first birth), control group \eqn{d'}
#' and target age \eqn{a}, estimates the descriptive estimands of Leventer (2025):
#' within-gender DID, the gender gaps under TD, the conventional estimator, the
#' effect of parenthood on the gender earnings ratio (NTD and proportional TD),
#' and the accounting of the gender gap. Returns 19 rows with standard errors
#' clustered by person.
#'
#' @param data A data.frame (or data.table) in long format: one row per person
#'   and age, with the person id, age, age at first birth, a female indicator and
#'   earnings. The panel need not be balanced. Each person's female indicator and
#'   age at first birth must be constant; a missing age at first birth means the
#'   person never has a child. Rows with missing earnings are dropped (with a
#'   message). Earnings may be zero, but the ratio rows need positive cell means.
#'   \code{data} is not modified.
#' @param d Whole number. Treatment group: age at first birth.
#' @param dp Whole number. Control group \eqn{d'}: an age at first birth that is
#'   not yet treated at the target age, \code{dp > a} (and \code{dp > d}). The
#'   paper uses the closest not-yet-treated group, \code{dp = a + 1} (Section
#'   1.3), as \code{\link{multiple_treatment_group_analysis}} does.
#' @param a Whole number. Target age; event time is \eqn{e = a - d}. With
#'   \code{a >= d} the rows are post-birth estimates; with \code{a < d - pre} they
#'   are pre-treatment validation (placebo) estimates (Sections 2.3, 4.2).
#' @param pre Whole number \eqn{\ge 1} (default 1). The baseline age is
#'   \eqn{d - pre}. The default, \eqn{d - 1}, is the paper's choice; larger values
#'   move the baseline earlier in case earnings at \eqn{d - 1} reflect
#'   anticipation (Section 3.1).
#' @param Y_name,age_name,D_name,id_name,female_name Names of the columns holding
#'   earnings, age, age at first birth, the person id (clustering unit) and the
#'   female indicator (1 / \code{TRUE} = female; also accepted: labels such as
#'   "female"/"male", "f"/"m", "woman"/"man"; any other label is an error).
#'
#' @details
#' Let \eqn{\mu(g, k, t)} be the mean earnings of gender \eqn{g \in \{f, m\}}
#' with age at first birth \eqn{k} at age \eqn{t}, estimated by the cell mean,
#' and \eqn{b = d - pre} the baseline age. The additive (DID) and multiplicative
#' imputations of counterfactual earnings at age \eqn{a} are
#' \deqn{\delta_{APO}(g) = \mu(g,d,b) + \mu(g,d',a) - \mu(g,d',b), \qquad
#'   \delta^{\times}_{APO}(g) = \mu(g,d,b)\,\mu(g,d',a) / \mu(g,d',b).}{
#'   delta_APO(g) = mu(g,d,b) + mu(g,d',a) - mu(g,d',b),
#'   delta_APO_x(g) = mu(g,d,b) mu(g,d',a) / mu(g,d',b).}
#' The rows, with the assumption under which each identifies its target
#' (all also need no anticipation):
#' \tabular{lll}{
#'   \strong{method} \tab \strong{estimand} \tab \strong{estimator; target} \cr
#'   DID_Female, DID_Male \tab APO \tab \eqn{\delta_{APO}(g)}; \eqn{APO(g, \infty)} under DID-PT \cr
#'   DID_Female, DID_Male \tab ATE \tab \eqn{\mu(g,d,a) - \delta_{APO}(g)}; \eqn{ATE(g)} under DID-PT \cr
#'   DID_Female, DID_Male \tab theta \tab ATE row / APO row; \eqn{\theta(g)} under DID-PT \cr
#'   TD \tab gap_ATE \tab ATE row f minus m; \eqn{ATE(f) - ATE(m)} under TD-PT \cr
#'   Conventional \tab gap_theta \tab theta row f minus m; \eqn{\theta(f) - \theta(m)} under DID-PT only (under NTD-PT it is biased, Theorem 1) \cr
#'   NTD \tab rho_effect \tab \eqn{\mu(f,d,a)/\mu(m,d,a) - \delta_{APO}(f)/\delta_{APO}(m)}; \eqn{\rho(d) - \rho(\infty)} under NTD-PT (Theorem 2) \cr
#'   TD_E_LOGS \tab rho_effect \tab as NTD with \eqn{\delta^{\times}_{APO}}; \eqn{\rho(d) - \rho(\infty)} under TD-E-LOGS (proposition in the online appendix on proportional DID and TD) \cr
#'   TD_PR \tab gap_theta_pre \tab \eqn{[\mu(g,d,a) - \delta^{\times}_{APO}(g)] / \mu(g,d,b)}, f minus m; \eqn{ATE(g)/APO(g,d,\infty,b)}, f minus m, under TD-PR (same proposition) \cr
#'   NTD, TD_E_LOGS \tab rho_obs \tab \eqn{\mu(f,d,a)/\mu(m,d,a)}; the observed gender earnings ratio \eqn{\rho(d)} \cr
#'   NTD, TD_E_LOGS \tab rho_cf \tab \eqn{\delta_{APO}(f)/\delta_{APO}(m)} (NTD) or with \eqn{\delta^{\times}_{APO}} (TD_E_LOGS); \eqn{\rho(\infty)} under NTD-PT (NTD) or TD-E-LOGS (TD_E_LOGS) \cr
#'   NTD, TD_E_LOGS \tab share_parenthood \tab \eqn{(\rho_{cf} - \rho_{obs}) / (1 - \rho_{obs})}; parenthood's share of the observed gender gap (Section 4.2), under the same assumption as rho_cf \cr
#'   NTD, TD_E_LOGS \tab share_other \tab \eqn{1 -} share_parenthood; the share of other factors
#' }
#' Gaps are female minus male. The conventional estimator is the 2x2 version of
#' the normalized event-study child penalty; under NTD it equals the target gap
#' times a gender-invariant bias factor (Theorem 1), see \code{\link{bias_bounds}}
#' for the paper's bias-bounding exercise. The accounting rows and their
#' standard errors are an extension of the paper's Section 4.2 accounting
#' exercise.
#'
#' \strong{Standard errors.} Each row is a smooth function of the eight cell
#' means; its influence function follows by the chain rule from those of the cell
#' means, \eqn{\psi_{\mu} = S (Y - \mu) / P(S)} with \eqn{S} the cell indicator
#' (the appendix on estimation and inference). The variance is \eqn{n^{-2} \sum_c (\sum_{i \in c} \psi_i)^2 \,
#' G / (G - 1)}, clustering by person (\eqn{n} person-age rows, \eqn{G} persons).
#' \code{vignette("estimators")} writes out every estimator and influence
#' function.
#'
#' @return A data.frame with 19 rows and columns \code{d}, \code{dp}, \code{a},
#'   \code{event_time} (\eqn{a - d}), \code{control_offset} (\eqn{d' - d}),
#'   \code{estimand}, \code{method}, \code{est}, \code{se}, \code{ci_l},
#'   \code{ci_h} (est -/+ 1.96 se), \code{t}, \code{p} (two-sided, normal), and
#'   \code{n_female_treat}, \code{n_female_control}, \code{n_male_treat},
#'   \code{n_male_control} (persons with \eqn{D = d} and \eqn{D = d'}). Attribute
#'   \code{"if_scores"}: person-level sums of the influence functions, used by
#'   \code{\link{aggregate_estimands}} and \code{\link{bias_bounds}}.
#'
#' @seealso \code{\link{multiple_treatment_group_analysis}} for the grid of
#'   comparisons the paper uses, \code{\link{aggregate_estimands}},
#'   \code{\link{bias_bounds}}, \code{vignette("estimators")}
#' @import data.table
#'
#' @examples
#' \donttest{
#' sim <- simulate_data(n_individuals = 2000)
#' # Treatment group d = 25 one year after first birth (a = 26),
#' # closest not-yet-treated control group d' = a + 1 = 27
#' res <- single_treatment_group_analysis(sim, d = 25, dp = 27, a = 26)
#' res[res$method %in% c("Conventional", "NTD"), c("method", "estimand", "est", "se")]
#' # Pre-treatment validation (placebo) test: a < d - 1
#' val <- single_treatment_group_analysis(sim, d = 25, dp = 27, a = 22)
#' val[val$method %in% c("Conventional", "NTD") & val$estimand %in% c("gap_theta", "rho_effect"),
#'     c("method", "estimand", "est", "se")]
#' }
#' @export
single_treatment_group_analysis <- function(data, d, dp, a, pre = 1,
                                            Y_name = "Y",
                                            age_name = "age",
                                            D_name = "D",
                                            id_name = "id",
                                            female_name = "female") {

  # ---- argument checks -------------------------------------------------------
  for (arg in c("d", "dp", "a", "pre")) {
    v <- get(arg)
    if (!is.numeric(v) || length(v) != 1L || !is.finite(v) || v != round(v)) {
      stop(sprintf("`%s` must be a single whole number.", arg), call. = FALSE)
    }
  }
  if (pre < 1) stop("`pre` must be at least 1 (the baseline age is d - pre).", call. = FALSE)
  if (dp <= d) {
    stop(sprintf("The control group must have its first birth after the treatment group: dp = %d <= d = %d.",
                 dp, d), call. = FALSE)
  }
  if (dp <= a) {
    stop(sprintf(paste0("The control group must not yet be treated at the target age: dp = %d <= a = %d. ",
                        "The paper uses the closest not-yet-treated group, dp = a + 1."), dp, a),
         call. = FALSE)
  }
  if (a == d - pre) {
    stop(sprintf("The target age a = %d is the baseline age d - pre; choose a different `a`.", a),
         call. = FALSE)
  }

  # Data prepared by prep_data_table() (e.g. inside multiple_treatment_group_analysis())
  # is used as is; anything else is validated and copied first.
  DT_full <- if (isTRUE(attr(data, "childpen_prepared"))) data else
    prep_data_table(data, Y_name, age_name, D_name, id_name, female_name)
  n_total <- attr(DT_full, "n_obs")
  G_total <- attr(DT_full, "n_ids")

  # Only the rows of groups d and dp at the baseline age and the target age enter the
  # estimators; the influence functions and SEs are scaled by the full data's n and G.
  DT <- DT_full[!is.na(D) & D %in% c(d, dp) & age %in% c(d - pre, a)]

  # Compute all 8 base means we need
  means <- list(
    y_d_minus_1_f_d    = compute_mean_if(DT, d-pre, 1, d, "if_y_d_minus_1_f_d", n_total),
    y_d_minus_1_m_d    = compute_mean_if(DT, d-pre, 0, d, "if_y_d_minus_1_m_d", n_total),
    y_a_f_d            = compute_mean_if(DT, a,   1, d, "if_y_a_f_d", n_total),
    y_a_m_d            = compute_mean_if(DT, a,   0, d, "if_y_a_m_d", n_total),
    y_a_f_dp           = compute_mean_if(DT, a,   1, dp, "if_y_a_f_dp", n_total),
    y_a_m_dp           = compute_mean_if(DT, a,   0, dp, "if_y_a_m_dp", n_total),
    y_d_minus_1_f_dp   = compute_mean_if(DT, d-pre, 1, dp, "if_y_d_minus_1_f_dp", n_total),
    y_d_minus_1_m_dp   = compute_mean_if(DT, d-pre, 0, dp, "if_y_d_minus_1_m_dp", n_total)
  )

  # APO and ATE formulas using pure column operations
  # APO(g,d,dp,a) = Y(d-1,g,d) + Y(a,g,dp) - Y(d-1,g,dp)
  DT[, if_apo_f := if_y_d_minus_1_f_d + if_y_a_f_dp - if_y_d_minus_1_f_dp]
  DT[, if_apo_m := if_y_d_minus_1_m_d + if_y_a_m_dp - if_y_d_minus_1_m_dp]

  apo_f <- means$y_d_minus_1_f_d + means$y_a_f_dp - means$y_d_minus_1_f_dp
  apo_m <- means$y_d_minus_1_m_d + means$y_a_m_dp - means$y_d_minus_1_m_dp

  # ATE(g,d,dp,a) = Y(a,g,d) - APO(g,d,dp,a)
  DT[, if_ate_f := if_y_a_f_d - if_apo_f]
  DT[, if_ate_m := if_y_a_m_d - if_apo_m]

  ate_f <- means$y_a_f_d - apo_f
  ate_m <- means$y_a_m_d - apo_m

  # Theta: ATE / APO (using delta method)
  DT[, if_theta_f := (1/apo_f) * if_ate_f - (ate_f/apo_f^2) * if_apo_f]
  DT[, if_theta_m := (1/apo_m) * if_ate_m - (ate_m/apo_m^2) * if_apo_m]

  theta_f <- ate_f / apo_f
  theta_m <- ate_m / apo_m

  # TD: ATE(f) - ATE(m)
  DT[, if_td := if_ate_f - if_ate_m]
  td <- ate_f - ate_m

  # Conventional estimator: theta(f) - theta(m)
  DT[, if_ntd_conv := if_theta_f - if_theta_m]
  ntd_conv <- theta_f - theta_m

  # NTD (new estimand): Y(f)/Y(m) - APO(f)/APO(m)
  DT[, if_ratio_y := (1/means$y_a_m_d) * if_y_a_f_d - (means$y_a_f_d/means$y_a_m_d^2) * if_y_a_m_d]
  DT[, if_ratio_apo := (1/apo_m) * if_apo_f - (apo_f/apo_m^2) * if_apo_m]
  DT[, if_ntd_new := if_ratio_y - if_ratio_apo]

  ntd_new <- (means$y_a_f_d / means$y_a_m_d) - (apo_f / apo_m)

  # Proportional TD (Leventer 2025, online appendix "Proportional DID and TD").
  # Multiplicative imputation of the counterfactual mean:
  #   APO_mult(g) = Y(d-pre,g,d) * Y(a,g,dp) / Y(d-pre,g,dp)
  apo_mult_f <- means$y_d_minus_1_f_d * means$y_a_f_dp / means$y_d_minus_1_f_dp
  apo_mult_m <- means$y_d_minus_1_m_d * means$y_a_m_dp / means$y_d_minus_1_m_dp
  DT[, if_apo_mult_f := apo_mult_f * (if_y_d_minus_1_f_d / means$y_d_minus_1_f_d +
                                      if_y_a_f_dp / means$y_a_f_dp -
                                      if_y_d_minus_1_f_dp / means$y_d_minus_1_f_dp)]
  DT[, if_apo_mult_m := apo_mult_m * (if_y_d_minus_1_m_d / means$y_d_minus_1_m_d +
                                      if_y_a_m_dp / means$y_a_m_dp -
                                      if_y_d_minus_1_m_dp / means$y_d_minus_1_m_dp)]

  # TD_E_LOGS: Y(a,F,d)/Y(a,M,d) - APO_mult(F)/APO_mult(M)  (same estimand as NTD)
  DT[, if_ratio_apo_mult := (1/apo_mult_m) * if_apo_mult_f - (apo_mult_f/apo_mult_m^2) * if_apo_mult_m]
  DT[, if_td_e_logs := if_ratio_y - if_ratio_apo_mult]
  td_e_logs <- (means$y_a_f_d / means$y_a_m_d) - (apo_mult_f / apo_mult_m)

  # TD_PR: theta_pre(F) - theta_pre(M), with
  #   theta_pre(g) = (Y(a,g,d) - APO_mult(g)) / Y(d-pre,g,d)
  theta_pre_f <- (means$y_a_f_d - apo_mult_f) / means$y_d_minus_1_f_d
  theta_pre_m <- (means$y_a_m_d - apo_mult_m) / means$y_d_minus_1_m_d
  DT[, if_theta_pre_f := (if_y_a_f_d - if_apo_mult_f) / means$y_d_minus_1_f_d -
       (theta_pre_f / means$y_d_minus_1_f_d) * if_y_d_minus_1_f_d]
  DT[, if_theta_pre_m := (if_y_a_m_d - if_apo_mult_m) / means$y_d_minus_1_m_d -
       (theta_pre_m / means$y_d_minus_1_m_d) * if_y_d_minus_1_m_d]
  DT[, if_td_pr := if_theta_pre_f - if_theta_pre_m]
  td_pr <- theta_pre_f - theta_pre_m

  # Accounting for the gender gap (Leventer 2025, Section 4.2): observed gap 1 - rho_obs =
  # parenthood (rho_cf - rho_obs) + other factors (1 - rho_cf). The shares' influence functions
  # are not in the paper; they are written out in vignette("estimators").
  rho_obs  <- means$y_a_f_d / means$y_a_m_d
  rho_cf   <- apo_f / apo_m
  rho_cf_x <- apo_mult_f / apo_mult_m
  share_ntd   <- (rho_cf - rho_obs) / (1 - rho_obs)
  share_elogs <- (rho_cf_x - rho_obs) / (1 - rho_obs)
  DT[, if_share_ntd := (if_ratio_apo - if_ratio_y) / (1 - rho_obs) +
       (rho_cf - rho_obs) * if_ratio_y / (1 - rho_obs)^2]
  DT[, if_share_elogs := (if_ratio_apo_mult - if_ratio_y) / (1 - rho_obs) +
       (rho_cf_x - rho_obs) * if_ratio_y / (1 - rho_obs)^2]

  if (any(!is.finite(c(ntd_new, td_e_logs, td_pr)))) {
    warning("Some ratio estimates are not finite: a cell mean of the outcome is zero.", call. = FALSE)
  }

  # Compute all SEs upfront
  ses <- c(
    se_cluster(DT, "if_apo_f", n_total, G_total), se_cluster(DT, "if_apo_m", n_total, G_total),
    se_cluster(DT, "if_ate_f", n_total, G_total), se_cluster(DT, "if_ate_m", n_total, G_total),
    se_cluster(DT, "if_theta_f", n_total, G_total), se_cluster(DT, "if_theta_m", n_total, G_total),
    se_cluster(DT, "if_td", n_total, G_total), se_cluster(DT, "if_ntd_conv", n_total, G_total), se_cluster(DT, "if_ntd_new", n_total, G_total),
    se_cluster(DT, "if_td_e_logs", n_total, G_total), se_cluster(DT, "if_td_pr", n_total, G_total),
    se_cluster(DT, "if_ratio_y", n_total, G_total), se_cluster(DT, "if_ratio_apo", n_total, G_total),
    se_cluster(DT, "if_share_ntd", n_total, G_total), se_cluster(DT, "if_share_ntd", n_total, G_total),
    se_cluster(DT, "if_ratio_y", n_total, G_total), se_cluster(DT, "if_ratio_apo_mult", n_total, G_total),
    se_cluster(DT, "if_share_elogs", n_total, G_total), se_cluster(DT, "if_share_elogs", n_total, G_total)
  )

  # Compute sample sizes (persons in each group, over all ages)
  n_female_d  <- DT_full[female == 1 & D == d,  uniqueN(id)]
  n_female_dp <- DT_full[female == 1 & D == dp, uniqueN(id)]
  n_male_d    <- DT_full[female == 0 & D == d,  uniqueN(id)]
  n_male_dp   <- DT_full[female == 0 & D == dp, uniqueN(id)]

  # ---- Extract id-level IF scores for aggregation ---------------------------
  # These are the cluster-summed influence functions per individual, for the persons
  # in groups d and dp (everyone else has zero). Needed by aggregate_estimands() and
  # bias_bounds() to compute SEs that account for shared control groups across
  # treatment groups.
  if_scores <- DT[, .(
    if_apo_f    = sum(if_apo_f),
    if_apo_m    = sum(if_apo_m),
    if_ate_f    = sum(if_ate_f),
    if_ate_m    = sum(if_ate_m),
    if_theta_f  = sum(if_theta_f),
    if_theta_m  = sum(if_theta_m),
    if_td       = sum(if_td),
    if_ntd_conv = sum(if_ntd_conv),
    if_ntd_new  = sum(if_ntd_new),
    if_td_e_logs = sum(if_td_e_logs),
    if_td_pr     = sum(if_td_pr),
    if_rho_obs        = sum(if_ratio_y),
    if_rho_cf_ntd     = sum(if_ratio_apo),
    if_share_ntd      = sum(if_share_ntd),
    if_rho_cf_e_logs  = sum(if_ratio_apo_mult),
    if_share_e_logs   = sum(if_share_elogs)
  ), by = id]

  estimates <- c(apo_f, apo_m, ate_f, ate_m, theta_f, theta_m,
                 td, ntd_conv, ntd_new, td_e_logs, td_pr,
                 rho_obs, rho_cf, share_ntd, 1 - share_ntd,
                 rho_obs, rho_cf_x, share_elogs, 1 - share_elogs)

  result <- data.frame(
    d = as.integer(d), dp = as.integer(dp), a = as.integer(a),
    event_time = as.integer(a - d), control_offset = as.integer(dp - d),
    estimand = c("APO", "APO", "ATE", "ATE", "theta", "theta",
                 "gap_ATE", "gap_theta", "rho_effect", "rho_effect", "gap_theta_pre",
                 "rho_obs", "rho_cf", "share_parenthood", "share_other",
                 "rho_obs", "rho_cf", "share_parenthood", "share_other"),
    method = c("DID_Female", "DID_Male", "DID_Female", "DID_Male", "DID_Female", "DID_Male",
               "TD", "Conventional", "NTD", "TD_E_LOGS", "TD_PR",
               "NTD", "NTD", "NTD", "NTD",
               "TD_E_LOGS", "TD_E_LOGS", "TD_E_LOGS", "TD_E_LOGS"),
    est = estimates,
    se = ses,
    stringsAsFactors = FALSE
  )
  result$ci_l <- result$est - 1.96 * result$se
  result$ci_h <- result$est + 1.96 * result$se
  result$t    <- result$est / result$se
  result$p    <- 2 * stats::pnorm(-abs(result$est / result$se))
  result$n_female_treat   <- n_female_d
  result$n_female_control <- n_female_dp
  result$n_male_treat     <- n_male_d
  result$n_male_control   <- n_male_dp

  attr(result, "if_scores") <- if_scores
  return(result)
}
