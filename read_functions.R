# read_functions.R

# Each function accepts DIR, serial, start_date, end_date
# Date inputs: POSIXct or Date


read_davis_iot <- function(DATA_ROOT_DIR, serial, start_date, end_date) {
  base_dir <- file.path(DATA_ROOT_DIR, "RAW/by-serial/davis-elastic", serial)
  files <- list.files(base_dir, pattern = "\\.csv$", full.names = TRUE)
  
  # For each file, extract the start and end date (format: YYYYMMDD_YYYYMMDD)
  get_range <- function(f) {
    m <- str_match(basename(f), "(\\d{8})_(\\d{8})_.*\\.csv$")
    if (is.na(m[1,1])) return(NULL)
    as.Date(c(m[1,2], m[1,3]), "%Y%m%d")
  }
  ranges <- lapply(files, get_range)
  selected <- sapply(ranges, function(r) between(r[1], start_date - 2, end_date) | between(r[2], start_date - 2, end_date)) 
  files_sel <- files[selected]
  
  if (length(files_sel) == 0) return(NULL)
  data_list <- lapply(files_sel, function(f) {
    df <- read.csv(f)
    df$timestamp <- as.POSIXct(df$timestamp, tz = "UTC")
    df
  })
  data <- bind_rows(data_list)
  data <- data %>% 
    filter(timestamp >= start_date & timestamp <= end_date) %>% 
    select(-c(barTrend, undefined, dayET, forecastIcons, uv), everything())
  
  pivot_longer(
    data,
    cols = -timestamp,
    names_to = "variable",
    values_to = "value"
  )
}

# Helper: turn a .dat line into a named list (works for Davis_yyyymmdd_HH.dat format)
format_line <- function(line_) {
  # Skip lines not containing LOOP:
  if (!grepl("LOOP:", line_)) return(NULL)
  if (grepl("WeeWX", line_)) return(NULL)
  
  # Extract JSON-like part after ') '
  json_part <- sub(".*?\\) ", "", line_)
  # Replace single quotes and parse as JSON
  json_part <- gsub("'([^']+)': '([^']*)'", "\"\\1\": \"\\2\"", json_part)
  json_part <- gsub("'", "\"", json_part)
  
  # Try parse as JSON to list
  data_list <- tryCatch({
    jsonlite::fromJSON(paste0("{", json_part, "}"))
  }, error = function(e) { NULL })
  return(data_list)
}

# For a single file
file_to_df <- function(file_) {
  lines_ <- readLines(file_)
  lines_formatted <- lapply(lines_, format_line)
  # Remove NULLs (non-data lines)
  lines_df <- dplyr::bind_rows(lines_formatted)
  return(lines_df)
}

read_davis_weewx <- function(DATA_ROOT_DIR, serial, start_date, end_date) {
  base_dir <- file.path(DATA_ROOT_DIR, "RAW/by-serial/davis_weewx", serial, "raw_loop")
  files <- list.files(base_dir, pattern = "^Davis_\\d{8}_\\d{2}\\.dat$", full.names = TRUE)
  # Pattern: Davis_YYYYMMDD_HH.dat
  get_datetime <- function(f) {
    m <- str_match(basename(f), "Davis_(\\d{8})_(\\d{2})\\.dat")
    if (is.na(m[1,1])) return(NULL)
    as.POSIXct(paste0(m[1,2], m[1,3]), format = "%Y%m%d%H", tz = "UTC")
  }
  file_datetimes <- as.POSIXct(unlist(lapply(files, get_datetime)), tz = "UTC")
  selected <- between(file_datetimes, start_date, end_date + 1)
  # Select those files overlapping with the interval (liberal: include any overlap in hours)
  files_sel <- files[selected]
  
  if (length(files_sel) == 0) return(NULL)
  
  lines_df_list <- lapply(files_sel, file_to_df)
  dat_df <- dplyr::bind_rows(lines_df_list) %>%
    dplyr::mutate(time = as.POSIXct(as.integer(dateTime), origin="1970-01-01", tz="UTC"))
  dat_df <- dat_df %>% filter(time >= start_date & time <= end_date)
  
  pivot_longer(
    dat_df,
    cols = -time,
    names_to = "variable",
    values_to = "value"
  ) %>% rename(timestamp = time)
}

parse_wxt_serial_file <- function(filename) {
  lines <- readLines(filename)
  file_datetime <- strptime(str_extract(filename, "\\d{8}_\\d{2}"), "%Y%m%d_%H", tz = "UTC")
  
  parse_line <- function(line) {
    parts <- strsplit(line, ";\\s*|,")[[1]]
    if (length(parts) < 2) return(NULL)
    time_str <- parts[1]
    # Calculate full timestamp
    full_timestamp <- strptime(paste0(as.Date(file_datetime), time_str), format = "%Y-%m-%d%H%M%S", tz = "UTC")
    if (lubridate::hour(full_timestamp) != lubridate::hour(file_datetime)) return(NULL)
    
    # Extract relevant data
    data <- str_extract_all(paste(parts[-1], collapse = ","), "(Dn|Dm|Dx|Ta|Tp|Ua|Pa|Sn|Sm|Sx|Ri)=-?\\d+\\.?\\d*")
    
    data <- unlist(data)
    
    data_frame <- tibble(Timestamp = full_timestamp)
    for (d in data) {
      key_value <- strsplit(d, "=")[[1]]
      key <- key_value[1]
      value <- as.numeric(key_value[2])
      data_frame[[key]] <- value
    }
    return(data_frame)
  }
  
  map_dfr(lines, parse_line)
}

read_wxt536_serial <- function(DATA_ROOT_DIR, serial, start_date, end_date) {
  base_dir <- file.path(DATA_ROOT_DIR, "RAW/by-serial/WXT536", serial)
  files <- list.files(base_dir, pattern = "^WXT536_.*_\\d{8}_\\d{2}\\.dat$", full.names = TRUE)
  # Pattern: WXT536_<serial>_YYYYMMDD_HH.dat
  get_datetime <- function(f) {
    m <- str_match(basename(f), "WXT536_.*_(\\d{8})_(\\d{2})\\.dat")
    if (is.na(m[1,1])) return(NULL)
    as.POSIXct(paste0(m[1,2], m[1,3]), format = "%Y%m%d%H", tz = "UTC")
  }
  file_datetimes <- as.POSIXct(unlist(lapply(files, get_datetime)), tz = "UTC")
  selected <- between(file_datetimes, start_date, end_date)
  files_sel <- files[selected]

    if (length(files_sel) == 0) return(NULL)
  
  all_data <- purrr::map_dfr(files_sel, parse_wxt_serial_file)
  all_data <- all_data %>% filter(Timestamp >= start_date & Timestamp <= end_date)
  pivot_longer(
    all_data,
    cols = -Timestamp,
    names_to = "variable",
    values_to = "value"
  ) %>% rename(timestamp = Timestamp)
}


read_WXT536_jcmb <- function(DATA_ROOT_DIR, serial, start_date, end_date) {
  base_dir <- file.path(DATA_ROOT_DIR, "RAW/by-serial/WXT536", serial, "weatherstation")
  files <- list.files(base_dir, pattern = "_minute_data\\.csv$", full.names = TRUE)
  get_file_date <- function(f) {
    m <- str_match(basename(f), "^(\\d{4}-\\d{2}-\\d{2})_minute_data\\.csv$")
    if (is.na(m[1,1])) return(NULL)
    as.Date(m[1,2])
  }
  browser() # hereiam - check all date reads are good. don't write parts of a day. 
  file_dates <- as.Date(unlist(lapply(files, get_file_date)))
  selected <- between(file_dates, start_date, end_date)
  files_sel <- files[selected]
  
  if (length(files_sel) == 0) return(NULL)
  data_list <- lapply(files_sel, function(f) {
    df <- read.csv(f, skip = 2, header = FALSE)
    col_names <- read.csv(f, nrows = 1, header = TRUE)
    colnames(df) <- colnames(col_names)
    df$Date.Time <- as.POSIXct(df$Date.Time)
    df
  })
  browser()
  data <- bind_rows(data_list) %>% filter(Date.Time >= start_date & Date.Time <= end_date)
  pivot_longer(
    data,
    cols = -Date.Time,
    names_to = "variable",
    values_to = "value"
  ) %>% rename(timestamp = Date.Time)
}

