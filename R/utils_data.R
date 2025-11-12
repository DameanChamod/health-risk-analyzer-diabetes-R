library(tidyverse)

zero_as_na <- c("Glucose","BloodPressure","SkinThickness","Insulin","BMI")

load_dataset <- function(path) {
  df <- readr::read_csv(path, show_col_types = FALSE)
  expected <- c(FEATURES, TARGET)
  miss <- setdiff(expected, names(df))
  if (length(miss) > 0) stop(paste("Missing columns:", paste(miss, collapse=", ")))
  df %>% mutate(across(all_of(zero_as_na), ~na_if(., 0)))
}
