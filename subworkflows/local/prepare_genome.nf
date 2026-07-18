include { BWA_INDEX as BWA_INDEX_REF } from "../../modules/CCBR/bwa/index"
include { KHMER_UNIQUEKMERS          } from '../../modules/CCBR/khmer/uniquekmers'
include { DOWNLOAD_GENOME
          SPLIT_REF_CHROMS
          RENAME_FASTA_CONTIGS as RENAME_FASTA_CONTIGS_REF
          RENAME_FASTA_CONTIGS as RENAME_FASTA_CONTIGS_BL
          RENAME_DELIM_CONTIGS
          GTF2BED
          WRITE_GENOME_CONFIG } from "../../modules/local/prepare_genome.nf"

include { PREPARE_BLACKLIST } from './prepare_blacklist.nf'

workflow PREPARE_GENOME {
    main:
        ch_genome_conf = Channel.empty()

        def genome_entry = params.genome ? params.genomes[ params.genome ] : null
        // all three sources are required by the reference-build path
        def can_download = genome_entry &&
                           genome_entry.fasta_url &&
                           genome_entry.gtf_url &&
                           genome_entry.blacklist_url
        // download when explicitly requested, or when prebuilt assets are unavailable (no index_dir, e.g. off-Biowulf)
        def want_download = can_download && (params.download_refs || !params.index_dir)
        // otherwise use prebuilt assets on shared storage (Biowulf)
        def use_prebuilt = genome_entry && params.index_dir && !want_download

        if (use_prebuilt) {
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
            } else {
                ch_blacklist_index = PREPARE_BLACKLIST(Channel.fromPath(params.blacklist, checkIfExists: true),
                                                       ch_fasta,
                                                       params.rename_contigs
                                                       ).index
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

        } else if (want_download || (params.genome_fasta && params.genes_gtf && params.blacklist)) {

            // resolve the raw fasta/gtf/blacklist sources, either by downloading
            // from the registry URLs or from user-supplied custom files
            def rl
            def meme_motifs_src
            def bioc_txdb_src
            def bioc_annot_src
            def fasta_file
            def gtf_file
            def blacklist_ch

            if (want_download) {
                // Nextflow stages each URL natively; DOWNLOAD_GENOME then verifies md5 and decompresses
                ch_downloads = Channel.of(
                    ['fasta',     genome_entry.fasta_url,     (genome_entry.fasta_md5 ?: '')],
                    ['gtf',       genome_entry.gtf_url,       (genome_entry.gtf_md5 ?: '')],
                    ['blacklist', genome_entry.blacklist_url, (genome_entry.blacklist_md5 ?: '')]
                ).map { name, url, md5 -> [ name, file(url), md5 ] }
                DOWNLOAD_GENOME(ch_downloads)
                DOWNLOAD_GENOME.out.file
                    .branch { name, f ->
                        fasta:     name == 'fasta'
                        gtf:       name == 'gtf'
                        blacklist: name == 'blacklist'
                    }
                    .set { dl }
                fasta_file   = dl.fasta.map     { name, f -> f }
                gtf_file     = dl.gtf.map       { name, f -> f }
                blacklist_ch = dl.blacklist.map { name, f -> f }
                rl              = genome_entry.read_length ?: params.read_length
                meme_motifs_src = genome_entry.meme_motifs
                bioc_txdb_src   = genome_entry.bioc_txdb
                bioc_annot_src  = genome_entry.bioc_annot
            } else {
                fasta_file   = Channel.fromPath(params.genome_fasta, checkIfExists: true)
                gtf_file     = Channel.fromPath(params.genes_gtf, checkIfExists: true)
                blacklist_ch = Channel.fromPath(params.blacklist, checkIfExists: true)
                rl              = params.read_length
                meme_motifs_src = params.meme_motifs
                bioc_txdb_src   = params.bioc_txdb
                bioc_annot_src  = params.bioc_annot
            }

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

            ch_genes_gtf = ch_gtf
            ch_blacklist_index =  PREPARE_BLACKLIST(blacklist_ch,
                                                    ch_fasta,
                                                    params.rename_contigs
                                                    ).index
            ch_reference_index = BWA_INDEX_REF(fasta_meta).index.collect()
            KHMER_UNIQUEKMERS(ch_fasta, rl)
            ch_gsize = KHMER_UNIQUEKMERS.out.kmers.map { it.text.trim() }
            ch_gene_info = GTF2BED ( ch_gtf ).bed
            SPLIT_REF_CHROMS(ch_fasta)
            ch_chrom_sizes = SPLIT_REF_CHROMS.out.chrom_sizes
            ch_chrom_dir = SPLIT_REF_CHROMS.out.chrom_dir
            if (meme_motifs_src && file(meme_motifs_src).exists()) {
                meme_motif_name = Channel.value(meme_motifs_src)
                ch_meme_motifs = Channel.fromPath(meme_motifs_src)
            } else {
                meme_motif_name = 'null'
                ch_meme_motifs = Channel.empty()
                params.run_meme = false
            }
            ch_bioc_txdb = Channel.value(bioc_txdb_src)
            ch_bioc_annot = Channel.value(bioc_annot_src)

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
