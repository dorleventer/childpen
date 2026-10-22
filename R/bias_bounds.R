#' Bias-corrected conventional estimates for assumed fathers' effects
#'
#' The bias-bounding exercise of Leventer (2025, Section 3.3). Under NTD the
#' conventional estimator (the gender gap in normalized DID) is biased for the
#' gender gap in normalized effects \eqn{\theta(f) - \theta(m)} when parallel
#' trends fails (Theorem 1). If fathers' normalized effect \eqn{\theta(m)} were
#' known, the gap would be identified (Proposition 2). This function computes the
#' bias-corrected gap for each assumed value of \eqn{\theta(m)}, for every
#' post-treatment cell of \code{results} (Proposition 2 applies after
#' treatment, \eqn{d' > a \ge d}); comparing it with the conventional estimate
#' bounds the bias.
#'
#' For a post-treatment cell \eqn{(d, d', a)}, with \eqn{\hat\Delta} the
#' \code{NTD} \code{rho_effect} estimate (the effect of parenthood on the gender
#' earnings ratio) and
#' \eqn{\hat\delta_{APO}(g)} the DID-imputed counterfactual mean of gender
#' \eqn{g} (rows \code{APO}, \code{DID_Female} / \code{DID_Male}), the
#' bias-corrected gap is (Proposition 2, in the form of the appendix on estimation and inference)
#' \deqn{\hat\Delta \, \frac{\hat\delta_{APO}(m)}{\hat\delta_{APO}(f)} \, (1 + \theta(m)).}{
#' Delta_hat * delta_APO(m) / delta_APO(f) * (1 + theta_m).}
#' It is linear in \eqn{\theta(m)}, so the values at the ends of an interval
#' bound it over the whole interval. Standard errors come from the delta method on
#' the stored person-level influence functions, clustered by person.
#'
#' @param results The data.frame returned by
#'   \code{\link{multiple_treatment_group_analysis}}, unmodified.
#' @param theta_m Numeric vector of assumed fathers' normalized effects
#'   (default \code{c(-0.1, 0.1)}, the paper's range).
#'
#' @return A data.frame with one row per cell and value of \code{theta_m}:
#'   \code{d}, \code{dp}, \code{a}, \code{event_time}, \code{theta_m},
#'   \code{est} (the bias-corrected gap), \code{se}, \code{ci_l}, \code{ci_h}.
#'
#' @seealso \code{\link{multiple_treatment_group_analysis}}
#' @examples
#' \donttest{
#' sim <- simulate_data(n_individuals = 2000)
#' res <- multiple_treatment_group_analysis(sim, treatment_groups = 24:26,
#'   periods_post = 2, periods_pre = NULL, verbose = FALSE)
#' bb <- bias_bounds(res)
#' # Conventional estimate and the bias-corrected band, d = 25
#' subset(res, method == "Conventional" & d == 25, c(event_time, est))
#' subset(bb, d == 25, c(event_time, theta_m, est, se))
#' }
#' @export
bias_bounds <- function(results, theta_m = c(-0.1, 0.1)) {
  if (!is.data.frame(results) || nrow(results) == 0L) {
    stop("`results` must be the output of multiple_treatment_group_analysis().", call. = FALSE)
  }
  if (!is.numeric(theta_m) || length(theta_m) == 0L || any(!is.finite(theta_m)) ||
      any(theta_m <= -1)) {
    stop("`theta_m` must be a numeric vector with values above -1.", call. = FALSE)
  }
  if_data <- attr(results, "if_data")
  n_obs   <- attr(results, "n_obs")
  n_ids   <- attr(results, "n_ids")
  if (is.null(if_data) || is.null(n_obs) || is.null(n_ids)) {
    stop("`results` carries no influence functions; pass the output of ",
         "multiple_treatment_group_analysis() unmodified.", call. = FALSE)
  }
  needed <- c("NTD", "DID_Female", "DID_Male")
  if (!all(needed %in% results$method)) {
    stop("`results` must contain the NTD, DID_Female and DID_Male rows.", call. = FALSE)
  }

  R <- data.table::as.data.table(results)
  cells <- merge(
    R[method == "NTD" & estimand == "rho_effect" & event_time >= 0,
      .(d, dp, a, event_time, rho = est)],
    merge(R[method == "DID_Female" & estimand == "APO", .(d, dp, a, apo_f = est)],
          R[method == "DID_Male"   & estimand == "APO", .(d, dp, a, apo_m = est)],
          by = c("d", "dp", "a")),
    by = c("d", "dp", "a"))

  G <- n_ids
  out <- vector("list", nrow(cells))
  for (k in seq_len(nrow(cells))) {
    ck <- cells[k]
    ifs <- if_data[d == ck$d & dp == ck$dp & a == ck$a]
    # IF of rho * apo_m / apo_f (delta method), per person
    base <- ifs$if_ntd_new * ck$apo_m / ck$apo_f +
            ifs$if_apo_m   * ck$rho / ck$apo_f -
            ifs$if_apo_f   * ck$rho * ck$apo_m / ck$apo_f^2
    se_base <- sqrt(sum(base^2) / n_obs^2 * G / (G - 1))
    est_base <- ck$rho * ck$apo_m / ck$apo_f
    out[[k]] <- data.frame(d = ck$d, dp = ck$dp, a = ck$a, event_time = ck$event_time,
                           theta_m = theta_m,
                           est = est_base * (1 + theta_m),
                           se  = se_base * (1 + theta_m))
  }
  out <- do.call(rbind, out)
  out$ci_l <- out$est - 1.96 * out$se
  out$ci_h <- out$est + 1.96 * out$se
  out <- out[order(out$d, out$event_time, out$dp, out$theta_m), ]
  rownames(out) <- NULL
  out
}
