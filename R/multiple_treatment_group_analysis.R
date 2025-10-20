#' Child penalty analysis over multiple treatment groups
#'
#' @param data A data.frame or data.table with the needed columns. Names can be
#'   mapped via \code{Y_name}, \code{age_name}, \code{D_name}, \code{id_name}, \code{female_name}.
#' @param treatment_groups Integer vector of treatment groups (e.g., 24:34).
#' @param periods_post Integer H >= 0. Post-treatment horizons; evaluates event
#'   times e = 0, 1, ..., H with target age a = d + e and control dp = a + 1.
#' @param periods_pre Integer K >= 0 (default 4). Number of pre-treatment horizons.
#'   Evaluates e = -K, ..., -pre with a = d + e. For each pre period, tests the same
#'   control offsets used post, i.e., dp = d + 1, 2, ..., H + 1. Set \code{NULL} to skip pre-trends.
#' @param max_age Integer (default 999). Upper bound; cells with dp > max_age are skipped.
#' @param min_age Integer (default 0). Lower bound; cells with a < min_age are skipped.
#' @param pre Integer (default 1). Pre-treatment anchor used in APO (uses d - pre).
#' @param Y_name,age_name,D_name,id_name,female_name Column name mappings passed to \code{prep_data_table()}.
#' @param verbose Logical (default \code{TRUE}). Print progress messages.
#'
#' @return A \code{data.frame} stacking results from \code{single_treatment_group_analysis()}.
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

  n_post <- length(treatment_groups) * (periods_post + 1L)
  n_pre  <- if (!is.null(periods_pre)) {
    length(treatment_groups) * periods_pre * (periods_post + 1L)
  } else 0L
  n_total <- n_post + n_pre

  results_list <- list()
  idx <- 1
  completed <- 0

  if(verbose) {
    cat(sprintf("\nRunning analysis for %d treatment groups...\n", length(treatment_groups)))
    cat(sprintf("Post-treatment event times: 0 to %d\n", periods_post))
    if (!is.null(periods_pre)) {
      cat(sprintf("Pre-treatment event times: %d to %d (testing %d control groups: d+%d to d+%d)\n",
                  -periods_pre-pre, -1-pre, (periods_post + 1), 1, (periods_post + 1)))
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
        for (offset in 1:(periods_post + 1)) {
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

  # ---- Combine all results; always return data.frame ----
  if (length(results_list) == 0L) {
    if (verbose) cat("No valid result rows produced. Returning empty data.frame.\n")
    return(data.frame())
  }

  result_df <- do.call(rbind, lapply(results_list, function(x) {
    if (is.data.frame(x)) x else as.data.frame(x, stringsAsFactors = FALSE)
  }))

  # Inferential cols
  result_df$ci_l <- result_df$est - 1.96 * result_df$se
  result_df$ci_h <- result_df$est + 1.96 * result_df$se
  result_df$t    <- result_df$est / result_df$se
  result_df$p    <- 2 * stats::pnorm(-abs(result_df$est / result_df$se))
  result_df$event_time <- result_df$a - result_df$d

  # Reorder safely (keep only existing cols) and DO NOT drop dims
  col_order <- c("d","dp","a","event_time",
                 "estimand","method","est","se","ci_l","ci_h","t","p",
                 "n_female_treat","n_female_control","n_male_treat","n_male_control")
  keep <- intersect(col_order, names(result_df))
  result_df <- result_df[, c(keep, setdiff(names(result_df), keep)), drop = FALSE]

  return(result_df)

}
