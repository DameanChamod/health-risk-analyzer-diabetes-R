# tests/testthat/helper_paths.R
# Compute project root from the tests directory:
proj_root <- normalizePath(file.path(testthat::test_path(), "..", ".."),
                           winslash = "/", mustWork = TRUE)

# Convenience joiner:
p <- function(...) file.path(proj_root, ...)

# Load shared code for all tests:
source(p("R", "config.R"))
source(p("R", "utils_data.R"))
