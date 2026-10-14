
include { BWA_MEM               } from '../../../modules/CCBR/bwa/mem'
include { DEDUPLICATE           } from "../../../subworkflows/local/deduplicate.nf"
include { SAMTOOLS_COUNT        } from '../../../modules/local/samtools/count'
include { COMPUTE_SCALINGFACTOR } from '../../../modules/local/spikein/compute_scalingFactor'
include { MULTIBAM_SUMMARY      } from "../../../modules/local/deeptools.nf"
include { MAKE_TABLE            } from '../../../modules/local/spikein/make_table'
include { BWA_INDEX as BWA_INDEX_SPIKEIN                 } from '../../../modules/CCBR/bwa/index'
include { KHMER_UNIQUEKMERS as KHMER_UNIQUEKMERS_SPIKEIN } from '../../../modules/CCBR/khmer/uniquekmers'
include { GUNZIP_REFERENCE as GUNZIP_SPIKEIN_FASTA
          SPLIT_REF_CHROMS as SPLIT_SPIKEIN_CHROMS       } from '../../../modules/local/prepare_genome.nf'

workflow ALIGN_SPIKEIN {
    take:
        ch_fastq
        ch_deduped_bam
        ch_frag_lengths
        spike_genome

    main:
        if (params.genomes[spike_genome]) {
            ch_spikein_index = Channel.fromPath(params.genomes[spike_genome].reference_index, checkIfExists: true)
                .collect()
                .map{ file -> [file.baseName, file] }
            ch_spikein_chrom_sizes = Channel.fromPath(params.genomes[spike_genome].chrom_sizes, checkIfExists: true)
            ch_spikein_gsize = Channel.of(params.genomes[spike_genome].effective_genome_size)
            ch_spikein_blacklist_bed = Channel.fromPath(params.genomes[spike_genome].blacklist_bed)

        } else if (params.spike_genome_fasta) {
            if (!params.read_length) {
                error "Building a custom spike-in reference requires --read_length."
            }
            spikein_fasta = Channel.fromPath(params.spike_genome_fasta, checkIfExists: true)
            if (file(params.spike_genome_fasta).extension == 'gz') {
                spikein_fasta = GUNZIP_SPIKEIN_FASTA(spikein_fasta).uncompressed
            }
            ch_spikein_index = BWA_INDEX_SPIKEIN(spikein_fasta.map{ it -> [it.baseName, it] }).index.collect()
            ch_spikein_chrom_sizes = SPLIT_SPIKEIN_CHROMS(spikein_fasta).chrom_sizes
            KHMER_UNIQUEKMERS_SPIKEIN(spikein_fasta, params.read_length)
            ch_spikein_gsize = KHMER_UNIQUEKMERS_SPIKEIN.out.kmers.map{ it.text.trim() }
            // MULTIBAM_SUMMARY skips the blacklist when the file doesn't exist
            ch_spikein_blacklist_bed = Channel.fromPath(params.spike_blacklist_bed ?: 'NO_FILE')

        } else {
            error "No reference available for spike-in genome '${spike_genome}'. Either choose a genome configured in conf/genomes.config (${params.genomes.keySet().sort().join(', ')}), or supply --spike_genome_fasta to build a custom reference."
        }

        BWA_MEM( ch_fastq, ch_spikein_index )
        DEDUPLICATE(BWA_MEM.out.bam.map{ meta, bam, bai -> [ meta, bam ] },
                    ch_spikein_chrom_sizes,
                    ch_spikein_gsize
                    )
        DEDUPLICATE.out.bam | view
        SAMTOOLS_COUNT( DEDUPLICATE.out.bam )
        SAMTOOLS_COUNT.out.count
            | map{ meta, count -> [meta.antibody, meta, count]}
            | groupTuple()
            | map{ ab, metas, counts -> [ metas, counts ] }
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
                | map{ meta, bam, bai -> [meta.antibody, meta, bam, bai]}
                | groupTuple()
                | map{ ab, metas, bams, bais -> [ metas, bams, bais ] }
                | combine(min_fraglen)
                | combine(ch_spikein_blacklist_bed)
                | MULTIBAM_SUMMARY
            MULTIBAM_SUMMARY.out.sf
                | set{ ch_sf_tsv } // https://github.com/nextflow-io/nextflow/issues/3970
        } else {
            error "Unknown spike-in normalization method: ${params.spike_norm_method}"
        }
        ch_spike_counts
            | transpose
            | map{ meta, count -> [1, meta, count]}
            | groupTuple()
            | map{ _x, metas, counts -> [ metas.flatten(), counts.flatten() ] }
            | set{ ch_spike_counts_flat }
        MAKE_TABLE( ch_sf_tsv.collect(), ch_spike_counts_flat )
        ch_sf_tsv
            | splitCsv(header: true, sep: '\t')
            | map{ row -> [ row.sample, row.scalingFactor ] }
            | set{ ch_scaling_factors }


    emit:
        sf_tsv            = MAKE_TABLE.out.tsv // for multiqc
        scaling_factors   = ch_scaling_factors // channel: [ val(meta_id), val(scaling_factor) ]
}
