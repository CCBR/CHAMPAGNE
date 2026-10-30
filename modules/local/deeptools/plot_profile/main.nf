process PLOT_PROFILE {
  label 'qc'
  label 'deeptools'
  label 'process_low'

  container "${params.containers_deeptools}"

  input:
    path(mat)

  output:
    path("*.pdf"), emit: pdf
    path("*.tab"), emit: tab

  script: // TODO set plotType for SE vs paired
  def legend_loc = mat.baseName.contains('metagene') ? 'upper-right' : 'upper-left'
  """
  plotProfile \\
    -m ${mat} \\
    --outFileName ${mat.baseName}.lineplot.pdf \\
    --outFileNameData ${mat.baseName}.plotProfile.tab \\
    --plotHeight 15 \\
    --plotWidth 15 \\
    --perGroup \\
    --yAxisLabel 'average RPGC' \\
    --plotType 'se' \\
    --legendLocation ${legend_loc}
  """

  stub:
  """
  touch ${mat.baseName}.lineplot.pdf ${mat.baseName}.plotProfile.tab
  """
}
