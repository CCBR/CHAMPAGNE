include { BWA_INDEX as BWA_INDEX_REF } from "../../modules/CCBR/bwa/index"
include { KHMER_UNIQUEKMERS          } from '../../modules/CCBR/khmer/uniquekmers'
include { SPLIT_REF_CHROMS
          RENAME_FASTA_CONTIGS as RENAME_FASTA_CONTIGS_REF
          RENAME_FASTA_CONTIGS as RENAME_FASTA_CONTIGS_BL
          RENAME_DELIM_CONTIGS
          GTF2BED
          WRITE_GENOME_CONFIG } from "../../modules/local/prepare_genome.nf"

include { PREPARE_BLACKLIST } from './prepare_blacklist.nf'

workflow PREPARE_GENOME {
    main:
        ch_genome_conf = Channel.empty()
        if (params.genomes[ params.genome ]) {
            ch_fasta = Channel.fromPath(params.genomes[ params.genome ].fasta, checkIfExists: true)
            ch_genes_gtf = Channel.fromPath(params.genomes[ params.genome ].genes_gtf, checkIfExists: true)
            ch_blacklist_index = Channel.empty()
            if (params.blacklist) {
                ch_blacklist_index = PREPARE_BLACKLIST(file(params.blacklist, checkIfExists: true),
                                                        ch_fasta,
                                                        params.rename_contigs
                                                        ).index
            }
            else if (params.genomes[ params.genome ].blacklist_index) {
                ch_blacklist_index = Channel.fromPath(params.genomes[ params.genome ].blacklist_index, checkIfExists: true)
                    .collect()
                    .map{ file ->
                        [file.baseName, file]
                    }
            }

            ch_reference_index = Channel.fromPath(params.genomes[ params.genome ].reference_index, checkIfExists: true)
                .collect()
                .map{ file ->
                    [file.baseName, file]
                }
            ch_chrom_dir = Channel.fromPath("${params.genomes[ params.genome ].chromosomes_dir}", type: 'dir', checkIfExists: true)
            ch_chrom_sizes = Channel.fromPath(params.genomes[ params.genome ].chrom_sizes, checkIfExists: true)
            ch_gene_info = Channel.fromPath(params.genomes[ params.genome ].gene_info, checkIfExists: true)
            ch_gsize = Channel.value(params.genomes[ params.genome ].effective_genome_size)
            ch_meme_motifs = Channel.fromPath(params.genomes[ params.genome ].meme_motifs, checkIfExists: true)
            ch_bioc_txdb = Channel.value(params.genomes[ params.genome ].bioc_txdb)
            ch_bioc_annot = Channel.value(params.genomes[ params.genome ].bioc_annot)

        } else if (params.genome_fasta && params.genes_gtf) {
            fasta_file = Channel.fromPath(params.genome_fasta, checkIfExists: true)
            gtf_file = file(params.genes_gtf, checkIfExists: true)

            // rename contigs from ensembl to UCSC if needed
            if (params.rename_contigs) {
                contig_map = file(params.rename_contigs, checkIfExists: true)
                ch_fasta = RENAME_FASTA_CONTIGS_REF(fasta_file, contig_map).fasta
                ch_gtf = RENAME_DELIM_CONTIGS(gtf_file, contig_map).delim
            } else {
                ch_fasta = fasta_file
                ch_gtf = gtf_file
            }

            fasta_meta = ch_fasta.map{ it -> [it.baseName, it]}

            ch_genes_gtf = Channel.fromPath(gtf_file)
            ch_blacklist_index = Channel.empty()
            if (params.blacklist) {
                ch_blacklist_index =  PREPARE_BLACKLIST(file(params.blacklist, checkIfExists: true),
                                                        ch_fasta,
                                                        params.rename_contigs
                                                        ).index
            }
            ch_reference_index = BWA_INDEX_REF(fasta_meta).index.collect()
            KHMER_UNIQUEKMERS(ch_fasta, params.read_length)
            ch_gsize = KHMER_UNIQUEKMERS.out.kmers.map { it.text.trim() }
            ch_gene_info = GTF2BED ( ch_gtf ).bed
            SPLIT_REF_CHROMS(ch_fasta)
            ch_chrom_sizes = SPLIT_REF_CHROMS.out.chrom_sizes
            ch_chrom_dir = SPLIT_REF_CHROMS.out.chrom_dir
            if (params.meme_motifs && file(params.meme_motifs).exists()) {
                meme_motif_name = Channel.value(params.meme_motifs)
                ch_meme_motifs = Channel.fromPath(params.meme_motifs)
            } else {
                meme_motif_name = 'null'
                ch_meme_motifs = Channel.empty()
                params.run_meme = false
            }
            ch_bioc_txdb = Channel.value(params.bioc_txdb)
            ch_bioc_annot = Channel.value(params.bioc_annot)

            WRITE_GENOME_CONFIG(
                ch_fasta,
                ch_genes_gtf,
                ch_reference_index,
                ch_blacklist_index,
                ch_chrom_sizes,
                ch_chrom_dir,
                ch_gene_info,
                ch_gsize,
                meme_motif_name,
                ch_bioc_txdb,
                ch_bioc_annot,

            )
            ch_genome_conf = WRITE_GENOME_CONFIG.out.conf.mix(WRITE_GENOME_CONFIG.out.files)

        } else {
            error "Either specify a genome in `conf/genomes.conf`, or specify a genome fasta, gtf, and blacklist file to build a custom reference."
        }

    emit:
        fasta = ch_fasta
        blacklist_index = ch_blacklist_index
        reference_index = ch_reference_index
        chrom_sizes = ch_chrom_sizes
        chrom_dir = ch_chrom_dir
        gene_info = ch_gene_info
        effective_genome_size = ch_gsize
        meme_motifs = ch_meme_motifs
        bioc_txdb = ch_bioc_txdb
        bioc_annot = ch_bioc_annot
        conf = ch_genome_conf
}
