process FASTQ_SCREEN {
    tag { meta.id }
    label 'qc'
    label 'process_high'

    container "${params.containers_fastq_screen}"

    input:
        tuple val(meta), path(fastq), path(conf), path(db_dir)

    output:
        path("${meta.id}*_screen.*"), emit: screen

    script:
    """
    fastq_screen -c $conf --threads $task.cpus $fastq
    """

    stub:
    """
    for EXT in html txt png; do
        touch ${meta.id}.trimmed_screen.\${EXT}
    done
    """
}
