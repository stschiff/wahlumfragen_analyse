library(magrittr)
library(ggplot2)

source('defs.R')

dat <- import_polldat_all()

polldat_pivoted <- dat %>%
  tidyr::pivot_longer(cols=c(CDU_CSU, SPD, GRÜNE, FDP, LINKE, AFD), names_to="Party", values_to="Percentage")

ggplot(polldat_pivoted, aes(x=Release_Date, y=Percentage, col=Party)) + geom_point()
  # ggplot(aes(x=Release_Date, y=Percentage, col=Party, shape=polling_institute, size=NrParticipants)) + geom_point() 

forward_df <- dat %>% run_forward(0.001, 1)

CDU_mean_df <- forward_df %>% dplyr::mutate(mean_CDU = purrr::map_dbl(dirichlet_params, ~.x[1]/sum(.x)))

ggplot(polldat_pivoted, aes(x=Release_Date, y=Percentage)) +
  geom_point() + geom_line(data = CDU_mean_df, aes(x = date, y = 100*mean_CDU))

