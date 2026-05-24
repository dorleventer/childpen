utils::globalVariables(c(
  ".", "id","age","D","female","Y","obs_id",
  "if_y_d_minus_1_f_d","if_y_d_minus_1_m_d","if_y_a_f_d","if_y_a_m_d",
  "if_y_a_f_dp","if_y_a_m_dp","if_y_d_minus_1_f_dp","if_y_d_minus_1_m_dp",
  "if_apo_f","if_apo_m","if_ate_f","if_ate_m","if_theta_f","if_theta_m",
  "if_td","if_ntd_conv","if_ratio_y","if_ratio_apo","if_ntd_new",
  "if_td_null_apo","if_td_null_ate","if_td_null_theta",
  "if_ntd_conv_null_apo","if_ntd_conv_null_ate","if_ntd_conv_null_theta",
  # aggregate_estimands() columns
  "agg_type", "n_groups",
  "est_ate", "se_ate", "est_apo", "se_apo",
  "event_time", "estimand", "method", "est", "se", "ci_l", "ci_h", "d",
  "w", "wt", "wt_col", "weighted_score", "agg_score", "agg_ate", "agg_apo", "ratio_if",
  "n_gd", "n_d", "B_own", "prop_contrib", "term1",
  # simulate_data() columns
  "alpha", "log_Y"
))
