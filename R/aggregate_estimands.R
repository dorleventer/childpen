#' Aggregate estimands across treatment groups
#'
#' Takes the stacked output of \code{multiple_treatment_group_analysis()} and
#' computes three aggregate estimands across treatment groups for each event
#' time:
#'
#' \describe{
#'   \item{\strong{avg_of_ratios} (\eqn{\theta_{\text{Agg},1}})}{
#'     Weighted average of the group-specific normalised effects
#'     \eqn{\theta(g, d, d+e)} across treatment groups \eqn{d}.  This is the
#'     preferred estimand because it averages effects that are already scaled
#'     by each group's baseline.}
#'   \item{\strong{ratio_of_avgs} (\eqn{\theta_{\text{Agg},2}})}{
#'     Ratio of the weighted-average ATE to the weighted-average APO.  The
#'     implicit weight on each group is \eqn{p_d \cdot \text{APO}_d}, giving
#'     higher-earning groups more influence.}
#'   \item{\strong{gender_ineq} (\eqn{\Delta\rho_{\text{Agg}}})}{
#'     Weighted average of \code{NTD_Alt} (estimand == "theta") across
#'     treatment groups — the aggregate gender-inequality estimand.}
#' }
#'
#' @param results A \code{data.frame} as returned by
#'   \code{multiple_treatment_group_analysis()}, with at minimum the columns
#'   \code{d}, \code{event_time}, \code{estimand}, \code{method}, \code{est},
#'   and \code{se}.
#' @param weights Named numeric vector of treatment-group weights (names must
#'   match the values of the \code{d} column coerced to character).  Values
#'   are normalised to sum to 1 within each event_time × method cell, so you
#'   only need to supply relative weights.  \code{NULL} (default) uses uniform
#'   weights over the treatment groups that have an estimate for that cell.
#' @param methods Character vector of methods to aggregate.  Defaults to all
#'   five main methods.
#' @param include_pre Logical.  If \code{TRUE}, also aggregate pre-treatment
#'   event times (\code{event_time < 0}).  Default \code{FALSE}.
#'
#' @return A \code{data.frame} with one row per
#'   \code{event_time} × \code{estimand} × \code{method} × \code{agg_type}
#'   combination, containing:
#'   \itemize{
#'     \item \code{event_time} — event time
#'     \item \code{estimand} — \code{"APO"}, \code{"ATE"}, or \code{"theta"}
#'     \item \code{method} — method name
#'     \item \code{agg_type} — one of \code{"avg_of_ratios"},
#'       \code{"ratio_of_avgs"}, \code{"gender_ineq"}
#'     \item \code{est} — aggregate estimate
#'     \item \code{se} — standard error (see Details)
#'     \item \code{ci_l}, \code{ci_h} — 95 \% Wald confidence interval
#'     \item \code{n_groups} — number of treatment groups contributing
#'   }
#'
#' @details
#' \strong{Standard errors.}  Because the raw influence functions are not
#' stored in the \code{results} object, SEs are computed treating the
#' group-specific estimates as mutually independent.
#'
#' For \code{avg_of_ratios}:
#' \deqn{\mathrm{SE}(\hat\theta_{\text{Agg},1}) = \sqrt{\sum_d w_d^2 \, \hat\sigma_d^2}}
#'
#' For \code{ratio_of_avgs}, the delta method is applied to the ratio
#' \eqn{\bar\mu_{\text{ATE}} / \bar\mu_{\text{APO}}}:
#' \deqn{\mathrm{SE} \approx \frac{1}{\bar\mu_{\text{APO}}}
#'   \sqrt{\mathrm{Var}(\bar\mu_{\text{ATE}}) +
#'         \hat\theta_{\text{Agg},2}^2 \, \mathrm{Var}(\bar\mu_{\text{APO}})}}
#' where variances are again computed via the independent-groups formula.
#'
#' \strong{Handling missing cells.}  Not every treatment group produces an
#' estimate for every event time (due to \code{max_age} / \code{min_age}
#' bounds).  The function operates on whichever groups are present for each
#' cell and reports how many via \code{n_groups}.  If \code{weights} is
#' supplied, only the entries whose names appear in the observed treatment
#' groups are used; the remaining weights are dropped and the retained weights
#' are renormalised.
#'
#' @import data.table
#' @export
#'
#' @examples
#' \dontrun{
#' # Assume `res` is the output of multiple_treatment_group_analysis()
#' agg <- aggregate_estimands(res)
#' head(agg)
#'
#' # Custom weights: more weight on later first-births
#' w <- c("24" = 0.1, "25" = 0.2, "26" = 0.3, "27" = 0.25, "28" = 0.15)
#' agg_w <- aggregate_estimands(res, weights = w)
#' }
aggregate_estimands <- function(results,
                                weights = NULL,
                                methods = c("DID_Female", "DID_Male", "TD", "NTD", "NTD_Alt"),
                                include_pre = FALSE) {

  # ---- Input checks -------------------------------------------------------
  if (!is.data.frame(results) || nrow(results) == 0L) {
    stop("`results` must be a non-empty data.frame.")
  }

  required_cols <- c("d", "event_time", "estimand", "method", "est", "se")
  missing_cols  <- setdiff(required_cols, names(results))
  if (length(missing_cols) > 0L) {
    stop("Missing required columns in `results`: ",
         paste(missing_cols, collapse = ", "))
  }

  if (!is.null(weights)) {
    if (!is.numeric(weights) || is.null(names(weights))) {
      stop("`weights` must be a named numeric vector (names = treatment groups as characters).")
    }
    if (any(weights < 0)) stop("All `weights` must be non-negative.")
  }

  # ---- Coerce to data.table for internal work -----------------------------
  DT <- data.table::as.data.table(results)

  # ---- Filter event times -------------------------------------------------
  if (!include_pre) {
    DT <- DT[event_time >= 0]
  }

  if (nrow(DT) == 0L) {
    warning("No rows remain after filtering. Returning empty data.frame.")
    return(data.frame())
  }

  # ---- Filter to requested methods ----------------------------------------
  DT <- DT[method %in% methods]

  if (nrow(DT) == 0L) {
    warning("No rows match the requested `methods`. Returning empty data.frame.")
    return(data.frame())
  }

  # ---- Helper: compute weights for a sub-table of a single cell -----------
  # Returns a numeric vector of normalised weights aligned to the rows of `sub`.
  .norm_weights <- function(d_vals, user_weights) {
    d_chr <- as.character(d_vals)
    if (is.null(user_weights)) {
      # Uniform
      n <- length(d_chr)
      return(rep(1.0 / n, n))
    }
    w <- user_weights[d_chr]
    w[is.na(w)] <- 0
    s <- sum(w)
    if (s == 0) {
      # Fall back to uniform when none of the user weights match
      return(rep(1.0 / length(d_chr), length(d_chr)))
    }
    w / s
  }

  # ---- 1. avg_of_ratios (theta_Agg,1) -------------------------------------
  # Weighted mean of theta estimates across d, for each (event_time, method).
  # Only applies to estimand == "theta".

  theta_rows <- DT[estimand == "theta"]

  agg1_list <- list()
  if (nrow(theta_rows) > 0L) {
    # Group by event_time x method
    cells <- unique(theta_rows[, .(event_time, method)])

    for (i in seq_len(nrow(cells))) {
      et  <- cells$event_time[i]
      mth <- cells$method[i]

      sub <- theta_rows[event_time == et & method == mth]
      w   <- .norm_weights(sub$d, weights)

      est_agg <- sum(w * sub$est)
      se_agg  <- sqrt(sum(w^2 * sub$se^2))

      agg1_list[[i]] <- data.table(
        event_time = et,
        estimand   = "theta",
        method     = mth,
        agg_type   = "avg_of_ratios",
        est        = est_agg,
        se         = se_agg,
        n_groups   = nrow(sub)
      )
    }
  }

  # ---- 2. ratio_of_avgs (theta_Agg,2) ------------------------------------
  # theta_Agg,2 = E_D[ATE] / E_D[APO], weighted by p_d.
  # Need ATE and APO for the same (d, event_time, method) triplets.
  # Methods that produce both ATE and APO: DID_Female, DID_Male.

  agg2_list <- list()

  # Collect all (d, event_time, method, estimand) rows for ATE and APO
  ate_rows <- DT[estimand == "ATE"]
  apo_rows <- DT[estimand == "APO"]

  if (nrow(ate_rows) > 0L && nrow(apo_rows) > 0L) {
    # Find cells that have both ATE and APO
    ate_cells <- unique(ate_rows[, .(d, event_time, method)])
    apo_cells <- unique(apo_rows[, .(d, event_time, method)])

    # Inner join on (d, event_time, method)
    joined <- merge(ate_cells, apo_cells, by = c("d", "event_time", "method"))

    if (nrow(joined) > 0L) {
      # Pull estimates
      ate_m <- merge(joined, ate_rows[, .(d, event_time, method, est_ate = est, se_ate = se)],
                     by = c("d", "event_time", "method"))
      both  <- merge(ate_m,  apo_rows[, .(d, event_time, method, est_apo = est, se_apo = se)],
                     by = c("d", "event_time", "method"))

      cells2 <- unique(both[, .(event_time, method)])

      for (i in seq_len(nrow(cells2))) {
        et  <- cells2$event_time[i]
        mth <- cells2$method[i]

        sub <- both[event_time == et & method == mth]
        w   <- .norm_weights(sub$d, weights)

        # Weighted means
        mu_ate <- sum(w * sub$est_ate)
        mu_apo <- sum(w * sub$est_apo)

        if (abs(mu_apo) < .Machine$double.eps^0.5) {
          est_agg <- NA_real_
          se_agg  <- NA_real_
        } else {
          est_agg <- mu_ate / mu_apo

          # Var(mu_ate) and Var(mu_apo) assuming independence across groups
          var_mu_ate <- sum(w^2 * sub$se_ate^2)
          var_mu_apo <- sum(w^2 * sub$se_apo^2)

          # Delta method: Var(ate/apo) ≈ (1/apo)^2 * Var(ate) + (ate/apo^2)^2 * Var(apo)
          se_agg <- sqrt((1 / mu_apo)^2 * var_mu_ate +
                           (mu_ate / mu_apo^2)^2 * var_mu_apo)
        }

        agg2_list[[i]] <- data.table(
          event_time = et,
          estimand   = "theta",
          method     = mth,
          agg_type   = "ratio_of_avgs",
          est        = est_agg,
          se         = se_agg,
          n_groups   = nrow(sub)
        )
      }
    }
  }

  # ---- 3. gender_ineq (Delta_rho_Agg) -------------------------------------
  # Weighted average of NTD_Alt theta estimates across d.

  ntd_alt_rows <- DT[method == "NTD_Alt" & estimand == "theta"]

  agg3_list <- list()
  if (nrow(ntd_alt_rows) > 0L) {
    cells3 <- unique(ntd_alt_rows[, .(event_time)])

    for (i in seq_len(nrow(cells3))) {
      et  <- cells3$event_time[i]

      sub <- ntd_alt_rows[event_time == et]
      w   <- .norm_weights(sub$d, weights)

      est_agg <- sum(w * sub$est)
      se_agg  <- sqrt(sum(w^2 * sub$se^2))

      agg3_list[[i]] <- data.table(
        event_time = et,
        estimand   = "theta",
        method     = "NTD_Alt",
        agg_type   = "gender_ineq",
        est        = est_agg,
        se         = se_agg,
        n_groups   = nrow(sub)
      )
    }
  }

  # ---- Combine and compute inferential columns ----------------------------
  all_parts <- c(agg1_list, agg2_list, agg3_list)

  if (length(all_parts) == 0L) {
    warning("No aggregate estimands could be computed. Returning empty data.frame.")
    return(data.frame())
  }

  out <- data.table::rbindlist(all_parts, use.names = TRUE, fill = TRUE)

  out[, ci_l := est - 1.96 * se]
  out[, ci_h := est + 1.96 * se]

  # Sort for readability
  data.table::setorderv(out, c("agg_type", "method", "event_time"))

  return(as.data.frame(out))
}
