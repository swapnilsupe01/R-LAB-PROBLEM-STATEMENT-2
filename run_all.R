# ==============================================================================
# MASTER RUNNER: LAB PROBLEM STATEMENT 2
# Executes Lab 3 (Control Flow for Data Cleaning) and Lab 4 (Advanced Missing Data)
# ==============================================================================

cat("\n====================================================================\n")
cat("          STARTING FULL EXECUTION: LAB PROBLEM STATEMENT 2          \n")
cat("====================================================================\n\n")

# Get script directory
base_dir <- getwd()
cat("Working Directory:", base_dir, "\n\n")

# 1. RUN LAB 3
cat(">>> [1/2] RUNNING LAB 3: CONTROL FLOW FOR DATA CLEANING...\n")
lab3_dir <- file.path(base_dir, "Lab3_Control_Flow")
if (dir.exists(lab3_dir)) setwd(lab3_dir)

source("Lab3_Control_Flow.R")
setwd(base_dir)

cat("\n--------------------------------------------------------------------\n")

# 2. RUN LAB 4
cat(">>> [2/2] RUNNING LAB 4: ADVANCED MISSING DATA HANDLING...\n")
lab4_dir <- file.path(base_dir, "Lab4_Missing_Data")
if (dir.exists(lab4_dir)) setwd(lab4_dir)

source("Lab4_Advanced_Missing_Data.R")
setwd(base_dir)

cat("\n====================================================================\n")
cat("    ALL LABS COMPLETED SUCCESSFULLY! ALL DELIVERABLES GENERATED     \n")
cat("====================================================================\n")
