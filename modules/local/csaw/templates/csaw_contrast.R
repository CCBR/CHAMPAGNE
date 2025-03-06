library(chipseqDBData)
library(csaw)
library(edgeR)
library(Rsamtools)
library(EnhancedVolcano)
library(stringr)
library(tidyr)
library(dplyr)
library(ChIPseeker)
library(TxDb.Mmusculus.UCSC.mm10.knownGene)  # Mouse genome annotation
library(org.Mm.eg.db)  # Mouse gene ID annotations
library(GenomicRanges)

main <- function(bam_files = c("Sp5GOF_Flag_1.bam", "Sp5GOF_Flag_2.bam", "Flag_1.bam", "Flag_2.bam"),
                sample_conditions = factor(c("Sp5GOF_Flag", "Sp5GOF_Flag", "Flag", "Flag")),
                outfile_annot = "annotated_combined_results.csv",
                outfile_normfactors = "norm_factors.txt") {

    design <- model.matrix(~sample_conditions)
    colnames(design) <- c("intercept", "condition")

    param <- readParam(minq=20)
    data <- windowCounts(bam_files, ext=110, width=10, param=param)

    binned <- windowCounts(bam_files, bin=TRUE, width=10000, param=param)
    keep <- filterWindowsGlobal(data, binned)$filter > log2(5)
    data <- data[keep,]

    data <- normFactors(binned, se.out=data)

    y <- asDGEList(data)
    y <- estimateDisp(y, design)
    fit <- glmQLFit(y, design, robust=TRUE)
    results <- glmQLFTest(fit)

    merged <- mergeResults(data, results$table, tol=1000L)

    summary(as.data.frame(merged$combined))
    hist(merged$combined$FDR)


    # TODO use combined instead of combined results
    combined_data <- as.data.frame(merged$combined)  # Extract as normal dataframe
    combined_data$regions <- as.character(merged$regions)  # Add genomic regions as strings

    # Split "regions" into three new columns
    combined_data <- combined_data %>%
    separate(regions, into = c("chr", "range"), sep = ":", remove = FALSE) %>%
    separate(range, into = c("start", "end"), sep = "-", convert = TRUE)

    # Check new structure
    head(combined_data)

    str(combined_data)  # Verify structure
    head(combined_data)  # View top rows


    # Extract chromosome, start, end positions from `regions`
    gr <- makeGRangesFromDataFrame(combined_data, keep.extra.columns=TRUE)

    # Load required libraries

    # Load mouse transcript database
    txdb <- TxDb.Mmusculus.UCSC.mm10.knownGene

    # Annotate peaks
    annotated_peaks <- annotatePeak(gr, TxDb=txdb, tssRegion=c(-2000, 2000), annoDb="org.Mm.eg.db")

    # Convert annotation to data frame
    annotated_df <- as.data.frame(annotated_peaks)

    # Merge with combined_data
    final_annotated <- cbind(combined_data, annotated_df)

    # Save annotated results
    readr::write_csv(final_annotated, outfile_annot)

    colnames(combined_data)
    logFC_col <- "rep.logFC"
    pval_col <- "FDR"

    EnhancedVolcano(combined_data,
                    lab=rownames(combined_data),
                    x = "rep.logFC",  # Log fold change column
                    y = "FDR",  # P-value column
                    title = "Differential Binding Analysis (csaw)",
                    pCutoff = 0.01,  # Significance threshold
                    FCcutoff = 1,  # Fold change threshold (log2)
                    pointSize = 2.0,  # Size of points
                    labSize = 3.0,  # Label size
                    col = c("black", "blue", "red", "red"),  # Colors: nonsig, lowFC, highFC, both
                    colAlpha = 0.75,  # Transparency
                    legendPosition = "right",
                    gridlines.major = TRUE,
                    gridlines.minor = FALSE
    )
    norm_factors <- data.frame(norm_factors = y$samples$norm.factors,
                               bam_file = bam_files)
    print(norm_factors) # use these with deeptools to scale bigwigs along with --normalizeUsing RPKM
    readr::write_csv(norm_factors, outfile_normfactors)
}