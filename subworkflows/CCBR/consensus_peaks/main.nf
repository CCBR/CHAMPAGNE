include { CAT_CAT        } from '../../../modules/CCBR/cat/cat/'
include { SORT_BED  } from '../../../modules/CCBR/sort/bed'
include { BEDTOOLS_MERGE } from '../../../modules/CCBR/bedtools/merge/'
include { CUSTOM_FORMATMERGEDBED as CONSENSUS_UNION  } from '../../../modules/CCBR/custom/formatmergedbed/'
include { CUSTOM_NORMALIZEPEAKS     } from '../../../modules/CCBR/custom/normalizepeaks/'

workflow CONSENSUS_PEAKS {

    take:
        // channel: [ val(meta), peak ]
        // meta should contain a group variable by which the peaks will be grouped
        // peaks should already be sorted by chromosome name then by start pos
        ch_peaks
        // whether to normalize p-values and q-values
        normalize

    main:

        ch_versions = Channel.empty()

        if (normalize) {
            ch_peaks | CUSTOM_NORMALIZEPEAKS
            ch_peaks = CUSTOM_NORMALIZEPEAKS.out.bed
            ch_versions = ch_versions.mix(CUSTOM_NORMALIZEPEAKS.out.versions)
        }

        peaks_grouped = ch_peaks
            .map{ meta, peak ->
                [ [id: meta.group], peak ]
            }
            .groupTuple()
        peaks_grouped | CAT_CAT
        SORT_BED( CAT_CAT.out.file_out )
        BEDTOOLS_MERGE(SORT_BED.out.bed, ' -c 1,5,6,7,8,9 -o count,collapse,collapse,collapse,collapse,collapse ')
        CONSENSUS_UNION(BEDTOOLS_MERGE.out.bed)
        consensus_peaks = CONSENSUS_UNION.out.bed.map { meta, bed ->
            meta.consensus = 'union'
            [meta, bed]
        }

        ch_versions = ch_versions.mix(
            CAT_CAT.out.versions,
            SORT_BED.out.versions,
            BEDTOOLS_MERGE.out.versions,
            CONSENSUS_UNION.out.versions
        )

    emit:
        peaks    = consensus_peaks
        versions = ch_versions
}
