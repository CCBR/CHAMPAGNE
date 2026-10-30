process QC_TABLE {
    label 'qc'

    container "${params.containers_base}"

    input:
        path(qc_stats)

    output:
        path("qc_table.tsv"), emit: txt

    script:
    """
    cat ${qc_stats.join(' ')} | createtable.py
    """

    stub:
    """
    touch qc_table.tsv
    """

}
