process PPQT_PROCESS {
    tag { meta.id }
    label 'qc'
    label 'ppqt'

    container "${params.containers_base}"

    input:
        tuple val(meta), path(fraglen)
    output:
        tuple val(meta), env(fraglen), emit: fraglen

    script:
    """
    fraglen=\$(process_ppqt.py ${fraglen} ${params.min_fragment_length})
    echo \$fraglen
    """

    stub:
    """
    fraglen=${params.min_fragment_length}
    echo \$fraglen
    """
}
