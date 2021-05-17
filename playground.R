library(magrittr)
library(ggplot2)

source('defs.R')

dat <- import_polldat_all() %>% dplyr::filter(Release_Date > "2017-01-01")

plot_polldat(dat)
# diff <- learn_diffusion(dat)
# 0.00654439
diff <- 0.00654439
fb_df <- dat %>% run_forward_backward(diff)

plot_model(fb_df)
