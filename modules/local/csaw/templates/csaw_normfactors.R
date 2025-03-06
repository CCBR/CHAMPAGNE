library(csaw)
library(edgeR)
library(Rsamtools)
library(stringr)
library(tidyr)
library(dplyr)

main <- function(bam_files = c("Sp5GOF_Flag_1.bam", "Sp5GOF_Flag_2.bam", "Flag_1.bam", "Flag_2.bam"),
                 outfile_normfactors = "norm_factors.csv") {

    param <- readParam(minq=20)
    data <- windowCounts(bam_files, ext=110, width=10, param=param)

    binned <- windowCounts(bam_files, bin=TRUE, width=10000, param=param)
    keep <- filterWindowsGlobal(data, binned)$filter > log2(5)
    data <- data[keep,]

    data <- normFactors(binned, se.out=data)

    y <- asDGEList(data)
    y <- estimateDisp(y)

    norm_factors <- data.frame(norm_factors = y$samples$norm.factors,
                               bam_file = bam_files)
    readr::write_csv(norm_factors, outfile_normfactors)
}
main(bam_files = "${bam_files}" %>% str_split(',') %>% unlist(),
     outfile_normfactors = "${outfile}"
)