process PLOT_PCA {
    label 'qc'
    label 'deeptools'
    label 'process_single'

    container "${params.containers_deeptools}"

    input:
        path(array)

    output:
        path("*.pdf"), emit: pdf
        path("*.tab"), emit: tab

    script:
    """
    plotPCA \\
      -in ${array} \\
      -o ${array.baseName}.pca.pdf \\
      --outFileNameData ${array.baseName}.plotPCA.tab
    """

    stub:
    """
    touch ${array.baseName}.pca.pdf ${array.baseName}.plotPCA.tab
    """
}
