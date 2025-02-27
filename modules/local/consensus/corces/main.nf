process CONSENSUS_CORCES {

    tag "${meta.id}.${meta.tool}"

    input:
        tuple val(meta), path(peaks)
        path(chrom_sizes)

    output:
        tuple val(meta), path("*.consensus_corces.bed"), emit: peaks

    script:
    def cat_peak_file = "${meta.id}.${meta.tool}.cat.bed"
    def outfile = "${meta.id}.${meta.tool}.consensus_corces.bed"
    """
    cat ${peaks.join(' ')} > ${cat_peak_file}
    consensus_corces.py ${cat_peak_file} ${outfile} ${chrom_sizes}
    """
}
