#!/usr/bin/env Rscript

# ---- Libraries ----
suppressPackageStartupMessages({
  library(argparse)
  library(GenomicRanges)
  library(rtracklayer)
  library(igraph)
})

# ---- Functions ----

addScorePerMillion <- function(gr) {
  pvals <- mcols(gr)[["pValue"]]
  mcols(gr)$score_per_million <- pvals * 1e6 / sum(pvals, na.rm = TRUE)
  return(gr)
}

centerPeaks <- function(gr, width = 500, summit_col = "peak") {
  if (!is.null(summit_col) && summit_col %in% colnames(mcols(gr))) {
    summit_val <- mcols(gr)[[summit_col]]
    use_peak <- summit_val >= 0
    centers <- ifelse(use_peak, start(gr) + summit_val, floor((start(gr) + end(gr)) / 2))
  } else {
    centers <- floor((start(gr) + end(gr)) / 2)
  }
  half_width <- floor(width / 2)
  IR <- IRanges(start = centers - half_width, width = width)
  gr <- GRanges(seqnames = seqnames(gr), ranges = IR, strand = strand(gr), mcols(gr))
  return(gr)
}

deduplicatePeaksFast <- function(gr, score_col = "score_per_million") {
  if (!score_col %in% colnames(mcols(gr))) stop(paste("Missing column:", score_col))
  hits <- findOverlaps(gr, gr, ignore.strand = TRUE)
  ov_df <- as.data.frame(hits)
  ov_df <- ov_df[ov_df$queryHits != ov_df$subjectHits, ]
  if (nrow(ov_df) == 0) {
    return(gr)
  }
  g <- graph_from_data_frame(ov_df, directed = FALSE)
  comps <- components(g)$membership
  comp_groups <- split(as.integer(names(comps)), comps)
  best_idx <- unlist(lapply(comp_groups, function(idx) {
    scores <- mcols(gr[idx])[[score_col]]
    idx[which.max(scores)]
  }))
  all_idx <- seq_along(gr)
  ungrouped_idx <- setdiff(all_idx, as.integer(names(comps)))
  gr[sort(c(best_idx, ungrouped_idx))]
}

processNarrowPeak <- function(file, width = 500) {
  gr <- import(file, format = "narrowPeak")
  gr <- addScorePerMillion(gr)
  gr <- centerPeaks(gr, width = width)
  return(gr)
}

gr_to_table <- function(gr, output_file) {
  # Convert GRanges to data.frame
  df <- data.frame(
    seqnames = as.character(seqnames(gr)),
    start = start(gr),
    end = end(gr),
    as.data.frame(mcols(gr)),
    stringsAsFactors = FALSE
  )
  df$strand <- "."
  df <- df[, c("seqnames", "start", "end", "name", "score", "strand", "signalValue", "pValue", "qValue", "peak")]

  # Write without column names or row names
  write.table(
    df,
    file = output_file,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    col.names = FALSE
  )
}


# ---- Argument Parsing ----

parser <- ArgumentParser(description = "Merge and deduplicate narrowPeak files by score_per_million")
parser$add_argument("narrowPeak_files", nargs = "+", help = "List of narrowPeak files to process")
parser$add_argument("--width", type = "integer", default = 500, help = "Peak width centered on summit or midpoint (default: 500)")
parser$add_argument("--output", type = "character", default = "merged_dedup_peaks.narrowPeak", help = "Output narrowPeak file")

args <- parser$parse_args()

# ---- Main Workflow ----

cat("Processing files:\n", paste(args$narrowPeak_files, collapse = "\n"), "\n\n")

# Step 1: Process each file individually
gr_list <- lapply(args$narrowPeak_files, function(file) {
  processNarrowPeak(file, width = args$width)
})

# Step 2: Merge all GRanges
gr_all <- do.call(c, gr_list)

# Step 3: Deduplicate by score_per_million
gr_final <- deduplicatePeaksFast(gr_all, score_col = "score_per_million")

# Step 4: Replace pValue column with score_per_million
mcols(gr_final)$pValue <- mcols(gr_final)$score_per_million
mcols(gr_final)$score_per_million <- NULL # optional cleanup

# Step 5: write output
gr_to_table(gr_final, args$output)

cat("Done! Wrote", length(gr_final), "peaks to", args$output, "\n")
