process HOMER_MOTIFS {
    tag "${meta.id}"
    label 'peaks'
    label 'process_medium'

    container 'nciccbr/ccbr_homer_4.11:v1'

    input:
        tuple val(meta), path(bed), path(genome_fasta)
        val(de_novo) // true or false
        path(motif_db)

    output:
        tuple val(meta), path("${meta.id}_homer/*"), emit: motifs
        tuple val(meta), path("${meta.id}_homer/background.fa"), path("${meta.id}_homer/target.fa"), emit: ame

    script:
    def args = de_novo ? "" : " -nomotif "
    """
    findMotifsGenome.pl \\
        ${bed} \\
        ${genome_fasta} \\
        ${meta.id}_homer/ \\
        -mknown ${motif_db} \\
        -size given \\
        -p ${task.cpus} \\
        -len 8,10 \\
        -dumpFasta \\
        -preparsedDir preparsed \\
        ${args}
    """

    stub:
    """
    mkdir ${meta.id}_homer/
    touch ${meta.id}_homer/background.fa ${meta.id}_homer/target.fa
    """
}
