process BED_PROTEIN_CODING {
    label 'qc'
    label 'process_single'

    container "${params.containers_base}"

    input:
      path(bed)

    output:
      path("*.protein_coding.bed"), emit: bed_prot
      path("*.all_genes.bed"),      emit: bed_all

    script:
    """
    grep --line-buffered 'protein_coding' ${bed} | awk -v OFS='\t' -F'\t' '{{print \$1, \$2, \$3, \$5, \".\", \$4}}' > ${bed.baseName}.protein_coding.bed
    cp ${bed} ${bed.baseName}.all_genes.bed
    """

    stub:
    """
    touch ${bed.baseName}.protein_coding.bed ${bed.baseName}.all_genes.bed
    """
}
