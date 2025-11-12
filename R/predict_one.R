# R/predict_one.R
source("R/config.R")
library(tidyverse)
library(tidymodels)
library(jsonlite)

# Load trained workflow and threshold
wf  <- readRDS(MODEL_RDS)
thr <- tryCatch(fromJSON(EVAL_JSON)$threshold_best, error = function(e) 0.5)
if (!is.finite(thr)) thr <- 0.5

# Example: a single person (edit these to test)
new_person <- tibble(
  Pregnancies = 2,
  Glucose = 150,
  BloodPressure = 80,
  SkinThickness = 25,
  Insulin = 100,
  BMI = 30.5,
  DiabetesPedigreeFunction = 0.6,
  Age = 40
)

# Predict probability of Outcome=1
prob  <- predict(wf, new_data = new_person, type = "prob")$.pred_1
label <- ifelse(prob >= thr, "At risk", "Not at risk")

cat(sprintf("Estimated probability: %.3f\n", prob))
cat(sprintf("Threshold used: %.2f\n", thr))
cat(sprintf("Classification: %s\n", label))
