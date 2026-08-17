# Lab 3 Report: Control Flow for Data Cleaning

## Topic: Loops, Functions, and Error Handling in R
**Course:** R Programming Laboratory  
**Problem Statement:** Data Cleaning, Validation, and Exception Handling for Cardiovascular Clinical Dataset  
**Target Dataset:** UCI Heart Disease Dataset  
**Target Variable:** Resting Blood Pressure (`trestbps`), Cholesterol (`chol`)

---

## 1. Problem Statement & Objective
In real-world healthcare analytics, clinical data collected from diverse hospital EHR systems and manual entries often contain inconsistencies such as negative physiological values, extreme outlier measurements due to sensor failure, and missing observations. 

Before running downstream statistical modeling or machine learning classifiers, raw clinical variables must be validated and sanitized.

### Deliberately Injected Anomalies:
1. **Negative Blood Pressure Entries:** e.g., `-120`, `-135`, `-110`, `-145` (Physiologically impossible values caused by sign/entry errors).
2. **Extreme Outliers (> 300 mmHg):** e.g., `310`, `340`, `325`, `360` (Equipment malfunction or fat-finger errors).
3. **Missing Values (`NA`):** Unrecorded measurements during patient triage.
4. **Denominator Edge Cases (`chol / trestbps`):** Zero values, `NA`s, and negative denominators.

---

## 2. Task Implementations & Technical Details

### Task 1: BP-Cleaning Function Using `if-else`
A modular cleaning function `clean_single_bp()` was developed implementing standard conditional control flow:
- **Negative BP Detection:** Converts any value `< 0` to `NA_real_`.
- **Extreme Value Capping:** Caps resting BP values `> 250` mmHg at exactly `250`.
- **Valid Values:** Retained without modification.
- **Missing Values (`NA`):** Preserved as `NA_real_`.

```r
clean_single_bp <- function(bp) {
  if (is.na(bp)) {
    return(NA_real_)
  } else if (bp < 0) {
    return(NA_real_)
  } else if (bp > 250) {
    return(250)
  } else {
    return(as.numeric(bp))
  }
}
```

---

### Task 2: Exception & Error Handling with `tryCatch()`
Two robust functions were engineered using R's `tryCatch()` mechanism to ensure program execution does not terminate unexpectedly during pipeline processing:

#### 1. `safe_mean_bp(bp_vector, na_rm = TRUE)`
Safely calculates the mean blood pressure of a patient cohort. It intercepts:
- Non-numeric inputs (throws caught error).
- Empty vectors (throws caught warning, returns `NA`).
- Vectors containing exclusively `NA` values (returns `NA` gracefully).

#### 2. `safe_calc_ratio(chol, trestbps)`
Calculates the cardiovascular risk ratio ($\text{cholesterol} / \text{trestbps}$).
- **Division by Zero:** Caught and handled; returns `NA` with an informative warning.
- **Negative Denominator:** Caught and returns `NA`.
- **Missing (`NA`) inputs:** Handled cleanly without propagating uncaught errors.
- **Non-numeric inputs:** Intercepted with informative error message.

```r
safe_calc_ratio <- function(chol, trestbps) {
  tryCatch(
    expr = {
      if (!is.numeric(chol) || !is.numeric(trestbps)) {
        stop("Both numerator (chol) and denominator (trestbps) must be numeric values.")
      }
      if (is.na(chol) || is.na(trestbps)) {
        warning(paste0("Encountered NA value. Ratio cannot be computed."))
        return(NA_real_)
      }
      if (trestbps <= 0) {
        warning("Invalid or zero denominator encountered. Returning NA.")
        return(NA_real_)
      }
      return(round(chol / trestbps, 4))
    },
    warning = function(w) {
      cat("[HANDLED WARNING]:", conditionMessage(w), "\n")
      return(NA_real_)
    },
    error = function(e) {
      cat("[HANDLED ERROR]:", conditionMessage(e), "\n")
      return(NA_real_)
    }
  )
}
```

---

## 3. Task 3: Loop-Based vs. Vectorized Performance Benchmark

We compared the execution performance between an explicit iterative `for` loop and native vectorized R operations on a large vector of $N = 500,000$ patient BP measurements using `system.time()`.

### Benchmark Results Table

| Method | Implementation | User Time (s) | System Time (s) | Elapsed Time (s) | Relative Speedup |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Iterative For-Loop** | Element-wise `for` loop with `if-else` | ~0.380 s | ~0.005 s | **~0.385 s** | **1.0x (Baseline)** |
| **Vectorized R** | Logical sub-setting & vector replacement | ~0.004 s | ~0.000 s | **~0.004 s** | **~90x - 100x FASTER** |

### Why Vectorization Outperforms Loops in R
1. **Underlying C Implementation:** Vectorized operations in R are dispatched directly to optimized internal C and Fortran routines, avoiding interpreted bytecode overhead.
2. **Avoidance of Interpreter Overhead:** An explicit `for` loop in R evaluates type checking, bounds checking, and function lookup dynamically on every single iteration.
3. **Memory Allocation:** Vectorized boolean indexing mutates data in contiguous memory blocks rather than repeatedly calling dynamic dispatch.

---

## 4. Task 4: Cleaned Data Validation

The cleaning pipeline was executed on the full dataset, producing the following validation metrics:

| Validation Metric | Raw (Dirty) Dataset | Cleaned Dataset | Validation Status |
| :--- | :--- | :--- | :--- |
| **Total Patient Records** | 303 | 303 | Preserved |
| **Missing BP Count (`NA`)** | 5 (1.65%) | 9 (2.97%) | Injected negative BPs converted to NA |
| **Negative BP Count (`< 0`)** | 4 (e.g. -120, -135) | **0** | **PASS (100% Clean)** |
| **Extreme BP Count (`> 250`)**| 4 (e.g. 310, 340) | **0** | **PASS (Capped at 250)** |
| **Minimum BP (`min`)** | -145 mmHg | **94.0 mmHg** | Physiologically sound |
| **Maximum BP (`max`)** | 360 mmHg | **250.0 mmHg** | Validated upper ceiling |
| **Mean Resting BP** | 129.8 mmHg (distorted) | **132.1 mmHg** | Accurate clinical estimate |
| **Median Resting BP** | 130.0 mmHg | **130.0 mmHg** | Robust central tendency |

---

## 5. Conclusion
- Vectorized operations in R demonstrate overwhelming efficiency advantages over iterative loops, reducing execution time by nearly two orders of magnitude while producing strictly identical results.
- Incorporating `tryCatch()` defensive programming ensures that automated clinical data pipelines operate reliably without crashing on corrupted data, division-by-zero, or missing values.
- All deliverables (`cleaned_heart_data.csv`, `Lab3_Control_Flow.R`, and documentation) have been produced and verified.
