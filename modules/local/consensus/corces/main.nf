process CONSENSUS_CORCES {

    tag "${meta.id}.${meta.tool}"
    container 'docker://nciccbr/ccbr_atacseq:v11-feat'

    input:
        tuple val(meta), path(peaks), path(chrom_sizes)

    output:
        tuple val(meta), path("*.consensus_corces.bed"), emit: peaks

    script:
    def cat_peak_file = "${meta.id}.${meta.tool}.cat.bed"
    def outfile = "${meta.id}.${meta.tool}.consensus_corces.bed"
    meta.consensus = 'corces'
    """
    #cat ${peaks.join(' ')} > ${cat_peak_file}
    #consensus_corces.py ${cat_peak_file} ${outfile} ${chrom_sizes}
    corces_consensus_peaks.R --width 500 --output ${outfile} ${peaks}
    """

    stub:
    """
    touch ${meta.id}.${meta.tool}.consensus_corces.bed
    """
}
