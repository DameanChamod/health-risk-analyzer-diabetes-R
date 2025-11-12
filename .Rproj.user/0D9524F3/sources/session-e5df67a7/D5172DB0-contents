# tests/testthat/test_data_validation.R
library(testthat)
library(pointblank)

test_that("raw dataset passes schema & range checks", {
  df <- readr::read_csv(DATA_PATH, show_col_types = FALSE)
  
  # ---- basic structure checks ----
  expect_true(all(c(FEATURES, TARGET) %in% names(df)))
  expect_true(all(sapply(df[FEATURES], is.numeric)))
  expect_true(is.numeric(df[[TARGET]]) || is.integer(df[[TARGET]]))
  
  # ---- value range & validity checks ----
  agent <- create_agent(tbl = df) %>%
    col_vals_between(vars(Pregnancies), 0, 20) %>%
    col_vals_between(vars(Glucose), 0, 400) %>%
    col_vals_between(vars(BloodPressure), 0, 250) %>%
    col_vals_between(vars(SkinThickness), 0, 99) %>%
    col_vals_between(vars(Insulin), 0, 1200) %>%
    col_vals_between(vars(BMI), 0, 80) %>%
    col_vals_between(vars(DiabetesPedigreeFunction), 0, 3) %>%
    col_vals_between(vars(Age), 1, 120) %>%
    col_vals_in_set(vars(Outcome), c(0, 1)) %>%
    interrogate()
  
  # ✅ robust pass/fail check
  expect_true(pointblank::all_passed(agent))
})

test_that("loader converts implausible zeros to NA", {
  df <- load_dataset(DATA_PATH)
  for (c in c("Glucose","BloodPressure","SkinThickness","Insulin","BMI")) {
    expect_false(any(df[[c]] == 0, na.rm = TRUE))
  }
})
