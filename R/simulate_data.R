#' Simulate panel data for child-penalty estimation
#'
#' Generates a balanced panel of annual earnings designed to show the patterns
#' the paper discusses: selection on the timing of first birth that makes
#' parallel trends fail in the paper's direction, effects of parenthood that
#' differ by age at first birth and fade with time since birth, and a gender
#' earnings ratio that falls with age. The true values are attached, so
#' estimates can be compared with them.
#'
#' @details
#' Earnings of person \eqn{i} with age at first birth \eqn{D_i} at age \eqn{a} are
#' \deqn{\log Y_{i,a} = h_{D_i}(a) + \kappa(a) F_i + \tau_{F_i}(D_i, a - D_i)\,1\{a \ge D_i\}
#'   + \alpha_i + \varepsilon_{i,a},}{
#'   log Y = h_D(a) + kappa(a) F + tau_F(D, a - D) 1{a >= D} + alpha + eps,}
#' with \eqn{F_i = 1} for women and:
#' \itemize{
#'   \item \strong{Career entry and growth} (selection on timing):
#'     \eqn{h_D(a) = 9.6 + 0.02 (a - 20) + \beta(D) x - 0.0015 x^2}, with
#'     experience \eqn{x = \max(a - s(D), 0)}, entry age
#'     \eqn{s(D) = 20 + 0.7 (D - 24)} and slope \eqn{\beta(D) = 0.09 + 0.008 (D - 28)}.
#'     Later first births enter the labor market later (more schooling) and then
#'     grow faster. Before treatment, later groups grow more slowly (they are not
#'     yet working), so pre-treatment DID estimates are negative and grow with the
#'     distance to the control group; after treatment, the later control groups
#'     grow faster, so parallel trends fails with a negative violation for earlier
#'     treatment groups.
#'   \item \strong{Gender gap by age}: \eqn{\kappa(a) = -0.04 - 0.015 \max(a - 25, 0)},
#'     so the female/male ratio absent children is \eqn{e^{\kappa(a)}}: 0.96 up to
#'     age 25, then falling.
#'   \item \strong{Effects of parenthood}: mothers
#'     \eqn{\tau_f(D, e) = -0.45 + 0.02 (D - 24) + 0.04 \min(e, 5)} (smaller for later
#'     first births, fading with event time \eqn{e}); fathers
#'     \eqn{\tau_m = -0.02}. In normalized terms \eqn{\theta(g) = e^{\tau_g} - 1}.
#'   \item \strong{Noise}: \eqn{\alpha_i \sim N(0, 0.20^2)} (permanent),
#'     \eqn{\varepsilon_{i,a} \sim N(0, 0.15^2)} (transitory), independent of
#'     everything else.
#'   \item \strong{Age at first birth}: drawn from \code{treatment_groups} with
#'     probabilities proportional to a normal density with mean 29 and standard
#'     deviation 4, independently of gender.
#' }
#' Under this design DID-PT and TD-PT fail; TD-E-LOGS holds exactly (the gender
#' terms cancel in log means); NTD-PT and TD-PR hold only approximately, because
#' the gender ratio changes with age between the baseline and the target age.
#' The NTD estimator therefore differs slightly from the true effect on the gender
#' earnings ratio (by up to about 0.01 in this design); the attached true values
#' show by how much.
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
#'   birth) and \code{Y} (earnings, positive). Attribute \code{"truth"}: the
#'   population values for every treatment group \code{d} and age
#'   \code{a >= d} (\code{event_time} = a - d): \code{APO_f}, \code{APO_m}
#'   (mean earnings absent children), \code{ATE_f}, \code{ATE_m},
#'   \code{theta_f}, \code{theta_m}, \code{gap_theta}, \code{rho_cf}
#'   (\eqn{\rho(\infty)}), \code{rho_obs} (\eqn{\rho(d)}), \code{rho_effect}
#'   (\eqn{\rho(d) - \rho(\infty)}), \code{share_parenthood}. Attribute
#'   \code{"params"}: the parameter values.
#'
#' @seealso \code{\link{multiple_treatment_group_analysis}}
#' @examples
#' \donttest{
#' sim <- simulate_data(n_individuals = 2000)
#' head(sim)
#' head(attr(sim, "truth"))
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
  treatment_groups <- sort(unique(as.integer(treatment_groups)))
  if (min(treatment_groups) < 21) {
    stop("`treatment_groups` must be >= 21: ages start at 20, and the baseline age d - 1 must be observed.",
         call. = FALSE)
  }

  # Age range: 20 to one below the latest treatment group
  age_range <- 20L:(max(treatment_groups) - 1L)

  # ---- Structural parameters (see Details) ----------------------------------
  par <- list(mu0 = 9.6, g0 = 0.02, s0 = 20, s1 = 0.7, b1 = 0.09, b1D = 0.008, b2 = -0.0015,
              k0 = -0.04, k1 = -0.015, k_age = 25,
              tf0 = -0.45, tfD = 0.02, tfe = 0.04, tm = -0.02,
              sigma_alpha = 0.20, sigma_eps = 0.15, d_mean = 29, d_sd = 4)
  h <- function(D, a) {                       # career entry and growth
    x <- pmax(a - (par$s0 + par$s1 * (D - 24)), 0)
    par$mu0 + par$g0 * (a - 20) + (par$b1 + par$b1D * (D - 28)) * x + par$b2 * x^2
  }
  kappa <- function(a) par$k0 + par$k1 * pmax(a - par$k_age, 0)   # gender gap by age
  tau <- function(female, D, e) {                                 # effects of parenthood
    female <- rep_len(female, length(D))
    ifelse(e < 0, 0, ifelse(female == 1, par$tf0 + par$tfD * (D - 24) + par$tfe * pmin(e, 5), par$tm))
  }

  # ---- Individual-level draws ---------------------------------------------
  n_female <- round(n_individuals * 0.5)
  n_male   <- n_individuals - n_female
  prob_d <- stats::dnorm(treatment_groups, par$d_mean, par$d_sd)

  individuals <- data.table::data.table(
    id     = seq_len(n_individuals),
    female = c(rep(1L, n_female), rep(0L, n_male)),
    # indexing, not sample(treatment_groups, ...): safe for one group
    D      = treatment_groups[sample.int(length(treatment_groups), n_individuals, replace = TRUE,
                                         prob = prob_d)],
    alpha  = stats::rnorm(n_individuals, 0, par$sigma_alpha)
  )

  # ---- Expand to panel ----------------------------------------------------
  panel <- individuals[rep(seq_len(.N), each = length(age_range))]
  panel[, age := rep(age_range, n_individuals)]
  data.table::setkey(panel, id, age)

  # ---- Log-earnings -------------------------------------------------------
  panel[, log_Y := h(D, age) + kappa(age) * female + tau(female, D, age - D) + alpha +
                   stats::rnorm(.N, 0, par$sigma_eps)]
  panel[, Y := exp(log_Y)]

  # ---- True values --------------------------------------------------------
  # E[Y_a(inf) | g, d] = exp(h_d(a) + kappa(a) 1{g = f} + (sigma_alpha^2 + sigma_eps^2) / 2)
  v <- (par$sigma_alpha^2 + par$sigma_eps^2) / 2
  truth <- expand.grid(d = treatment_groups, a = age_range)
  truth <- truth[truth$a >= truth$d, ]
  truth$event_time <- truth$a - truth$d
  truth$APO_f   <- exp(h(truth$d, truth$a) + kappa(truth$a) + v)
  truth$APO_m   <- exp(h(truth$d, truth$a) + v)
  truth$theta_f <- exp(tau(1, truth$d, truth$event_time)) - 1
  truth$theta_m <- exp(tau(0, truth$d, truth$event_time)) - 1
  truth$ATE_f   <- truth$APO_f * truth$theta_f
  truth$ATE_m   <- truth$APO_m * truth$theta_m
  truth$gap_theta <- truth$theta_f - truth$theta_m
  truth$rho_cf  <- truth$APO_f / truth$APO_m
  truth$rho_obs <- truth$rho_cf * (1 + truth$theta_f) / (1 + truth$theta_m)
  truth$rho_effect <- truth$rho_obs - truth$rho_cf
  truth$share_parenthood <- (truth$rho_cf - truth$rho_obs) / (1 - truth$rho_obs)
  truth <- truth[order(truth$d, truth$a), ]
  rownames(truth) <- NULL

  # ---- Return clean output ------------------------------------------------
  out <- as.data.frame(panel[, .(id, female, age, D, Y)])
  attr(out, "truth")  <- truth
  attr(out, "params") <- par
  out
}
