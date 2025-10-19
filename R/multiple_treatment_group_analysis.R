#' Child penalty analysis over multiple treatment groups
#'
#' Runs \code{single_treatment_group_analysis()} over a grid of treatment groups
#' and event-time horizons, stacking results into one data frame.
#'
#' @param data A \code{data.frame} or \code{data.table} containing the raw input data.
#'   Must include columns corresponding to identifiers, treatment status, age, gender, and the outcome.
#'   These columns can be specified using the arguments \code{Y_name}, \code{age_name},
#'   \code{D_name}, \code{id_name}, and \code{female_name}.
#' @param treatment_groups Integer vector of treatment groups (e.g., \code{24:34}).
#' @param periods_post Integer \eqn{H \ge 0}. Post-treatment horizons; the function
#'   evaluates 2-by-2 designs via event times \eqn{e \in \{0,1,\ldots,H\}} with target age
#'   \eqn{a = d + e} and closest not-yet-treated control group \eqn{d' = a + 1}.
#' @param periods_pre Integer \eqn{K \ge 0} (default \code{4}). Number of
#'   pre-treatment horizons. The function evaluates
#'   \eqn{e \in \{-K, \ldots, -\mathrm{pre}\}} with \eqn{a = d + e}. Outputs are produced
#'   for all control groups used in post-treatment estimation.
#'   Set \code{NULL} to skip pre-trend computations.
#' @param max_age Integer (default \code{999}). Upper bound; cells with
#'   \eqn{d' >} \code{max_age} are skipped.
#' @param min_age Integer (default \code{0}). Lower bound; cells with
#'   \eqn{a <} \code{min_age} are skipped.
#' @param pre Integer (default \code{1}). Offset used for the pre-treatment anchor in the underlying
#'   2-by-2 designs; determines which pre-period is used in APO construction.
#' @param Y_name Character. Column name in \code{data} holding the outcome variable.
#'   Default \code{"Y"}.
#' @param age_name Character. Column name in \code{data} holding the age variable.
#'   Default \code{"age"}.
#' @param D_name Character. Column name in \code{data} holding the treatment group indicator
#'   (e.g., age-at-treatment). Default \code{"D"}.
#' @param id_name Character. Column name in \code{data} holding the cluster identifier
#'   (e.g., individual ID). Default \code{"id"}.
#' @param female_name Character. Column name in \code{data} holding the binary gender indicator
#'   (1 = female). Default \code{"female"}.
#' @import data.table
#'
#' @details
#' For post-treatment horizons the function loops over
#' \eqn{e = 0,1,\ldots,\mathrm{periods\_post}} and calls
#' \code{single_treatment_group_analysis(data, d, d' = a+1, a = d+e, pre)}.
#' For pre-treatment horizons, it loops over
#' \eqn{e = -\mathrm{periods\_pre}, \ldots, -\mathrm{pre}}, sets \eqn{a = d + e},
#' and tests multiple controls \eqn{d' = d + \Delta} with
#' \eqn{\Delta \in \{1, \ldots, \mathrm{periods\_post}+1\}} (closest not-yet-treated up
#' to the maximum post horizon).
#'
#' @return A \code{data.frame} stacking estimator (\code{est}) and clustered SE (\code{se})) by treatment group (\code{d}), control group (\code{dp}) and age (\code{age}), as outputed by \code{single_treatment_group_analysis()}.
#'
#' @export
multiple_treatment_group_analysis <- function(data,
                            treatment_groups,      # e.g., 24:34
                            periods_post,      # e.g., 0:5 (years after treatment)
                            periods_pre = 4,
                            max_age = 999,
                            min_age = 0,
                            pre = 1,
                            Y_name = "Y",
                            age_name = "age",
                            D_name = "D",
                            id_name = "id",
                            female_name = "female",
                            verbose = T) {

  # Suppress data.table messages and progress bars
  old_verbose <- getOption("datatable.verbose")
  old_progress <- getOption("datatable.showProgress")
  options(datatable.verbose = FALSE, datatable.showProgress = FALSE)
  on.exit(options(datatable.verbose = old_verbose, datatable.showProgress = old_progress))

  # Calculate total number of estimations
  n_post <- length(treatment_groups) * periods_post
  n_pre <- if (!is.null(periods_pre)) {
    length(treatment_groups) * periods_pre * (periods_post + 1)
  } else { 0 }
  n_total <- n_post + n_pre

  results_list <- list()
  idx <- 1
  completed <- 0

  control_offsets = periods_post + 1

  if(verbose) {
    cat(sprintf("\nRunning analysis for %d treatment groups...\n", length(treatment_groups)))
    cat(sprintf("Post-treatment event times: 0 to %d\n", periods_post))
    if (!is.null(periods_pre)) {
      cat(sprintf("Pre-treatment event times: %d to %d (testing %d control groups: d+%d to d+%d)\n",
                  -periods_pre-pre, -1-pre, control_offsets, 1, control_offsets))
    }
    cat(sprintf("Total estimations: %d (%d post + %d pre)\n\n", n_total, n_post, n_pre))
  }


  start_time_total <- Sys.time()

  DT <- prep_data_table(data, Y_name, age_name, D_name, id_name, female_name)

  # Post-treatment estimates
  for (d in treatment_groups) {
    for (event_time in 0:periods_post) {
      a <- d + event_time      # outcome age
      dp <- a + 1              # control: closest not yet treated

      # Skip if control group would be out of range
      if (dp > max_age) {
        if(verbose) cat(sprintf("  Skipping d=%d, event_time=%d (control dp=%d > max_age)\n", d, event_time, dp))
        next
      }

      tryCatch({
        res <- single_treatment_group_analysis(data, d, dp, a, pre)
        res$d <- d
        res$dp <- dp
        res$a <- a

        results_list[[idx]] <- res
        idx <- idx + 1
        completed <- completed + 1

        # Progress update
        elapsed <- as.numeric(difftime(Sys.time(), start_time_total, units = "mins"))
        pct <- 100 * completed / n_total
        rate <- completed / elapsed
        remaining <- (n_total - completed) / rate
        if(verbose) {
        cat(sprintf("Progress: %d/%d (%.1f%%) | Elapsed: %.1f min | Remaining: ~%.1f min\n",
                    completed, n_total, pct, elapsed, remaining))
        }

      }, error = function(e) {
        cat(sprintf("  Error for d=%d, event_time=%d: %s\n", d, event_time, e$message))
      })
    }
  }

  # Pre-treatment estimates (pre-trends)
  if (!is.null(periods_pre)) {
    for (d in treatment_groups) {
      for (event_time in (-pre - periods_pre):(- pre - 1)) {
        a <- d + event_time  # outcome age (a < d for pre-treatment)

        # Skip if outcome age would be out of range
        if (a < min_age) {
          if(verbose) cat(sprintf("  Skipping d=%d, event_time=%d (outcome a=%d < min_age)\n", d, event_time, a))
          next
        }

        # Test against multiple control groups
        for (offset in control_offsets) {
          dp <- d + offset

          # Skip if control group would be out of range
          if (dp > max_age) next

          tryCatch({
            res <- single_treatment_group_analysis(data, d, dp, a, pre)
            res$d <- d
            res$dp <- dp
            res$a <- a

            results_list[[idx]] <- res
            idx <- idx + 1
            completed <- completed + 1

            # Progress update
            elapsed <- as.numeric(difftime(Sys.time(), start_time_total, units = "mins"))
            pct <- 100 * completed / n_total
            rate <- completed / elapsed
            remaining <- (n_total - completed) / rate
            if(verbose) {
            cat(sprintf("Progress: %d/%d (%.1f%%) | Elapsed: %.1f min | Remaining: ~%.1f min\n",
                        completed, n_total, pct, elapsed, remaining))
            }

          }, error = function(e) {
            cat(sprintf("  Error for d=%d, event_time=%d, dp=%d: %s\n",
                        d, event_time, dp, e$message))
          })
        }
      }
    }
  }

  total_elapsed <- as.numeric(difftime(Sys.time(), start_time_total, units = "mins"))
  if(verbose) cat(sprintf("\nCompleted %d estimations in %.1f minutes\n\n", completed, total_elapsed))

  # Combine all results
  result_df <- do.call(rbind, results_list)
  result_df$ci_l <- result_df$est - 1.96 * result_df$se
  result_df$ci_h <- result_df$est + 1.96 * result_df$se
  result_df$t <- result_df$est / result_df$se
  result_df$p <- 2 * pnorm(-abs(result_df$est / result_df$se))
  result_df$event_time <- result_df$a - result_df$d

  # Reorder columns for clarity
  col_order <- c("d", "dp", "a", " event_time",
                 "estimand", "method", "est", "se", "ci_l", "ci_h", "t", "p",
                 "n_female_treat", "n_female_control", "n_male_treat", "n_male_control")

  result_df[, col_order]
}
