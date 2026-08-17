# R Programming - Lab Problem Statement 2

This repository contains the complete implementation, datasets, benchmark results, validation pipelines, visualizations, and documentation for **Lab Problem Statement 2**, consisting of:
1. **Lab 3: Control Flow for Data Cleaning** (Loops, Functions, Exception Handling `tryCatch()`, Benchmarking)
2. **Lab 4: Advanced Missing Data Handling** (`NA`, `NULL`, `NaN`, `""`, Sentinel Values, Custom Median Imputation)

---

## 📁 Repository Structure

```
LAB PROBLEM STATEMENT 2/
│
├── Lab3_Control_Flow/
│   ├── heart_disease_raw_dirty.csv          # Raw dataset with simulated negative, extreme (>300), and NA BP values
│   ├── cleaned_heart_data.csv               # Sanitized dataset after cleaning and validation
│   ├── Lab3_Control_Flow.R                  # Complete standalone executable R script
│   └── Lab3_Report.md                       # Comprehensive report with benchmark analysis and conclusions
│
├── Lab4_Missing_Data/
│   ├── adult_raw_dirty.csv                  # Raw dataset with NA, NaN, "", and age=999
│   ├── cleaned_adult_data.csv               # Cleaned & imputed dataset
│   ├── Lab4_Advanced_Missing_Data.R         # Complete standalone executable R script
│   ├── missingness_before.png               # Visualization of missingness before cleaning
│   ├── missingness_after.png                # Visualization of missingness after cleaning
│   ├── missingness_comparison.png           # Comparative bar chart (Before vs After)
│   └── Lab4_Report.md                       # Comprehensive report, concept definitions, and interpretations
│
├── LAB_PROBLEM_STATEMENT_2.ipynb            # Google Colab / Jupyter Notebook containing Lab 3 & Lab 4
├── run_all.R                                # Master one-click runner executing both labs
└── README.md                                # This documentation guide
```

---

## 🚀 How to Run

### Option 1: Execute Entire Suite via Rscript (One Command)
Open PowerShell or Command Prompt in this folder and run:
```bash
Rscript run_all.R
```

### Option 2: Execute Individual Labs
```bash
# To run Lab 3:
cd Lab3_Control_Flow
Rscript Lab3_Control_Flow.R

# To run Lab 4:
cd ../Lab4_Missing_Data
Rscript Lab4_Advanced_Missing_Data.R
```

### Option 3: Run via Google Colab / Jupyter Notebook
1. Open Google Colab (https://colab.research.google.com) or your local Jupyter Notebook server.
2. Upload `LAB_PROBLEM_STATEMENT_2.ipynb`.
3. Run all cells sequentially.
4. Export as PDF or download for submission.

---

## 🧪 Summary of Results

### Lab 3: Control Flow for Data Cleaning
- **Custom `if-else` BP Cleaner:** Converted negative values (`-120`, `-135`, etc.) to `NA`; capped extreme values (`>250` mmHg) to `250`; preserved valid measurements.
- **Exception Handling (`tryCatch`):** `safe_mean_bp()` and `safe_calc_ratio()` safely handle non-numeric data, missing records, and division-by-zero without crashing.
- **Benchmark (`system.time()` on $N = 500,000$ items):**
  - **Iterative `for` loop:** $\approx 0.385\text{ s}$
  - **Vectorized R operations:** $\approx 0.004\text{ s}$
  - **Performance Advantage:** Vectorized approach is **$\sim 90\text{x} - 100\text{x}$ faster**.

### Lab 4: Advanced Missing Data Handling
- **Concepts Clarified:** Distinct behavior of `NA`, `NULL`, `NaN`, `""`, and sentinel `999`.
- **Treatment Pipeline:**
  - Sentinel `age = 999` $\to$ `NA`.
  - Blank strings in `workclass` and `occupation` $\to$ `"Unknown"`.
  - `age` and `hours_per_week` $\to$ Imputed via custom `impute_median()`.
- **Data Quality:** Complete case coverage increased from **$92.6\%$ to $100.0\%$**.
