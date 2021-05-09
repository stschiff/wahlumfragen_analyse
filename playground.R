library(readr)
library(magrittr)

dat <- read_tsv("data/Forsa.txt", col_types = cols(Release_Date = col_date(format = "%d.%m.%Y"), 
                                                   Polling_Start = col_date(format = "%d.%m.%Y"), 
                                                   Polling_End = col_date(format = "%d.%m.%Y"))) %>%
  dplyr::rename(CDU_CSU = `CDU/CSU`)
  
