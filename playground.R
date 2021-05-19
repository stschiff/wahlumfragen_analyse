library(magrittr)
library(ggplot2)

source('defs.R')

dat <- import_polldat_all() %>% dplyr::filter(Release_Date > "2017-08-01")

plot_polldat(dat)
diff <- learn_diffusion(dat)
# 0.006124379
diff <- 0.006124379
fb_df <- dat %>% run_forward_backward(diff,
                                      projection_dates = c("2021-06-01", "2021-07-01", "2021-08-01", "2021-09-01"))

plot_model(fb_df)
