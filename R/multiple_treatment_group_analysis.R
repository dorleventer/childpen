#' Child-penalty estimates for many treatment groups and event times
#'
#' Runs \code{\link{single_treatment_group_analysis}} over a grid of 2x2
#' comparisons. For each treatment group \eqn{d} (age at first birth) and event
#' time \eqn{e = 0, \dots, H}, the target age \eqn{a = d + e} is compared with the
#' closest not-yet-treated group \eqn{d' = a + 1} (Leventer 2025, Section 1.3).
#' Pre-treatment event times are estimated against every control group used
#' after treatment, because the identifying assumptions must hold pair by pair
#' (Section 2.3). Results are stacked, and the person-level influence functions
#' that \code{\link{aggregate_estimands}} and \code{\link{bias_bounds}} need are
#' attached.
#'
#' @param data A data.frame or data.table in long format, one row per person and
#'   age; see \code{\link{single_treatment_group_analysis}} for the requirements.
#'   It is not modified.
#' @param treatment_groups Integer vector of ages at first birth \eqn{d} to
#'   estimate (the paper uses 24:34). Groups \eqn{d + 1, \dots, d + H + 1} must be
#'   in \code{data} to serve as controls.
#' @param periods_post Whole number \eqn{H \ge 0}: post-treatment event times
#'   \eqn{e = 0, \dots, H} (the paper uses 5).
#' @param periods_pre Whole number \eqn{K \ge 0} (default 4), or \code{NULL}:
#'   number of pre-treatment event times for validation tests,
#'   \eqn{e = -(pre + K), \dots, -(pre + 1)} (with the defaults \eqn{-5, \dots, -2};
#'   \eqn{e = -pre} is the baseline). \code{0} or \code{NULL} skips them.
#' @param max_control_group Largest age at first birth allowed as a control group
#'   (the paper's \eqn{D_{max}}; default \code{Inf}, no bound). Cells whose control
#'   group is above it are not estimated.
#' @param min_pre_age Smallest target age for pre-treatment cells (default 0, no
#'   bound). Post-treatment cells are not affected.
#' @param pre Whole number \eqn{\ge 1} (default 1): the baseline age is \eqn{d - pre}.
#' @param Y_name,age_name,D_name,id_name,female_name Names of the columns holding
#'   earnings, age, age at first birth, the person id and the female indicator.
#' @param verbose Logical (default \code{TRUE}). Report progress, one line per
#'   treatment group.
#'
#' @return A data.frame with one block of rows per estimated cell
#'   (\code{d}, \code{dp}, \code{a}), sorted by \code{d}, \code{event_time} and
#'   \code{dp}; the columns are those of
#'   \code{\link{single_treatment_group_analysis}}. Attributes used by
#'   \code{\link{aggregate_estimands}} and \code{\link{bias_bounds}}:
#'   \code{"if_data"} (person-level influence functions per cell), \code{"n_obs"}
#'   (rows of the prepared data), \code{"n_ids"} (persons), \code{"id_info"}
#'   (\code{id}, \code{female}, \code{D}). Attribute \code{"skipped"} lists cells
#'   that could not be estimated, with the reason (e.g. an empty
#'   gender x group x age cell). Pass the result to the aggregation functions
#'   unmodified.
#'
#' @seealso \code{\link{single_treatment_group_analysis}},
#'   \code{\link{aggregate_estimands}}, \code{\link{bias_bounds}}
#' @examples
#' \donttest{
#' sim <- simulate_data(n_individuals = 2000)
#' res <- multiple_treatment_group_analysis(sim, treatment_groups = 24:26,
#'   periods_post = 1, periods_pre = 2, verbose = FALSE)
#' # The new estimand, by treatment group and event time
#' subset(res, method == "NTD" & estimand == "rho_effect" & event_time >= 0,
#'        c(d, event_time, dp, est, se))
#' # Pre-treatment validation tests of NTD, one row per control group
#' subset(res, method == "Conventional" & event_time < 0,
#'        c(d, event_time, control_offset, est, se))
#' }
#' @export
multiple_treatment_group_analysis <- function(data,
                                              treatment_groups,
                                              periods_post,
                                              periods_pre = 4,
                                              max_control_group = Inf,
                                              min_pre_age = 0,
                                              pre = 1,
                                              Y_name = "Y",
                                              age_name = "age",
                                              D_name = "D",
                                              id_name = "id",
                                              female_name = "female",
                                              verbose = TRUE) {

  # ---- argument checks -------------------------------------------------------
  whole <- function(x) is.numeric(x) && all(is.finite(x)) && all(x == round(x))
  if (missing(treatment_groups) || !whole(treatment_groups) || length(treatment_groups) == 0L) {
    stop("`treatment_groups` must be a vector of whole numbers (ages at first birth), e.g. 24:34.",
         call. = FALSE)
  }
  if (missing(periods_post) || !whole(periods_post) || length(periods_post) != 1L || periods_post < 0) {
    stop("`periods_post` must be one whole number H >= 0; event times 0, ..., H are estimated.",
         call. = FALSE)
  }
  if (!is.null(periods_pre) &&
      (!whole(periods_pre) || length(periods_pre) != 1L || periods_pre < 0)) {
    stop("`periods_pre` must be one whole number K >= 0, or NULL.", call. = FALSE)
  }
  if (identical(as.numeric(periods_pre), 0)) periods_pre <- NULL
  if (!whole(pre) || length(pre) != 1L || pre < 1) {
    stop("`pre` must be one whole number >= 1 (the baseline age is d - pre).", call. = FALSE)
  }
  if (!is.numeric(max_control_group) || length(max_control_group) != 1L) {
    stop("`max_control_group` must be one number.", call. = FALSE)
  }
  if (!is.numeric(min_pre_age) || length(min_pre_age) != 1L) {
    stop("`min_pre_age` must be one number.", call. = FALSE)
  }

  # Suppress data.table messages and progress bars
  old_verbose <- getOption("datatable.verbose")
  old_progress <- getOption("datatable.showProgress")
  options(datatable.verbose = FALSE, datatable.showProgress = FALSE)
  on.exit(options(datatable.verbose = old_verbose, datatable.showProgress = old_progress))

  DT <- prep_data_table(data, Y_name, age_name, D_name, id_name, female_name)

  results_list <- list()
  if_list <- list()
  skipped <- list()
  idx <- 1

  run_cell <- function(d, dp, a) {
    tryCatch({
      res <- single_treatment_group_analysis(DT, d, dp, a, pre)
      ifs <- attr(res, "if_scores")
      ifs$d <- d
      ifs$dp <- dp
      ifs$a <- a
      if_list[[idx]] <<- ifs
      results_list[[idx]] <<- res
      idx <<- idx + 1
      TRUE
    }, error = function(e) {
      skipped[[length(skipped) + 1L]] <<- data.frame(d = d, dp = dp, a = a,
                                                     reason = conditionMessage(e),
                                                     stringsAsFactors = FALSE)
      FALSE
    })
  }

  t0 <- Sys.time()
  # Post-treatment cells: control = closest not-yet-treated group
  for (d in treatment_groups) {
    t_d <- Sys.time(); n_ok <- 0L
    for (event_time in 0:periods_post) {
      a  <- d + event_time      # outcome age
      dp <- a + 1               # control: closest not yet treated
      if (dp > max_control_group) {
        skipped[[length(skipped) + 1L]] <- data.frame(d = d, dp = dp, a = a,
          reason = "control group above max_control_group", stringsAsFactors = FALSE)
        next
      }
      n_ok <- n_ok + run_cell(d, dp, a)
    }
    if (verbose) message(sprintf("d = %d: %d post-treatment cells (%.1f s)", d, n_ok,
                                 as.numeric(difftime(Sys.time(), t_d, units = "secs"))))
  }

  # Pre-treatment cells: every control group used after treatment
  if (!is.null(periods_pre)) {
    for (d in treatment_groups) {
      t_d <- Sys.time(); n_ok <- 0L
      for (event_time in (-pre - periods_pre):(-pre - 1)) {
        a <- d + event_time    # outcome age (a < d - pre)
        if (a < min_pre_age) {
          skipped[[length(skipped) + 1L]] <- data.frame(d = d, dp = NA_real_, a = a,
            reason = "target age below min_pre_age", stringsAsFactors = FALSE)
          next
        }
        for (offset in 1:(periods_post + 1)) {
          dp <- d + offset
          if (dp > max_control_group) {
            skipped[[length(skipped) + 1L]] <- data.frame(d = d, dp = dp, a = a,
              reason = "control group above max_control_group", stringsAsFactors = FALSE)
            next
          }
          n_ok <- n_ok + run_cell(d, dp, a)
        }
      }
      if (verbose) message(sprintf("d = %d: %d pre-treatment cells (%.1f s)", d, n_ok,
                                   as.numeric(difftime(Sys.time(), t_d, units = "secs"))))
    }
  }

  skipped_df <- if (length(skipped)) do.call(rbind, skipped) else
    data.frame(d = numeric(0), dp = numeric(0), a = numeric(0), reason = character(0))
  n_fail <- sum(!grepl("^control group above|^target age below", skipped_df$reason))

  if (length(results_list) == 0L) {
    stop("No cell could be estimated. First reasons: ",
         paste(utils::head(unique(skipped_df$reason), 3), collapse = "; "), call. = FALSE)
  }
  if (n_fail > 0L) {
    message(sprintf("%d cells could not be estimated (see attr(result, \"skipped\")), e.g.: %s",
                    n_fail, skipped_df$reason[!grepl("^control group above|^target age below",
                                                      skipped_df$reason)][1]))
  }
  if (verbose) message(sprintf("Estimated %d cells in %.1f s", length(results_list),
                               as.numeric(difftime(Sys.time(), t0, units = "secs"))))

  result_df <- do.call(rbind, results_list)
  result_df <- result_df[order(result_df$d, result_df$event_time, result_df$dp), , drop = FALSE]
  rownames(result_df) <- NULL

  # Attach id-level IF scores for aggregate SE computation
  if_data <- data.table::rbindlist(if_list, use.names = TRUE)
  if_data[, event_time := a - d]
  attr(result_df, "if_data") <- if_data
  attr(result_df, "n_obs") <- nrow(DT)
  attr(result_df, "n_ids") <- DT[, data.table::uniqueN(id)]
  # Individual-level (id, female, D) lookup for sample-proportion weights
  attr(result_df, "id_info") <- unique(DT[, .(id, female, D)])
  attr(result_df, "skipped") <- skipped_df

  result_df
}
