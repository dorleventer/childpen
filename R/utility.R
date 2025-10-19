#' Prepare analysis data.table with standard column names
#'
#' Standardizes input column names to \code{id}, \code{age}, \code{D},
#' \code{female}, and \code{Y}; coerces types; validates basic conditions; and
#' returns a keyed \code{data.table} ready for the estimators.
#'
#' @param data A \code{data.frame} or \code{data.table}.
#' @param Y_name Character. Column in \code{data} holding the outcome. Default \code{"Y"}.
#' @param age_name Character. Column holding age. Default \code{"age"}.
#' @param D_name Character. Column holding the treatment group (e.g., age-at-treatment).
#'   Will be renamed to \code{D}. Default \code{"D"}.
#' @param id_name Character. Column holding the cluster identifier. Default \code{"id"}.
#' @param female_name Character. Column holding the binary female indicator (1=female).
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

  DT <- data.table::as.data.table(data)

  # Map provided names -> canonical names (id, age, D, female, Y)
  rename_map <- c(
    setNames(id_name,     "id"),
    setNames(age_name,    "age"),
    setNames(D_name,      "D"),
    setNames(female_name, "female"),
    setNames(Y_name,      "Y")
  )

  for (target in names(rename_map)) {
    src <- rename_map[[target]]
    if (!identical(src, target)) {
      if (!src %in% names(DT)) stop(sprintf("prep_data_table(): column '%s' not found in data.", src))
      if (target %in% names(DT) && !identical(src, target)) {
        stop(sprintf("prep_data_table(): target column '%s' already exists; cannot rename '%s' -> '%s'.",
                     target, src, target))
      }
      data.table::setnames(DT, src, target)
    } else {
      if (!src %in% names(DT)) stop(sprintf("prep_data_table(): required column '%s' not found in data.", src))
    }
  }

  # Coerce types
  if (is.factor(DT$id)) DT[, id := as.character(id)]
  if (!is.integer(DT$age)) DT[, age := as.integer(round(age))]
  if (!is.integer(DT$D))   DT[, D   := as.integer(round(D))]
  if (is.logical(DT$female)) DT[, female := as.integer(female)]
  if (is.factor(DT$female))  DT[, female := as.character(female)]
  if (is.character(DT$female)) {
    vals <- tolower(trimws(DT$female))
    DT[, female := as.integer(vals %in% c("1","f","female","w","true","t","yes","y"))]
  }
  if (!is.numeric(DT$female)) DT[, female := as.numeric(female)]
  if (!all(DT$female %in% c(0,1))) stop("'female' must be binary (0/1) after coercion.")

  if (!is.numeric(DT$Y)) {
    suppressWarnings(DT[, Y := as.numeric(Y)])
    if (!is.numeric(DT$Y)) stop("'Y' must be numeric.")
  }

  # Validate required columns
  req <- c("id","age","D","female","Y")
  missing_any <- setdiff(req, names(DT))
  if (length(missing_any)) stop("Missing columns: ", paste(missing_any, collapse=", "))

  # obs_id + key
  DT[, obs_id := paste0(id, "@", age)]
  data.table::setkey(DT, obs_id)

  DT
}
#' @keywords internal
compute_mean_if <- function(DT, age_val, gender, age_d_val, col_name) {
  S <- as.numeric(DT$age == age_val & DT$female == gender & DT$age_d == age_d_val)
  p <- mean(S)
  if (p <= 0) stop(sprintf("Empty subgroup: age=%d, gender=%d, age_d=%d", age_val, gender, age_d_val))

  Y_bar <- mean(S * DT$Y) / p
  psi   <- (S / p) * (DT$Y - Y_bar)

  DT[, (col_name) := psi]
  Y_bar
}

#' @keywords internal
se_cluster <- function(DT, if_col) {
  # cluster sums of the IF
  cluster_scores <- DT[, .(score = sum(get(if_col))), by = id]
  n <- nrow(DT)                 # total observations contributing ψ_i
  G <- nrow(cluster_scores)     # number of clusters
  v_hat <- (sum(cluster_scores$score^2) / (n^2)) * (G / (G - 1))
  sqrt(v_hat)
}
