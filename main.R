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

DATA_ROOT_DIR = "C:/Users/willm/OneDrive - University of Edinburgh/UoE/data-root/"
qc_limits <- yaml::read_yaml("qc_config.yml")

# todo: add flexible file_pattern_strings list for each e.g. 
# "RAW/by-castle_no_sn/davis_weewx/{castle_no_sn}/raw_loop/Davis_%Y%m%d_??.dat"
# currently placeholder
# Define your list of instruments and their serial numbers
instruments <- list(
  # list(type = "davis_weewx", serial = "castle_no_sn", file_pattern_strings = NA),
  # list(type = "wxt536_jcmb", serial = "1540027", file_pattern_strings = NA),
  # list(type = "davis_iot", serial = "jcmb-weather-01", file_pattern_strings = NA),
  list(type = "wxt536_serial", serial = "S0230710", file_pattern_strings = NA)
  # Add more as needed
)

# Define the period of interest
start_date <- as.Date("2025-03-08")
end_date  <- as.Date("2025-07-09")

for (inst in instruments) {
  inst_name <- inst$type
  serial <- inst$serial
  # Read and standardise the data for this instrument/serial
  dat <- standardise_station(
    station_meta[[inst_name]],
    DATA_ROOT_DIR,
    serial,
    start_date,
    end_date
  )
  
  if (is.null(dat) || nrow(dat) == 0) next
  
  # Aggregate data (adjust time window if needed)
  dat_agg <- agg_time(dat, start_date, end_date)
  # Apply quality control
  dat_qc <- simple_qc(dat_agg, qc_limits)
  
  # Split by day and output one file per day per instrument
  dat_qc$day <- as.Date(dat_qc$timestamp)
  day_list <- split(dat_qc, dat_qc$day)
  for (day in names(day_list)) {
    day_data <- day_list[[day]]
    if (nrow(day_data) < 10) next
    out_dir <- file.path("OUTPUT", inst_name, serial)
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    out_file <- file.path(out_dir, paste0(as.character(day), ".csv"))
    write.csv(day_data, out_file, row.names = FALSE)
  }
}
