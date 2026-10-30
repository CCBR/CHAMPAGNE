process CONVERT_SICER { // https://github.com/CCBR/Pipeliner/blob/86c6ccaa3d58381a0ffd696bbf9c047e4f991f9e/Rules/ChIPseq.snakefile#L389-L431
    tag { meta.id }
    label 'peaks'
    label 'process_single'

    container "${params.containers_base}"

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
