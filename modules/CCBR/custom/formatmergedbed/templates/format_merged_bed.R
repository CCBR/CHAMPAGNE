#!/usr/bin/env Rscript
library(dplyr)
library(glue)
library(purrr)
library(stringr)
library(readr)
library(tidyr)

main <- function(
  version_file = "versions.yml",
  merged_file = "${merged_bed}",
  out_file = "${outfile}",
  n_cores = as.integer("${task.cpus}"),
  min_count = 1
) {
  doFuture::registerDoFuture()
  future::plan(future::multicore, workers = n_cores)
  write_version(version_file)
  merged_dat <- read_tsv(
    merged_file,
    col_names = FALSE,
    col_types = "ciiiccccc"
  )
  if (nrow(merged_dat) == 0) {
    stop("The merged bed file is empty")
  }
  colnames(merged_dat) <- c(
    "chrom",
    "start",
    "end",
    "counts",
    "score_cat",
    "strand_cat",
    "signal_cat",
    "pvalue_cat",
    "qvalue_cat"
  )
  merged_dat %>%
    filter(counts >= min_count) %>%
    future.apply::future_apply(1, select_best_peak) %>%
    bind_rows() %>%
    select(
      "chrom",
      "start",
      "end",
      "peakID",
      "score",
      "strand",
      "signal",
      "pvalue",
      "qvalue"
    ) %>%
    write_tsv(out_file, col_names = FALSE)
}

select_best_peak <- function(dat_row) {
  return(
    dat_row %>%
      vec_to_df() %>%
      pivot_collapsed_columns() %>%
      slice_max(pvalue, n = 1, with_ties = FALSE)
  )
}

vec_to_df <- function(vec) {
  vec %>%
    as.list() %>%
    as_tibble()
}

pivot_collapsed_columns <- function(dat_row) {
  row_pivot <- dat_row %>%
    select(ends_with("_cat")) %>%
    t() %>%
    as.data.frame()
  long_row <- row_pivot %>%
    mutate(names = rownames(row_pivot)) %>%
    separate_wider_delim(V1, delim = ",", names_sep = "_") %>%
    mutate(names = str_replace(names, "_cat", "")) %>%
    pivot_longer(starts_with("V1")) %>%
    pivot_wider(names_from = names, values_from = value) %>%
    select(-name)
  return(
    dat_row %>%
      select(-ends_with("cat")) %>%
      bind_cols(long_row) %>%
      mutate(across(c("start", "end", "counts"), as.integer)) %>%
      mutate(peakID = glue("{chrom}:{start}-{end}")) %>%
      mutate(across(c("score", "signal", "pvalue", "qvalue"), as.numeric))
  )
}

write_version <- function(version_file) {
  write_lines(get_version(), version_file)
}

get_version <- function() {
  return(paste0(R.version[["major"]], ".", R.version[["minor"]]))
}


main(
  "versions.yml",
  "${merged_bed}",
  "${outfile}",
  n_cores = as.integer("${task.cpus}")
)
