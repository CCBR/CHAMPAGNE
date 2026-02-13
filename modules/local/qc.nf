
process FASTQC {
    tag { meta.id }
    label 'qc'
    label 'process_high'

    //container "${params.containers_fastqc}"
    container 'docker://nciccbr/ccrgb_qctools:v4.0'

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

process PRESEQ {
    """
    Calls preseq c_curve and lc_extrap
    """
    tag { meta.id }
    label 'qc'
    label 'preseq'

    container "${params.containers_preseq}"

    // preseq is known to fail inexplicably, especially on small datasets.
    // https://github.com/nf-core/methylseq/issues/161
    errorStrategy 'ignore'

    input:
        tuple val(meta), path(bam)

    output:
        path("*.c_curve"), emit: c_curve
        path("*.lc_extrap.txt"), emit: preseq
        tuple val(meta), path("*.preseq.log"), emit: log

    script:
    // TODO handle paired: https://github.com/nf-core/rnaseq/blob/3bec2331cac2b5ff88a1dc71a21fab6529b57a0f/modules/nf-core/preseq/lcextrap/main.nf#L25
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    preseq c_curve -B -o ${prefix}.c_curve ${bam}
    preseq lc_extrap -B -D -o ${prefix}.lc_extrap.txt ${bam} -seed 12345 -v -l 100000000000 2> ${prefix}.preseq.log
    """

    stub:
    """
    touch ${meta.id}.c_curve ${meta.id}.lc_extrap.txt ${meta.id}.preseq.log
    """
}

process HANDLE_PRESEQ_ERROR {
    tag { meta.id }
    label 'qc'
    label 'preseq'

    container "${params.containers_base}"

    input:
        tuple val(meta), val(log)

    output:
        tuple val(meta), path("*nrf.txt"), emit: nrf

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "NA\tNA\tNA\n" > ${prefix}.preseq.nrf.txt
    """
}

process PARSE_PRESEQ_LOG {
    """
    Calls bin/parse_preseq_log.py to get NRF statistics from the preseq log.
    """
    tag { meta.id }
    label 'qc'
    label 'preseq'

    container "${params.containers_base}"

    input:
        tuple val(meta), path(log)

    output:
        tuple val(meta), path("*nrf.txt"), emit: nrf

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    parse_preseq_log.py ${prefix}.preseq.log > ${prefix}.preseq.nrf.txt
    """

    stub:
    """
    touch ${meta.id}.preseqlog.nrf.txt
    """
}

process PHANTOM_PEAKS {
    tag { meta.id }
    label 'qc'
    label 'ppqt'
    label 'process_medium'

    container "${params.containers_phantom_peaks}"

    input:
        tuple val(meta), path(bam), path(bai)

    output:
        path("${meta.id}.ppqt.pdf")                    , emit: pdf
        tuple val(meta), path("${meta.id}.spp.out")    , emit: spp
        tuple val(meta), path("${meta.id}.fraglen.txt"), emit: fraglen
        path  "versions.yml"                           , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '1.2.2' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    def prep_bam = ''
    if (meta.single_end) {
        prep_bam = """
        BAM=${bam}
        """
    } else { // for PE, just use first read of each pair
        prep_bam = """
        BAM=${bam.baseName}.f66.bam
        samtools view -b -f 64 -o \$BAM ${bam}
        samtools index \$BAM
        """
    }
    """
    ${prep_bam}
    Rscript \$(which run_spp.R) -c=\$BAM -savp=${prefix}.ppqt.pdf -out=${prefix}.spp.out
    # get fragment length
    frag_len=`cut -f 3 ${prefix}.spp.out | sed 's/,.*//g'`
    echo \$frag_len > "${meta.id}.fraglen.txt"

    # export versions
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        phantompeakqualtools: $VERSION
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}.ppqt.pdf ${meta.id}.spp.out ${meta.id}.fraglen.txt versions.yml
    """
}

process PPQT_PROCESS {
    tag { meta.id }
    label 'qc'
    label 'ppqt'

    container "${params.containers_base}"

    input:
        tuple val(meta), path(fraglen)
    output:
        tuple val(meta), env(fraglen), emit: fraglen

    script:
    """
    fraglen=\$(process_ppqt.py ${fraglen} ${params.min_fragment_length})
    echo \$fraglen
    """

    stub:
    """
    fraglen=${params.min_fragment_length}
    echo \$fraglen
    """
}

process NGSQC_GEN { // TODO segfault - https://github.com/CCBR/CHAMPAGNE/issues/13
    tag { meta.id }
    label 'qc'

    container "${params.containers_ngsqc}"

    input:
        tuple val(meta), path(bed), path(chrom_sizes)

    output:
        path("NGSQC_report.txt"), emit: report

    script:
    """
    ngsqc -v ${bed} ${chrom_sizes}
    """

    stub:
    """
    touch NGSQC_report.txt
    """
}

/*
process PLOT_NGSQC {
    // TODO refactor bin/ngsqc_plot.py for simplicity

}
*/

process QC_STATS {
    tag { meta.id }
    label 'qc'

    container "${params.containers_base}"

    input:
        tuple val(meta), path(raw_fastq), path(count_file_blacklist), path(aligned_flagstat), path(filtered_flagstat), path(dedup_flagstat), path(idxstat), path(preseq_nrf), path(ppqt_spp), val(fraglen)


    output:
        path("${meta.id}.qc_stats.txt")

    script:
    def outfile = "${meta.id}.qc_stats.txt"
    """
    touch ${outfile}

    # Number of reads
    zcat ${raw_fastq} | wc -l | filterMetrics.py ${meta.id} tnreads >> ${outfile}

    # Number of reads after blacklist filter
    n_reads_after_blacklist=`cat ${count_file_blacklist}`
    echo -e "${meta.id}\\tN_reads_surviving_blacklist\\t\${n_reads_after_blacklist}" >> ${outfile}

    # Number of mapped reads
    grep 'mapped (' ${aligned_flagstat} | awk '{{print \$1,\$3}}' | filterMetrics.py ${meta.id} mnreads >> ${outfile}

    # Number of mapped reads surviving filter
    grep 'mapped (' ${filtered_flagstat} | awk '{{print \$1,\$3}}' | filterMetrics.py ${meta.id} N_mapped_reads_surviving_filter >> ${outfile}

    # Number of uniquely mapped reads
    grep 'mapped (' ${dedup_flagstat} | awk '{{print \$1,\$3}}' | filterMetrics.py ${meta.id} unreads >> ${outfile}

    # NRF, PCB1, PCB2
    cat ${preseq_nrf} | filterMetrics.py ${meta.id} nrf >> ${outfile}

    # NSC, RSC, Qtag
    awk '{{print \$(NF-2),\$(NF-1),\$NF}}' ${ppqt_spp} | filterMetrics.py ${meta.id} ppqt >> ${outfile}

    # Fragment Length
    echo "${meta.id}\tFragmentLength\t${fraglen}" >> ${outfile}
    """

    stub:
    """
    touch ${meta.id}.qc_stats.txt
    """

}

process QC_TABLE {
    label 'qc'

    container "${params.containers_base}"

    input:
        path(qc_stats)

    output:
        path("qc_table.tsv"), emit: txt

    script:
    """
    cat ${qc_stats.join(' ')} | createtable.py
    """

    stub:
    """
    touch qc_table.tsv
    """

}

process MULTIQC {
    container "${params.containers_multiqc}"

    input:
        path(multiqc_conf)
        path(custom_logo)
        path(input_files)

    output:
        path('multiqc_report.html'), emit: html

    script:
    """
    multiqc \\
        -c ${multiqc_conf} \\
        .
    """

    stub:
    """
    touch multiqc_report.html
    """
}
