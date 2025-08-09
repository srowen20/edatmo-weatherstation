# main.R

library(dplyr)
library(lubridate)
library(tidyr)
library(yaml)
library(stringr)

source("station_meta.R")
source("read_functions.R")
source("ingestion.R")
source("qc.R")
VERSION <- "V001"

# todo: do interval stats e.g. t_min, t_max
# todo: add wind gust stats if available 
DATA_ROOT_DIR = "C:/Users/willm/OneDrive - University of Edinburgh/UoE/data-root/"
qc_config <- yaml::read_yaml("qc_config.yml")

# todo: add flexible file_pattern_strings list for each e.g. 
# "RAW/by-castle_no_sn/davis_weewx/{castle_no_sn}/raw_loop/Davis_%Y%m%d_??.dat"
# currently placeholder
# Define your list of instruments and their serial numbers
instruments <- list(
  # list(type = "davis_weewx", serial = "castle_no_sn", file_pattern_strings = NA),
  list(type = "wxt536_jcmb", serial = "1540027", file_pattern_strings = NA),
  list(type = "davis_iot", serial = "jcmb-weather-01", file_pattern_strings = NA),
  list(type = "wxt536_serial", serial = "S0230710", file_pattern_strings = NA)
  # Add more as needed
)

# Define the period of interest
date_seq <- seq.Date(as.Date(qc_config$dates$start_date), as.Date(qc_config$dates$end_date), by = qc_config$out_file$length_days)

for (i in 2:length(date_seq)) {
  start_date <- date_seq[i - 1]
  end_date  <- date_seq[i]
  print(paste(start_date, "->", end_date))
  for (inst in instruments) {
    inst_name <- inst$type
    serial <- inst$serial
    # Read and standardise the data for this instrument/serial
    # read in +- 1 days then trim after. 
    
    dat <- standardise_station(
      station_meta[[inst_name]],
      DATA_ROOT_DIR,
      serial,
      start_date - 1,
      end_date + 1
    )
    
    if (is.null(dat) || nrow(dat) == 0) next
    # Aggregate data (adjust time window if needed)
    dat_agg <- agg_time(dat, start_date, end_date)
    if (is.null(dat_agg) || nrow(dat_agg) == 0) next
    # Apply quality control
    dat_qc <- simple_qc(dat_agg, qc_config$qc_limits)
    # Cut to the given interval
    dat_qc <- dat_qc %>%
      dplyr::filter(between(timestamp, start_date, as.POSIXct(end_date, tz = "UTC") - 0.1))
    if (is.null(dat_qc) || nrow(dat_qc) == 0) next
    # output one file per date interval and per instrument
    out_dir <- file.path(qc_config$out_file$out_dir, VERSION, inst_name, serial)
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    out_file <- file.path(out_dir, paste0(inst$type, "_", inst$serial, "_", start_date, "_", end_date, ".csv"))
    print(out_file)
    dat_qc$timestamp <- format(dat_qc$timestamp, "%Y-%m-%d %H:%M:%S")
    write.csv(dat_qc, out_file, row.names = FALSE, quote = TRUE)
  }
}
