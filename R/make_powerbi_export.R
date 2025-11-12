source("R/config.R"); source("R/utils_data.R")
library(tidyverse); library(tidymodels); library(jsonlite)

df <- load_dataset(DATA_PATH)
wf <- readRDS(MODEL_RDS)

# predict probability of Outcome=1
proba <- predict(wf, new_data = df, type = "prob")$.pred_1

# load tuned threshold (fallback 0.5)
thr <- tryCatch(fromJSON(EVAL_JSON)$threshold_best, error = function(e) 0.5)
if (!is.finite(thr)) thr <- 0.5

out <- df %>%
  mutate(
    risk_proba = proba,
    risk_label = ifelse(risk_proba >= thr, 1L, 0L)
  )

readr::write_csv(out, POP_RISK_CSV)
message("Wrote: ", POP_RISK_CSV)
