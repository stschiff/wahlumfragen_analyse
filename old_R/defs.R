library(magrittr)
library(ggplot2)


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
    dplyr::select(c(Release_Date, Polling_Start, Polling_End, polling_institute, NrParticipants,
                    CDU_CSU, SPD, GRÜNE, LINKE, FDP, AFD)) %>%
    dplyr::mutate(SONSTIGE = 100.0 - CDU_CSU - SPD - GRÜNE - LINKE - FDP - AFD) %>%
    dplyr::arrange(Release_Date)
}

import_polldat_all <- function() {
  c("Allensbach", "Emnid", "FgWahlen", "Forsa", "GMS", "Infratest", "Insa") %>%
    purrr::map_dfr(~import_polldat(.)) %>%
    dplyr::arrange(Release_Date)
}

import_election_dat <- function() {
  readr::read_tsv("data/Wahlergebnisse.txt",
                  col_types = readr::cols(Date = readr::col_date(format = "%d.%m.%Y")))
}

update_dirichlet <- function(dirichlet_params, poll_results, poll_size) {
  return(dirichlet_params + poll_results / 100.0 * poll_size)
}

diffuse_dirichlet <- function(dirichlet_params, time, diffusion_constant) {
  A <- sum(dirichlet_params)
  newA <- A * (1.0 + length(dirichlet_params) * diffusion_constant**2 * time) / (1.0 + A * diffusion_constant**2 * time)
  return(dirichlet_params * newA / A)
}

diffuse_dirichlet2 <- function(dirichlet_params, time, diffusion_constant) {
  A <- sum(dirichlet_params)
  k <- length(dirichlet_params)
  newA <- pmax(k, (A - diffusion_constant**2 * time * (A + 1)) / (1.0 + diffusion_constant**2 * time * (A + 1)))
  return(dirichlet_params * newA / A)
}

compute_logl_part <- function(pollVec, N, alphaVec) {
  nVec <- pollVec / 100.0 * N
  A <- sum(alphaVec)
  return(lgamma(A) + lgamma(N + 1) - lgamma(A + N) +
    sum(lgamma(nVec + alphaVec)) - sum(lgamma(alphaVec)) - sum(lgamma(nVec + 1)))
}

compute_likelihood <- function(input_df,
                               diffusion_constant,
                               diffusion_fun = diffuse_dirichlet2,
                               date_col = "Release_Date",
                               size_col = "NrParticipants",
                               parties = c("CDU_CSU", "SPD", "GRÜNE", "FDP", "LINKE", "AFD", "SONSTIGE")) {
  n <- nrow(input_df)
  k <- length(parties)
  prior <- rep(1.0, k)
  res <- 0
  for(i in 1:n) {
    poll_results <- unlist(input_df[i, parties], use.names = FALSE)
    size <- as.numeric(input_df[i, size_col])
    res <- res + compute_logl_part(poll_results, size, prior)
    new_dirichlet_params <- update_dirichlet(prior, poll_results, size)
    next_diff <- if(i < n) as.numeric(input_df[i + 1, date_col]  - input_df[i, date_col]) else 1
    if(next_diff < 0) stop("Error in forward algorithm: Input data must be date-sorted")
    prior <- diffusion_fun(new_dirichlet_params, next_diff, diffusion_constant)
  }
  return(res)
}

learn_diffusion <- function(input_df,
                            diffusion_fun = diffuse_dirichlet2,
                            date_col = "Release_Date",
                            size_col = "NrParticipants",
                            parties = c("CDU_CSU", "SPD", "GRÜNE", "FDP", "LINKE", "AFD", "SONSTIGE")) {
  fun <- function(d) {compute_likelihood(input_df, d, diffusion_fun, date_col, size_col, parties)}
  result <- optimise(fun, interval=c(10^-6, 0.1), maximum = TRUE)
  return(result$maximum)
}

run_forward <- function(input_df,
                        diffusion_constant,
                        diffusion_fun = diffuse_dirichlet2,
                        date_col = "Release_Date",
                        size_col = "NrParticipants",
                        parties = c("CDU_CSU", "SPD", "GRÜNE", "FDP", "LINKE", "AFD", "SONSTIGE")) {
  n <- nrow(input_df)
  k <- length(parties)
  forward_vec <- vector(mode = "list", n)
  prior <- rep(1.0, k)
  for(i in 1:n) {
    poll_results <- unlist(input_df[i, parties], use.names = FALSE)
    size <- as.numeric(input_df[i, size_col])
    new_dirichlet_params <- update_dirichlet(prior, poll_results, size)
    forward_vec[[i]] <- new_dirichlet_params
    next_diff <- if(i < n) as.numeric(input_df[i + 1, date_col]  - input_df[i, date_col]) else 1
    if(next_diff < 0) stop("Error in forward algorithm: Input data must be date-sorted")
    prior <- diffusion_fun(new_dirichlet_params, next_diff, diffusion_constant)
  }
  return(forward_vec)
}

run_backward <- function(input_df,
                         diffusion_constant,
                         diffusion_fun = diffuse_dirichlet2,
                         date_col = "Release_Date",
                         size_col = "NrParticipants",
                         parties = c("CDU_CSU", "SPD", "GRÜNE", "FDP", "LINKE", "AFD", "SONSTIGE")) {
  n <- nrow(input_df)
  k <- length(parties)
  backward_vec <- vector(mode = "list", n)
  prior <- rep(1.0, k)
  for(i in n:1) {
    backward_vec[[i]] <- prior
    poll_results <- unlist(input_df[i, parties], use.names = FALSE)
    size <- as.numeric(input_df[i, size_col])
    new_dirichlet_params <- update_dirichlet(prior, poll_results, size)
    next_diff <- if(i > 1) as.numeric(input_df[i, date_col]  - input_df[i - 1, date_col]) else 1
    if(next_diff < 0) stop("Error in backward algorithm: Input data must be date-sorted")
    prior <- diffusion_fun(new_dirichlet_params, next_diff, diffusion_constant)
  }
  return(backward_vec)
}

run_forward_backward <- function(input_df,
                                 diffusion_constant,
                                 diffusion_fun = diffuse_dirichlet2,
                                 date_col = "Release_Date",
                                 size_col = "NrParticipants",
                                 parties = c("CDU_CSU", "SPD", "GRÜNE", "FDP", "LINKE", "AFD", "SONSTIGE")) {
  forward_vec_ <- run_forward(input_df, diffusion_constant, diffusion_fun, date_col, size_col, parties)
  backward_vec_ <- run_backward(input_df, diffusion_constant, diffusion_fun, date_col, size_col, parties)
  dates <- input_df[[date_col]]
  # Getting rid of double dates because of multiple polls per day
  ret <- tibble::tibble(date = dates, forward_vec = forward_vec_, backward_vec = backward_vec_) %>%
    dplyr::group_by(date) %>%
    dplyr::summarise(
      forward_vec = forward_vec[length(forward_vec)],
      backward_vec = backward_vec[length(backward_vec)]
    ) %>%
    dplyr::mutate(posterior = purrr::map2(forward_vec, backward_vec, ~ .x + .y - 1))
  for (i in 1:length(parties)) {
    partyName <- parties[i]
    b1 <- purrr::map_dbl(ret$posterior, ~ .x[i])
    b2 <- purrr::map_dbl(ret$posterior, ~ sum(.x) - .x[i])
    ret <- dplyr::mutate(ret, "{partyName}" := purrr::map2(b1, b2, ~ c(.x, .y)))
  }
  return(ret)
}

plot_polldat <- function(input_df,
                         date_col = "Release_Date") {
  
  parties <- c("CDU_CSU", "SPD", "GRÜNE", "FDP", "LINKE", "AFD")
  pivoted_polldat <- input_df %>% dplyr::select(all_of(c(date_col, parties))) %>%
    tidyr::pivot_longer(cols=all_of(parties), names_to="Party", values_to="Percentage") %>%
    dplyr::mutate(Party = factor(Party, levels=parties))
  
  cols <- c("black", "red", "green", "yellow", "purple", "blue")
  names(cols) <- parties
  
  ggplot(pivoted_polldat) +
    geom_point(aes(x=.data[[date_col]], y=Percentage, col=Party)) +
    scale_colour_manual(values = cols)
}

plot_model <- function(fb_df,
                       date_col = "date") {
  
  parties <- c("CDU_CSU", "SPD", "GRÜNE", "FDP", "LINKE", "AFD")
  cols <- c("black", "red", "green", "yellow", "purple", "blue", "gray")
  names(cols) <- parties

  plot_dat <- fb_df %>%
    dplyr::select(all_of(c(date_col, parties))) %>%
    tidyr::pivot_longer(cols = all_of(parties), names_to = "Party", values_to = "beta_params") %>%
    dplyr::mutate(
      Party = factor(Party, levels=parties),
      mean = purrr::map_dbl(beta_params, ~ .x[1] / (.x[1] + .x[2])),
      q025 = purrr::map_dbl(beta_params, ~ qbeta(0.025, .x[1], .x[2])),
      q50 = purrr::map_dbl(beta_params, ~ qbeta(0.5, .x[1], .x[2])),
      q975 = purrr::map_dbl(beta_params, ~ qbeta(0.975, .x[1], .x[2]))
    )
  
  ggplot(plot_dat, aes(x = .data[[date_col]], y = mean)) +
    geom_ribbon(aes(ymin=q025, ymax=q975, fill = Party), alpha=0.5) +
    scale_fill_manual(values = cols)
}

plot_polldat_with_model <- function(input_df,
                                    fb_df,
                                    date_col1 = "Release_Date",
                                    date_col2 = "date") {

  parties <- c("CDU_CSU", "SPD", "GRÜNE", "FDP", "LINKE", "AFD")
  pivoted_polldat <- input_df %>% dplyr::select(all_of(c(date_col1, parties))) %>%
    tidyr::pivot_longer(cols=all_of(parties), names_to="Party", values_to="Percentage") %>%
    dplyr::mutate(Party = factor(Party, levels=parties))
  
  cols <- c("black", "red", "green", "yellow", "purple", "blue")
  names(cols) <- parties
  
  model_plot_dat <- fb_df %>%
    dplyr::select(all_of(c(date_col2, parties))) %>%
    tidyr::pivot_longer(cols = all_of(parties), names_to = "Party", values_to = "beta_params") %>%
    dplyr::mutate(
      Party = factor(Party, levels=parties),
      mean = purrr::map_dbl(beta_params, ~ .x[1] / (.x[1] + .x[2])),
      q025 = purrr::map_dbl(beta_params, ~ qbeta(0.025, .x[1], .x[2])),
      q50 = purrr::map_dbl(beta_params, ~ qbeta(0.5, .x[1], .x[2])),
      q975 = purrr::map_dbl(beta_params, ~ qbeta(0.975, .x[1], .x[2]))
    )
  
  ggplot(pivoted_polldat) +
    geom_point(aes(x=.data[[date_col1]], y=Percentage, col=Party), alpha = 0.3) +
    scale_colour_manual(values = cols) +
    geom_ribbon(data = model_plot_dat,
                aes(x = .data[[date_col2]],
                    y = 100 * mean,
                    ymin = 100 * q025,
                    ymax = 100 * q975, fill = Party),
                alpha = 0.7) +
    scale_fill_manual(values = cols)
}

projection_dirichlet <-function(fb_df,
                                projection_date_str,
                                date_col = "date",
                                posterior_col = "posterior") {
  final_date <- tail(fb_df[[date_col]], n=1)
  final_dirichlet_params <- tail(fb_df[[posterior_col]], n=1)[[1]]
  projection_date <- as.Date(projection_date_str)
  diff_days <- as.numeric(projection_date - final_date)
  diffuse_dirichlet2(final_dirichlet_params, diff_days, diff)
}

projection_beta <- function(fb_df,
                             projection_date_str,
                             date_col = "date",
                             posterior_col = "posterior") {
  projected_dirichlet_params <- projection_dirichlet(fb_df, projection_date_str, date_col, posterior_col)
  
  parties <- c("CDU_CSU", "SPD", "GRÜNE", "FDP", "LINKE", "AFD")
  tibble::tibble(
    party = parties,
    beta_params = purrr::map2(parties,
                              1:length(parties),
                              ~ c(projected_dirichlet_params[.y],
                                  sum(projected_dirichlet_params) - projected_dirichlet_params[.y])),
    q025 = purrr::map_dbl(beta_params, ~ qbeta(0.025, .x[1], .x[2])),
    q50 = purrr::map_dbl(beta_params, ~ qbeta(0.5, .x[1], .x[2])),
    q975 = purrr::map_dbl(beta_params, ~ qbeta(0.975, .x[1], .x[2]))
  )
}

projection_simulation <- function(fb_df,
                                  projection_date_str,
                                  boost_size = 0.01,
                                  ndraws = 10000,
                                  date_col = "date",
                                  posterior_col = "posterior") {
  projected_dirichlet_params <- projection_dirichlet(fb_df, projection_date_str, date_col, posterior_col)
  random_props <- gtools::rdirichlet(ndraws, dir_params)[,1:6]
  
  
  parties <- c("CDU_CSU", "SPD", "GRÜNE", "FDP", "LINKE", "AFD")
  
}

coalition_probs <- function(dir_params, ndraws) {
  random_props <- gtools::rdirichlet(ndraws, dir_params)[,1:6]
  random_props[random_props < 0.05] <- 0.0
  norm_facs <- rowSums(random_props)
  random_props_norm <- random_props / norm_facs
  parties <- c("CDU_CSU", "SPD", "GRÜNE", "FDP", "LINKE", "AFD")
  coalitions = list(
    c("CDU_CSU", "SPD"),
    c("CDU_CSU", "SPD", "GRÜNE"),
    c("SPD", "GRÜNE"),
    c("SPD", "GRÜNE", "FDP"),
    c("CDU_CSU", "FDP"),
    c("CDU_CSU", "FDP", "GRÜNE"),
    c("CDU_CSU", "FDP", "SPD"),
    c("SPD", "LINKE"),
    c("SPD", "GRÜNE", "LINKE")
  )
  probs = purrr::map_dbl(coalitions, function(coalition) {
    coalition_i <- match(coalition, parties)
    sum(rowSums(random_props_norm[,coalition_i]) > 0.5) / ndraws
  })
  tibble::tibble(
    name = purrr::map_chr(coalitions, ~ paste(.x, collapse=' + ')),
    probs = probs
  )
}

largest_party_probs <- function(dir_params, ndraws) {
  random_props <- gtools::rdirichlet(ndraws, dir_params)[,1:6]
  res <- purrr::map_dbl(1:6, function(party_i) {
    sum(apply((random_props - random_props[,party_i]) <= 0, 1, all)) / ndraws
  })
  tibble::tibble(
    parties = c("CDU_CSU", "SPD", "GRÜNE", "FDP", "LINKE", "AFD"),
    prob = res
  )
}

