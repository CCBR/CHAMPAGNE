#!/usr/bin/env Rscript
library(dplyr)
library(glue)
library(purrr)
library(stringr)
library(readr)
library(tidyr)

main <- function(
  version_file = "versions.yml",
  peak_file = "${peak}",
  out_file = "${outfile}"
) {
  write_version(version_file)
  peak_dat <- read_peaks(peak_file) %>%
    mutate(peakID = glue("{chrom}:{start}-{end}")) %>%
    normalize() %>%
    write_tsv(out_file, col_names = FALSE)
}

get_version <- function() {
  return(paste0(R.version[["major"]], ".", R.version[["minor"]]))
}

write_version <- function(version_file) {
  write_lines(get_version(), version_file)
}

read_peaks <- function(peak_file) {
  peak_colnames <- c(
    "chrom",
    "start",
    "end",
    "peakID",
    "score",
    "strand",
    "signal",
    "pvalue",
    "qvalue",
    "peak"
  )
  peaks <- read_tsv(peak_file, col_names = FALSE)
  colnames(peaks) <- peak_colnames[seq_len(ncol(peaks))]
  return(peaks)
}

normalize <- function(peak_dat, norm_method = corces) {
  return(
    peak_dat %>%
      mutate(
        pvalue_norm = norm_method(pvalue),
        qvalue_norm = 10^(-pvalue_norm) %>%
          p.adjust(method = "BH") %>%
          -log10(.)
      ) %>%
      select(-c(pvalue, qvalue)) %>%
      rename(pvalue = pvalue_norm, qvalue = qvalue_norm)
  )
}

#' Normalize consensus peak values with the method from Corces et al.
#' https://doi.org/10.1126/science.aav1898
corces <- function(x) {
  return(x / sum(x) / 10^6)
}

main("versions.yml", "${peak}", "${outfile}")
