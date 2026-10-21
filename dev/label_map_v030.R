# Label map from the v0.2.x output to v0.3.0 (sourced by dev/snapshot_compare.R when passed as
# its third argument). Applied to every BASELINE result data.frame (one with a `method` column)
# before rows are matched, so a v0.2.x baseline can certify that v0.3.0 numbers are unchanged.
#   methods:   NTD_Conv -> Conventional, NTD_New -> NTD
#   estimands: TD ATE -> gap_ATE; Conventional theta -> gap_theta; Delta_rho -> rho_effect;
#              TD_PR theta_pre -> gap_theta_pre
#   agg_type:  avg_of_ratios, gender_ineq -> weighted_avg
#   removed by design: methods TD_Null and NTD_Conv_Null (rows dropped from the baseline)
relabel_baseline <- function(b) {
  b <- as.data.frame(b)
  removed <- b$method %in% c("TD_Null", "NTD_Conv_Null")
  attr_keep <- attributes(b)[setdiff(names(attributes(b)), c("names", "row.names", "class"))]
  b <- b[!removed, , drop = FALSE]
  for (nm in names(attr_keep)) attr(b, nm) <- attr_keep[[nm]]
  b$method[b$method == "NTD_Conv"] <- "Conventional"
  b$method[b$method == "NTD_New"]  <- "NTD"
  if ("estimand" %in% names(b)) {
    b$estimand[b$method == "TD" & b$estimand == "ATE"] <- "gap_ATE"
    b$estimand[b$method == "Conventional" & b$estimand == "theta"] <- "gap_theta"
    b$estimand[b$estimand == "Delta_rho"] <- "rho_effect"
    b$estimand[b$method == "TD_PR" & b$estimand == "theta_pre"] <- "gap_theta_pre"
  }
  if ("agg_type" %in% names(b)) {
    b$agg_type[b$agg_type %in% c("avg_of_ratios", "gender_ineq")] <- "weighted_avg"
  }
  attr(b, "n_removed_by_design") <- sum(removed)
  b
}
