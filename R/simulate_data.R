#' Simulate panel data for child-penalty estimation
#'
#' Generates a balanced panel of annual earnings with life-cycle growth, a gender
#' gap, selection on the timing of first birth, and gendered effects of
#' parenthood, for trying out the estimators.
#'
#' @details
#' Earnings of person \eqn{i} at age \eqn{a} are
#' \deqn{\log Y_{i,a} = \mu_0 + \lambda D_i + \alpha_i + \beta_1 (a - 20) +
#'   \beta_2 (a - 20)^2 + \kappa F_i + \tau_f F_i 1\{a \ge D_i\} +
#'   \tau_m (1 - F_i) 1\{a \ge D_i\} + \varepsilon_{i,a},}{
#'   log Y = mu_0 + lambda D + alpha + beta_1 (a - 20) + beta_2 (a - 20)^2 +
#'   kappa F + tau_f F 1{a >= D} + tau_m (1 - F) 1{a >= D} + eps,}
#' with \eqn{F_i = 1} for women, \eqn{\mu_0 = 10}, \eqn{\lambda = 0.03},
#' \eqn{\beta_1 = 0.08}, \eqn{\beta_2 = -0.003}, \eqn{\kappa = -0.10},
#' \eqn{\tau_f = -0.30}, \eqn{\tau_m = -0.05}, a permanent effect
#' \eqn{\alpha_i \sim N(0, 0.20^2)} and a transitory shock
#' \eqn{\varepsilon_{i,a} \sim N(0, 0.15^2)}. The age at first birth \eqn{D_i} is
#' drawn uniformly from \code{treatment_groups}, independently of gender and
#' \eqn{\alpha_i}; \eqn{\lambda D_i} makes later first births earn more at every
#' age (selection on timing).
#'
#' True values, the same for every treatment group and age after first birth:
#' \eqn{\theta(f) = e^{-0.30} - 1 = -0.259}, \eqn{\theta(m) = e^{-0.05} - 1 =
#' -0.049}, gap \eqn{-0.210}; counterfactual gender earnings ratio
#' \eqn{\rho(\infty) = e^{-0.10} = 0.905}, observed ratio \eqn{\rho(d) = 0.705},
#' effect of parenthood on the ratio \eqn{\rho(d) - \rho(\infty) = -0.200};
#' parenthood's share of the gender gap 0.678. Because \eqn{\lambda D_i} scales
#' earnings levels by group, parallel trends in levels (DID-PT) and TD-PT fail,
#' while NTD-PT, TD-PR and TD-E-LOGS hold.
#'
#' @param n_individuals Whole number \eqn{\ge 2}. Number of individuals (default
#'   10 000), half of them women (rounded).
#' @param treatment_groups Whole numbers \eqn{\ge 21}: ages at first birth (default
#'   \code{24:28}). Ages run from 20 to \code{max(treatment_groups) - 1}, so the
#'   largest group is never observed treated and serves only as a control.
#' @param seed Whole number or \code{NULL}. RNG seed (default 42). The caller's RNG
#'   state is saved and restored on exit, so calling this function does not
#'   alter the global random stream; \code{set.seed()} before the call has no
#'   effect unless \code{seed = NULL}, which draws from the current RNG state.
#'
#' @return A balanced long panel (data.frame), \code{n_individuals} x
#'   (\code{max(treatment_groups)} - 20) rows sorted by id and age, with columns
#'   \code{id}, \code{female} (1 = female), \code{age}, \code{D} (age at first
#'   birth) and \code{Y} (earnings, positive).
#'
#' @seealso \code{\link{multiple_treatment_group_analysis}}
#' @examples
#' \donttest{
#' sim <- simulate_data(n_individuals = 2000)
#' head(sim)
#' range(sim$age)
#' }
#'
#' @export
simulate_data <- function(n_individuals   = 10000,
                          treatment_groups = 24:28,
                          seed            = 42) {

  # Seed for reproducible output, but restore the caller's RNG state on exit so
  # the function has no global side effect (CRAN policy on RNG state).
  if (!is.null(seed)) {
    if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
      on.exit(assign(".Random.seed", old_seed, envir = .GlobalEnv), add = TRUE)
    } else {
      on.exit(
        if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
          rm(".Random.seed", envir = .GlobalEnv)
        },
        add = TRUE
      )
    }
    set.seed(seed)
  }
  if (!is.numeric(n_individuals) || length(n_individuals) != 1L || n_individuals < 2 ||
      n_individuals != round(n_individuals)) {
    stop("`n_individuals` must be one whole number >= 2.", call. = FALSE)
  }
  if (!is.numeric(treatment_groups) || length(treatment_groups) == 0L ||
      any(treatment_groups != round(treatment_groups))) {
    stop("`treatment_groups` must be a vector of whole numbers (ages at first birth).", call. = FALSE)
  }
  treatment_groups <- sort(as.integer(treatment_groups))
  if (min(treatment_groups) < 21) {
    stop("`treatment_groups` must be >= 21: ages start at 20, and the baseline age d - 1 must be observed.",
         call. = FALSE)
  }

  # Age range: 20 to one below the latest treatment group
  age_range <- 20L:(max(treatment_groups) - 1L)

  # ---- Structural parameters (not user-facing) ----------------------------
  mu_0        <- 10.0    # log-earnings intercept
  beta_1      <- 0.08    # age return per year above 20
  beta_2      <- -0.003  # concavity (diminishing returns to experience)
  gamma       <- -0.10   # female log-earnings discount
  lambda      <- 0.03    # selection: per-year-of-D premium in logs
  theta_f     <- -0.30   # female treatment effect in logs (~26% drop)
  theta_m     <- -0.05   # male treatment effect in logs (~5% drop)
  sigma_alpha <- 0.20    # permanent ability SD
  sigma_eps   <- 0.15    # transitory shock SD

  # ---- Individual-level draws ---------------------------------------------
  n_female <- round(n_individuals * 0.5)
  n_male   <- n_individuals - n_female

  individuals <- data.table::data.table(
    id     = seq_len(n_individuals),
    female = c(rep(1L, n_female), rep(0L, n_male)),
    # indexing, not sample(treatment_groups, ...): identical draws, and safe for one group
    D      = treatment_groups[sample.int(length(treatment_groups), n_individuals, replace = TRUE)],
    alpha  = stats::rnorm(n_individuals, 0, sigma_alpha)
  )

  # ---- Expand to panel ----------------------------------------------------
  panel <- individuals[rep(seq_len(.N), each = length(age_range))]
  panel[, age := rep(age_range, n_individuals)]
  data.table::setkey(panel, id, age)

  # ---- Log-earnings -------------------------------------------------------
  a <- panel$age - 20L
  panel[, log_Y := mu_0 + lambda * D + alpha +
                   beta_1 * a + beta_2 * a^2 +
                   gamma * female +
                   data.table::fifelse(female == 1L & age >= D, theta_f, 0) +
                   data.table::fifelse(female == 0L & age >= D, theta_m, 0) +
                   stats::rnorm(.N, 0, sigma_eps)]

  panel[, Y := exp(log_Y)]

  # ---- Return clean output ------------------------------------------------
  out <- panel[, .(id, female, age, D, Y)]
  return(as.data.frame(out))
}
