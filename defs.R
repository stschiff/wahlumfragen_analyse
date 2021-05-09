import_polldat <- function(filename) {
  read_tsv(filename, col_types = cols(Release_Date = col_date(format = "%d.%m.%Y"), 
                                      Polling_Start = col_date(format = "%d.%m.%Y"), 
                                      Polling_End = col_date(format = "%d.%m.%Y")))
}
