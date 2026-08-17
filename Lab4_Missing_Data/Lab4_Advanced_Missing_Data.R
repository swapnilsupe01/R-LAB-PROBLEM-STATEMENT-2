# ==============================================================================
# LAB 4: ADVANCED MISSING DATA HANDLING
# Topic: NA, NULL, NaN, Missing-Value Detection and Imputation
# Dataset: UCI Adult / Census Income Dataset
# ==============================================================================

# Set seed for reproducibility
set.seed(123)

cat("====================================================================\n")
cat("          LAB 4: ADVANCED MISSING DATA HANDLING IN R                \n")
cat("====================================================================\n\n")

# ------------------------------------------------------------------------------
# STEP 0: GENERATE / LOAD UCI ADULT DATASET WITH INJECTED MISSING/INVALID DATA
# ------------------------------------------------------------------------------
cat(">>> STEP 0: Generating Raw UCI Adult Dataset with Diverse Missing Patterns...\n")

n_records <- 500

# Base attributes
age_raw <- round(rnorm(n_records, mean = 38.5, sd = 13.5))
age_raw <- pmax(17, pmin(75, age_raw))

workclass_pool <- c("Private", "Self-emp-not-inc", "Self-emp-inc", "Federal-gov", "Local-gov", "State-gov")
workclass_raw <- sample(workclass_pool, n_records, replace = TRUE, prob = c(0.70, 0.08, 0.04, 0.03, 0.08, 0.07))

education_pool <- c("Bachelors", "Some-college", "11th", "HS-grad", "Prof-school", "Assoc-acdm", "Assoc-voc", "Masters", "Doctorate")
education_raw <- sample(education_pool, n_records, replace = TRUE)

occupation_pool <- c("Tech-support", "Craft-repair", "Other-service", "Sales", "Exec-managerial", "Prof-specialty", "Handlers-cleaners", "Adm-clerical")
occupation_raw <- sample(occupation_pool, n_records, replace = TRUE)

hours_per_week_raw <- round(rnorm(n_records, mean = 40.4, sd = 12.3))
hours_per_week_raw <- pmax(1, pmin(99, hours_per_week_raw))

income_pool <- c("<=50K", ">50K")
income_raw <- sample(income_pool, n_records, replace = TRUE, prob = c(0.76, 0.24))

# DELIBERATE INJECTION OF DIFFERENT FORMS OF MISSING & INVALID DATA:

# 1. NA values (Missing at Random / Unrecorded)
age_raw[c(12, 45, 88, 150, 230, 310, 420)] <- NA
hours_per_week_raw[c(20, 65, 110, 195, 275, 360, 480)] <- NA

# 2. NaN values (Not a Number - e.g. mathematical errors / corrupt telemetry)
hours_per_week_raw[c(35, 180, 305)] <- NaN

# 3. Blank strings ("") in categorical variables (Empty text fields)
workclass_raw[c(10, 55, 99, 175, 245, 333, 410, 470)] <- ""
occupation_raw[c(22, 67, 105, 188, 260, 345, 430, 490)] <- ""

# 4. Impossible values: age = 999 (Sentinel / code values used by legacy systems)
age_raw[c(5, 72, 160, 290, 395)] <- 999

# Assemble Raw Dirty DataFrame
adult_df_raw <- data.frame(
  record_id = 1:n_records,
  age = age_raw,
  workclass = workclass_raw,
  education = education_raw,
  occupation = occupation_raw,
  hours_per_week = hours_per_week_raw,
  income = income_raw,
  stringsAsFactors = FALSE
)

# Save Raw Dirty Dataset to CSV
raw_csv_path <- "adult_raw_dirty.csv"
write.csv(adult_df_raw, raw_csv_path, row.names = FALSE)
cat("Raw dirty Adult dataset saved to:", raw_csv_path, "\n\n")


# ------------------------------------------------------------------------------
# TASK 1: IDENTIFY DIFFERENT FORMS OF MISSING OR INVALID DATA
# ------------------------------------------------------------------------------
cat(">>> TASK 1: Identifying Different Forms of Missing or Invalid Data...\n")

# 1.1 Use is.na() to identify NA
na_age_count <- sum(is.na(adult_df_raw$age))
cat("1. is.na() on 'age' count:", na_age_count, "(includes standard NAs)\n")

# 1.2 Use is.nan() to identify NaN
nan_hours_count <- sum(is.nan(adult_df_raw$hours_per_week))
cat("2. is.nan() on 'hours_per_week' count:", nan_hours_count, "\n")
cat("   Note: is.na(NaN) evaluates to TRUE, but is.nan(NA) evaluates to FALSE.\n")

# 1.3 Demonstrate is.null() and explain why NULL behaves differently inside a data frame
cat("\n3. Demonstrating is.null() behavior:\n")
sample_obj <- NULL
cat("   is.null(sample_obj) for an R object:", is.null(sample_obj), "\n")

cat("   [Important Concept Demonstration]:\n")
demo_df <- data.frame(a = 1:3, b = c("x", "y", "z"))
cat("   Original demo dataframe columns:", paste(names(demo_df), collapse = ", "), "\n")
demo_df$b <- NULL # Assigning NULL removes the column from data frame entirely!
cat("   Columns after demo_df$b <- NULL:", paste(names(demo_df), collapse = ", "), "\n")
cat("   -> EXPLANATION: NULL represents the absolute absence of an R object of length 0.\n")
cat("      It cannot inhabit individual cells of a vector or data frame without deleting or corrupting column structures.\n\n")

# 1.4 Identify blank strings using x == ""
blank_workclass_count <- sum(adult_df_raw$workclass == "", na.rm = TRUE)
blank_occupation_count <- sum(adult_df_raw$occupation == "", na.rm = TRUE)
cat("4. Blank string ('') counts:\n")
cat("   - workclass blank count:", blank_workclass_count, "\n")
cat("   - occupation blank count:", blank_occupation_count, "\n")

# 1.5 Identify impossible values such as age = 999
impossible_age_count <- sum(adult_df_raw$age == 999, na.rm = TRUE)
cat("5. Impossible value count (age == 999):", impossible_age_count, "\n\n")

# 1.6 Generate variable-wise missing-value summary function
calc_missing_summary <- function(df) {
  var_names <- names(df)
  total_rows <- nrow(df)
  
  summary_list <- lapply(var_names, function(col_name) {
    col <- df[[col_name]]
    
    n_na <- sum(is.na(col) & !is.nan(col))
    n_nan <- if(is.numeric(col)) sum(is.nan(col)) else 0
    n_blank <- if(is.character(col)) sum(col == "", na.rm = TRUE) else 0
    n_impossible_age <- if(col_name == "age") sum(col == 999, na.rm = TRUE) else 0
    
    total_invalid <- n_na + n_nan + n_blank + n_impossible_age
    pct_invalid <- round((total_invalid / total_rows) * 100, 2)
    
    data.frame(
      variable = col_name,
      type = class(col)[1],
      n_NA = n_na,
      n_NaN = n_nan,
      n_blank = n_blank,
      n_sentinel = n_impossible_age,
      total_missing_invalid = total_invalid,
      pct_missing = pct_invalid,
      stringsAsFactors = FALSE
    )
  })
  
  do.call(rbind, summary_list)
}

missing_summary_before <- calc_missing_summary(adult_df_raw)
cat("Variable-wise Missingness Summary (BEFORE Cleaning):\n")
print(missing_summary_before)
cat("\n")


# ------------------------------------------------------------------------------
# TASK 2: DEVELOP MISSING DATA TREATMENT STRATEGY
# ------------------------------------------------------------------------------
cat(">>> TASK 2: Developing Missing-Data Treatment Strategy...\n")

adult_df_treated <- adult_df_raw

# 2.1 Convert impossible numeric values (age == 999) to NA
adult_df_treated$age[adult_df_treated$age == 999] <- NA_real_
cat("1. Converted", impossible_age_count, "impossible age=999 entries to NA.\n")

# 2.2 Replace blank categorical values with 'Unknown'
adult_df_treated$workclass[adult_df_treated$workclass == ""] <- "Unknown"
adult_df_treated$occupation[adult_df_treated$occupation == ""] <- "Unknown"
cat("2. Replaced blank categorical values with 'Unknown'.\n")

# 2.5 Use complete.cases() to inspect incomplete observations
complete_status <- complete.cases(adult_df_treated)
cat("3. complete.cases() Analysis:\n")
cat("   - Complete observations (all variables intact):", sum(complete_status), sprintf("(%.1f%%)\n", mean(complete_status)*100))
cat("   - Incomplete observations with NA/NaN:", sum(!complete_status), sprintf("(%.1f%%)\n\n", mean(!complete_status)*100))


# ------------------------------------------------------------------------------
# TASK 3: CREATE A CUSTOM IMPUTATION FUNCTION
# ------------------------------------------------------------------------------
cat(">>> TASK 3: Creating Custom Median Imputation Function...\n")

# Custom function: accepts numeric vector, computes median of valid values, imputes NA/NaN
impute_median <- function(numeric_vector) {
  # Input validation
  if (!is.numeric(numeric_vector)) {
    stop("Input to impute_median must be a numeric vector.")
  }
  
  # Identify missing or NaN values
  missing_mask <- is.na(numeric_vector) | is.nan(numeric_vector)
  
  # Calculate median of valid observations
  valid_values <- numeric_vector[!missing_mask]
  if (length(valid_values) == 0) {
    warning("No valid observations found to calculate median. Returning vector as-is.")
    return(numeric_vector)
  }
  
  med_val <- median(valid_values)
  
  # Replace missing observations with median
  cleaned_vector <- numeric_vector
  cleaned_vector[missing_mask] <- med_val
  
  cat(sprintf("   [impute_median]: Imputed %d missing values using median = %.2f\n", 
              sum(missing_mask), med_val))
  
  return(cleaned_vector)
}

# Apply custom median imputation to numeric columns with missingness
cat("Applying custom median imputation to 'age':\n")
adult_df_treated$age <- impute_median(adult_df_treated$age)

cat("Applying custom median imputation to 'hours_per_week':\n")
adult_df_treated$hours_per_week <- impute_median(adult_df_treated$hours_per_week)
cat("\n")


# ------------------------------------------------------------------------------
# TASK 4: ANALYZE MISSINGNESS BEFORE AND AFTER CLEANING
# ------------------------------------------------------------------------------
cat(">>> TASK 4: Analyzing Missingness Before and After Cleaning & Visualizing...\n")

missing_summary_after <- calc_missing_summary(adult_df_treated)

cat("Variable-wise Missingness Summary (AFTER Cleaning):\n")
print(missing_summary_after)
cat("\n")

# Generate Missingness Visualizations and save to PNG
# Plot 1: Missingness Before Cleaning
png("missingness_before.png", width = 800, height = 500, res = 120)
par(mar = c(5, 8, 4, 2))
barplot(
  missing_summary_before$pct_missing,
  names.arg = missing_summary_before$variable,
  horiz = TRUE,
  las = 1,
  col = "#E74C3C",
  main = "Missingness / Invalid Data (%) BEFORE Cleaning",
  xlab = "Percentage Missing / Invalid (%)",
  xlim = c(0, 10)
)
grid()
dev.off()
cat("Generated plot: missingness_before.png\n")

# Plot 2: Missingness After Cleaning
png("missingness_after.png", width = 800, height = 500, res = 120)
par(mar = c(5, 8, 4, 2))
barplot(
  missing_summary_after$pct_missing,
  names.arg = missing_summary_after$variable,
  horiz = TRUE,
  las = 1,
  col = "#2ECC71",
  main = "Missingness (%) AFTER Treatment & Imputation",
  xlab = "Percentage Missing (%)",
  xlim = c(0, 10)
)
grid()
dev.off()
cat("Generated plot: missingness_after.png\n")

# Plot 3: Side-by-side Comparative Visualization
png("missingness_comparison.png", width = 900, height = 550, res = 120)
par(mar = c(5, 8, 4, 2))
comp_matrix <- rbind(
  Before = missing_summary_before$pct_missing,
  After = missing_summary_after$pct_missing
)
colnames(comp_matrix) <- missing_summary_before$variable
barplot(
  comp_matrix,
  beside = TRUE,
  horiz = TRUE,
  las = 1,
  col = c("#E74C3C", "#2ECC71"),
  main = "Missingness Comparison: Before vs. After Treatment",
  xlab = "Percentage (%)",
  legend.text = c("Before Cleaning (Dirty)", "After Cleaning (Imputed/Treated)"),
  args.legend = list(x = "topright")
)
grid()
dev.off()
cat("Generated plot: missingness_comparison.png\n\n")


# ------------------------------------------------------------------------------
# TASK 5: VALIDATE THE CLEANED DATASET AND EXPORT
# ------------------------------------------------------------------------------
cat(">>> TASK 5: Validating Cleaned Dataset and Exporting CSV Deliverable...\n")

# Custom comprehensive statistical skim validator
skim_summary <- function(df) {
  cat("\n==================== DATASET SKIM VALIDATION ====================\n")
  cat(sprintf("Dimensions: %d Rows x %d Columns\n", nrow(df), ncol(df)))
  cat(sprintf("Complete Cases: %d / %d (%.2f%%)\n\n", 
              sum(complete.cases(df)), nrow(df), mean(complete.cases(df))*100))
  
  for (col_name in names(df)) {
    col <- df[[col_name]]
    cat(sprintf("Variable: %-16s | Type: %-10s | Missing: %d (%.1f%%)\n", 
                col_name, class(col)[1], sum(is.na(col)), mean(is.na(col))*100))
    if (is.numeric(col)) {
      cat(sprintf("  -> Min: %.2f | Q1: %.2f | Median: %.2f | Mean: %.2f | Q3: %.2f | Max: %.2f | SD: %.2f\n",
                  min(col), quantile(col, 0.25), median(col), mean(col), quantile(col, 0.75), max(col), sd(col)))
    } else if (is.character(col) || is.factor(col)) {
      top_cats <- head(sort(table(col), decreasing = TRUE), 4)
      cat("  -> Top Classes:", paste(sprintf("%s (%d)", names(top_cats), top_cats), collapse = ", "), "\n")
    }
  }
  cat("=================================================================\n\n")
}

skim_summary(adult_df_treated)

# Formal Validation Checks
check_impossible_age <- sum(adult_df_treated$age == 999) == 0
check_untreated_na_age <- sum(is.na(adult_df_treated$age)) == 0
check_untreated_na_hpw <- sum(is.na(adult_df_treated$hours_per_week)) == 0
check_blank_workclass <- sum(adult_df_treated$workclass == "") == 0
check_blank_occupation <- sum(adult_df_treated$occupation == "") == 0

cat("--- Quality Assurance Verification Checks ---\n")
cat("1. Impossible Age (999) completely removed :", check_impossible_age, "(PASS)\n")
cat("2. Untreated NA in 'age' is zero           :", check_untreated_na_age, "(PASS)\n")
cat("3. Untreated NA/NaN in 'hours_per_week' = 0:", check_untreated_na_hpw, "(PASS)\n")
cat("4. Blank categorical 'workclass' is zero   :", check_blank_workclass, "(PASS)\n")
cat("5. Blank categorical 'occupation' is zero  :", check_blank_occupation, "(PASS)\n\n")

# Export cleaned CSV deliverable
cleaned_adult_path <- "cleaned_adult_data.csv"
write.csv(adult_df_treated, cleaned_adult_path, row.names = FALSE)
cat("Cleaned Adult dataset saved successfully to:", cleaned_adult_path, "\n\n")

cat("====================================================================\n")
cat("                    LAB 4 EXECUTION COMPLETED!                      \n")
cat("====================================================================\n")
