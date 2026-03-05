include { BAM_COVERAGE
          NORMALIZE_INPUT
          BIGWIG_SUM
          BED_PROTEIN_CODING
          COMPUTE_MATRIX
          PLOT_FINGERPRINT
          PLOT_CORRELATION
          PLOT_PCA
          PLOT_HEATMAP
          PLOT_PROFILE        } from "../../../modules/local/deeptools.nf"

workflow DEEPTOOLS {
    take:
        deduped_bam
        frag_lengths
        effective_genome_size
        gene_info
        scaling_factors

    main:

        deduped_bam
            | map{ meta, bam, bai ->
                def norm_method = meta.is_input ? params.deeptools_normalize_input : params.deeptools_normalize_samples
                [ meta.id, meta, bam, bai, norm_method ]
            }
            | join(scaling_factors)
            | map{ id, meta, bam, bai, norm_method, sf -> [meta, bam, bai, norm_method, sf] }
            | join(frag_lengths)
            | combine(effective_genome_size)
            | BAM_COVERAGE
        BAM_COVERAGE.out.bigwig
            .set { bigwigs }

        bigwigs
            .map{ meta, bigwig -> bigwig }
            .collect() | BIGWIG_SUM
        bw_array = BIGWIG_SUM.out.array
        bw_array.combine(Channel.of('heatmap', 'scatterplot')).combine(Channel.value(params.deeptools_corr_method)) | PLOT_CORRELATION
        bw_array | PLOT_PCA

        // Create channel: [ meta, ip_bw, input_bw ]
        bigwigs
            .combine(bigwigs)
            .map {
                meta1, bw1, meta2, bw2 ->
                    meta1.input == meta2.id ? [ meta1, bw1, bw2 ] : null
            }
            .set { ch_ip_ctrl_bigwig }

        // get normalized bigwigs
        ch_ip_ctrl_bigwig | NORMALIZE_INPUT
        NORMALIZE_INPUT.out.bigwig.map{ meta, bigwig -> bigwig }.set{ bigwigs_norm }

        // get bed file of only protein-coding genes
        gene_info | BED_PROTEIN_CODING
        beds = BED_PROTEIN_CODING.out.bed_prot.mix(BED_PROTEIN_CODING.out.bed_all)

        // group raw bigwigs by sample basename to group replicates & sample/input pairs together
        bigwigs_raw = ch_ip_ctrl_bigwig
            .map{ meta, sample_bw, input_bw ->
                [ [ id: meta.sample_basename ], sample_bw ]
            }
            .concat(ch_ip_ctrl_bigwig
                .map{ meta, sample_bw, input_bw ->
                    [ [ id: meta.sample_basename], input_bw ]
                }
            )
        // create plots with:
        //    - raw or normalized bigwigs
        //    - protein coding or all genes
        //    - metagene or TSS
        ch_all_bigwigs = Channel.value([ id: 'inputnorm' ])
            .combine(bigwigs_norm)
            .mix(bigwigs_raw)
            .groupTuple()
            .map{ meta, bigwigs ->
                [ meta, bigwigs.unique() ]
            }
            .combine(beds)
            .combine(Channel.of('metagene','TSS'))
        COMPUTE_MATRIX(ch_all_bigwigs)
        PLOT_HEATMAP(COMPUTE_MATRIX.out.mat)
        PLOT_PROFILE(COMPUTE_MATRIX.out.mat)

        ch_inputs = deduped_bam
            .combine(deduped_bam)
            .map {
                meta1, bam1, bai1, meta2, bam2, bai2 ->
                    meta1.input == meta2.id ? [ [id: meta1.sample_basename], bam2, bai2 ] : null
            }
        ch_samples = deduped_bam
            .combine(deduped_bam)
            .map {
                meta1, bam1, bai1, meta2, bam2, bai2 ->
                    meta1.input == meta2.id ? [ [id: meta1.sample_basename], bam1, bai1 ] : null
            }
        ch_inputs.mix(ch_samples)
            .groupTuple()
            .map{ meta, bams, bais ->
                [ meta, bams.unique(), bais.unique() ]
            }
            .set { ch_ip_ctrl_bam_bai }
        ch_ip_ctrl_bam_bai | PLOT_FINGERPRINT

    emit:
        bigwigs             = bigwigs
        bigwigs_input_norm  = NORMALIZE_INPUT.out.bigwig
        fingerprint_matrix  = PLOT_FINGERPRINT.out.matrix
        fingerprint_metrics = PLOT_FINGERPRINT.out.metrics
        corr                = PLOT_CORRELATION.out.tab
        pca                 = PLOT_PCA.out.tab
        profile             = PLOT_PROFILE.out.tab
        heatmap             = PLOT_CORRELATION.out.png
}
