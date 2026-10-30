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
