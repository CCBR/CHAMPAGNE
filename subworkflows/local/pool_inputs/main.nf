
include { CAT_CAT as CONCAT_INPUTS                  } from "../../../modules/nf-core/cat/cat"

workflow POOL_INPUTS {
    take:
        ch_reads
    main:
        ch_reads.branch { meta, reads ->
                input: meta.is_input
                samples: !meta.is_input
            }
            .set{ fastqs_branched }

        fastqs_branched.input.map { meta, reads ->
            [ meta.sample_basename, meta, reads ]
            }
            .groupTuple()
            .map{ sample_basename, metas, reads ->
                [ [id: sample_basename, sample_basename: sample_basename, rep: '', single_end: metas[0].single_end, antibody: '', control: '', is_input: true], reads.flatten() ]}
            | CONCAT_INPUTS

        CONCAT_INPUTS.out.file_out
            .mix(fastqs_branched.samples)
            .set{ mixed_reads }

    emit:
        reads = mixed_reads
}
