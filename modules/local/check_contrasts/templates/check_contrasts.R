#!/usr/bin/env Rscript
options(error = rlang::entrace)
library(assertthat)
library(dplyr)
library(glue)

main <- function(contrasts_filename = "${contrasts}",
                 samplesheet_filename = "${samplesheet}",
                 versions_filename = "versions.yml",
                 process_name = "${task.process}") {
  write_version(versions_filename, process_name = process_name)
  contrasts_df <- readr::read_tsv(contrasts_filename)
  assert_that(all(colnames(contrasts_df) == c("contrast_name", "group1", "group2")))

  samples_df <- readr::read_csv(samplesheet_filename)
  sample_names  <- samples_df %>% dplyr::pull(sample)
  # check individual contrasts
  purrr::pmap(contrasts_df, check_contrast, sample_names = sample_names)

  # ensure contrast names are unique
  contrast_names <- contrasts_df %>% dplyr::pull(contrast_name)
  assert_that(
    length(unique(contrast_names)) == length(contrast_names),
    msg = glue("Contrast names must be unique")
  )
  message("✅ Contrasts are all valid")
}

#' Check an individual contrast comparison
check_contrast <- function(contrast_name, group1, group2, sample_names) {
  group1_samples <- unlist(strsplit(group1, ","))
  group2_samples <- unlist(strsplit(group2, ","))
  # Ensure each group has at least 1 sample
  assert_that(length(group1_samples) > 0,
              msg = glue("group1 must have at least one sample for {contrast_name}"))
  assert_that(length(group2_samples) > 0,
              msg = glue("group2 must have at least one sample for {contrast_name}"))
  # Ensure every sample is in the sample sheet
  extra_samples <- setdiff(c(group1_samples,group2_samples), sample_names)
  assert_that(length(extra_samples) == 0,
              msg = glue("All samples in {contrast_name} must be in the sample sheet. Extra samples found: {paste(extra_samples, collapse = ',')}"))
  # Ensure each sample is in only one group
  assert_that(
    length(intersect(group1_samples, group2_samples)) == 0,
    msg = glue("Each sample can only appear in one group per contrast (check {contrast_name})")
  )
}

#' Get R version as a semantic versioning string
get_r_version <- function() {
  return(paste0(R.version[["major"]], ".", R.version[["minor"]]))
}

#' Write R version to a yaml file
write_version <- function(version_file, process_name = "${task.process}") {
  readr::write_lines(
    glue('"{process_name}":',
      "R: {get_r_version()}",
      .sep = "\\n\\t"
    ),
    version_file
  )
}

main()
