
process MAKE_TABLE {
    // make table for multiqc report
    label 'process_low'

    container 'nciccbr/ccbr_ubuntu_base_20.04:v6'

    input:
        path(sf_tsv)
        tuple val(metas), val(spikein_counts)

    output:
        path("spike_sf.tsv"), emit: tsv

    when:
        task.ext.when == null || task.ext.when

    script:
    ids = metas.collect{ it.id }.join(',')
    counts_joined = spikein_counts.join(',')
    """
    make_sf_table.py ${sf_tsv} ${ids} ${counts_joined}
    """
}
