process GEM {
    tag { meta.id }
    label 'peaks'
    label 'process_high'

    container "${params.containers_gem}"

    input:
        tuple val(meta), path(chip), path(input), val(format), path(read_dists), path(chrom_sizes), path(chrom_dir), val(effective_genome_size)

    output:
        tuple val(meta), path("${meta.id}/*GEM_events.narrowPeak"), val("${task.process.tokenize(':')[-1].toLowerCase()}"), emit: peak
        tuple val(meta), path("${meta.id}/*GEM_events.txt"), val("${task.process.tokenize(':')[-1].toLowerCase()}"), emit: event

    script:
    // $GEMJAR is defined in the docker container
    def f = format == 'BAMPE' ? 'SAM' : format
    """
    java -Xmx${task.memory.toGiga()}G -jar \$GEMJAR \\
      --t ${task.cpus} \\
      --d ${read_dists} \\
      --g ${chrom_sizes} \\
      --genome ${chrom_dir} \\
      --s ${effective_genome_size} \\
      --expt ${chip} \\
      --ctrl ${input} \\
      --f ${f} \\
      --out ${meta.id} \\
      --fold ${params.gem_fold} \\
      --k_min ${params.gem_k_min} \\
      --k_max ${params.gem_k_max} \\
      --nrf \\
      --outNP \\
      --outMEME
    """

    stub:
    """
    mkdir ${meta.id}
    for ext in txt narrowPeak; do
        touch ${meta.id}/${meta.id}.GEM_events.\$ext
    done
    """
}
