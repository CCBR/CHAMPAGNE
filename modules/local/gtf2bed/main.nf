process GTF2BED {
    tag { gtf }
    label 'process_single'

    container 'nciccbr/ccbr_ubuntu_base_20.04:v5'

    input:
        path(gtf)

    output:
        path("${gtf.baseName}.bed"), emit: bed

    script:
    """
    cat ${gtf} | gtf2bed > ${gtf.baseName}.bed

    """
    stub:
    """
    touch ${gtf.baseName}.bed
    """
}
