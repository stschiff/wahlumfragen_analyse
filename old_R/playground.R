library(magrittr)
library(ggplot2)

source('defs.R')

dat <- import_polldat_all() %>%
  dplyr::filter(Release_Date > "2017-08-01")

diff <- learn_diffusion(dat)
# 0.006368817
diff <- 0.006368817
fb_df <- dat %>% run_forward_backward(diff)

plot_polldat_with_model(dplyr::filter(dat, Release_Date > "2021-01-01"),
                        dplyr::filter(fb_df, date > "2021-01-01"))

dir_params <- projection_dirichlet(fb_df, "2021-09-26")

coalition_prob(dir_params, 10000, c("CDU_CSU", "SPD"))


projection_beta <- projection_beta(fb_df, "2021-09-26")
parties <- c("CDU_CSU", "SPD", "GRÜNE", "FDP", "LINKE", "AFD")
cols <- c("black", "red", "green", "yellow", "purple", "blue")
dplyr::select(projection_beta, party, beta_params) %>%
  dplyr::right_join(
    tidyr::expand_grid(party = parties, x = seq(0, 0.32, 0.001))
  ) %>%
  dplyr::mutate(party = factor(party, levels=parties)) %>% 
  dplyr::mutate(
    y = purrr::map2_dbl(x, beta_params, ~ dbeta(.x, .y[1], .y[2]))
  ) %>%
  ggplot() +
    geom_area(aes(x = x, y = y, fill=party), position='identity', alpha=0.7) +
    scale_fill_manual(values = cols)


largest_party_prob(dir_params, 1000, "CDU")
