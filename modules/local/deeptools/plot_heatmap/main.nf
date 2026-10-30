process PLOT_HEATMAP {
  label 'qc'
  label 'deeptools'
  label 'process_high'

  container "${params.containers_deeptools}"

  input:
    path(mat)

  output:
    path("*.png"), emit: png

  script:
  // sets colorMap to "BuGn" if "metagene" in matrix filename, otherwise use "BuPu"
  def color_map = mat.baseName.contains('metagene') ? 'BuGn' : 'BuPu'
  """
  export MPLCONFIGDIR=./tmp
  plotHeatmap \\
    -m ${mat} \\
    -out ${mat.baseName}.heatmap.png \\
    --colorMap ${color_map} \\
    --yAxisLabel 'average RPGC' \\
    --regionsLabel 'genes' \\
    --legendLocation 'none'
  """

  stub:
  """
  touch ${mat.baseName}.heatmap.png
  """
}
