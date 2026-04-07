#!/usr/bin/env Rscript
load_package <- function(x) {
  suppressPackageStartupMessages(library(x, character.only = TRUE))
  invisible(x)
}
messages <- lapply(c("ChIPseeker", "dplyr", "glue", "ggplot2"), load_package)

parser <- argparse::ArgumentParser()
parser$add_argument("-p", "--peak", required = TRUE, help = "peak file")
parser$add_argument(
  "-o",
  "--outfile-prefix",
  required = TRUE,
  type = "character",
  dest = "outfile_prefix",
  help = "prefix for output filenames"
)
parser$add_argument(
  "--genome-txdb",
  dest = "txdb",
  required = TRUE,
  help = "BioConductor TxDb package, e.g. TxDb.Hsapiens.UCSC.hg38.knownGene"
)
parser$add_argument(
  "--genome-annot",
  dest = "adb",
  required = TRUE,
  help = "BioConductor annotation package, e.g. org.Hs.eg.db"
)

# get command line options, if help option encountered print help and exit,
# otherwise if options not found on command line then set defaults,
args <- parser$parse_args()
outfile_prefix <- args$outfile_prefix
adb <- args$adb
load_package(adb)
load_package(args$txdb)
txdb <- args$txdb %>%
  rlang::sym() %>%
  eval()

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
  peaks <- read.table(peak_file, sep = "\t")
  if (!dplyr::between(ncol(peaks), 9, 10)) {
    stop("Unexpected number of columns in peak file")
  }
  colnames(peaks) <- peak_colnames[seq_len(ncol(peaks))]
  return(peaks)
}
np <- read_peaks(args$peak)

# plots for individual peak file
peaks <- GenomicRanges::GRanges(
  seqnames = np$chrom,
  ranges = IRanges(np$start, np$end),
  pvalue = np$pvalue,
  qvalue = np$qvalue
)
print(peaks)
plots <- list(
  covplot = covplot(peaks, weightCol = "qvalue"),
  plotPeakProf2 = plotPeakProf2(
    peak = peaks,
    upstream = rel(0.2),
    downstream = rel(0.2),
    conf = 0.95,
    by = "gene",
    type = "body",
    nbin = 800,
    TxDb = txdb,
    weightCol = "qvalue",
    ignore_strand = TRUE
  )
)

names(plots) %>%
  lapply(function(plot_name) {
    ggsave(
      filename = glue("{outfile_prefix}_{plot_name}.png"),
      plot = plots[[plot_name]],
      device = "png"
    )
  })
