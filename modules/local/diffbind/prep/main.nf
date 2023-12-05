process PREP_DIFFBIND {
    tag { "${metas[0].contrast}.${metas[0].tool}" }
    label 'process_single'

    input:
        tuple val(metas), path(bams), path(bais), path(peaks)

    output:
        tuple val(new_meta), path("*.csv"), emit: csv

    script:
    assert metas*.contrast.toSet().size() == 1
    assert metas*.tool.toSet().size() == 1
    new_meta = [contrast: metas[0].contrast, tool: metas[0].tool]
    def csv_text = [['sampleID', "replicate", 'condition', 'bam', 'bai', 'peak']]
    [metas, bams, bais, peaks]
        .transpose()
        .each { meta, bam, bai, peak ->
            csv_text.add([meta.id, meta.rep, meta.group, bam, bai, peak])
        }
    csv_text = csv_text*.join(',').join(System.lineSeparator)
    """
    echo -ne "${csv_text}" > ${metas[0].contrast}.${metas[0].tool}.csv
    """

    stub:
    """
    touch ${metas[0].contrast}.${metas[0].tool}.csv
    """
}
