#' Prepare analysis data.table with standard column names
#'
#' Standardizes input column names to \code{id}, \code{age}, \code{D},
#' \code{female}, and \code{Y}; coerces types; validates the panel; and
#' returns a keyed \code{data.table} ready for the estimators. The input is
#' never modified (a data.table is copied).
#'
#' Validation: every column must exist; \code{female} must be 0/1, logical, or
#' a recognised label (female: "1", "f", "female", "w", "woman", "women", "t",
#' "true", "y", "yes"; male: "0", "m", "male", "man", "men", "false", "n", "no");
#' any other value is an error. Rows with a missing outcome are dropped with a
#' message. A missing or non-finite \code{D} marks a person who never has a
#' child (kept, with a message). \code{id} must not be missing;
#' (\code{id}, \code{age}) must be unique; \code{female} and \code{D} must be
#' constant within \code{id}; both genders must be present.
#'
#' @param data A \code{data.frame} or \code{data.table}.
#' @param Y_name Character. Column in \code{data} holding the outcome. Default \code{"Y"}.
#' @param age_name Character. Column holding age. Default \code{"age"}.
#' @param D_name Character. Column holding the age at first birth (treatment group).
#'   Will be renamed to \code{D}. Default \code{"D"}.
#' @param id_name Character. Column holding the person identifier (clustering unit).
#'   Default \code{"id"}.
#' @param female_name Character. Column holding the female indicator (1 = female).
#'   Default \code{"female"}.
#'
#' @return A \code{data.table} with columns \code{id}, \code{age}, \code{D},
#'   \code{female}, \code{Y}, plus a keyed \code{obs_id = paste0(id, "@", age)}.
#' @keywords internal
prep_data_table <- function(data,
                            Y_name = "Y",
                            age_name = "age",
                            D_name = "D",
                            id_name = "id",
                            female_name = "female") {

  if (!is.data.frame(data)) stop("`data` must be a data.frame or data.table.", call. = FALSE)
  # Work on a copy: data.table operations below modify by reference.
  DT <- if (data.table::is.data.table(data)) data.table::copy(data) else data.table::as.data.table(data)

  # Strip haven_labelled class that arrives when data is loaded via haven::read_dta().
  # We intentionally avoid adding haven as a dependency: the check uses the class
  # string directly.  Each labelled column is coerced to its underlying base type
  # (integer if storage mode is "integer", numeric otherwise) so that subsequent
  # as.integer() / data.table operations work without warnings.
  haven_cols <- names(DT)[vapply(DT, function(col) inherits(col, "haven_labelled"), logical(1))]
  if (length(haven_cols)) {
    for (col in haven_cols) {
      # unclass() drops haven_labelled (and any co-inherited vctrs class) before
      # coercing, so base as.integer()/as.numeric() are used rather than any
      # vctrs dispatch that would error on the labelled class.
      raw <- unclass(DT[[col]])
      if (identical(typeof(raw), "integer")) {
        data.table::set(DT, j = col, value = as.integer(raw))
      } else {
        data.table::set(DT, j = col, value = as.numeric(raw))
      }
    }
  }

  # Map provided names -> canonical names (id, age, D, female, Y)
  arg_of <- c(id = "id_name", age = "age_name", D = "D_name", female = "female_name", Y = "Y_name")
  rename_map <- c(id = id_name, age = age_name, D = D_name, female = female_name, Y = Y_name)
  for (target in names(rename_map)) {
    src <- rename_map[[target]]
    if (!is.character(src) || length(src) != 1L) {
      stop(sprintf("`%s` must be a single column name.", arg_of[[target]]), call. = FALSE)
    }
    if (!src %in% names(DT)) {
      stop(sprintf("Column '%s' (argument `%s`) not found in `data`. Columns in `data`: %s.",
                   src, arg_of[[target]], paste(names(DT), collapse = ", ")), call. = FALSE)
    }
  }
  for (target in names(rename_map)) {
    src <- rename_map[[target]]
    if (!identical(src, target)) {
      if (target %in% names(DT)) {
        stop(sprintf("`data` already has a column '%s'; cannot rename '%s' (argument `%s`) to it.",
                     target, src, arg_of[[target]]), call. = FALSE)
      }
      data.table::setnames(DT, src, target)
    }
  }

  # ---- id -------------------------------------------------------------------
  if (is.factor(DT$id)) DT[, id := as.character(id)]
  if (anyNA(DT$id)) stop(sprintf("%d rows have a missing person id (`%s`).",
                                 sum(is.na(DT$id)), id_name), call. = FALSE)

  # ---- age ------------------------------------------------------------------
  if (!is.numeric(DT$age)) stop(sprintf("Age column '%s' must be numeric.", age_name), call. = FALSE)
  if (anyNA(DT$age)) stop(sprintf("%d rows have a missing age (`%s`).",
                                  sum(is.na(DT$age)), age_name), call. = FALSE)
  if (!is.integer(DT$age)) DT[, age := as.integer(round(age))]

  # ---- D (age at first birth); missing / non-finite = never has a child -------
  if (is.factor(DT$D)) DT[, D := as.character(D)]
  if (is.character(DT$D)) {
    num <- suppressWarnings(as.numeric(DT$D))
    bad <- unique(DT$D[is.na(num) & !is.na(DT$D) & nzchar(trimws(DT$D))])
    if (length(bad)) {
      stop(sprintf("Column '%s' (argument `D_name`) must hold ages at first birth; non-numeric values: %s.",
                   D_name, paste(utils::head(bad, 5), collapse = ", ")), call. = FALSE)
    }
    DT[, D := num]
  }
  if (!is.numeric(DT$D)) stop(sprintf("Column '%s' (argument `D_name`) must be numeric.", D_name), call. = FALSE)
  if (!is.integer(DT$D)) {
    never <- !is.finite(DT$D)
    DT[, D := as.integer(round(data.table::fifelse(never, NA_real_, as.numeric(D))))]
  }
  n_never <- DT[is.na(D), data.table::uniqueN(id)]
  if (n_never > 0L) {
    message(sprintf("%d persons have a missing or infinite `%s`; they are treated as never having a child.",
                    n_never, D_name))
  }

  # ---- female -----------------------------------------------------------------
  if (is.logical(DT$female)) DT[, female := as.integer(female)]
  if (is.factor(DT$female)) DT[, female := as.character(female)]
  if (is.character(DT$female)) {
    vals <- tolower(trimws(DT$female))
    fem  <- c("1", "f", "female", "w", "woman", "women", "t", "true", "y", "yes")
    male <- c("0", "m", "male", "man", "men", "false", "n", "no")
    bad  <- unique(DT$female[!(vals %in% c(fem, male))])
    if (length(bad)) {
      stop(sprintf(paste0("Column '%s' (argument `female_name`) has values that are not a recognised ",
                          "gender label: %s. Use 1/0, TRUE/FALSE, or labels such as \"female\"/\"male\"."),
                   female_name, paste(utils::head(bad, 5), collapse = ", ")), call. = FALSE)
    }
    DT[, female := as.integer(vals %in% fem)]
  }
  if (!is.numeric(DT$female)) DT[, female := as.numeric(female)]
  if (!all(DT$female %in% c(0, 1))) {
    stop(sprintf("Column '%s' (argument `female_name`) must be 1 for women and 0 for men; found: %s.",
                 female_name, paste(utils::head(setdiff(unique(DT$female), c(0, 1)), 5), collapse = ", ")),
         call. = FALSE)
  }

  # ---- Y ----------------------------------------------------------------------
  if (!is.numeric(DT$Y)) {
    stop(sprintf("Outcome column '%s' (argument `Y_name`) must be numeric.", Y_name), call. = FALSE)
  }
  n_na_y <- sum(is.na(DT$Y))
  if (n_na_y > 0L) {
    message(sprintf("Dropping %d rows with a missing outcome (`%s`).", n_na_y, Y_name))
    DT <- DT[!is.na(Y)]
  }

  # ---- panel structure ----------------------------------------------------------
  n_dup <- sum(duplicated(DT, by = c("id", "age")))
  if (n_dup > 0L) {
    stop(sprintf("%d rows repeat an (id, age) pair; `data` must have one row per person and age.",
                 n_dup), call. = FALSE)
  }
  varies <- DT[, .(nf = data.table::uniqueN(female), nd = data.table::uniqueN(D)), by = id]
  if (any(varies$nf > 1L)) {
    stop(sprintf("`%s` varies within person for %d ids; it must be constant within `%s`.",
                 female_name, sum(varies$nf > 1L), id_name), call. = FALSE)
  }
  if (any(varies$nd > 1L)) {
    stop(sprintf("`%s` varies within person for %d ids; it must be constant within `%s`.",
                 D_name, sum(varies$nd > 1L), id_name), call. = FALSE)
  }
  if (!all(c(0, 1) %in% DT$female)) {
    stop("`data` must contain both women (female = 1) and men (female = 0).", call. = FALSE)
  }

  # obs_id + key
  DT[, obs_id := paste0(id, "@", age)]
  data.table::setkey(DT, obs_id)
  data.table::setattr(DT, "childpen_prepared", TRUE)

  DT
}

#' @keywords internal
compute_mean_if <- function(DT, age_val, gender, D_val, col_name) {
  # !is.na(D) first: persons who never have a child (D missing) are in no group
  S <- as.numeric(DT$age == age_val & DT$female == gender & !is.na(DT$D) & DT$D == D_val)
  p <- mean(S)
  if (p <= 0) {
    stop(sprintf("No %s with age at first birth %d observed at age %d.",
                 if (gender == 1) "women" else "men", D_val, age_val), call. = FALSE)
  }

  Y_bar <- mean(S * DT$Y) / p
  psi   <- (S / p) * (DT$Y - Y_bar)

  DT[, (col_name) := psi]
  Y_bar
}

#' @keywords internal
se_cluster <- function(DT, if_col) {
  # cluster sums of the IF
  cluster_scores <- DT[, list(score = sum(get(if_col))), by = id]
  n <- nrow(DT)                 # total observations contributing ψ_i
  G <- nrow(cluster_scores)     # number of clusters
  v_hat <- (sum(cluster_scores$score^2) / (n^2)) * (G / (G - 1))
  sqrt(v_hat)
}
