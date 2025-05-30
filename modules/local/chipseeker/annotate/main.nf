process CHIPSEEKER_ANNOTATE {
    tag "${meta.id}"
    label 'peaks'
    label 'process_high'

    container 'nciccbr/ccbr_chipseeker:1.1.2'

    input:
        tuple val(meta), path(bed)
        val(txdb)
        val(annot_db)

    output:
        tuple val(meta), path("${meta.id}/*.annotated.txt"), path("${meta.id}/*.summary.txt"), path("${meta.id}/*.genelist.txt"), emit: txt
        path("${meta.id}/*.annotation.Rds"),                                                                emit: annot
        path("${meta.id}/*.png"),                                                                           emit: plots

    script:
    """
    chipseeker_annotate.R \\
        --peak ${bed} \\
        --outfile-prefix ${bed.baseName} \\
        --genome-txdb ${txdb} \\
        --genome-annot ${annot_db} \\
        --uptss 2000 \\
        --downtss 2000 \\
        --toppromoterpeaks 1000 \\
        --cores ${task.cpus}
    """

    stub:
    """
    for ftype in annotated.txt summary.txt genelist.txt annotation.Rds .png
    do
        touch ${meta.id}/${meta.id}.\${ftype}
    done
    """
}
