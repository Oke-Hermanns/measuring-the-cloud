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

system2("Rscript", c(file.path(repo_root, "analysis", "storage", "build_csv.R"), result_id))

output_dir <- file.path(repo_root, "analysis", "storage", result_id)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

output_file <- sprintf("storage_benchmark_analysis_%s.html", result_id)

rmarkdown::render(
  input = file.path(repo_root, "analysis", "storage", "storage_benchmark_analysis.Rmd"),
  params = list(result_id = result_id, note = note),
  output_file = output_file,
  output_dir = output_dir,
  envir = new.env(parent = globalenv())
)

