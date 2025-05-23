
include { CAT_CAT as CONCAT_INPUTS_SINGLE;
          CAT_CAT as CONCAT_INPUTS_PAIRED  } from "../../../modules/nf-core/cat/cat"

workflow POOL_INPUTS {
    take:
        ch_reads
    main:
        ch_reads
            | branch { meta, reads ->
                input_single: meta.is_input && meta.single_end
                input_paired: meta.is_input && !meta.single_end
                samples: !meta.is_input
            }
            | set{ fastqs_branched }

        // make sure forward and reverse reads are retained
        fastqs_branched.input_paired
            | map { meta, reads ->
                [ [meta + [r: 1], meta + [r: 2]], [reads[0], reads[1]] ]
            }
            | transpose()
            | map { meta, reads ->
                [ "${meta.sample_basename}_R${meta.r}", meta, reads ]
            }
            | groupTuple()
            | map{ group_name, metas, reads ->
                def meta = metas[0]
                meta.id = group_name
                meta.rep = ''
                meta.remove('r')
                [ meta, reads.flatten().sort() ]
            }
            | CONCAT_INPUTS_PAIRED
        CONCAT_INPUTS_PAIRED.out.file_out
            | map { meta, read ->
                [ meta.sample_basename, meta, read ]
            }
            | groupTuple()
            | map { sample_basename, metas, reads ->
                def meta = metas[0]
                meta.id = sample_basename
                [ meta, reads.flatten().sort() ]
            }

        fastqs_branched.input_single
            | map { meta, reads ->
                [ meta.sample_basename, meta, reads ]
            }
            | groupTuple()
            | map{ sample_basename, metas, reads ->
                def meta = metas[0]
                meta.id = sample_basename
                meta.rep = ''
                [ meta, reads.flatten().sort() ]}
            | CONCAT_INPUTS_SINGLE


        CONCAT_INPUTS_SINGLE.out.file_out
            .mix(fastqs_branched.samples)
            .set{ mixed_reads }

    emit:
        reads = mixed_reads
}
