process RENAME_DELIM_CONTIGS {
    """
    Convert ensembl to UCSC contig names in a delimited file (e.g. GTF, BED)
    using cvbio https://github.com/clintval/cvbio#updatecontignames
    """
    tag { delim }

    container "nciccbr/ccbr_cvbio_3.0.0:v1.0.1"

    input:
        path(delim)
        path(map)

    output:
        path("*_renamed*"), emit: delim

    script:
    def renamed_delim = "${delim.getSimpleName()}_renamed.${delim.getExtension()}"
    """
    cvbio UpdateContigNames \\
        -i ${delim} \\
        -o ${renamed_delim} \\
        -m ${map} \\
        --comment-chars '#' \\
        --columns 0 \\
        --skip-missing false
    """

    stub:
    def renamed_delim = "${delim.getSimpleName()}_renamed.${delim.getExtension()}"
    """
    touch ${renamed_delim}
    """
}
