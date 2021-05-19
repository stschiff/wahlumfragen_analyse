library(magrittr)
library(ggplot2)

source('defs.R')

dat <- import_polldat_all() %>% dplyr::filter(Release_Date > "2017-10-01")

plot_polldat(dat)
diff <- learn_diffusion(dat)
# 0.006124379
diff <- 0.006124379
fb_df <- dat %>% run_forward_backward(diff, projection_dates = "2021-09-20")

plot_model(fb_df)
