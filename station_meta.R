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
      "solarRadiation" = "GHI (W m-2)",
      "windDirection" = "wdir sample (deg)",
      "windSpeed" = "ws sample (m s-1)"
    )
  ),
  "davis_weewx" = list(
    read_func = read_davis_weewx,
    varmap = c(
      "outHumidity" = "RH (%)",
      "outTemp" = "Tair (degC)", 
      "pressure" = "press (hPa)",
      "rainRate" = "rain (mm h-1)",            
      "windDir" = "wdir sample (deg)",
      "windSpeed" = "ws sample (m s-1)"
    )
  ),
  "wxt536_serial" = list(
    read_func = read_wxt536_serial,
    varmap = c(
      "Dn" = "wdir min (deg)",
      "Dm" = "wdir avg (deg)",
      "Dx" = "wdir max (deg)",
      "Sn" = "ws min (m s-1)",
      "Sm" = "ws avg (m s-1)",
      "Sx" = "ws max (m s-1)",
      "Ta" = "Tair (degC)",
      "Ua" = "RH (%)",
      "Pa" = "press (hPa)",
      "Ri" = "rain (mm h-1)"
    )
  ),
  
  "wxt536_jcmb" = list(
    read_func = read_WXT536_jcmb,
    varmap = c(
      "Wind.Dir.Min" = "wdir min (deg)",
      "Wind.Dir.Max" = "wdir max (deg)",
      "Wind.Dir.Ave" = "wdir avg (deg)",
      "Wind.Speed.Min" = "ws min (m s-1)",
      "Wind.Speed.Max" = "ws max (m s-1)",
      "Wind.Speed.Ave" = "ws avg (m s-1)",
      "Air.Pressure" = "press (hPa)",
      "Air.Temp" = "Tair (degC)",
      "Humidity" = "RH (%)",
      "Rain.Intensity" = "rain (mm h-1)"
    )
  )
)
