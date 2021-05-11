library(magrittr)

import_polldat <- function(polling_institute) {
  filename <- switch(polling_institute,
                     "Allensbach" = "data/Allensbach.txt",
                     "Emnid" = "data/Emnid.txt",
                     "FgWahlen" = "data/FgWahlen.txt",
                     "Forsa" = "data/Forsa.txt",
                     "GMS" = "data/GMS.txt",
                     "Infratest" = "data/Infratest.txt",
                     "Insa" = "data/Insa.txt")
  if(is.null(filename)) {
    stop(paste("Unknown polling institute", polling_institute))
  }
  dat <- readr::read_tsv(filename,
                         col_types = readr::cols(Release_Date = readr::col_date(format = "%d.%m.%Y"),
                                                 Polling_Start = readr::col_date(format = "%d.%m.%Y"),
                                                 Polling_End = readr::col_date(format = "%d.%m.%Y")),
                         na = c("", "NA", "n/a"))
  # Fixing n/a values in NrParticipants in Allensbach and FW/Piraten in Insa
  dat %>%
    tidyr::fill(NrParticipants) %>%
    tidyr::fill(FDP, AFD) %>%
    dplyr::mutate(polling_institute = polling_institute) %>%
    dplyr::select(c(Release_Date, Polling_Start, Polling_End, polling_institute, NrParticipants, CDU_CSU, SPD, GRÜNE, LINKE, FDP, AFD))
}

import_polldat_all <- function() {
  c("Allensbach", "Emnid", "FgWahlen", "Forsa", "GMS", "Infratest", "Insa") %>%
    purrr::map_dfr(~import_polldat(.)) %>%
    dplyr::arrange(Release_Date)
}

update_dirichlet <- function(dirichlet_params, poll_results, eff_size) {
  return(dirichlet_params + poll_results / 100.0 * eff_size)
}

diffuse_dirichlet <- function(dirichlet_params, time, diffusion_constant) {
  A <- sum(dirichlet_params)
  newA <- A * (1.0 + length(dirichlet_params) * diffusion_constant**2 * time) / (1.0 + A * diffusion_constant**2 * time)
  return(dirichlet_params * newA / A)
}

run_forward <- function(input_df,
                        diffusion_constant,
                        size_reduction,
                        date_col = "Release_Date",
                        size_col = "NrParticipants",
                        parties = c("CDU_CSU", "SPD", "GRÜNE", "FDP", "LINKE", "AFD")) {
  n <- nrow(input_df)
  k <- length(parties)
  forward_vec <- vector(mode = "list", n)
  prior <- rep(1.0, k)
  for(i in 1:n) {
    poll_results <- unlist(input_df[i, parties], use.names = FALSE)
    size <- as.numeric(input_df[i, size_col])
    new_dirichlet_params <- update_dirichlet(prior, poll_results, size * size_reduction)
    forward_vec[[i]] <- new_dirichlet_params
    next_diff <- if(i < n) as.numeric(input_df[i + 1, date_col]  - input_df[i, date_col]) else 1
    prior <- diffuse_dirichlet(new_dirichlet_params, next_diff, diffusion_constant)
  }
  return(tibble::tibble(date=input_df[[date_col]], dirichlet_params=forward_vec))
}

