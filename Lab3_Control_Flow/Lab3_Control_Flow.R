# ==============================================================================
# LAB 3: CONTROL FLOW FOR DATA CLEANING
# Topic: Loops, Functions, and Error Handling in R
# Dataset: UCI Heart Disease Dataset (Resting Blood Pressure 'trestbps')
# ==============================================================================

# Set seed for reproducibility
set.seed(42)

cat("====================================================================\n")
cat("            LAB 3: CONTROL FLOW FOR DATA CLEANING IN R             \n")
cat("====================================================================\n\n")

# ------------------------------------------------------------------------------
# STEP 0: GENERATE / LOAD RAW HEART DISEASE DATASET WITH INJECTED ANOMALIES
# ------------------------------------------------------------------------------
cat(">>> STEP 0: Generating Raw UCI Heart Disease Dataset with Injected Anomalies...\n")

# Base clinical attributes simulation matching UCI Cleveland Heart Disease structure
n_patients <- 303

patient_id <- 1:n_patients
age <- round(rnorm(n_patients, mean = 54, sd = 9))
age <- pmax(29, pmin(77, age)) # Bound age between 29 and 77

sex <- sample(c(0, 1), n_patients, replace = TRUE, prob = c(0.32, 0.68)) # 1 = male, 0 = female
cp <- sample(0:3, n_patients, replace = TRUE, prob = c(0.47, 0.17, 0.28, 0.08)) # Chest pain type

# Baseline Resting Blood Pressure (trestbps in mmHg) - Normal physiological range: 94 - 200
trestbps_raw <- round(rnorm(n_patients, mean = 131, sd = 17.5))

# Baseline Cholesterol (chol in mg/dl)
chol_raw <- round(rnorm(n_patients, mean = 246, sd = 51))
chol_raw <- pmax(126, pmin(564, chol_raw))

thalach <- round(rnorm(n_patients, mean = 149, sd = 23)) # Max heart rate
target <- sample(c(0, 1), n_patients, replace = TRUE, prob = c(0.46, 0.54)) # Disease presence

# DELIBERATE INJECTION OF REALISTIC DATA-ENTRY PROBLEMS:
# 1. Negative BP values (e.g. -120, -135) - Typos / sign errors
neg_indices <- c(15, 78, 142, 220)
trestbps_raw[neg_indices] <- c(-120, -135, -110, -145)

# 2. Extreme BP readings > 300 mmHg (e.g. 310, 340, 360) - Equipment malfunction / fat-finger errors
extreme_indices <- c(34, 112, 189, 275)
trestbps_raw[extreme_indices] <- c(310, 340, 325, 360)

# 3. Missing BP values (NA) - Missing observations
na_indices <- c(50, 95, 160, 210, 280)
trestbps_raw[na_indices] <- NA

# Also inject a couple zero / NA values in cholesterol for error-handling testing
chol_raw[c(25, 130)] <- 0
chol_raw[c(60, 205)] <- NA

# Combine into Data Frame
heart_df_raw <- data.frame(
  patient_id = patient_id,
  age = age,
  sex = sex,
  cp = cp,
  trestbps = trestbps_raw,
  chol = chol_raw,
  thalach = thalach,
  target = target
)

# Save Raw Dirty Dataset to CSV
raw_csv_path <- "heart_disease_raw_dirty.csv"
write.csv(heart_df_raw, raw_csv_path, row.names = FALSE)
cat("Raw dirty dataset saved to:", raw_csv_path, "\n")
cat("Summary of Raw Resting BP (trestbps):\n")
print(summary(heart_df_raw$trestbps))
cat("Total NAs:", sum(is.na(heart_df_raw$trestbps)), "\n")
cat("Negative BP count (<0):", sum(heart_df_raw$trestbps < 0, na.rm = TRUE), "\n")
cat("Extreme BP count (>250):", sum(heart_df_raw$trestbps > 250, na.rm = TRUE), "\n\n")


# ------------------------------------------------------------------------------
# TASK 1: CREATE A BP-CLEANING FUNCTION USING IF-ELSE
# ------------------------------------------------------------------------------
cat(">>> TASK 1: Creating BP-Cleaning Function using if-else...\n")

# Single value cleaning function using conditional if-else logic
clean_single_bp <- function(bp) {
  # Check for NA first
  if (is.na(bp)) {
    return(NA_real_)
  } else if (bp < 0) {
    # Detect negative BP values and convert them to NA
    return(NA_real_)
  } else if (bp > 250) {
    # Detect resting BP values greater than 250 mmHg and cap them at 250
    return(250)
  } else {
    # Retain valid BP values without modification
    return(as.numeric(bp))
  }
}

# Wrapper function for a vector using an explicit for-loop (Loop-based)
clean_bp_loop <- function(bp_vector) {
  cleaned <- numeric(length(bp_vector))
  for (i in seq_along(bp_vector)) {
    cleaned[i] <- clean_single_bp(bp_vector[i])
  }
  return(cleaned)
}

# Vectorized BP-cleaning function using vectorized ifelse / logical indexing
clean_bp_vectorized <- function(bp_vector) {
  cleaned <- bp_vector
  # Negative values converted to NA
  cleaned[cleaned < 0] <- NA_real_
  # Values > 250 capped at 250
  cleaned[cleaned > 250 & !is.na(cleaned)] <- 250
  return(cleaned)
}

# Test Task 1 function on specific sample inputs
test_vals <- c(-120, 120, 270, NA, 320, 140, -50)
cat("Testing clean_single_bp on:", paste(test_vals, collapse = ", "), "\n")
cat("Result:", paste(sapply(test_vals, clean_single_bp), collapse = ", "), "\n\n")


# ------------------------------------------------------------------------------
# TASK 2: IMPLEMENT ERROR HANDLING USING tryCatch()
# ------------------------------------------------------------------------------
cat(">>> TASK 2: Implementing Robust Error Handling using tryCatch()...\n")

# 2.1 Safely calculate mean BP when missing values / invalid data are present
safe_mean_bp <- function(bp_vector, na_rm = TRUE) {
  tryCatch(
    expr = {
      # Input validation
      if (!is.numeric(bp_vector)) {
        stop("Input vector 'bp_vector' must be numeric.")
      }
      if (length(bp_vector) == 0) {
        warning("Input vector is empty. Returning NA.")
        return(NA_real_)
      }
      
      valid_elements <- bp_vector[!is.na(bp_vector)]
      if (length(valid_elements) == 0) {
        warning("All elements in the input vector are NA. Returning NA.")
        return(NA_real_)
      }
      
      calc_mean <- mean(bp_vector, na.rm = na_rm)
      return(calc_mean)
    },
    warning = function(w) {
      cat("[WARNING in safe_mean_bp]:", conditionMessage(w), "\n")
      return(NA_real_)
    },
    error = function(e) {
      cat("[ERROR in safe_mean_bp]:", conditionMessage(e), "\n")
      return(NA_real_)
    }
  )
}

# 2.2 Safely calculate a ratio (such as chol / trestbps) with full exception handling
safe_calc_ratio <- function(chol, trestbps) {
  tryCatch(
    expr = {
      # Verify inputs are numeric
      if (!is.numeric(chol) || !is.numeric(trestbps)) {
        stop("Both numerator (chol) and denominator (trestbps) must be numeric values.")
      }
      
      # Handle NA in either component
      if (is.na(chol) || is.na(trestbps)) {
        warning(paste0("Encountered NA value (chol=", chol, ", trestbps=", trestbps, "). Ratio cannot be computed."))
        return(NA_real_)
      }
      
      # Handle zero or negative denominator
      if (trestbps == 0) {
        warning("Division by zero encountered: trestbps is 0. Returning NA.")
        return(NA_real_)
      }
      if (trestbps < 0) {
        warning(paste0("Invalid negative denominator: trestbps=", trestbps, ". Returning NA."))
        return(NA_real_)
      }
      
      # Calculate valid ratio
      ratio <- chol / trestbps
      return(round(ratio, 4))
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

# Vectorized wrapper for safe ratio calculation
safe_chol_bp_ratio_vector <- function(chol_vec, bp_vec) {
  n <- length(chol_vec)
  ratios <- numeric(n)
  for (i in 1:n) {
    # Suppress verbose inline prints for large vector run, but catch edge cases
    suppressWarnings({
      if (is.na(chol_vec[i]) || is.na(bp_vec[i]) || bp_vec[i] <= 0) {
        ratios[i] <- NA_real_
      } else {
        ratios[i] <- round(chol_vec[i] / bp_vec[i], 4)
      }
    })
  }
  return(ratios)
}

# Demonstrate tryCatch on diverse edge cases:
cat("--- Demonstrating safe_mean_bp tryCatch() ---\n")
cat("Safe mean on valid vector:", safe_mean_bp(c(120, 130, 140, NA)), "\n")
cat("Safe mean on all NAs:", safe_mean_bp(c(NA, NA)), "\n")
cat("Safe mean on non-numeric input:", safe_mean_bp("invalid_data"), "\n\n")

cat("--- Demonstrating safe_calc_ratio tryCatch() ---\n")
cat("Valid Ratio (240 / 120):", safe_calc_ratio(240, 120), "\n")
cat("Zero Denominator (240 / 0):", safe_calc_ratio(240, 0), "\n")
cat("NA Denominator (240 / NA):", safe_calc_ratio(240, NA), "\n")
cat("Negative Denominator (240 / -120):", safe_calc_ratio(240, -120), "\n")
cat("Invalid Type ('two' / 120):", safe_calc_ratio("two", 120), "\n\n")


# ------------------------------------------------------------------------------
# TASK 3: COMPARE LOOP-BASED AND VECTORIZED DATA CLEANING
# ------------------------------------------------------------------------------
cat(">>> TASK 3: Comparing Loop-Based vs. Vectorized Execution Time...\n")

# Create a large simulated benchmark dataset by replicating the vector (N = 500,000)
large_n <- 500000
large_bp_sample <- sample(trestbps_raw, size = large_n, replace = TRUE)

cat("Benchmarking on large vector of size N =", large_n, "elements...\n")

# 1. Benchmark Loop-based approach
time_loop <- system.time({
  cleaned_large_loop <- clean_bp_loop(large_bp_sample)
})

# 2. Benchmark Vectorized approach
time_vectorized <- system.time({
  cleaned_large_vec <- clean_bp_vectorized(large_bp_sample)
})

# Check accuracy equivalence
is_identical <- all.equal(cleaned_large_loop, cleaned_large_vec)

# Output Timing Comparison
cat("\n================ BENCHMARK RESULTS (system.time) ================\n")
cat(sprintf("%-25s : Elapsed Time: %.4f seconds (User: %.4f s, Sys: %.4f s)\n", 
            "1. For-Loop Approach", time_loop["elapsed"], time_loop["user.self"], time_loop["sys.self"]))
cat(sprintf("%-25s : Elapsed Time: %.4f seconds (User: %.4f s, Sys: %.4f s)\n", 
            "2. Vectorized Approach", time_vectorized["elapsed"], time_vectorized["user.self"], time_vectorized["sys.self"]))

speedup <- round(time_loop["elapsed"] / max(time_vectorized["elapsed"], 0.0001), 2)
cat(sprintf("Vectorized method is approximately %.2fx FASTER than the for-loop method.\n", speedup))
cat("Outputs from both approaches are identical:", is_identical, "\n")
cat("==================================================================\n\n")


# ------------------------------------------------------------------------------
# TASK 4: VALIDATE THE CLEANED DATA AND EXPORT DELIVERABLE
# ------------------------------------------------------------------------------
cat(">>> TASK 4: Validating Cleaned Data and Exporting Results...\n")

# Apply cleaning to the full heart disease dataset
heart_df_cleaned <- heart_df_raw
heart_df_cleaned$trestbps_cleaned <- clean_bp_vectorized(heart_df_raw$trestbps)
heart_df_cleaned$chol_trestbps_ratio <- safe_chol_bp_ratio_vector(heart_df_cleaned$chol, heart_df_cleaned$trestbps_cleaned)

# 4.1 Count missing BP values before and after
missing_bp_before <- sum(is.na(heart_df_raw$trestbps))
missing_bp_after <- sum(is.na(heart_df_cleaned$trestbps_cleaned))

# 4.2 Statistical summaries for cleaned BP
clean_bp_no_na <- na.omit(heart_df_cleaned$trestbps_cleaned)
min_bp <- min(clean_bp_no_na)
max_bp <- max(clean_bp_no_na)
mean_bp <- mean(clean_bp_no_na)
median_bp <- median(clean_bp_no_na)

# 4.3 Validation checks
has_negative <- any(clean_bp_no_na < 0)
has_above_250 <- any(clean_bp_no_na > 250)

cat("--- Validation Summary for Resting BP (trestbps) ---\n")
cat("1. Missing BP Count (Before) :", missing_bp_before, "(Original NAs)\n")
cat("2. Missing BP Count (After)  :", missing_bp_after, "(Original NAs + Injected Negatives converted to NA)\n")
cat(sprintf("3. Minimum Cleaned BP        : %.1f mmHg\n", min_bp))
cat(sprintf("4. Maximum Cleaned BP        : %.1f mmHg (Capped at 250)\n", max_bp))
cat(sprintf("5. Mean Cleaned BP           : %.2f mmHg\n", mean_bp))
cat(sprintf("6. Median Cleaned BP         : %.2f mmHg\n", median_bp))
cat("7. Any Negative BP Remaining :", has_negative, "(PASS: No negative values)\n")
cat("8. Any BP > 250 Remaining    :", has_above_250, "(PASS: All extreme values capped at 250)\n\n")

# Export final cleaned CSV deliverable
cleaned_csv_path <- "cleaned_heart_data.csv"
write.csv(heart_df_cleaned, cleaned_csv_path, row.names = FALSE)
cat("Cleaned dataset successfully exported to:", cleaned_csv_path, "\n\n")

cat("====================================================================\n")
cat("                    LAB 3 EXECUTION COMPLETED!                      \n")
cat("====================================================================\n")
