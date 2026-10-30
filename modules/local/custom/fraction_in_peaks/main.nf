process FRACTION_IN_PEAKS {
    tag { meta.id }
    label 'peaks'
    label 'process_single'

    container "${params.containers_frip}"

    input:
        tuple val(meta), path(dedup_bam), path(dedup_bai), path(peaks), val(peak_tool), path(chrom_sizes)

    output:
        path("*.FRiP.txt")

    script:
    """
    export OPENBLAS_NUM_THREADS='1'
    frip.py -p ${peaks} -b ${dedup_bam} -g ${chrom_sizes} -t ${peak_tool} -s ${meta.id} -o ${meta.id}_${peak_tool}.FRiP.txt
    """

    stub:
    """
    touch ${meta.id}_${peak_tool}.FRiP.txt
    """
}
