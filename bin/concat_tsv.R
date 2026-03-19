#!/usr/bin/env Rscript --vanilla

library(dplyr)
library(purrr)
library(readr)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop(
    "Error: not enough positional arguments; need at least 2.\n  Example usage:\n   Rscript concat_tsv.R output.tsv path/to/file1.tsv path/to/file2.tsv"
  )
}

args[-1] %>%
  map(read_tsv) %>%
  list_rbind() %>%
  write_tsv(args[1])
