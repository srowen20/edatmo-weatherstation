# qc.R

library(yaml)
qc_limits <- yaml::read_yaml("qc_config.yml")
simple_qc <- function(df, qc_limits) {
  df %>%
    dplyr::rowwise() %>%
    dplyr::filter({
      lim <- qc_limits[[variable]]
      !is.null(lim) && dplyr::between(value, lim$min, lim$max)
    }) %>%
    dplyr::ungroup()
}
