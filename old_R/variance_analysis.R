library(magrittr)
library(ggplot2)

source('defs.R')


dat <- import_polldat_all() %>% dplyr::filter(Release_Date > "2017-08-01")
# diff <- learn_diffusion(dat)
diff <- 0.00637722
fb_df <- dat %>% run_forward_backward(diff)
parties <- c("CDU_CSU", "SPD", "GRÜNE", "FDP", "LINKE", "AFD")
model_estimates <- fb_df %>%
  dplyr::select(all_of(c("date", parties))) %>%
  tidyr::pivot_longer(all_of(parties), names_to = "party", values_to = "beta_params") %>%
  dplyr::mutate(mean = purrr::map_dbl(beta_params, ~ .x[1] / (.x[1] + .x[2]))) %>%
  dplyr::select(date, party, mean, beta_params)

deviations <- dat %>%
  dplyr::select(Release_Date, all_of(parties), NrParticipants) %>%
  tidyr::pivot_longer(all_of(parties), names_to = "party", values_to = "percent") %>%
  dplyr::inner_join(
    model_estimates,
    by = c("Release_Date" = "date", "party" = "party"),
    suffix = c(".real", ".model")) %>%
  dplyr::mutate(
    stddev = purrr::map2_dbl(beta_params, NrParticipants,
      ~ 100 * sqrt((1.0 / .y) * .x[1] * .x[2] / (.x[1] + .x[2])^2 * (.x[1] + .x[2] + .y) / (.x[1] + .x[2] + 1.0))
    ),
    norm_dev_percent = abs(percent - 100 * mean) / stddev
  )

deviations %>% ggplot() + geom_histogram(aes(norm_dev_percent))

deviations %>% dplyr::summarise(mean_dev = mean(norm_dev_percent))

# Result is 0.733, which means that the poll results are not overdispersed, but underdispersed.
# So there is no evidence for effective poll sizes being lower!



