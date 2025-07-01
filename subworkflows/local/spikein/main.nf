
include { BWA_MEM                } from '../../../modules/CCBR/bwa/mem'
include { SAMTOOLS_COUNT } from '../../../modules/local/samtools/count'
include { COMPUTE_SCALINGFACTOR } from '../../../modules/local/spikein/compute_scalingFactor'
include { MULTIBAM_SUMMARY } from "../../../modules/local/deeptools.nf"
include { MAKE_TABLE } from '../../../modules/local/spikein/make_table'

workflow ALIGN_SPIKEIN {
    take:
        ch_fastq
        spike_genome
        ch_frag_lengths
    main:
        ch_spikein_fasta = Channel.fromPath(params.genomes[spike_genome].fasta, checkIfExists: true)
        ch_spikein_index = Channel.fromPath(params.genomes[spike_genome].reference_index, checkIfExists: true)
            .collect()
            .map{ file -> [file.baseName, file] }
        ch_spikein_blacklist_bed = Channel.fromPath(params.genomes[spike_genome].blacklist_bed)

        BWA_MEM( ch_fastq, ch_spikein_index )
        SAMTOOLS_COUNT( BWA_MEM.out.bam )
        SAMTOOLS_COUNT.out.count
            | map{ meta, count -> [1, meta, count]}
            | groupTuple()
            | map{ idx, metas, counts -> [ metas, counts ] }
            | set{ ch_spike_counts }

        if (params.spike_norm_method == 'guenther') {
            ch_spike_counts
                | COMPUTE_SCALINGFACTOR
                | set { ch_sf_tsv }
        } else if (params.spike_norm_method == 'delorenzi') {
            ch_frag_lengths
                | map{ meta, fraglen -> fraglen}
                | min()
                | set{ min_fraglen }
            BWA_MEM.out.bam
                | map{ meta, bam, bai -> [1, meta, bam, bai]}
                | groupTuple()
                | map{ idx, metas, bams, bais -> [ metas, bams, bais ] }
                | combine(min_fraglen)
                | combine(ch_spikein_blacklist_bed)
                | MULTIBAM_SUMMARY
            MULTIBAM_SUMMARY.out.sf
                | set{ ch_sf_tsv } // https://github.com/nextflow-io/nextflow/issues/3970
        } else {
            error "Unknown spike-in normalization method: ${params.spike_norm_method}"
        }

        MAKE_TABLE( ch_sf_tsv, ch_spike_counts )
        ch_sf_tsv
            | splitCsv(header: true, sep: '\t')
            | map{ row -> [ row.sample, row.scalingFactor ] }
            | set{ ch_scaling_factors }


    emit:
        sf_tsv            = MAKE_TABLE.out.tsv // for multiqc
        scaling_factors   = ch_scaling_factors // channel: [ val(meta_id), val(scaling_factor) ]
}
