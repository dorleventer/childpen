#' Unconditional estimands for a single treatment group
#'
#' Estimates 15 descriptive estimands for triplet (treatment group, control group and target age). SEs are calcualted using influence-function (IF) calculations with clustering within \code{id}.
#'
#' @param data A \code{data.table} with columns:
#'   \itemize{
#'     \item \code{id} — cluster identifier (i.e., person)
#'     \item \code{age} — integer age
#'     \item \code{female} — 0/1 indicator (1 = females)
#'     \item \code{D} — treatment group
#'     \item \code{Y} — numeric outcome
#'   }
#' @param d Integer. Treatment group (age at first childbirth)
#' @param dp Integer. Control group (closest not-yet-treated group)
#' @param a Integer. Target age.
#' @param pre Integer, default \code{1}. Offset used for the pre-treatment anchor.
#' @param Y_name,age_name,D_name,id_name,female_name Column name mappings passed to \code{prep_data_table()}.
#'
#' @details
#' Let \eqn{Y(a, g, d^\star)} denote the mean outcome at age \eqn{a} for gender
#' \eqn{g \in \{0,1\}} (1 = female) when assigned to group \eqn{d^\star}.
#' The core components are:
#' \itemize{
#'   \item \strong{APO}(g; d, d', a) \eqn{= Y(d-\mathrm{pre}, g, d) + Y(a, g, d') - Y(d-\mathrm{pre}, g, d')}
#'   \item \strong{ATE}(g; d, d', a) \eqn{= Y(a, g, d) - \mathrm{APO}(g; d, d', a)}
#'   \item \strong{\eqn{\theta}(g)} \eqn{= \mathrm{ATE}(g) / \mathrm{APO}(g)}
#' }
#' From these, the cross-gender contrasts are formed:
#' \itemize{
#'   \item \strong{TD} \eqn{= \mathrm{ATE}(F) - \mathrm{ATE}(M)}
#'   \item \strong{NTD} \eqn{= \theta(F) - \theta(M)}
#'   \item \strong{NTD Alt} \eqn{= \frac{Y(a,F,d)}{Y(a,M,d)} - \frac{\mathrm{APO}(F)}{\mathrm{APO}(M)}}
#'   \item \strong{TD Null} and \strong{NTD Null} variants are defined analogously
#'         under a null-effect-for-fathers bias-correction.
#' }
#'
#' Internally, influence functions for all pieces are written into temporary
#' columns of a \code{data.table} via \code{compute_mean_if()}, and cluster-robust
#' standard errors are computed by summing the IFs at the \code{id} level via \code{se_cluster()}.
#'
#' @return A \code{data.frame} with one row per estimand/method combination:
#' \itemize{
#'   \item \code{estimand} — one of \code{"APO"}, \code{"ATE"}, \code{"theta"}
#'   \item \code{method} — one of \code{"DID_Female"}, \code{"DID_Male"}, \code{"TD"},
#'         \code{"NTD"}, \code{"NTD_Alt"}, \code{"TD_Null"}, \code{"NTD_Null"}
#'   \item \code{est} — estimate
#'   \item \code{se} — cluster-robust standard error
#'   \item \code{n_female_treat}, \code{n_female_control},
#'         \code{n_male_treat}, \code{n_male_control} — sample counts
#' }
#'
#' @note Requires helper functions \code{compute_mean_if()} and \code{se_cluster()}.
#' @import data.table
#'
#' @examples
#' \dontrun{
#' library(data.table)
#' set.seed(1)
#' DT <- CJ(id = 1:80, age = 20:26)
#' DT[, female := +(id %% 2 == 0)]
#' DT[, D := 24L]
#' DT[, Y := rnorm(.N, 10 + 0.5*female + 0.1*(age-20))]
#' # compute_mean_if() and se_cluster() must be available in the package
#' res <- single_treatment_group_analysis(DT, d = 24, dp = 26, a = 25, pre = 1)
#' head(res)
#' }
#' @export
single_treatment_group_analysis <- function(data, d, dp, a, pre = 1,
                                            Y_name = "Y",
                                            age_name = "age",
                                            D_name = "D",
                                            id_name = "id",
                                            female_name = "female") {

  DT <- if (inherits(data, "data.table")) data else
    prep_data_table(data, Y_name, age_name, D_name, id_name, female_name)

  # Compute all 8 base means we need
  means <- list(
    y_d_minus_1_f_d    = compute_mean_if(DT, d-pre, 1, d,  "if_y_d_minus_1_f_d"),
    y_d_minus_1_m_d    = compute_mean_if(DT, d-pre, 0, d,  "if_y_d_minus_1_m_d"),
    y_a_f_d            = compute_mean_if(DT, a,   1, d,  "if_y_a_f_d"),
    y_a_m_d            = compute_mean_if(DT, a,   0, d,  "if_y_a_m_d"),
    y_a_f_dp           = compute_mean_if(DT, a,   1, dp, "if_y_a_f_dp"),
    y_a_m_dp           = compute_mean_if(DT, a,   0, dp, "if_y_a_m_dp"),
    y_d_minus_1_f_dp   = compute_mean_if(DT, d-pre, 1, dp, "if_y_d_minus_1_f_dp"),
    y_d_minus_1_m_dp   = compute_mean_if(DT, d-pre, 0, dp, "if_y_d_minus_1_m_dp")
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

  # NTD: Theta(f) - Theta(m)
  DT[, if_ntd := if_theta_f - if_theta_m]
  ntd <- theta_f - theta_m

  # NTD_alt: Y(f)/Y(m) - APO(f)/APO(m)
  DT[, if_ratio_y := (1/means$y_a_m_d) * if_y_a_f_d - (means$y_a_f_d/means$y_a_m_d^2) * if_y_a_m_d]
  DT[, if_ratio_apo := (1/apo_m) * if_apo_f - (apo_f/apo_m^2) * if_apo_m]
  DT[, if_ntd_alt := if_ratio_y - if_ratio_apo]

  ntd_alt <- (means$y_a_f_d / means$y_a_m_d) - (apo_f / apo_m)

  # TD Null estimands
  DT[, if_td_null_apo := if_apo_f + if_ate_m]
  td_null_apo <- apo_f + ate_m

  DT[, if_td_null_ate := if_td]  # Same as TD
  td_null_ate <- td

  DT[, if_td_null_theta := (1/td_null_apo) * if_td_null_ate - (td_null_ate/td_null_apo^2) * if_td_null_apo]
  td_null_theta <- td_null_ate / td_null_apo

  # NTD Null estimands
  ntd_null_apo <- (apo_f * means$y_a_m_d) / apo_m
  DT[, if_ntd_null_apo := (means$y_a_m_d/apo_m) * if_apo_f +
       (apo_f/apo_m) * if_y_a_m_d -
       (ntd_null_apo/apo_m) * if_apo_m]

  DT[, if_ntd_null_ate := if_y_a_f_d - if_ntd_null_apo]
  ntd_null_ate <- means$y_a_f_d - ntd_null_apo

  DT[, if_ntd_null_theta := (1/ntd_null_apo) * if_ntd_null_ate - (ntd_null_ate/ntd_null_apo^2) * if_ntd_null_apo]
  ntd_null_theta <- ntd_null_ate / ntd_null_apo

  # Compute all SEs upfront
  ses <- c(
    se_cluster(DT, "if_apo_f"), se_cluster(DT, "if_apo_m"),
    se_cluster(DT, "if_ate_f"), se_cluster(DT, "if_ate_m"),
    se_cluster(DT, "if_theta_f"), se_cluster(DT, "if_theta_m"),
    se_cluster(DT, "if_td"), se_cluster(DT, "if_ntd"), se_cluster(DT, "if_ntd_alt"),
    se_cluster(DT, "if_td_null_apo"), se_cluster(DT, "if_td_null_ate"),
    se_cluster(DT, "if_td_null_theta"),
    se_cluster(DT, "if_ntd_null_apo"), se_cluster(DT, "if_ntd_null_ate"),
    se_cluster(DT, "if_ntd_null_theta")
  )

  # Compute sample sizes
  n_female_d <- DT[female == 1 & D == d, uniqueN(id)]
  n_female_dp <- DT[female == 1 & D == dp, uniqueN(id)]
  n_male_d <- DT[female == 0 & D == d, uniqueN(id)]
  n_male_dp <- DT[female == 0 & D == dp, uniqueN(id)]

  # Create result data.frame (fast!)
  estimates <- c(apo_f, apo_m, ate_f, ate_m, theta_f, theta_m,
                 td, ntd, ntd_alt,
                 td_null_apo, td_null_ate, td_null_theta,
                 ntd_null_apo, ntd_null_ate, ntd_null_theta)

  result <- data.frame(
    estimand = c("APO", "APO", "ATE", "ATE", "theta", "theta",
                 "ATE", "theta", "theta",
                 "APO", "ATE", "theta",
                 "APO", "ATE", "theta"),
    method = c("DID_Female", "DID_Male", "DID_Female", "DID_Male", "DID_Female", "DID_Male",
               "TD", "NTD", "NTD_Alt",
               "TD_Null", "TD_Null", "TD_Null",
               "NTD_Null", "NTD_Null", "NTD_Null"),
    est = estimates,
    se = ses,
    n_female_treat = n_female_d,
    n_female_control = n_female_dp,
    n_male_treat = n_male_d,
    n_male_control = n_male_dp
  )

  return(result)
}
