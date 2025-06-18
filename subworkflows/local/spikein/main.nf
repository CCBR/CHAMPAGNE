
include { BWA_MEM                } from '../../../modules/CCBR/bwa/mem'
include { SAMTOOLS_COUNT } from '../../../modules/local/samtools/count'
include { MULTIBAM_SUMMARY } from "../../../modules/local/deeptools.nf"

workflow ALIGN_SPIKEIN {
    take:
        ch_fastq
        spike_genome
    main:
        ch_spikein_fasta = Channel.fromPath(params.genomes[spike_genome].fasta, checkIfExists: true)
        ch_spikein_index = Channel.fromPath(params.genomes[spike_genome].reference_index, checkIfExists: true)
            .collect()
            .map{ file -> [file.baseName, file] }

        BWA_MEM( ch_fastq, ch_spikein_index )
        SAMTOOLS_COUNT( BWA_MEM.out.bam )
        ch_spikein_bam = BWA_MEM.out.bam
            | map{ meta, bam, bai -> [1, meta, bam, bai]}
            | groupTuple()
            | map{ idx, metas, bams, bais -> [ metas, bams, bais ] }
        MULTIBAM_SUMMARY(ch_spikein_bam)
        // TODO read scaling factor file as value channel with [val(meta), path(scaling_factor)]
        MULTIBAM_SUMMARY.out.sf
            | splitCsv(header: true, sep: '\t')
            | map{ row -> [ row.sample, row.scalingFactor ] }
            | set{ch_scaling_factors}

    emit:
        n_spikein_reads   = SAMTOOLS_COUNT.out.count
        multibam_count    = MULTIBAM_SUMMARY.out.count
        multibam_sf       = MULTIBAM_SUMMARY.out.sf // channel: [ path(scalingFactors.tsv) ]
        scaling_factors   = ch_scaling_factors // channel: [ val(meta_id), val(scaling_factor) ]
}
