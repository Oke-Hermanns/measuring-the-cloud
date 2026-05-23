#!/usr/bin/env Rscript

detect_repo_root <- function() {
  file_arg <- grep("^--file=", commandArgs(), value = TRUE)
  if (length(file_arg) > 0) {
    script_path <- normalizePath(sub("^--file=", "", file_arg[[1]]))
    return(normalizePath(file.path(dirname(script_path), "..", "..")))
  }
  normalizePath(getwd())
}

repo_root <- detect_repo_root()
args <- commandArgs(trailingOnly = TRUE)

result_id <- if (length(args) >= 1 && nzchar(args[[1]])) args[[1]] else "all"
note <- if (length(args) >= 2 && nzchar(args[[2]])) args[[2]] else NULL

source(file.path(repo_root, "analysis", "network", "build_csv.R"), local = TRUE)
write_network_csvs(repo_root = repo_root, run_spec = result_id)

if (grepl(",", result_id, fixed = TRUE)) {
  run_ids <- trimws(strsplit(result_id, ",", fixed = TRUE)[[1]])
  result_id <- paste(c("combined", run_ids), collapse = "__")
}

output_dir <- file.path(repo_root, "analysis", "network", result_id)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

output_file <- sprintf("network_benchmark_analysis_%s.html", result_id)

rmarkdown::render(
  input = file.path(repo_root, "analysis", "network", "network_benchmark_analysis.Rmd"),
  params = list(result_id = result_id, note = note),
  output_file = output_file,
  output_dir = output_dir,
  envir = new.env(parent = globalenv())
)
