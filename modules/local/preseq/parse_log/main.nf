process PARSE_PRESEQ_LOG {
    """
    Calls bin/parse_preseq_log.py to get NRF statistics from the preseq log.
    """
    tag { meta.id }
    label 'qc'
    label 'preseq'

    container "${params.containers_base}"

    input:
        tuple val(meta), path(log)

    output:
        tuple val(meta), path("*nrf.txt"), emit: nrf

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    parse_preseq_log.py ${prefix}.preseq.log > ${prefix}.preseq.nrf.txt
    """

    stub:
    """
    touch ${meta.id}.preseqlog.nrf.txt
    """
}
