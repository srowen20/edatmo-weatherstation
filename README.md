# edatmo-weatherstation

R code that reads the raw files from our weather stations, averages them to 5 minutes, applies some basic limits and writes out a cleaned up CSV for each station. Most of it is Will Morrison's. The two changes I made, in September 2026, were fixing the output folder and a crash when a station has no data for the dates asked for.

## What it does

`main.R` loops over the stations listed near the top (a Davis weewx station, the Vaisala WXT536 at JCMB, a Davis IoT station and a second WXT536). For each one it reads the raw files, averages them, flags values outside the limits in `qc_config.yml` and writes one CSV per station per day.

## Running it

```
Rscript main.R <DATA_ROOT_DIR> <start date> <end date>
```

For example `Rscript main.R /path/to/data-root 2026-10-01 2026-10-14`. In the pipeline this is run for you by `run_edatmo_met.sh` in edatmo-automation at 03:00, and by the backfill script. It needs the R packages dplyr, lubridate, tidyr, yaml, stringr, purrr and jsonlite.

## Things to know

- This is not where the pressure files for PROFFAST come from. Those are made by `tools/pressure` in EM27-processing. This repo makes a separate cleaned up weather product.
- The output folder is set in `qc_config.yml` (`out_dir`) and it is currently an absolute path in my own folder. If you run this on another account, change it first or it will try to write there.
- `_qc_config.yml` is a second copy of the settings and the two files are not the same. The code reads `qc_config.yml`.

If you can't open this repo, email sophierowen@outlook.com with your GitHub username.
