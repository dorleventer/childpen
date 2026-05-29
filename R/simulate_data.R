#' Simulate panel data for child-penalty estimation
#'
#' Generates a balanced panel with lifecycle earnings, a gender gap, selection
#' on treatment timing, and gendered treatment effects. The DGP is:
#'
#' \deqn{\log Y_{it} = \mu_0 + \lambda D_i + \alpha_i
#'   + \beta_1 (a - 20) + \beta_2 (a - 20)^2
#'   + \gamma \cdot \mathbf{1}[f]
#'   + \theta_f \cdot \mathbf{1}[f, a \ge D]
#'   + \theta_m \cdot \mathbf{1}[m, a \ge D]
#'   + \varepsilon_{it}}
#'
#' where \eqn{\alpha_i \sim N(0,\sigma_\alpha^2)} is a permanent individual
#' effect and \eqn{\varepsilon_{it} \sim N(0,\sigma_\varepsilon^2)} is a
#' transitory shock. The term \eqn{\lambda D_i} generates positive selection
#' on treatment timing: individuals who have children later earn more, on
#' average, than those who have children earlier.
#'
#' @param n_individuals Integer. Number of individuals (default 10 000).
#' @param treatment_groups Integer vector. Treatment groups to include
#'   (default \code{24:28}).
#' @param seed Integer or \code{NULL}. RNG seed (default 42). The caller's RNG
#'   state is saved and restored on exit, so calling this function does not
#'   alter the global random stream. Set to \code{NULL} to draw from the
#'   current RNG state without reseeding.
#'
#' @return A \code{data.frame} with columns \code{id}, \code{female},
#'   \code{age}, \code{D}, \code{Y}.
#'
#' @examples
#' \donttest{
#' sim <- simulate_data(n_individuals = 2000)
#' head(sim)
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
  treatment_groups <- sort(as.integer(treatment_groups))

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
    D      = sample(treatment_groups, n_individuals, replace = TRUE),
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
