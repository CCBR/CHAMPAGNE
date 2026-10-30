process CONCAT_PEAK_META {
    label 'peaks'
    label 'process_single'

    container "${params.containers_base}"

    input:
        path(peak_metas)

    output:
        path("*.tsv")

    script:
    """
    echo -e "sample_id\\ttool\\tchrom\\tchromStart\\tchromEnd" > peak_meta.tsv
    cat ${peak_metas} |\\
      sort -k 1,1 -k 2,2 >>\\
      peak_meta.tsv
    """

    stub:
    """
    touch peak_meta.tsv
    """
}
