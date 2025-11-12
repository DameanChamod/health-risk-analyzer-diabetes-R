library(testthat)
library(jsonlite)

ensure_trained <- function() {
  if (!file.exists(MODEL_RDS) || !file.exists(EVAL_JSON)) {
    source(p("R", "train.R"))  # use project-root-aware path
  }
}

test_that("model meets minimum performance thresholds", {
  ensure_trained()
  m <- jsonlite::fromJSON(EVAL_JSON)
  
  auc   <- as.numeric(m$test_threshold_default$roc_auc)
  prauc <- as.numeric(m$test_threshold_default$pr_auc)
  f1_b  <- as.numeric(m$test_threshold_best$f1)
  rec_b <- as.numeric(m$test_threshold_best$recall)
  
  expect_gt(auc,   0.74)
  expect_gt(prauc, 0.55)
  expect_gt(f1_b,  0.60)
  expect_gte(rec_b,0.80)
})

test_that("best threshold exists and is in [0,1]", {
  ensure_trained()
  m <- jsonlite::fromJSON(EVAL_JSON)
  thr <- as.numeric(m$threshold_best)
  expect_true(is.finite(thr))
  expect_gte(thr, 0); expect_lte(thr, 1)
})
