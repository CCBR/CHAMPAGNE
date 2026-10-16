process MANORM_PAIRWISE {
    """
    adapted from: https://github.com/CCBR/Pipeliner/blob/86c6ccaa3d58381a0ffd696bbf9c047e4f991f9e/Rules/ChIPseq.snakefile#L709-L785
    """
    tag "${meta1.id}_vs_${meta2.id}"
    label 'process_single'

    container 'nciccbr/ccbr_manorm:v1'

    input:
        tuple val(meta1), val(meta2), path(tagalign1), path(tagalign2), path(peak1), path(peak2)

    output:
        tuple val(meta_out), path("${meta1.id}_vs_${meta2.id}/*")

    script:
    meta_out = [id: meta1.id, tool: meta1.tool, contrast: "${meta1.id}_vs_${meta2.id}"]
    """
    manorm \\
        --p1 ${peak1} \\
        --p2 ${peak2} \\
        --r1 ${tagalign1} \\
        --r2 ${tagalign2} \\
        --s1 ${meta1.fraglen} \\
        --s2 ${meta2.fraglen} \\
        -o ${meta1.id}_vs_${meta2.id}/ \\
        --name1 ${meta1.group} \\
        --name2 ${meta2.group}
    """

    stub:
    meta_out = [id: meta1.id, tool: meta1.tool, contrast: "${meta1.id}_vs_${meta2.id}"]
    """
    mkdir ${meta1.id}_vs_${meta2.id}/
    touch ${meta1.id}_vs_${meta2.id}/blank.txt
    """
}
