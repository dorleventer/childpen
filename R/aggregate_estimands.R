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
#'     Weighted average of \code{NTD_New} (estimand == "Delta_rho") across
#'     treatment groups -- the aggregate gender-inequality estimand.}
#' }
#'
#' @param results A \code{data.frame} as returned by
#'   \code{multiple_treatment_group_analysis()}, with at minimum the columns
#'   \code{d}, \code{event_time}, \code{estimand}, \code{method}, \code{est},
#'   and \code{se}.  If \code{results} carries influence-function data (attached
#'   automatically by \code{multiple_treatment_group_analysis()}), standard
#'   errors account for shared control groups across treatment groups.
#' @param weights How to weight treatment groups.  One of:
#'   \itemize{
#'     \item \code{"sample"} (default): use sample-proportion weights as in
#'       Leventer (2025).  Within-gender weights
#'       \eqn{w_{g,d} = n_{g,d}/\sum n_{g,\tilde d}} are used for
#'       \code{DID_Female} and \code{DID_Male}; cross-gender weights
#'       \eqn{w_d = n_d / \sum n_{\tilde d}} for \code{TD}, \code{NTD_Conv},
#'       and \code{NTD_New}.  Standard errors account for estimation of the
#'       weights.
#'     \item \code{NULL}: uniform weights (equal weight per group).
#'     \item A named numeric vector: custom fixed weights (names = treatment
#'       groups as characters).  Values are renormalised to sum to 1.
#'   }
#' @param methods Character vector of methods to aggregate.  Defaults to all
#'   five main methods.
#' @param include_pre Logical.  If \code{TRUE}, also aggregate pre-treatment
#'   event times (\code{event_time < 0}).  Default \code{FALSE}.
#'
#' @return A \code{data.frame} with one row per
#'   \code{event_time} by \code{estimand} by \code{method} by \code{agg_type}
#'   combination, containing:
#'   \itemize{
#'     \item \code{event_time} -- event time
#'     \item \code{estimand} -- \code{"APO"}, \code{"ATE"}, \code{"theta"}, or \code{"Delta_rho"}
#'     \item \code{method} -- method name
#'     \item \code{agg_type} -- one of \code{"avg_of_ratios"},
#'       \code{"ratio_of_avgs"}, \code{"gender_ineq"}
#'     \item \code{est} -- aggregate estimate
#'     \item \code{se} -- standard error (see Details)
#'     \item \code{ci_l}, \code{ci_h} -- 95 \% Wald confidence interval
#'     \item \code{n_groups} -- number of treatment groups contributing
#'   }
#'
#' @details
#' \strong{Standard errors.}  When the \code{results} object carries
#' influence-function (IF) data from \code{multiple_treatment_group_analysis()},
#' aggregate SEs account for dependence across treatment groups caused by shared
#' control individuals.
#'
#' With \code{weights = "sample"}, the IF additionally accounts for estimation
#' of the weights, following the formula in Leventer (2025, Appendix G):
#' \deqn{\psi_{A(e)} = \sum_d \left[ w_d\,\psi_{B_d}
#'   + \frac{B_d - A(e)}{M}\,\psi_{p_d} \right]}
#' where \eqn{M = \sum_d p_d} and \eqn{\psi_{p_d}} is the IF of the group
#' proportion.
#'
#' With fixed weights (\code{NULL} or a named vector), the second term drops
#' out and the IF reduces to \eqn{\sum_d w_d\,\psi_{B_d}}.
#'
#' For \code{ratio_of_avgs}, the delta method is applied to the ratio
#' \eqn{\bar\mu_{\text{ATE}} / \bar\mu_{\text{APO}}} using the aggregate IFs
#' for the numerator and denominator.
#'
#' If IF data is not available (e.g., when the user supplies a manually
#' constructed results table), SEs are computed under an independence
#' approximation with a warning.
#'
#' \strong{Handling missing cells.}  Not every treatment group produces an
#' estimate for every event time (due to \code{max_age} / \code{min_age}
#' bounds).  The function operates on whichever groups are present for each
#' cell and reports how many via \code{n_groups}.  If \code{weights} is
#' supplied as a named vector, only the entries whose names appear in the
#' observed treatment groups are used; the remaining weights are dropped and
#' the retained weights are renormalised.
#'
#' @import data.table
#' @export
#'
#' @examples
#' \donttest{
#' set.seed(1)
#' sim <- simulate_data(n_individuals = 500)
#' res <- multiple_treatment_group_analysis(sim, treatment_groups = 24:25,
#'                                          periods_post = 2, verbose = FALSE)
#' agg <- aggregate_estimands(res)
#' head(agg)
#' }
aggregate_estimands <- function(results,
                                weights = "sample",
                                methods = c("DID_Female", "DID_Male", "TD", "NTD_Conv", "NTD_New"),
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

  use_sample_weights <- is.character(weights) && length(weights) == 1L &&
                        weights == "sample"
  use_fixed_weights  <- is.numeric(weights)
  use_uniform        <- is.null(weights)

  if (!use_sample_weights && !use_fixed_weights && !use_uniform) {
    stop('`weights` must be "sample", NULL, or a named numeric vector.')
  }

  if (use_fixed_weights) {
    if (is.null(names(weights))) {
      stop("`weights` must be a named numeric vector (names = treatment groups as characters).")
    }
    if (any(weights < 0)) stop("All `weights` must be non-negative.")
  }

  # ---- Extract IF data if available ----------------------------------------
  if_data <- attr(results, "if_data")
  n_obs   <- attr(results, "n_obs")
  n_ids   <- attr(results, "n_ids")
  id_info <- attr(results, "id_info")
  has_ifs <- !is.null(if_data) && !is.null(n_obs) && !is.null(n_ids)

  if (!has_ifs) {
    warning("Influence-function data not available. ",
            "SEs are computed under an independence approximation, ",
            "which ignores dependence from shared control groups. ",
            "Pass the output of multiple_treatment_group_analysis() directly ",
            "to get proper SEs.")
  }

  if (use_sample_weights && is.null(id_info)) {
    warning('weights = "sample" requires id_info from ',
            "multiple_treatment_group_analysis(). Falling back to uniform weights.")
    use_sample_weights <- FALSE
    use_uniform <- TRUE
  }

  # ---- Precompute sample-proportion group sizes ----------------------------
  if (use_sample_weights) {
    # Within-gender counts: n_{g,d}
    n_female_by_d <- id_info[female == 1, .N, by = D]
    data.table::setnames(n_female_by_d, "N", "n_gd")
    n_male_by_d   <- id_info[female == 0, .N, by = D]
    data.table::setnames(n_male_by_d, "N", "n_gd")

    # Cross-gender counts: n_d
    n_by_d <- id_info[, .N, by = D]
    data.table::setnames(n_by_d, "N", "n_d")

    # T = ages per individual (balanced panel)
    T_ages <- n_obs / n_ids
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

  # ---- Helper: compute normalised weights for a cell -----------------------
  # Returns weights for a vector of d values.
  # weight_type: "within_female", "within_male", or "cross"
  .get_weights <- function(d_vals, weight_type = NULL) {
    d_chr <- as.character(d_vals)

    if (use_uniform) {
      n <- length(d_chr)
      return(rep(1.0 / n, n))
    }

    if (use_fixed_weights) {
      w <- weights[d_chr]
      w[is.na(w)] <- 0
      s <- sum(w)
      if (s == 0) return(rep(1.0 / length(d_chr), length(d_chr)))
      return(as.numeric(w / s))
    }

    # Sample-proportion weights
    if (weight_type == "within_female") {
      counts <- n_female_by_d[D %in% d_vals]
    } else if (weight_type == "within_male") {
      counts <- n_male_by_d[D %in% d_vals]
    } else {
      counts <- n_by_d[D %in% d_vals]
    }

    # Ensure order matches d_vals
    if (weight_type %in% c("within_female", "within_male")) {
      w <- counts$n_gd[match(d_vals, counts$D)]
    } else {
      w <- counts$n_d[match(d_vals, counts$D)]
    }
    w[is.na(w)] <- 0
    s <- sum(w)
    if (s == 0) return(rep(1.0 / length(d_vals), length(d_vals)))
    as.numeric(w / s)
  }

  # ---- Helper: weight type for a method ------------------------------------
  .weight_type <- function(mth) {
    if (mth == "DID_Female") return("within_female")
    if (mth == "DID_Male")   return("within_male")
    return("cross")  # TD, NTD_Conv, NTD_New
  }

  # ---- Helper: SE from aggregate IFs (cluster-robust) ----------------------
  # Computes the SE of a weighted aggregate, optionally including the
  # proportion-IF correction term from the paper.
  #
  # if_col:      name of the IF column in if_data
  # d_vals:      vector of d values being aggregated
  # et:          event time
  # w_vec:       normalised weight vector (same order as d_vals)
  # B_vals:      single-group estimate values (same order as d_vals)
  # A_est:       aggregate point estimate
  # weight_type: "within_female", "within_male", or "cross" (for sample weights)
  .agg_se_from_ifs <- function(if_col, d_vals, et, w_vec, B_vals, A_est,
                               weight_type = NULL) {
    w_named <- stats::setNames(w_vec, as.character(d_vals))

    # Term 1: weighted sum of single-group IFs
    sub <- if_data[event_time == et & d %in% d_vals]
    sub[, wt := w_named[as.character(d)]]
    sub[, weighted_score := wt * get(if_col)]

    id_scores <- sub[, .(term1 = sum(weighted_score)), by = id]

    # Term 2: proportion-IF correction (only for sample weights)
    if (use_sample_weights && !is.null(weight_type)) {
      # M = sum of proportions for groups in this cell
      if (weight_type == "within_female") {
        M_total <- sum(n_female_by_d[D %in% d_vals, n_gd])
      } else if (weight_type == "within_male") {
        M_total <- sum(n_male_by_d[D %in% d_vals, n_gd])
      } else {
        M_total <- sum(n_by_d[D %in% d_vals, n_d])
      }

      # For each individual: (B_{D_c} - A) / M, with gender filter
      # Map B values by d
      B_named <- stats::setNames(B_vals, as.character(d_vals))

      # Get each individual's D and compute their proportion-IF contribution
      id_D <- id_info[, .(id, female, D)]

      # Only individuals whose D is in d_vals contribute a non-zero proportion IF
      # (for others, B_{D_c} is undefined but the proportion IF simplifies to
      #  -(B_{D_c} - A)/M * p_d which sums to zero across d anyway)
      #
      # Using the simplification from the appendix derivation:
      # Sum_d (B_d - A)/M * psi_{p_d,c} = (B_{D_c} - A)/M * gender_match
      # where gender_match = 1 for cross-gender, 1{g_c = g} for within-gender

      id_D[, B_own := B_named[as.character(D)]]
      id_D[, prop_contrib := 0.0]

      if (weight_type == "within_female") {
        id_D[female == 1 & D %in% d_vals,
             prop_contrib := T_ages * (B_own - A_est) / M_total]
      } else if (weight_type == "within_male") {
        id_D[female == 0 & D %in% d_vals,
             prop_contrib := T_ages * (B_own - A_est) / M_total]
      } else {
        id_D[D %in% d_vals,
             prop_contrib := T_ages * (B_own - A_est) / M_total]
      }

      # Merge with term1 scores
      id_scores <- merge(id_scores, id_D[, .(id, prop_contrib)],
                         by = "id", all = TRUE)
      id_scores[is.na(term1), term1 := 0]
      id_scores[is.na(prop_contrib), prop_contrib := 0]
      id_scores[, agg_score := term1 + prop_contrib]
    } else {
      id_scores[, agg_score := term1]
    }

    G <- n_ids
    v_hat <- (sum(id_scores$agg_score^2) / (n_obs^2)) * (G / (G - 1))
    sqrt(v_hat)
  }

  # ---- Helper: SE under independence (fallback) ----------------------------
  .agg_se_indep <- function(w_vec, se_vec) {
    sqrt(sum(w_vec^2 * se_vec^2))
  }

  # ---- 1. avg_of_ratios (theta_Agg,1) -------------------------------------
  theta_rows <- DT[estimand == "theta"]

  # Map method -> IF column for theta
  theta_if_map <- c(
    DID_Female = "if_theta_f",
    DID_Male   = "if_theta_m",
    NTD_Conv   = "if_ntd_conv"
  )

  agg1_list <- list()
  if (nrow(theta_rows) > 0L) {
    cells <- unique(theta_rows[, .(event_time, method)])

    for (i in seq_len(nrow(cells))) {
      et  <- cells$event_time[i]
      mth <- cells$method[i]

      sub <- theta_rows[event_time == et & method == mth]
      wt  <- .weight_type(mth)
      w   <- .get_weights(sub$d, wt)

      est_agg <- sum(w * sub$est)

      if (has_ifs && mth %in% names(theta_if_map)) {
        se_agg <- .agg_se_from_ifs(theta_if_map[[mth]], sub$d, et, w,
                                   B_vals = sub$est, A_est = est_agg,
                                   weight_type = wt)
      } else {
        se_agg <- .agg_se_indep(w, sub$se)
      }

      agg1_list[[length(agg1_list) + 1L]] <- data.table(
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
  agg2_list <- list()

  ate_rows <- DT[estimand == "ATE"]
  apo_rows <- DT[estimand == "APO"]

  ate_if_map <- c(DID_Female = "if_ate_f", DID_Male = "if_ate_m")
  apo_if_map <- c(DID_Female = "if_apo_f", DID_Male = "if_apo_m")

  if (nrow(ate_rows) > 0L && nrow(apo_rows) > 0L) {
    ate_cells <- unique(ate_rows[, .(d, event_time, method)])
    apo_cells <- unique(apo_rows[, .(d, event_time, method)])

    joined <- merge(ate_cells, apo_cells, by = c("d", "event_time", "method"))

    if (nrow(joined) > 0L) {
      ate_m_dt <- merge(joined, ate_rows[, .(d, event_time, method, est_ate = est, se_ate = se)],
                     by = c("d", "event_time", "method"))
      both  <- merge(ate_m_dt, apo_rows[, .(d, event_time, method, est_apo = est, se_apo = se)],
                     by = c("d", "event_time", "method"))

      cells2 <- unique(both[, .(event_time, method)])

      for (i in seq_len(nrow(cells2))) {
        et  <- cells2$event_time[i]
        mth <- cells2$method[i]

        sub <- both[event_time == et & method == mth]
        wt  <- .weight_type(mth)
        w   <- .get_weights(sub$d, wt)

        mu_ate <- sum(w * sub$est_ate)
        mu_apo <- sum(w * sub$est_apo)

        if (abs(mu_apo) < .Machine$double.eps^0.5) {
          est_agg <- NA_real_
          se_agg  <- NA_real_
        } else {
          est_agg <- mu_ate / mu_apo

          if (has_ifs && mth %in% names(ate_if_map)) {
            # Delta method on aggregate IFs for numerator and denominator
            w_named <- stats::setNames(w, as.character(sub$d))
            sub_if <- if_data[event_time == et & d %in% sub$d]
            sub_if[, wt_col := w_named[as.character(d)]]

            ate_col <- ate_if_map[[mth]]
            apo_col <- apo_if_map[[mth]]

            id_scores <- sub_if[, .(
              agg_ate = sum(wt_col * get(ate_col)),
              agg_apo = sum(wt_col * get(apo_col))
            ), by = id]

            # Apply delta method: IF(ratio) per id
            id_scores[, ratio_if := (1 / mu_apo) * agg_ate -
                                    (mu_ate / mu_apo^2) * agg_apo]

            G <- n_ids
            v_hat <- (sum(id_scores$ratio_if^2) / (n_obs^2)) * (G / (G - 1))
            se_agg <- sqrt(v_hat)
          } else {
            var_mu_ate <- sum(w^2 * sub$se_ate^2)
            var_mu_apo <- sum(w^2 * sub$se_apo^2)
            se_agg <- sqrt((1 / mu_apo)^2 * var_mu_ate +
                             (mu_ate / mu_apo^2)^2 * var_mu_apo)
          }
        }

        agg2_list[[length(agg2_list) + 1L]] <- data.table(
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
  ntd_new_rows <- DT[method == "NTD_New" & estimand == "Delta_rho"]

  agg3_list <- list()
  if (nrow(ntd_new_rows) > 0L) {
    cells3 <- unique(ntd_new_rows[, .(event_time)])

    for (i in seq_len(nrow(cells3))) {
      et  <- cells3$event_time[i]

      sub <- ntd_new_rows[event_time == et]
      w   <- .get_weights(sub$d, "cross")

      est_agg <- sum(w * sub$est)

      if (has_ifs) {
        se_agg <- .agg_se_from_ifs("if_ntd_new", sub$d, et, w,
                                   B_vals = sub$est, A_est = est_agg,
                                   weight_type = "cross")
      } else {
        se_agg <- .agg_se_indep(w, sub$se)
      }

      agg3_list[[length(agg3_list) + 1L]] <- data.table(
        event_time = et,
        estimand   = "Delta_rho",
        method     = "NTD_New",
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

  data.table::setorderv(out, c("agg_type", "method", "event_time"))

  return(as.data.frame(out))
}
