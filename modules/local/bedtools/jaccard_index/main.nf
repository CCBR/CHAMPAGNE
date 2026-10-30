process JACCARD_INDEX {
    tag "${toolA} ${metaA.id} vs. ${toolB} ${metaB.id}"
    label 'peaks'
    label 'process_low'

    container "${params.containers_base}"

    input:
        tuple val(metaA), path(peakA), val(toolA),  val(metaB), path(peakB), val(toolB), path(chrom_sizes)

    output:
        path("jaccard*.txt")

    script:
    // if groups are defined, use them as labels. otherwise use sample IDs.
    def labelA = metaA.group ?: metaA.id
    def labelB = metaB.group ?: metaB.id
    """
    bedtools sort -i ${peakA} -g ${chrom_sizes} > ${peakA.baseName}.sorted.bed
    bedtools sort -i ${peakB} -g ${chrom_sizes} > ${peakB.baseName}.sorted.bed
    bedtools jaccard -a ${peakA.baseName}.sorted.bed -b ${peakB.baseName}.sorted.bed -g ${chrom_sizes} |\\
      tail -n 1 |\\
      awk -v fA=${peakA} -v fB=${peakB} -v lA=${labelA} -v lB=${labelB} -v tA=${toolA} -v tB=${toolB} \\
        '{printf("%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n",fA,lA,tA,fB,lB,tB,\$1,\$2,\$3,\$4)}' > \\
        jaccard_${toolA}_${metaA.id}_vs_${toolB}_${metaB.id}.txt
    """
    stub:
    """
    touch jaccard_${toolA}_${metaA.id}_vs_${toolB}_${metaB.id}.txt
    """
}
