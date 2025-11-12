# R/train.R
# Train, evaluate, calibrate, and save artifacts for the Diabetes (Pima) classifier

# ---------------------------------------------------------------------
# 1. Robust project-root detection (works from anywhere)
# ---------------------------------------------------------------------
find_project_root <- function() {
  here <- normalizePath(".", winslash = "/", mustWork = TRUE)
  # try ., .., ../.., ../../..
  candidates <- c(here,
                  dirname(here),
                  dirname(dirname(here)),
                  dirname(dirname(dirname(here))))
  for (cand in candidates) {
    if (file.exists(file.path(cand, "R", "config.R"))) return(cand)
  }
  stop("Could not locate project root (no R/config.R found).")
}

# Use existing ROOT if valid; otherwise auto-detect
if (exists("ROOT", inherits = FALSE) &&
    file.exists(file.path(ROOT, "R", "config.R"))) {
  ROOT <- normalizePath(ROOT, winslash = "/", mustWork = TRUE)
} else {
  ROOT <- find_project_root()
}

source(file.path(ROOT, "R", "config.R"))
source(file.path(ROOT, "R", "utils_data.R"))

# ---------------------------------------------------------------------
# 2. Libraries
# ---------------------------------------------------------------------
library(tidyverse)
library(tidymodels)
library(jsonlite)
library(ggplot2)
library(cowplot)
library(pROC)
library(PRROC)
# tidymodels_prefer() # optional for resolving function name conflicts

# ---------------------------------------------------------------------
# 3. Helper functions
# ---------------------------------------------------------------------
metrics_at <- function(y_true, p, threshold = 0.5) {
  pred <- as.factor(ifelse(p >= threshold, 1, 0))
  y <- as.factor(y_true)
  tibble(
    threshold = threshold,
    roc_auc   = as.numeric(yardstick::roc_auc_vec(y, p, event_level = "second")),
    pr_auc    = as.numeric(yardstick::average_precision_vec(y, p, event_level = "second")),
    accuracy  = as.numeric(yardstick::accuracy_vec(y, pred)),
    precision = as.numeric(yardstick::precision_vec(y, pred, event_level = "second")),
    recall    = as.numeric(yardstick::recall_vec(y, pred, event_level = "second")),
    f1        = as.numeric(yardstick::f_meas_vec(y, pred, beta = 1, event_level = "second"))
  )
}

find_best_threshold <- function(y_true, p, min_recall = NULL) {
  grid <- seq(0.1, 0.9, by = 0.01)
  res <- purrr::map_dfr(grid, ~metrics_at(y_true, p, .x))
  if (!is.null(min_recall)) res <- dplyr::filter(res, recall >= min_recall)
  dplyr::arrange(res, dplyr::desc(f1)) %>%
    dplyr::slice(1) %>%
    dplyr::pull(threshold)
}

plot_roc_pr <- function(y_true, p, path_png) {
  roc_obj <- pROC::roc(y_true, p, quiet = TRUE)
  pr_obj  <- PRROC::pr.curve(scores.class0 = p[y_true == 1],
                             scores.class1 = p[y_true == 0], curve = TRUE)
  
  p1 <- ggplot() +
    geom_line(aes(x = 1 - roc_obj$specificities, y = roc_obj$sensitivities)) +
    labs(title = sprintf("ROC (AUC = %.3f)", pROC::auc(roc_obj)),
         x = "1 - Specificity (FPR)", y = "Sensitivity (TPR)")
  
  pr_df <- as.data.frame(pr_obj$curve); names(pr_df) <- c("Recall","Precision","Threshold")
  p2 <- ggplot(pr_df, aes(x = Recall, y = Precision)) +
    geom_line() +
    labs(title = sprintf("PR Curve (AP = %.3f)", pr_obj$auc.integral))
  
  ggsave(path_png, plot = cowplot::plot_grid(p1, p2, ncol = 1),
         width = 6, height = 8, dpi = 150)
}

plot_calibration <- function(y_true, p, path_png, bins = 10) {
  dfc <- tibble(y = y_true, p = p) %>%
    mutate(bin = ntile(p, bins)) %>%
    group_by(bin) %>%
    summarize(mean_p = mean(p), frac_pos = mean(y), .groups = "drop")
  
  gg <- ggplot(dfc, aes(x = mean_p, y = frac_pos)) +
    geom_point() +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
    labs(title = "Calibration curve",
         x = "Predicted probability (bin avg)",
         y = "Observed frequency") +
    coord_equal()
  
  ggsave(path_png, plot = gg, width = 6, height = 5, dpi = 150)
}

# ---------------------------------------------------------------------
# 4. Load & prepare data
# ---------------------------------------------------------------------
df <- load_dataset(DATA_PATH)
df[[TARGET]] <- factor(df[[TARGET]], levels = c(0, 1))  # outcome must be factor

# ---------------------------------------------------------------------
# 5. Split
# ---------------------------------------------------------------------
set.seed(RANDOM_STATE)
spl   <- initial_split(df, prop = 0.8, strata = TARGET)
train <- training(spl)
test  <- testing(spl)

# ---------------------------------------------------------------------
# 6. Recipe (impute + scale)
# ---------------------------------------------------------------------
rec <- recipe(as.formula(paste(TARGET, "~", paste(FEATURES, collapse = "+"))), data = train) %>%
  step_impute_median(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors())

# ---------------------------------------------------------------------
# 7. Model (logistic regression)
# ---------------------------------------------------------------------
spec <- logistic_reg(mode = "classification") %>%
  set_engine("glm")

wf <- workflow() %>%
  add_model(spec) %>%
  add_recipe(rec)

# ---------------------------------------------------------------------
# 8. Cross-validation
# ---------------------------------------------------------------------
set.seed(RANDOM_STATE)
folds       <- vfold_cv(train, v = 5, strata = TARGET)
metrics_set <- metric_set(roc_auc, pr_auc, accuracy, recall, precision, f_meas)

res        <- fit_resamples(wf, resamples = folds, metrics = metrics_set,
                            control = control_resamples(save_pred = TRUE))
cv_metrics <- collect_metrics(res)

# ---------------------------------------------------------------------
# 9. Fit final & test evaluation
# ---------------------------------------------------------------------
final_fit <- fit(wf, data = train)
p_test    <- predict(final_fit, new_data = test, type = "prob")$.pred_1
y_test    <- as.numeric(as.character(test[[TARGET]]))

thr_default <- 0.5
thr_best    <- find_best_threshold(y_test, p_test, min_recall = 0.80)

m_default <- metrics_at(y_test, p_test, thr_default)
m_best    <- metrics_at(y_test, p_test, thr_best)

# ---------------------------------------------------------------------
# 10. Plots (ROC/PR + Calibration)
# ---------------------------------------------------------------------
plot_roc_pr(y_test, p_test, ROC_PR_PNG)
plot_calibration(y_test, p_test, CALIB_PNG)

# ---------------------------------------------------------------------
# 11. Confusion Matrix @ best threshold
# ---------------------------------------------------------------------
pred_best <- factor(ifelse(p_test >= thr_best, 1, 0), levels = c(0, 1))
cm_data   <- tibble(
  truth    = factor(y_test, levels = c(0, 1)),
  estimate = pred_best
)
cm <- yardstick::conf_mat(data = cm_data, truth = truth, estimate = estimate)
cm_df <- as_tibble(cm$table)
gg_cm <- ggplot(cm_df, aes(Prediction, Truth, fill = n)) +
  geom_tile() +
  geom_text(aes(label = n), color = "white", size = 6) +
  scale_fill_gradient(low = "#6aa84f", high = "#274e13") +
  ggtitle(sprintf("Confusion Matrix (threshold = %.2f)", thr_best))
ggsave(CONF_MAT_PNG, gg_cm, width = 5, height = 4, dpi = 150)

# ---------------------------------------------------------------------
# 12. Save artifacts
# ---------------------------------------------------------------------
saveRDS(final_fit, MODEL_RDS)
out_metrics <- list(
  cv                     = cv_metrics,
  test_threshold_default = m_default,
  test_threshold_best    = m_best,
  threshold_best         = as.numeric(thr_best)
)
write_json(out_metrics, EVAL_JSON, pretty = TRUE, auto_unbox = TRUE)

message("Saved model to: ", MODEL_RDS)
message("Best threshold: ", round(thr_best, 2))
