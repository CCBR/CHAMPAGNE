
process CALC_GENOME_FRAC {
    label 'peaks'
    label 'process_single'

    container = "${params.containers_base}"

    input:
        path(chrom_sizes)
        val(effective_genome_size)

    output:
        env(genome_frac), emit: genome_frac

    script:
    """
    genome_frac=`calc_effective_genome_fraction.py ${effective_genome_size} ${chrom_sizes}`
    echo \$genome_frac
    """

    stub:
    """
    genome_frac=0.75
    echo \$genome_frac
    """
}


process MACS_BROAD {
    tag { meta.id }
    label 'peaks'
    label 'process_high'

    container = "${params.containers_macs2}"

    input:
        tuple val(meta), path(chip), path(input), val(format), val(fraglen), val(genome_frac), val(effective_genome_size)

    output:
        tuple val(meta), path("${meta.id}_peaks.broadPeak"), val("${task.process.tokenize(':')[-1].toLowerCase()}"), emit: peak
        path("${meta.id}_peaks.xls")
        path("${meta.id}_peaks.gappedPeak")

    script:
    """
    macs2 callpeak \\
      -t ${chip} \\
      -c ${input} \\
      -g ${effective_genome_size} \\
      -n ${meta.id} \\
      --extsize ${fraglen} \\
      --nomodel \\
      -q ${params.macs_broad.q} \\
      --keep-dup='all' \\
      --format ${format} \\
      --broad \\
      --broad-cutoff ${params.macs_broad.cutoff}
    """

    stub:
    """
    for ext in xls broadPeak gappedPeak; do
        touch ${meta.id}_peaks.\${ext}
    done
    """

}

process MACS_NARROW {
    tag { meta.id }
    label 'peaks'
    label 'process_high'

    container = "${params.containers_macs2}"

    input:
        tuple val(meta), path(chip), path(input), val(format), val(fraglen), val(genome_frac), val(effective_genome_size)

    output:
        tuple val(meta), path("${meta.id}_peaks.narrowPeak"), val("${task.process.tokenize(':')[-1].toLowerCase()}"), emit: peak
        tuple val(meta), path("${meta.id}_peaks.xls"), val("${task.process.tokenize(':')[-1].toLowerCase()}"),        emit: xls
        tuple val(meta), path("${meta.id}_summits.bed"), val("${task.process.tokenize(':')[-1].toLowerCase()}"),      emit: summits

    script:
    """
    macs2 callpeak \\
      -t ${chip} \\
      -c ${input} \\
      -g ${effective_genome_size} \\
      -n ${meta.id} \\
      --extsize ${fraglen} \\
      --nomodel \\
      -q ${params.macs_narrow.q} \\
      --keep-dup='all' \\
      --format ${format}
    """

    stub:
    """
    for ext in peaks.xls peaks.narrowPeak summits.bed; do
        touch ${meta.id}_\${ext}
    done
    """
}

process SICER {
    tag { meta.id }
    label 'peaks'
    label 'process_high'

    container = "${params.containers_sicer}"

    input:
        tuple val(meta), path(chip), path(input), val(fraglen), val(genome_frac)

    output:
        tuple val(meta), path("*islands-summary"), val("${task.process.tokenize(':')[-1].toLowerCase()}"), emit: peak
        tuple path("*island.bed"), path("*.scoreisland"), path("*normalized.wig"),                         emit: sicer

    script:
    """
    sicer \\
      -t ${chip} \\
      -c ${input} \\
      -s ${params.sicer_species} \\
      -rt 100 \\
      -w 300 \\
      -f ${fraglen} \\
      -egf ${genome_frac} \\
      -g 600 \\
      -fdr 1E-2 \\
      -cpu ${task.cpus}
    """

    stub:
    """
    for ext in scoreisland normalized.wig islands-summary island.bed; do
        touch ${chip.baseName}.\${ext}
    done
    """
}

process CONVERT_SICER { // https://github.com/CCBR/Pipeliner/blob/86c6ccaa3d58381a0ffd696bbf9c047e4f991f9e/Rules/ChIPseq.snakefile#L389-L431
    tag { meta.id }
    label 'peaks'
    label 'process_single'

    container = "${params.containers_base}"

    input:
        tuple val(meta), path(sicer_peaks), val(peak_tool)

    output:
        tuple val(meta), path("${sicer_peaks.baseName}.converted_sicer.broadPeak"), val(peak_tool), emit: peak, optional: true
        tuple val(meta), path("${sicer_peaks.baseName}.converted.bed"), val(peak_tool),             emit: bed

    script:
    $/
    #!/usr/bin/env python
    import math
    with open("${sicer_peaks}",'r') as f:
        intxt = f.readlines()
    # input columns if input-normalized: chrom, start, end, ChIP tag count, input tag count, p-value, fold-enrichment, q-value
    # input columns if no input: chrom, start, end, score
    outBroadPeak = [None] * len(intxt)
    outBed = [None] * len(intxt)
    for i in range(len(intxt)):
        tmp = intxt[i].strip().split('\t')
        if len(tmp) == 8:
            # assuming that a p-value/q-value of 0 is super significant, -log10(1e-500)
            if tmp[5] == "0.0":
                pval="500"
            else:
                pval = str(-(math.log10(float(tmp[5]))))
            if tmp[7] == "0.0":
                qval="500"
                qvalScore="5000"
            else:
                qval = str(-(math.log10(float(tmp[7]))))
                qvalScore = str(int(-10*math.log10(float(tmp[7]))))
            outBroadPeak[i] = "\t".join(tmp[0:3] + ["Peak"+str(i+1),tmp[3],".", tmp[6], pval, qval])
            outBed[i] = "\t".join(tmp[0:3] + ["Peak"+str(i+1),qvalScore])
        else:
            score = str(int(float(tmp[3])))
            outBed[i] = "\t".join(tmp[0:3] + ["Peak"+str(i+1),score])
    # output broadPeak columns: chrom, start, end, name, ChIP tag count, strand, fold-enrichment, -log10 p-value, -log10 q-value
    with open("${sicer_peaks.baseName}.converted.bed",'w') as g:
        g.write( "\n".join(outBed) + '\n' )
    if outBroadPeak[0] != None:
        with open("${sicer_peaks.baseName}.converted_sicer.broadPeak", 'w') as h:
            h.write( "\n".join(outBroadPeak) + '\n' )
    /$

    stub:
    """
    touch ${sicer_peaks.baseName}.converted.bed ${sicer_peaks.baseName}.converted_sicer.broadPeak
    """

}
/*
process SICER_NO_CTRL { // TODO just use one process for each peak caller with optional ctrl input
    script:
    """
    sicer \\
      -t ${chip} \\
      -s ${params.genome} \\
      -rt 100 \\
      -w 300 \\
      -f ${fraglen} \\
      -egf ${genome_frac} \\
      -g 600 \\
      -e 100 \\
      -cpu ${task.cpus}
    """
}
*/
process GEM {
    tag { meta.id }
    label 'peaks'
    label 'process_high'

    container = "${params.containers_gem}"

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

process FILTER_GEM {
    tag { meta.id }

    container "${params.containers_base}"

    input:
        tuple val(meta), path(peak), val(tool), path(chrom_sizes)

    output:
        tuple val(meta), path("${peak}.filtered"), val(tool), emit: peak

    script:
    """
    #!/usr/bin/env python

    chrom_ends = dict()
    with open('${chrom_sizes}', 'r') as chrom_file:
        for line in chrom_file:
            chrom, end = line.split()
            chrom_ends[chrom] = int(end)

    count_bad_peaks = 0
    with open('${peak}', 'r') as infile:
        with open('${peak}.filtered', 'w') as outfile:
            for line in infile:
                line_split = line.split()
                chrom = line_split[0]
                start = int(line_split[1])
                end = int(line_split[2])
                if start > 0 and end < chrom_ends[chrom]:
                    outfile.write(line)
                else:
                    count_bad_peaks += 1
    print(f"Filtered out {count_bad_peaks} peaks")
    """
    stub:
    """
    touch ${peak}.filtered
    """

}

process FRACTION_IN_PEAKS {
    tag { meta.id }
    label 'peaks'
    label 'process_single'

    container "${params.containers_frip}"

    input:
        tuple val(meta), path(dedup_bam), path(dedup_bai), path(peaks), val(peak_tool), path(chrom_sizes)

    output:
        path("*.FRiP.txt")

    script:
    """
    export OPENBLAS_NUM_THREADS='1'
    frip.py -p ${peaks} -b ${dedup_bam} -g ${chrom_sizes} -t ${peak_tool} -s ${meta.id} -o ${meta.id}_${peak_tool}.FRiP.txt
    """

    stub:
    """
    touch ${meta.id}_${peak_tool}.FRiP.txt
    """
}

process CONCAT_FRIPS {
    label 'peaks'
    label 'process_single'

    container "${params.containers_base}"

    input:
        path(frips)

    output:
        path("FRiP.txt")

    script:
    """
    head -n 1 ${frips.get(1)} > FRiP.txt
    for f in ${frips}; do
        tail -n 1 \$f >> FRiP.txt
    done
    """
    stub:
    """
    touch FRiP.txt
    """

}

process PLOT_FRIP {
    label 'peaks'
    label 'process_single'

    container "${params.containers_r}"

    input:
        path(frips)

    output:
        path("*.png")

    script:
    """
    plot_frip.R ${frips}
    """

    stub:
    """
    touch blank.png
    """
}

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

process CONCAT_JACCARD {
    label 'peaks'
    label 'process_single'

    container "${params.containers_base}"

    input:
        path(jaccards)

    output:
        path("jaccard_all.txt")

    script:
    """
    echo -e "fileA\\tlabelA\\ttoolA\\tfileB\\tlabelB\\ttoolB\\tintersection\\tunion\\tjaccard\\tn_intersections" > jaccard_all.txt
    cat ${jaccards} |\\
      sort -k 1,1 -k 2,2 >>\\
      jaccard_all.txt
    """
    stub:
    """
    touch jaccard_all.txt
    """
}

process PLOT_JACCARD {
    label 'peaks'
    label 'process_single'

    container "${params.containers_r}"

    input:
        path(jaccard)

    output:
        path("*.png")

    script:
    """
    plot_jaccard.R ${jaccard}
    """

    stub:
    """
    touch plot.png
    """

}

process GET_PEAK_META {
    tag "${meta.id}.${peak_tool}"
    label 'peaks'
    label 'process_single'

    container "${params.containers_base}"

    input:
        tuple val(meta), path(dedup_bam), path(dedup_bai), path(peaks), val(peak_tool), path(chrom_sizes)

    output:
        path("*.tsv")

    script:
    """
    awk -v id=${meta.id} -v tool=${peak_tool} 'BEGIN{FS=OFS="\\t"}{print id,tool,\$1,\$2,\$3}' ${peaks} > peak_meta_${meta.id}_${peak_tool}.tsv
    """

    stub:
    """
    touch peak_meta_${meta.id}_${peak_tool}.tsv
    """
}

process CONCAT_PEAK_META {
    label 'peaks'
    label 'process_single'

    container "${params.containers_base}"

    input:
        path(peak_metas)

    output:
        path("*.tsv")

    script:
    """
    echo -e "sample_id\\ttool\\tchrom\\tchromStart\\tchromEnd" > peak_meta.tsv
    cat ${peak_metas} |\\
      sort -k 1,1 -k 2,2 >>\\
      peak_meta.tsv
    """

    stub:
    """
    touch peak_meta.tsv
    """
}

process PLOT_PEAK_WIDTHS {
    label 'peaks'
    label 'process_single'

    container "${params.containers_r}"

    input:
        path(peak_meta)

    output:
        path("*.png")

    script:
    """
    plot_peak_widths.R ${peak_meta}
    """

    stub:
    """
    touch peak_widths.png
    """
}
