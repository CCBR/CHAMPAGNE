process HANDLE_PRESEQ_ERROR {
    tag { meta.id }
    label 'qc'
    label 'preseq'

    container "${params.containers_base}"

    input:
        tuple val(meta), val(log)

    output:
        tuple val(meta), path("*nrf.txt"), emit: nrf

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "NA\tNA\tNA\n" > ${prefix}.preseq.nrf.txt
    """
}
