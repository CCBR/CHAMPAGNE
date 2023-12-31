process MEME_AME {
    tag "${meta.id}.${meta.group}"
    label 'peaks'
    label 'process_medium'

    container 'nciccbr/ccbr_atacseq:v1.10'

    input:
        tuple val(meta), path(background), path(target)
        path(motifs)

    output:
        tuple val(meta), path("${meta.id}.${meta.group}.ame.tsv"), emit: ame

    script:
    """
    run_ame() {
        motif_file=\$1
        ame_dir=${meta.id}.${meta.group}/\$motif_file/
        mkdir -p \$ame_dir
        ame \\
            --o \$ame_dir \\
            --noseq \\
            --control ${background} \\
            --seed 20231103 \\
            --verbose 1 \\
            ${target} \\
            \${motif_file}
    }
    export -f run_ame
    mkdir motifs
    tar -xzf ${motifs} -C motifs
    # parallelize meme ame by running on each motif separately
    find motifs/ -name "*.meme" -type f | \\
        parallel \\
        -j ${task.cpus} \\
        run_ame
    # get header row
    sed -n '1p;2q' ${meta.id}.${meta.group}/motifs/*/ame.tsv > ${meta.id}.${meta.group}.ame.tsv
    # concatenate data row from all ame output files
    sed -sn 2p ${meta.id}.${meta.group}/motifs/*/ame.tsv | sort -k 6,6g >> ${meta.id}.${meta.group}.ame.tsv
    """

    stub:
    """
    touch ${meta.id}.${meta.group}.ame.tsv
    """
}
