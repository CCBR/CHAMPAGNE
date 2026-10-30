process PRESEQ {
    """
    Calls preseq c_curve and lc_extrap
    """
    tag { meta.id }
    label 'qc'
    label 'preseq'

    container "${params.containers_preseq}"

    // preseq is known to fail inexplicably, especially on small datasets.
    // https://github.com/nf-core/methylseq/issues/161
    errorStrategy 'ignore'

    input:
        tuple val(meta), path(bam)

    output:
        path("*.c_curve"), emit: c_curve
        path("*.lc_extrap.txt"), emit: preseq
        tuple val(meta), path("*.preseq.log"), emit: log

    script:
    // TODO handle paired: https://github.com/nf-core/rnaseq/blob/3bec2331cac2b5ff88a1dc71a21fab6529b57a0f/modules/nf-core/preseq/lcextrap/main.nf#L25
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    preseq c_curve -B -o ${prefix}.c_curve ${bam}
    preseq lc_extrap -B -D -o ${prefix}.lc_extrap.txt ${bam} -seed 12345 -v -l 100000000000 2> ${prefix}.preseq.log
    """

    stub:
    """
    touch ${meta.id}.c_curve ${meta.id}.lc_extrap.txt ${meta.id}.preseq.log
    """
}
