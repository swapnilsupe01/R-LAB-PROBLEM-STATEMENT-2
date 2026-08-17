# Lab 4 Report: Advanced Missing Data Handling

## Topic: NA, NULL, NaN, Missing-Value Detection and Imputation
**Course:** R Programming Laboratory  
**Problem Statement:** Missing-Value Detection, Categorical Standardization, and Median Imputation for Workforce Demographic Analytics  
**Target Dataset:** UCI Adult / Census Income Dataset  
**Variables:** `age`, `workclass`, `education`, `occupation`, `hours_per_week`, `income`

---

## 1. Important R Concepts: Distinguishing NA, NULL, NaN, and ""

Understanding how R treats missing and non-existent values is critical for data engineering:

| Concept | Meaning in R | Type / Class | Behavior in Data Frame / Vector | Detection Function |
| :--- | :--- | :--- | :--- | :--- |
| **`NA`** | *Not Available* (Missing value) | Logical (or typed `NA_real_`, `NA_character_`) | Inhabits individual vector/data-frame cells without altering structure | `is.na(x)` |
| **`NaN`** | *Not a Number* (Undefined math result, e.g. $0/0$) | Numeric | Inhabits numeric cells; `is.na(NaN)` evaluates to `TRUE` | `is.nan(x)` |
| **`NULL`** | *Absence of an object / empty entity* | `NULL` (length 0) | **Cannot** occupy a single data-frame cell. Assigning `df$col <- NULL` deletes the entire column | `is.null(x)` |
| **`""`** | *Blank String* (Empty character value) | Character | Stored as valid non-missing text unless explicitly treated | `x == ""` or `trimws(x) == ""` |
| **Sentinel Values** | *Impossible Numbers* (e.g. `999` for age) | Numeric | Stored as valid numeric values; distorts mean/variance unless recoded | Conditional checks (`x == 999`) |

### Demonstration of `NULL` in R:
```r
demo_df <- data.frame(a = 1:3, b = c("x", "y", "z"))
demo_df$b <- NULL  # Entire column 'b' is deleted, not filled with empty cells!
```

---

## 2. Missing-Data Treatment Strategy

The cleaning pipeline adopts a 4-step treatment strategy:
1. **Recoding Impossible Numeric Outliers:** Convert `age == 999` to `NA`.
2. **Standardizing Categorical Missingness:** Convert blank strings `""` in `workclass` and `occupation` to `"Unknown"`.
3. **Custom Median Imputation for Numeric Features:** Impute missing `age` and `hours_per_week` with the median of valid observations.
4. **Validation and Quality Check:** Ensure 100% complete cases and non-distorted distributions.

---

## 3. Custom Median Imputation Function

```r
impute_median <- function(numeric_vector) {
  if (!is.numeric(numeric_vector)) {
    stop("Input to impute_median must be a numeric vector.")
  }
  
  missing_mask <- is.na(numeric_vector) | is.nan(numeric_vector)
  valid_values <- numeric_vector[!missing_mask]
  
  if (length(valid_values) == 0) {
    warning("No valid observations found to calculate median.")
    return(numeric_vector)
  }
  
  med_val <- median(valid_values)
  cleaned_vector <- numeric_vector
  cleaned_vector[missing_mask] <- med_val
  
  return(cleaned_vector)
}
```

---

## 4. Missingness Analysis Before and After Cleaning

### Summary Table

| Variable | Data Type | Raw Invalid/Missing Count | Raw Missing (%) | Post-Cleaning Missing Count | Post-Cleaning Missing (%) | Action Taken |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `record_id` | integer | 0 | 0.0% | 0 | 0.0% | Retained as ID |
| `age` | numeric | 12 (7 NA + 5 sentinel 999) | 2.4% | **0** | **0.0%** | Converted 999 $\to$ NA, Median Imputed (38.0) |
| `workclass` | character | 8 (Blank strings `""`) | 1.6% | **0** | **0.0%** | Replaced with `"Unknown"` |
| `education` | character | 0 | 0.0% | 0 | 0.0% | Retained |
| `occupation` | character | 8 (Blank strings `""`) | 1.6% | **0** | **0.0%** | Replaced with `"Unknown"` |
| `hours_per_week` | numeric | 10 (7 NA + 3 NaN) | 2.0% | **0** | **0.0%** | Median Imputed (40.0) |
| `income` | character | 0 | 0.0% | 0 | 0.0% | Retained |

---

## 5. Visualizations Generated
The script produces three publication-quality visual plots:
1. `missingness_before.png`: Horizontal bar chart displaying percentage of missing and invalid entries per column in the raw dataset.
2. `missingness_after.png`: Confirms 0% missingness across all features post-cleaning.
3. `missingness_comparison.png`: Side-by-side comparison bar chart contrasting the dirty vs. treated dataset.

---

## 6. Dataset Validation & Quality Assurance Summary

```
==================== DATASET SKIM VALIDATION ====================
Dimensions: 500 Rows x 7 Columns
Complete Cases: 500 / 500 (100.00%)

Variable: age              | Type: numeric    | Missing: 0 (0.0%)
  -> Min: 17.00 | Q1: 29.00 | Median: 38.00 | Mean: 38.42 | Q3: 48.00 | Max: 75.00 | SD: 13.14
Variable: workclass        | Type: character  | Missing: 0 (0.0%)
  -> Top Classes: Private (347), Local-gov (43), Self-emp-not-inc (38), State-gov (36)
Variable: occupation       | Type: character  | Missing: 0 (0.0%)
  -> Top Classes: Sales (74), Prof-specialty (69), Exec-managerial (66), Craft-repair (62)
Variable: hours_per_week   | Type: numeric    | Missing: 0 (0.0%)
  -> Min: 5.00 | Q1: 32.00 | Median: 40.00 | Mean: 40.31 | Q3: 49.00 | Max: 77.00 | SD: 12.08
=================================================================
```

### Verification Checklist:
- [x] Impossible `age == 999` removed (0 remaining).
- [x] All `NA` and `NaN` values in `age` and `hours_per_week` successfully median-imputed.
- [x] Blank strings in `workclass` and `occupation` replaced with `"Unknown"`.
- [x] `complete.cases()` increased from **92.6% to 100.0%**.

---

## 7. Short Interpretation of Cleaning Results
1. **Preservation of Statistical Properties:** Using the median for imputation prevents introducing undue bias to skewed demographic distributions (like income and working hours), preserving standard deviation and interquartile ranges much better than mean imputation.
2. **Safe Handling of Incomplete Records:** Rather than discarding incomplete rows (which would eliminate ~7.4% of survey respondents and potentially introduce selection bias), systematically treating categorical blanks as `"Unknown"` preserves vital demographic relationships.
3. **Data Readiness:** The dataset is now 100% complete and fully preprocessed for downstream classification models (e.g., predicting income $>50\text{K}$).
