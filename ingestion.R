# ingestion.R
library(dplyr)
library(lubridate)
library(tidyr)
library(stringr)

standardise_station <- function(station_meta_entry, DATA_ROOT_DIR, serial, start_date, end_date) {
  dat <- station_meta_entry$read_func(DATA_ROOT_DIR, serial, start_date, end_date)
  
  if (is.null(dat) || nrow(dat) == 0) return(NULL)
  dat <- dat %>% 
    dplyr::mutate(variable = station_meta_entry$varmap[variable]) %>%
    dplyr::mutate(value = as.numeric(value)) %>%
    na.omit()
  dat
}

agg_time <- function(df, start_date, end_date, agg_interval) {
  df %>%
    na.omit() %>%
    dplyr::mutate(timestamp = lubridate::ceiling_date(timestamp, agg_interval)) %>%
    dplyr::group_by(timestamp, variable) %>%
    dplyr::summarise(
      value = median(as.numeric(value), na.rm = TRUE), 
      .groups = "drop"
    ) %>%
    dplyr::filter(dplyr::between(timestamp, start_date, end_date + 1))
}