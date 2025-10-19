#' Simulate panel data for child-penalty estimators
#'
#' Generates a panel of individuals over ages with gender, treatment group, and
#' earnings. The data-generating process uses a male baseline earnings profile,
#' female penalty parameters with partial recovery, and AR(1) shocks in logs.
#' @param n_individuals Integer. Number of individuals to simulate (default \code{10000}).
#' @param seed Integer. RNG seed.
#'
#' @details
#' For females, an individual-specific initial penalty is drawn \eqn{\sim N(-0.30, 0.15^2)}
#' at treatment age, and partial recovery increases earnings by \code{0.02} per year since birth:
#' \deqn{ \text{penalty\_pct}_{i,a} = \text{initial\_penalty}_i + 0.02 \cdot (a - D_i) \;\; \text{for } a \ge D_i.}
#' Observed earnings are \eqn{Y_{i,a} = Y_{\infty,i,a} \cdot (1 + \text{penalty\_pct}_{i,a})}.
#'
#' @return A \code{data.frame} with columns:
#' \itemize{
#'   \item \code{id} (individual id),
#'   \item \code{female} (0/1),
#'   \item \code{age} (integer),
#'   \item \code{D} (treatment age group; renamed from \code{age_d} for consistency),
#'   \item \code{Y_inf} (counterfactual earnings absent penalties),
#'   \item \code{Y} (observed earnings).
#' }
#'
#' @examples
#' \dontrun{
#' set.seed(1)
#' sim <- simulate_data(n_individuals = 2000)
#' head(sim)
#' }
#'
#' @export
simulate_data <- function(male_profiles   = NULL,
                          female_params   = NULL,
                          variance_params = NULL,
                          n_individuals   = 10000,
                          seed            = 42) {


  male_profiles   <- get("male_profiles",   envir = asNamespace("childpen"))
  female_params   <- get("female_params",   envir = asNamespace("childpen"))
  variance_params <- get("variance_params", envir = asNamespace("childpen"))

  age_range <- 20:40

  # Extract parameters
  sigma_alpha <- variance_params$sigma_alpha_log
  rho         <- variance_params$rho
  sigma_nu    <- variance_params$sigma_nu_log

  treatment_groups <- sort(unique(male_profiles$age_d))

  # Assign gender counts
  n_female <- round(n_individuals * 0.5)
  n_male   <- n_individuals - n_female

  # Assign treatment groups at random
  age_d <- sample(treatment_groups, n_individuals, replace = TRUE)

  # Individuals
  individuals <- data.table::data.table(
    id     = seq_len(n_individuals),
    female = c(rep(1L, n_female), rep(0L, n_male)),
    age_d  = age_d,
    alpha_i = stats::rnorm(n_individuals, 0, sigma_alpha)
  )

  # Expand to panel
  panel <- individuals[rep(1:.N, each = length(age_range))]
  panel[, age := rep(age_range, n_individuals)]
  data.table::setkey(panel, id, age)

  # Merge male profiles
  panel <- merge(panel, data.table::as.data.table(male_profiles), by = "age_d", all.x = TRUE)

  # Male baseline (logs)
  panel[, log_Y_inf_male := b0 + b1*age + b2*age^2 + b3*age^3]

  # Female ratio path
  gap_start <- female_params$gap_start_age
  gap_rate  <- female_params$gap_rate
  min_ratio <- female_params$min_ratio

  panel[, ratio := ifelse(age <= gap_start, 1.0,
                          pmax(min_ratio, 1.0 - gap_rate * (age - gap_start)))]

  # Baseline (logs), before individual effects
  panel[, log_Y_inf_base := ifelse(female == 1,
                                   log_Y_inf_male + log(ratio),
                                   log_Y_inf_male)]

  # AR(1) shocks in logs (vectorized)
  n_periods <- length(age_range)
  n_indiv   <- panel[, data.table::uniqueN(id)]

  eps_matrix <- matrix(0, nrow = n_periods, ncol = n_indiv)
  eps_matrix[1, ] <- stats::rnorm(n_indiv, 0, sigma_nu / sqrt(1 - rho^2))
  for (t in 2:n_periods) {
    eps_matrix[t, ] <- rho * eps_matrix[t - 1, ] + stats::rnorm(n_indiv, 0, sigma_nu)
  }
  panel[, epsilon := as.vector(t(eps_matrix))]

  # Final Y_inf
  panel[, Y_inf := exp(log_Y_inf_base + alpha_i + epsilon)]

  # Female penalties: id-specific initial penalty + recovery
  unique_mothers <- unique(panel[female == 1, .(id)])
  unique_mothers[, initial_penalty := stats::rnorm(.N, mean = -0.30, sd = 0.15)]
  panel <- merge(panel, unique_mothers, by = "id", all.x = TRUE)

  panel[female == 1 & age >= age_d,
        penalty_pct := initial_penalty + 0.02 * (age - age_d)]
  panel[is.na(penalty_pct), penalty_pct := 0]

  # Observed earnings
  panel[, Y := Y_inf * (1 + penalty_pct)]

  # Return (rename age_d -> D for package consistency)
  out <- panel[, .(id, female, age, D = age_d, Y_inf, Y)]
  return(as.data.frame(out))
}
