library(testthat)
library(tidymodels)

load_model <- function() readRDS(MODEL_RDS)

test_that("workflow loads and predicts on valid input", {
  if (!file.exists(MODEL_RDS)) source(p("R", "train.R"))
  wf <- load_model()
  new_row <- tibble(
    Pregnancies=2, Glucose=150, BloodPressure=80, SkinThickness=25,
    Insulin=100, BMI=30.5, DiabetesPedigreeFunction=0.6, Age=40
  )
  p <- predict(wf, new_data = new_row, type = "prob")$.pred_1
  expect_true(is.numeric(p)); expect_gte(p, 0); expect_lte(p, 1)
})

test_that("recipe imputes NAs at scoring time", {
  if (!file.exists(MODEL_RDS)) source(p("R", "train.R"))
  wf <- load_model()
  new_row <- tibble(
    Pregnancies=2, Glucose=NA, BloodPressure=80, SkinThickness=25,
    Insulin=100, BMI=30.5, DiabetesPedigreeFunction=0.6, Age=40
  )
  p <- predict(wf, new_data = new_row, type = "prob")$.pred_1
  expect_true(is.finite(p))
})
