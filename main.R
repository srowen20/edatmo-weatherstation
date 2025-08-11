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
VERSION <- "V010"

args <- commandArgs(trailingOnly = TRUE)
qc_config <- yaml::read_yaml("qc_config.yml")

if (length(args) >= 1) {
  DATA_ROOT_DIR <- args[[1]]
} else {
  DATA_ROOT_DIR <- Sys.getenv("DATA_ROOT_DIR")
  # DATA_ROOT_DIR <- "C:/Users/willm/OneDrive - University of Edinburgh/UoE/data-root/"
}
if (DATA_ROOT_DIR == "" || is.null(DATA_ROOT_DIR)) {
  stop("DATA_ROOT_DIR must be set as the first command line argument or the DATA_ROOT_DIR environment variable.")
}
if (length(args) >= 2) {
  start_date <- as.Date(args[[2]])
  end_date <- as.Date(args[[3]])
} else {
  start_date <- as.Date(qc_config$dates$start_date)
  end_date <- as.Date(qc_config$dates$end_date)
}

# Define your list of instruments and their serial numbers
instruments <- list(
  list(type = "davis_weewx", serial = "castle_no_sn", file_pattern_strings = NA),
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
  print(paste(start_date, "->", end_date, "..."))
  for (inst in instruments) {
    inst_name <- inst$type
    serial <- inst$serial
    
      # Read and standardise the data for this instrument/serial
    # read in +- 1 days then trim after (inefficient but will catch all required data)
    dat <- standardise_station(
      station_meta[[inst_name]],
      DATA_ROOT_DIR,
      serial,
      start_date - 1,
      end_date + 1
    )
    
    if (is.null(dat) || nrow(dat) == 0) next
    # Aggregate data (adjust time window if needed)
    dat_agg <- agg_time(dat, start_date, end_date, agg_interval = qc_config$dates$agg_interval)
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
    out_file <- file.path(out_dir, paste0(inst$type, "_", inst$serial, "_", start_date, "_", end_date, "_", gsub(" ", "", qc_config$dates$agg_interval), "_", VERSION, ".csv"))
    print(out_file)
    dat_qc$timestamp <- format(dat_qc$timestamp, "%Y-%m-%d %H:%M:%S")
    write.csv(dat_qc, out_file, row.names = FALSE, quote = TRUE)
  }
}
