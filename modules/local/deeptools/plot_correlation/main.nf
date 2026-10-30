process PLOT_CORRELATION {
    label 'qc'
    label 'deeptools'
    label 'process_single'

    container "${params.containers_deeptools}"

    input:
        tuple path(array), val(plottype), val(deeptools_corr_method)

    output:
        path("*.png"), emit: png
        path("*.tab"), emit: tab

    script:
    def args = (plottype == 'heatmap')? '--plotNumbers': ''
    // TODO throw error if plottype != either'heatmap' or 'scatterplot'
    """
    plotCorrelation \\
      -in ${array} \\
      -o ${array.baseName}.${deeptools_corr_method}_${plottype}_deeptools.png \\
      --outFileCorMatrix ${array.baseName}.${deeptools_corr_method}_${plottype}.tab \\
      -c '${deeptools_corr_method}' \\
      -p '${plottype}' \\
      --skipZeros \\
      --removeOutliers ${args} \\
      --plotTitle '${deeptools_corr_method} correlation ${plottype}'
    """

    stub:
    """
    touch ${array.baseName}.${deeptools_corr_method}_${plottype}.png ${array.baseName}.${deeptools_corr_method}_${plottype}.tab
    """
}
