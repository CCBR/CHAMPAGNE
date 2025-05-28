process CHIPSEEKER_PLOTLIST {
    label 'peaks'
    label 'process_medium'

    container 'nciccbr/ccbr_chipseeker:1.1.2'

    input:
        path(rds)

    output:
        path("*.png"), emit: plots

    script:
    """
    chipseeker_plotlist.R \\
        --annotations ${rds.join(' ')} \\
        --outfile ${meta.id}_plot_anno_bar.png
    """

    stub:
    """
    touch plot_anno_bar.png
    """
}
