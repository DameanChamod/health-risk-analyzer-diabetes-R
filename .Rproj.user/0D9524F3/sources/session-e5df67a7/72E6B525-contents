# R/config.R
library(fs)

# If ROOT was set by tests, keep it; otherwise use current dir
if (!exists("ROOT", inherits = FALSE)) {
  ROOT <- path_abs(".")
}

DATA_PATH <- path(ROOT, "data", "diabetes.csv")
ART <- path(ROOT, "artifacts"); dir_create(ART)
PBI_DIR <- path(ROOT, "powerbi"); dir_create(PBI_DIR)

MODEL_RDS <- path(ART, "workflow_diabetes.rds")
EVAL_JSON <- path(ART, "eval_metrics.json")
CONF_MAT_PNG <- path(ART, "confusion_matrix.png")
ROC_PR_PNG <- path(ART, "roc_pr_curves.png")
CALIB_PNG <- path(ART, "calibration_curve.png")
EXPL_DIR <- path(ART, "shap_like_examples"); dir_create(EXPL_DIR)
POP_RISK_CSV <- path(PBI_DIR, "population_risk.csv")

FEATURES <- c("Pregnancies","Glucose","BloodPressure","SkinThickness",
              "Insulin","BMI","DiabetesPedigreeFunction","Age")
TARGET <- "Outcome"

RANDOM_STATE <- 42
set.seed(RANDOM_STATE)
