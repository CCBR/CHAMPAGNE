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
