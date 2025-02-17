process PREP_DIFFBIND {
    tag { "${meta.id}.${meta.contrast}.${meta.tool}" }
    label 'process_low'

    container "${params.containers.base}"

    input:
        tuple val(meta), path(bam), path(bai), path(peak), path(ctrl_bam), path(ctrl_bai)

    output:
        tuple val(meta), path("*.csv"), emit: csv

    script:
    def csv_text = [
        ['SampleID', "Replicate", 'Condition', 'bamReads', "ControlID", "bamControl", 'Peaks', 'PeakCaller'],
        [meta.id,     meta.rep,    meta.group,  bam,       meta.input, ctrl_bam,     peak,    meta.tool]
    ]*.join(',').join(System.lineSeparator) + '\n'
    """
    echo -ne "${csv_text}" > ${meta.contrast}.${meta.tool}.${meta.id}.csv
    """

    stub:
    """
    touch ${meta.contrast}.${meta.tool}.${meta.id}.csv
    """
}
