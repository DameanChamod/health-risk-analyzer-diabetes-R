#  Health Risk Analyzer (Diabetes Prediction)

An end-to-end **machine learning project in R** that predicts diabetes risk based on health metrics such as BMI, glucose, and age.  
The project uses **tidymodels** for model building, **testthat / pointblank** for QA validation, and **Power BI** for interactive visualization.

---

##  Overview

This project trains a supervised **logistic regression** model on the *PIMA Indians Diabetes Dataset* to classify individuals as **At Risk** or **Not at Risk**.  
It demonstrates the full ML lifecycle — data validation, preprocessing, model training, evaluation, explainability, and dashboard visualization.

---

##  Tech Stack

| Layer | Tools & Libraries |
|-------|-------------------|
| **Language** | R |
| **ML Framework** | tidymodels, parsnip, recipes, yardstick |
| **Data Validation** | pointblank, testthat |
| **Visualization** | ggplot2, cowplot, Power BI |
| **Explainability** | DALEX |
| **Version Control** | Git + GitHub |

---

## Project Structure

health-risk-analyzer-diabetes-R/
├─ R/ # R scripts (train, predict, utils, explain)
├─ data/ # PIMA Indians Diabetes dataset
├─ artifacts/ # Saved models, plots, metrics
├─ powerbi/ # Exported dataset for Power BI dashboard
├─ tests/testthat/ # QA and validation tests
└─ README.md # Project documentation

## Key Features

- **Data preprocessing & validation** — handled with `recipes` and `pointblank`
- **Supervised ML** — logistic regression model for binary classification
- **Automated QA** — tests for schema, training metrics, and inference consistency
- **Model evaluation** — ROC/PR curves, calibration plots, confusion matrix
- **Power BI dashboard** — visualizes population-level risk trends by features (Age, BMI, Glucose)

---

## Results

- Best tuned threshold: **0.16**  
- Model accuracy ≈ **84%**  
- High recall for positive (At Risk) cases  
- Power BI dashboard for population-level risk insights


---

##  QA & Testing

- **testthat** for unit & functional tests  
- **pointblank** for dataset integrity  
- **Automated validation** during model training and inference

Run all tests:
```r
testthat::test_dir("tests/testthat")

