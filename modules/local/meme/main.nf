process MEME_AME {
    tag "${meta.id}.${meta.group}"
    label 'peaks'
    label 'process_medium'

    container 'nciccbr/ccbr_atacseq:v1.10'

    input:
        tuple val(meta), path(background), path(target), path(motifs)

    output:
        tuple val(meta), path("*.ame.tsv"),          emit: ame
        tuple val(meta), path("*.sequences.tsv.gz"), emit: seq

    script:
    prefix = "${meta.group}".length() > 0 ? "${meta.id}.${meta.group}" : "${meta.id}"
    """
    run_ame() {
        motif_file=\$1
        ame_dir=${prefix}/\$motif_file/
        mkdir -p \$ame_dir
        ame \\
            --o \$ame_dir \\
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
    sed -n '1p;2q' ${prefix}/motifs/*/ame.tsv > tmp.tsv
    # concatenate data row from all ame output files
    sed -sn 2p ${prefix}/motifs/*/ame.tsv | sort -k 6,6g >> tmp.tsv
    # recalculate ranks after concatenating motifs & sorting by column 6
    cat tmp.tsv | awk 'NR==1 {print; next} {OFS="\\t"; \$1=NR-1; print}' > ${prefix}.ame.tsv

    # motifs in sequences
    sed -n '1p;2q' ${prefix}/motifs/*/sequences.tsv > ${prefix}.sequences.tsv
    sed -s '1d' ${prefix}/motifs/*/sequences.tsv | sort -k 6,6gr --buffer-size=2g --parallel=${task.cpus} >> ${prefix}.sequences.tsv
    pigz -p ${task.cpus} ${prefix}.sequences.tsv
    """

    stub:
    prefix = "${meta.group}".length() > 0 ? "${meta.id}.${meta.group}" : "${meta.id}"
    """
    touch ${prefix}.ame.tsv
    touch ${prefix}.sequences.tsv.gz
    """
}
