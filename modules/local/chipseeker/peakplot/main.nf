process CHIPSEEKER_PEAKPLOT {
    tag "${meta.id}"
    label 'peaks'
    label 'process_high'

    container 'nciccbr/ccbr_chipseeker:1.1.2'

    input:
        tuple val(meta), path(bed)
        val(txdb)
        val(annot_db)

    output:
        tuple val(meta), path("*.png"), emit: plots

    script:
    """
    chipseeker_peakplot.R \\
        --peak ${bed} \\
        --outfile-prefix ${bed.baseName} \\
        --genome-txdb ${txdb} \\
        --genome-annot ${annot_db}
    """

    stub:
    """
    for ftype in annotated.txt summary.txt genelist.txt annotation.Rds .png
    do
        touch ${meta.id}.\${ftype}
    done
    """
}
