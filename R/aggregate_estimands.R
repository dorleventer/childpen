#' Aggregate estimates across treatment groups
#'
#' Averages the treatment-group-specific estimates from
#' \code{\link{multiple_treatment_group_analysis}} across treatment groups, by
#' event time (Leventer 2025, Section 5). The default weights are the
#' treatment-group shares in the sample. Standard errors account for persons who
#' serve as controls for several treatment groups.
#'
#' @param results The data.frame returned by
#'   \code{\link{multiple_treatment_group_analysis}}, unmodified (its attributes
#'   carry the influence functions). A table without them is accepted, with
#'   standard errors under an independence approximation and a warning.
#' @param weights How to weight treatment groups:
#'   \itemize{
#'     \item \code{"sample"} (default): treatment-group shares. Within gender,
#'       \eqn{w_{g,d} = n_{g,d} / \sum_{k} n_{g,k}}, for \code{DID_Female} and
#'       \code{DID_Male}; across genders, \eqn{w_d = n_d / \sum_{k} n_{k}}, for
#'       all other methods.
#'     \item \code{"uniform"} or \code{NULL}: equal weight per treatment group.
#'     \item A named numeric vector (names = treatment groups): fixed weights,
#'       renormalized to sum to one over the groups present at each event time.
#'       Groups missing from the vector get weight zero, with a warning.
#'   }
#' @param methods Methods to aggregate (default: all). \code{DID_Female},
#'   \code{DID_Male}: \code{weighted_avg} and \code{ratio_of_avgs} of
#'   \code{theta}; \code{Conventional}: \code{weighted_avg} of \code{gap_theta};
#'   \code{NTD} and \code{TD_E_LOGS}: \code{weighted_avg} of \code{rho_effect}
#'   and of the accounting rows \code{rho_obs}, \code{rho_cf},
#'   \code{share_parenthood}, \code{share_other};
#'   \code{TD}: \code{weighted_avg} of \code{gap_ATE}; \code{TD_PR}:
#'   \code{weighted_avg} of \code{gap_theta_pre}.
#' @param include_pre Logical (default \code{FALSE}). Also aggregate
#'   pre-treatment event times. A pre-treatment event time has one cell per
#'   control group (\code{control_offset} = \eqn{d' - d}), and each offset is
#'   aggregated separately, so each row is the validation test of one
#'   treatment-control distance.
#'
#' @return A data.frame with one row per event time, estimand, method and
#'   aggregation type: \code{event_time}, \code{control_offset} (\eqn{d' - d};
#'   after treatment it is \code{event_time} + 1), \code{estimand},
#'   \code{method}, \code{agg_type}, \code{est}, \code{se}, \code{n_groups}
#'   (treatment groups with positive weight), \code{ci_l}, \code{ci_h} (est -/+
#'   1.96 se), \code{t}, \code{p}.
#'
#' @details
#' \code{agg_type = "weighted_avg"} is \eqn{\sum_d w_d B_d} over the
#' treatment-group estimates \eqn{B_d}. For \code{DID_Female} / \code{DID_Male}
#' this is \eqn{\theta_{Agg,1}(g, e)}; for \code{Conventional} it is the
#' conventional aggregate gap \eqn{\Delta\theta_{Agg}(e)}, which under NTD is
#' biased for the gap in normalized effects (Theorem 1); for \code{NTD} it is
#' \eqn{\rho_{Agg}(e)}, the aggregate effect of parenthood on the gender earnings
#' ratio. \code{agg_type = "ratio_of_avgs"} (DID rows only) is
#' \eqn{\theta_{Agg,2}(g, e)}, the ratio of the weighted average ATE to the
#' weighted average APO; it puts more weight on higher-earning groups, which is
#' why the paper prefers \eqn{\theta_{Agg,1}} (Section 5.1).
#'
#' \strong{Standard errors.} The influence function of an aggregate (aggregate
#' estimator section of the appendix on estimation and inference) sums the treatment-group influence functions with the weights; with
#' \code{weights = "sample"} it adds the term for the estimated shares,
#' \eqn{\psi_{A(e)} = P_e^{-1}\sum_d [(B_d - A(e))\psi_{p_d} + p_d\psi_{B_d}]},
#' \eqn{\psi_{p_d} = 1\{D = d\} - p_d}, where \eqn{p_d} is the share of persons
#' in group \eqn{d} (\eqn{1\{G = g, D = d\} - p_{g,d}} with the joint share of
#' gender \eqn{g} and group \eqn{d} for the within-gender DID rows) and
#' \eqn{P_e} the summed share of the aggregated groups. For
#' \code{ratio_of_avgs} the chain rule is applied to the ratio of the two
#' weighted averages, each with its share term. Standard errors are clustered by
#' person. The share term is put on the person-age scale with the average number
#' of ages per person, exact for a balanced panel.
#'
#' Not every treatment group has an estimate at every event time; each event
#' time uses the groups present, and \code{n_groups} reports how many.
#'
#' @seealso \code{\link{multiple_treatment_group_analysis}}, \code{\link{bias_bounds}}
#' @examples
#' \donttest{
#' sim <- simulate_data(n_individuals = 2000)
#' res <- multiple_treatment_group_analysis(sim, treatment_groups = 24:26,
#'   periods_post = 2, periods_pre = NULL, verbose = FALSE)
#' agg <- aggregate_estimands(res)
#' agg[agg$method %in% c("NTD", "Conventional"), ]
#' }
#' @import data.table
#' @export
aggregate_estimands <- function(results,
                                weights = "sample",
                                methods = c("DID_Female", "DID_Male", "TD", "Conventional", "NTD",
                                            "TD_E_LOGS", "TD_PR"),
                                include_pre = FALSE) {

  # ---- Input checks -------------------------------------------------------
  if (!is.data.frame(results) || nrow(results) == 0L) {
    stop("`results` must be a non-empty data.frame (the output of multiple_treatment_group_analysis()).",
         call. = FALSE)
  }

  required_cols <- c("d", "event_time", "estimand", "method", "est", "se")
  missing_cols  <- setdiff(required_cols, names(results))
  if (length(missing_cols) > 0L) {
    stop("Missing required columns in `results`: ",
         paste(missing_cols, collapse = ", "), call. = FALSE)
  }

  unknown <- setdiff(methods, unique(results$method))
  if (length(unknown) == length(methods)) {
    stop(sprintf("None of `methods` is in `results`. Methods in `results`: %s.",
                 paste(unique(results$method), collapse = ", ")), call. = FALSE)
  }

  if (identical(weights, "uniform")) weights <- NULL
  use_sample_weights <- is.character(weights) && length(weights) == 1L &&
                        weights == "sample"
  use_fixed_weights  <- is.numeric(weights)
  use_uniform        <- is.null(weights)

  if (!use_sample_weights && !use_fixed_weights && !use_uniform) {
    stop('`weights` must be "sample", "uniform", NULL, or a named numeric vector.', call. = FALSE)
  }

  if (use_fixed_weights) {
    if (is.null(names(weights))) {
      stop("`weights` must be a named numeric vector (names = treatment groups, e.g. c(`24` = 1)).",
           call. = FALSE)
    }
    if (any(weights < 0)) stop("All `weights` must be non-negative.", call. = FALSE)
    groups <- as.character(unique(results$d))
    if (!any(names(weights) %in% groups)) {
      stop(sprintf("No name of `weights` matches a treatment group in `results` (%s).",
                   paste(groups, collapse = ", ")), call. = FALSE)
    }
    unmatched <- setdiff(groups, names(weights))
    if (length(unmatched)) {
      warning(sprintf("Treatment groups without a weight get weight zero: %s.",
                      paste(unmatched, collapse = ", ")), call. = FALSE)
    }
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
            "to get proper SEs.", call. = FALSE)
  }

  if (use_sample_weights && is.null(id_info)) {
    warning('weights = "sample" requires id_info from ',
            "multiple_treatment_group_analysis(). Falling back to uniform weights.", call. = FALSE)
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
    warning("No rows remain after filtering. Returning empty data.frame.", call. = FALSE)
    return(data.frame())
  }

  # ---- Filter to requested methods ----------------------------------------
  DT <- DT[method %in% methods]

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
    return("cross")  # TD, Conventional, NTD, TD_E_LOGS, TD_PR
  }

  # ---- Helper: person-level IF of a weighted aggregate (cluster-robust) ------
  # psi_A = sum_d w_d psi_{B_d}  +  (with sample weights) the term for the estimated
  # shares, (B_{D_i} - A) / P_e for persons i in the aggregated groups (Appendix C.1):
  #   psi_A(e) = P_e^{-1} sum_d [ (B_d - A) psi_{p_d} + p_d psi_{B_d} ],
  #   psi_{p_d} = 1{D = d} - p_d,  P_e = sum_d p_d  (shares of persons, not counts).
  # if_data is person-level and on the person-age scale (sums of observation IFs), so the
  # share term is multiplied by T = n_obs / n_ids to put it on the same scale.
  #
  # if_col:      name of the IF column in if_data
  # d_vals:      treatment groups aggregated
  # et, offset:  event time and control offset (dp - d) of the cell
  # w_vec:       normalised weights (same order as d_vals)
  # B_vals:      group estimates (same order as d_vals); A_est: the aggregate
  # weight_type: "within_female", "within_male", or "cross" (for sample weights)
  .agg_if_scores <- function(if_col, d_vals, et, offset, w_vec, B_vals, A_est,
                             weight_type = NULL) {
    w_named <- stats::setNames(w_vec, as.character(d_vals))

    # Term 1: weighted sum of single-group IFs
    sub <- if_data[event_time == et & d %in% d_vals & (dp - d) == offset]
    sub[, wt := w_named[as.character(d)]]
    sub[, weighted_score := wt * get(if_col)]

    id_scores <- sub[, .(term1 = sum(weighted_score)), by = id]

    # Term 2: estimated shares (only for sample weights)
    if (use_sample_weights && !is.null(weight_type)) {
      # P_e: share of persons in the aggregated groups (within gender: joint share of
      # gender g and the group)
      if (weight_type == "within_female") {
        P_e <- sum(n_female_by_d[D %in% d_vals, n_gd]) / n_ids
      } else if (weight_type == "within_male") {
        P_e <- sum(n_male_by_d[D %in% d_vals, n_gd]) / n_ids
      } else {
        P_e <- sum(n_by_d[D %in% d_vals, n_d]) / n_ids
      }

      B_named <- stats::setNames(B_vals, as.character(d_vals))
      id_D <- id_info[, .(id, female, D)]
      id_D[, B_own := B_named[as.character(D)]]
      id_D[, prop_contrib := 0.0]
      # sum_d (B_d - A) (1{D_i = d} - p_d) / P_e = (B_{D_i} - A) / P_e for persons in the
      # groups, since sum_d p_d (B_d - A) / P_e = sum_d w_d B_d - A = 0
      if (weight_type == "within_female") {
        id_D[female == 1 & D %in% d_vals, prop_contrib := T_ages * (B_own - A_est) / P_e]
      } else if (weight_type == "within_male") {
        id_D[female == 0 & D %in% d_vals, prop_contrib := T_ages * (B_own - A_est) / P_e]
      } else {
        id_D[D %in% d_vals, prop_contrib := T_ages * (B_own - A_est) / P_e]
      }

      id_scores <- merge(id_scores, id_D[, .(id, prop_contrib)], by = "id", all = TRUE)
      id_scores[is.na(term1), term1 := 0]
      id_scores[is.na(prop_contrib), prop_contrib := 0]
      id_scores[, agg_score := term1 + prop_contrib]
    } else {
      id_scores[, agg_score := term1]
    }
    id_scores[, .(id, agg_score)]
  }

  .se_from_scores <- function(scores) {
    G <- n_ids
    sqrt((sum(scores^2) / (n_obs^2)) * (G / (G - 1)))
  }

  .agg_se_from_ifs <- function(if_col, d_vals, et, offset, w_vec, B_vals, A_est,
                               weight_type = NULL) {
    .se_from_scores(.agg_if_scores(if_col, d_vals, et, offset, w_vec, B_vals, A_est,
                                   weight_type)$agg_score)
  }

  # ---- Helper: SE under independence (fallback) ----------------------------
  .agg_se_indep <- function(w_vec, se_vec) {
    sqrt(sum(w_vec^2 * se_vec^2))
  }

  # ---- 1. weighted_avg: sum_d w_d B_d ----------------------------------------
  # theta_Agg,1 (DID), the conventional gap, rho_Agg (NTD, TD_E_LOGS), the TD gap
  # in levels and the TD_PR gap; one cell per (event_time, method).
  # (method, estimand) -> person-level IF column in if_data
  avg_spec <- data.table::data.table(
    method   = c("DID_Female", "DID_Male", "TD", "Conventional", "NTD", "TD_E_LOGS", "TD_PR",
                 "NTD", "NTD", "NTD", "TD_E_LOGS", "TD_E_LOGS", "TD_E_LOGS"),
    estimand = c("theta", "theta", "gap_ATE", "gap_theta", "rho_effect", "rho_effect",
                 "gap_theta_pre",
                 "rho_obs", "rho_cf", "share_parenthood", "rho_obs", "rho_cf", "share_parenthood"),
    if_col   = c("if_theta_f", "if_theta_m", "if_td", "if_ntd_conv", "if_ntd_new", "if_td_e_logs",
                 "if_td_pr",
                 "if_rho_obs", "if_rho_cf_ntd", "if_share_ntd",
                 "if_rho_obs", "if_rho_cf_e_logs", "if_share_e_logs"),
    sign     = 1
  )
  # share_other = 1 - share_parenthood: same IF with the opposite sign
  avg_spec <- rbind(avg_spec, data.table::data.table(
    method = c("NTD", "TD_E_LOGS"), estimand = "share_other",
    if_col = c("if_share_ntd", "if_share_e_logs"), sign = -1))
  avg_rows <- merge(DT, avg_spec, by = c("method", "estimand"))

  agg1_list <- list()
  if (nrow(avg_rows) > 0L) {
    # Pre-treatment cells have several control groups per (d, event_time): one aggregate per
    # control offset dp - d (post-treatment cells have one, offset = event_time + 1).
    cells <- unique(avg_rows[, .(event_time, control_offset, method, estimand)])

    for (i in seq_len(nrow(cells))) {
      et  <- cells$event_time[i]
      off <- cells$control_offset[i]
      mth <- cells$method[i]
      est_name <- cells$estimand[i]

      sub <- avg_rows[event_time == et & control_offset == off & method == mth & estimand == est_name]
      wt  <- .weight_type(mth)
      w   <- .get_weights(sub$d, wt)
      if_col <- sub$if_col[1]; sgn <- sub$sign[1]

      est_agg <- sum(w * sub$est)

      if (has_ifs && if_col %in% names(if_data)) {
        # the SE of sum_d w_d B_d with IF sign * psi: the sign does not change the variance,
        # but the weight-estimation term uses B_d, so pass B_d = sign * est to keep it consistent
        se_agg <- .agg_se_from_ifs(if_col, sub$d, et, off, w,
                                   B_vals = sgn * sub$est, A_est = sgn * est_agg,
                                   weight_type = wt)
      } else {
        se_agg <- .agg_se_indep(w, sub$se)
      }

      agg1_list[[length(agg1_list) + 1L]] <- data.table(
        event_time = et,
        control_offset = off,
        estimand   = est_name,
        method     = mth,
        agg_type   = "weighted_avg",
        est        = est_agg,
        se         = se_agg,
        n_groups   = sum(w > 0)
      )
    }
  }

  # ---- 2. ratio_of_avgs (theta_Agg,2) ------------------------------------
  agg2_list <- list()

  ate_rows <- DT[estimand == "ATE" & method %in% c("DID_Female", "DID_Male")]
  apo_rows <- DT[estimand == "APO" & method %in% c("DID_Female", "DID_Male")]

  ate_if_map <- c(DID_Female = "if_ate_f", DID_Male = "if_ate_m")
  apo_if_map <- c(DID_Female = "if_apo_f", DID_Male = "if_apo_m")

  if (nrow(ate_rows) > 0L && nrow(apo_rows) > 0L) {
    keys <- c("d", "event_time", "control_offset", "method")
    both <- merge(ate_rows[, .(d, event_time, control_offset, method, est_ate = est, se_ate = se)],
                  apo_rows[, .(d, event_time, control_offset, method, est_apo = est, se_apo = se)],
                  by = keys)

    if (nrow(both) > 0L) {
      cells2 <- unique(both[, .(event_time, control_offset, method)])

      for (i in seq_len(nrow(cells2))) {
        et  <- cells2$event_time[i]
        off <- cells2$control_offset[i]
        mth <- cells2$method[i]

        sub <- both[event_time == et & control_offset == off & method == mth]
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
            # Chain rule on the IFs of the two weighted averages (each with its
            # estimated-share term under sample weights)
            num <- .agg_if_scores(ate_if_map[[mth]], sub$d, et, off, w,
                                  B_vals = sub$est_ate, A_est = mu_ate, weight_type = wt)
            den <- .agg_if_scores(apo_if_map[[mth]], sub$d, et, off, w,
                                  B_vals = sub$est_apo, A_est = mu_apo, weight_type = wt)
            id_scores <- merge(num, den, by = "id", suffixes = c("_num", "_den"))
            id_scores[, ratio_if := (1 / mu_apo) * agg_score_num -
                                    (mu_ate / mu_apo^2) * agg_score_den]
            se_agg <- .se_from_scores(id_scores$ratio_if)
          } else {
            var_mu_ate <- sum(w^2 * sub$se_ate^2)
            var_mu_apo <- sum(w^2 * sub$se_apo^2)
            se_agg <- sqrt((1 / mu_apo)^2 * var_mu_ate +
                             (mu_ate / mu_apo^2)^2 * var_mu_apo)
          }
        }

        agg2_list[[length(agg2_list) + 1L]] <- data.table(
          event_time = et,
          control_offset = off,
          estimand   = "theta",
          method     = mth,
          agg_type   = "ratio_of_avgs",
          est        = est_agg,
          se         = se_agg,
          n_groups   = sum(w > 0)
        )
      }
    }
  }

  # ---- Combine and compute inferential columns ----------------------------
  all_parts <- c(agg1_list, agg2_list)

  if (length(all_parts) == 0L) {
    stop("No aggregate could be computed for the requested `methods`.", call. = FALSE)
  }

  out <- data.table::rbindlist(all_parts, use.names = TRUE, fill = TRUE)

  out[, ci_l := est - 1.96 * se]
  out[, ci_h := est + 1.96 * se]
  out[, t := est / se]
  out[, p := 2 * stats::pnorm(-abs(est / se))]

  data.table::setorderv(out, c("method", "agg_type", "event_time", "control_offset"))

  return(as.data.frame(out))
}
