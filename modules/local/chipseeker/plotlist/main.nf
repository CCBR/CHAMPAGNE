process CHIPSEEKER_PLOTLIST {
    label 'peaks'
    label 'process_medium'
    tag { meta.consensus }

    container 'nciccbr/ccbr_chipseeker:1.1.2'

    input:
        tuple val(meta), path(rds)

    output:
        path("${meta.consensus}_plot_anno_bar.png")

    script:
    """
    chipseeker_plotlist.R \\
        --annotations ${rds.join(' ')} \\
        --outfile ${meta.consensus}_plot_anno_bar.png
    """

    stub:
    """
    touch ${meta.consensus}_plot_anno_bar.png
    """
}
