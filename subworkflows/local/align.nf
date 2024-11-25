include { BWA_MEM as BWA_MEM_REF          } from "../../modules/CCBR/bwa/mem"
include { FILTER_QUALITY    } from "../../modules/local/align.nf"
include { SAMTOOLS_FLAGSTAT as SAMTOOLS_FLAGSTAT_ALIGN
          SAMTOOLS_FLAGSTAT as SAMTOOLS_FLAGSTAT_FILTER } from '../../modules/CCBR/samtools/flagstat'
include { SAMTOOLS_SORT     } from '../../modules/CCBR/samtools/sort'

workflow ALIGN_GENOME {

    take:
        reads
        reference

    main:
        BWA_MEM_REF(reads, reference)
        SAMTOOLS_FLAGSTAT_ALIGN( BWA_MEM_REF.out.bam )
        FILTER_QUALITY( BWA_MEM_REF.out.bam )
        SAMTOOLS_SORT( FILTER_QUALITY.out.bam )
        SAMTOOLS_FLAGSTAT_FILTER( SAMTOOLS_SORT.out.bam )

        ch_versions = Channel.empty().mix(
            BWA_MEM_REF.out.versions,
            SAMTOOLS_FLAGSTAT_ALIGN.out.versions
        )

    emit:
        bam               = FILTER_QUALITY.out.bam
        aligned_flagstat  = SAMTOOLS_FLAGSTAT_ALIGN.out.flagstat
        filtered_flagstat = SAMTOOLS_FLAGSTAT_FILTER.out.flagstat
        versions          = ch_versions
}
