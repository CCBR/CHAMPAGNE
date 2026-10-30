process FASTQC {
    tag { meta.id }
    label 'qc'
    label 'process_high'

    //container "${params.containers_fastqc}"
    container 'nciccbr/ccrgb_qctools:v4.0'

    input:
        tuple val(meta), path(fastq), val(fqtype)
    output:
        path("*.html"), emit: html
        path ("*.zip"), emit: zip

    script:
    """
    fastqc \
      $fastq \
      -t $task.cpus \
      -o .
    """

    stub:
    """
    touch ${meta.id}_${fqtype}_fastqc.html ${meta.id}_${fqtype}_fastqc.zip
    """
}
