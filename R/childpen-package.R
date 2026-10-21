#' childpen: Identification and Estimation of Child Penalties
#'
#' Estimators from Leventer (2025), "Identification of Child Penalties"
#' (\doi{10.48550/arXiv.2602.07486}), for event-study comparisons of parents by
#' age at first birth.
#'
#' The workflow:
#' \enumerate{
#'   \item \code{\link{multiple_treatment_group_analysis}} estimates every 2x2
#'     comparison (treatment group \eqn{d}, closest not-yet-treated control
#'     \eqn{d' = a + 1}, target age \eqn{a}) for a set of treatment groups and
#'     event times, plus pre-treatment validation tests;
#'     \code{\link{single_treatment_group_analysis}} does one comparison.
#'   \item \code{\link{aggregate_estimands}} averages across treatment groups by
#'     event time.
#'   \item \code{\link{bias_bounds}} runs the bias-bounding exercise for the
#'     conventional estimator.
#' }
#' \code{\link{simulate_data}} generates a panel with known true values to try
#' them out. \code{vignette("estimators")} writes out every estimator and its
#' influence function.
#'
#' @keywords internal
"_PACKAGE"
