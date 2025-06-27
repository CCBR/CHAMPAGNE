
process COMPUTE_SCALINGFACTOR {

    label 'process_low'

    container 'nciccbr/ccbr_ubuntu_base_20.04:v6'

    input:
        tuple val(metas), val(counts)

    output:
        path("scaling_factors.tsv")

    when:
        task.ext.when == null || task.ext.when

    script:
    ids = metas.collect{ it.id }.join(',')
    counts_joined = counts.join(',')
    """
    compute_scaling_factors.py ${ids} ${counts_joined}
    """
}
