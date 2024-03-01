#!/usr/bin/env Rscript
# adapted from: https://github.com/CCBR/ASPEN/blob/55f909d76500c3502c1c397ef3000908649b0284/workflow/scripts/ccbr_annotate_peaks.R
load_package <- function(x) {
  suppressPackageStartupMessages(library(x, character.only = TRUE))
  invisible(x)
}
messages <- lapply(c("ChIPseeker", "dplyr", "glue", "ggplot2"), load_package)

parser <- argparse::ArgumentParser()
parser$add_argument("-p", "--peak", required = TRUE, help = "peak file")
parser$add_argument("-u", "--uptss", required = FALSE, type = "integer", default = 2000, help = "upstream bases from TSS")
parser$add_argument("-d", "--downtss", required = FALSE, type = "integer", default = 2000, help = "upstream bases from TSS")
parser$add_argument("-t", "--toppromoterpeaks", required = FALSE, type = "integer", default = 1000, help = "filter top N peaks in promoters for genelist output")
parser$add_argument("-o", "--outfile-prefix", required = TRUE, type = "character", dest = "outfile_prefix", help = "prefix for output filenames")
parser$add_argument("--genome-txdb", dest = "txdb", required = TRUE, help = "BioConductor TxDb package, e.g. TxDb.Hsapiens.UCSC.hg38.knownGene")
parser$add_argument("--genome-annot", dest = "adb", required = TRUE, help = "BioConductor annotation package, e.g. org.Hs.eg.db")
parser$add_argument("--cores", required = TRUE, type = "integer", help = "Number of cores to use")

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
dir.create(file.path(outfile_prefix), showWarnings = FALSE)

# parse peak file
np <- read.table(args$peak, sep = "\t")
peak_colnames <- c(
  "chrom",
  "chromStart",
  "chromEnd",
  "name",
  "score",
  "strand",
  "signalValue",
  "pValue",
  "qValue"
)
num_columns <- ncol(np)
if (num_columns == 9) {
  colnames(np) <- peak_colnames
  np <- np %>% mutate(peak = NA)
} else if (num_columns == 10) {
  colnames(np) <- c(peak_colnames, "peak")
} else {
  stop(paste("Expected 9 or 10 columns in peak file, but", num_columns, "given"))
}
np <- np[order(-np$qValue), ]
np$peakID <- paste(np$chrom, ":", np$chromStart, "-", np$chromEnd, sep = "")

peaks <- GenomicRanges::GRanges(
  seqnames = np$chrom,
  ranges = IRanges(np$chromStart, np$chromEnd)
)

# using annotatePeak from ChIPseeker
annot <- annotatePeak(
  peak = peaks,
  tssRegion = c(-2000, 2000),
  TxDb = txdb,
  level = "transcript",
  genomicAnnotationPriority = c("Promoter", "5UTR", "3UTR", "Exon", "Intron", "Downstream", "Intergenic"),
  annoDb = adb,
  sameStrand = FALSE,
  ignoreOverlap = FALSE,
  ignoreUpstream = FALSE,
  ignoreDownstream = FALSE,
  overlap = "TSS"
)
saveRDS(annot, file = glue("{outfile_prefix}/{outfile_prefix}.annotation.Rds"))

padf <- as.data.frame(annot)
padf$peakID <- paste(padf$seqnames, ":", padf$start, "-", padf$end, sep = "")
merged <- dplyr::full_join(padf, np, by = "peakID") %>%
  dplyr::select(any_of(c(
    "peakID",
    "chrom",
    "chromStart",
    "chromEnd",
    "width",
    "annotation",
    "geneChr",
    "geneStart",
    "geneEnd",
    "geneLength",
    "geneStrand",
    "geneId",
    "transcriptId",
    "distanceToTSS",
    "ENSEMBL",
    "SYMBOL",
    "GENENAME",
    "score",
    "signalValue",
    "pValue",
    "qValue",
    "peak"
  ))) %>%
  dplyr::rename("#peakID" = "peakID") %>%
  dplyr::arrange(dplyr::desc(qValue))

annotated_outfile <- glue("{outfile_prefix}/{outfile_prefix}.annotated.txt")
write.table(merged, annotated_outfile, sep = "\t", quote = FALSE, row.names = FALSE)
l <- paste("# Median peak width : ", median(merged$width), sep = "")
write(l, annotated_outfile, append = TRUE)
l <- paste("# Median pValue : ", median(merged$pValue), sep = "")
write(l, annotated_outfile, append = TRUE)
l <- paste("# Median qValue : ", median(merged$qValue), sep = "")
write(l, annotated_outfile, append = TRUE)


# get promoter genes
outfile_genelist <- glue("{outfile_prefix}/{outfile_prefix}.genelist.txt")
# ... all lines with annotation starting with "Promoter"
promoters1 <- dplyr::filter(merged, grepl("Promoter", annotation))
# ... all lines with annotation is "5' UTR"
promoters2 <- merged[merged$annotation == "5' UTR", ]
promoters <- rbind(promoters1, promoters2)
promoters <- promoters[order(-promoters$qValue), ]
promoters <- head(promoters, n = args$toppromoterpeaks)
# ENSEMBL and SYMBOL may not be in the merged df columns, depending on adb/txdb
if (length(intersect(c("ENSEMBL", "SYMBOL"), colnames(promoters))) == 2) {
  promoter_genes <- unique(promoters[, c("ENSEMBL", "SYMBOL")])
  colnames(promoter_genes) <- c("#ENSEMBL", "SYMBOL")
  write.table(promoter_genes, outfile_genelist, sep = "\t", quote = FALSE, row.names = FALSE)
}
l <- paste("# Median peak width : ", median(promoters$width), sep = "")
write(l, outfile_genelist, append = TRUE)
l <- paste("# Median pValue : ", median(promoters$pValue), sep = "")
write(l, outfile_genelist, append = TRUE)
l <- paste("# Median qValue : ", median(promoters$qValue), sep = "")
write(l, outfile_genelist, append = TRUE)

# annotation type frequency table

l <- paste("#annotationType", "frequency", "medianWidth", "medianpValue", "medianqValue", sep = "\t")
outfile_summary <- glue("{outfile_prefix}/{outfile_prefix}.summary.txt")
write(l, outfile_summary)
atypes <- c(
  "3' UTR",
  "5' UTR",
  "Distal Intergenic",
  "Downstream (<1kb)",
  "Downstream (1-2kb)",
  "Downstream (2-3kb)",
  "Promoter (<=1kb)",
  "Promoter (1-2kb)"
)
for (ann in atypes) {
  x <- merged[merged$annotation == ann, ]
  w <- median(x$width)
  p <- median(x$pValue)
  q <- median(x$qValue)
  l <- paste(gsub(" ", "", ann), nrow(x), w, p, q, sep = "\t")
  write(l, outfile_summary, append = TRUE)
}
for (ann in c("Exon", "Intron")) {
  x <- dplyr::filter(merged, grepl(ann, annotation))
  w <- median(x$width)
  p <- median(x$pValue)
  q <- median(x$qValue)
  l <- paste(gsub(" ", "", ann), nrow(x), w, p, q, sep = "\t")
  write(l, outfile_summary, append = TRUE)
}

# upset plot
ggsave(
  filename = glue("{outfile_prefix}/{outfile_prefix}_upsetplot.png"),
  plot = upsetplot(annot, vennpie = TRUE),
  device = "png"
)
