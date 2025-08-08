# station_meta.R
source("read_functions.R")

station_meta <- list(
  "davis_iot" = list(
    read_func = read_davis_iot,
    varmap = c(
      "outsideHumidity" = "RH (%)",
      "outsideTemperature" = "Tair (degC)", 
      "pressure" = "press (hPa)",
      "rainRate" = "rain (mm h-1)",
      "solarRadiation" = "GHI",
      "windDirection" = "wdir (deg)",
      "windSpeed" = "ws (m s-1)"
    )
  ),
  "davis_weewx" = list(
    read_func = read_davis_weewx,
    varmap = c(
      "outHumidity" = "RH (%)",
      "outTemp" = "Tair (degC)", 
      "pressure" = "press (hPa)",
      "rainRate" = "rain (mm h-1)",            
      "windDir" = "wdir (deg)",
      "windSpeed" = "ws (m s-1)"
    )
  ),
  "wxt536_serial" = list(
    read_func = read_wxt536_serial,
    varmap = c(
      "Dm" = "wdir (deg)",
      "Sm" = "ws (m s-1)",
      "Pa" = "press (hPa)",
      "Ta" = "Tair (degC)",
      "Ua" = "RH (%)",
      "Ri" = "rain (mm h-1)"
    )
  ),
  "wxt536_jcmb" = list(
    read_func = read_WXT536_jcmb,
    varmap = c(
      "Wind.Dir.Ave" = "wdir (deg)",
      "Wind.Speed.Ave" = "ws (m s-1)",
      "Air.Pressure" = "press (hPa)",
      "Air.Temp" = "Tair (degC)",
      "Humidity" = "RH (%)",
      "Rain.Intensity" = "rain (mm h-1)"
    )
  )
)
