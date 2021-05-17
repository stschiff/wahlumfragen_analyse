library(magrittr)
library(ggplot2)

source('defs.R')

dat <- import_polldat_all() %>% dplyr::filter(Release_Date > "2017-01-01")

parties <- c("CDU_CSU", "SPD", "GRÜNE", "FDP", "LINKE", "AFD")
polldat_pivoted <- pivot_polldat(dat)

cols <- c("black", "red", "green", "yellow", "purple", "blue", "gray")
names(cols) <- parties
ggplot(polldat_pivoted, aes(x=Release_Date, y=Percentage, col=Party)) + geom_point() + scale_colour_manual(values = cols)

diff <- learn_diffusion(dat)
fb_df <- dat %>% run_forward_backward(diff)

marginal_df <- make_marginal_beta_params(fb_df)

ggplot(marginal_df, aes(x = date, y = mean, col=Party)) + geom_line() + scale_colour_manual(values = cols)

ggplot(polldat_pivoted, aes(x=Release_Date, y=Percentage)) +
  geom_point(aes(col=Party)) +
  geom_line(data = posterior_means, aes(x = date, y = 100*mean_CDU, col="black")) +
  geom_line(data = posterior_means, aes(x = date, y = 100*mean_SPD, col="red"))

optimise(function(x) compute_likelihood(dat, x), interval=c(10^-6, 0.1), maximum = TRUE)
# $maximum [1] 0.00654439 $objective [1] -25380.29

