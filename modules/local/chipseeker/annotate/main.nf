process CHIPSEEKER_ANNOTATE {
    tag "${meta.id}.${group}"
    label 'peaks'
    label 'process_medium'

    container 'nciccbr/ccbr_chipseeker:1.1.2'

    input:
        tuple val(meta), path(bed), val(group)

    output:
        tuple val(meta), path("*.annotated.txt"), path("*.summary.txt"), path("*.genelist.txt"), emit: txt
        path("*.annotation.Rds"),                                                                emit: annot
        path("*.png"),                                                                           emit: plots

    script:
    """
    chipseeker_annotate.R \\
        --peak ${bed} \\
        --outfile-prefix ${meta.id}.${group} \\
        --genome ${params.genome} \\
        --uptss 2000 \\
        --downtss 2000 \\
        --toppromoterpeaks 1000
    """

    stub:
    """
    for ftype in annotated.txt summary.txt genelist.txt annotation.Rds .png
    do
        touch ${meta.id}.${group}.\${ftype}
    done
    """
}
