## Process workflow

TODO add images to show workflow

### Pipeline Checks

- Input files are checked that they meet standard formatting; some file access is reviewed

- Processes include:

  - INPUT_CHECK:SAMPLESHEET_CHECK
  - INPUT_CHECK:CHECK_CONTRASTS

- Output directories include:

  - check_contrasts

## Pre-alignment

- Adaptors are trimmed, if blacklists are included, filtering occurs

- Processes include:

  - CUTADAPT
  - FILTER_BLACKLIST:BWA_MEM
  - FILTER_BLACKLIST:SAMTOOLS_FILTERALIGNED
  - FILTER_BLACKLIST:PICARD_SAMTOFASTQ
  - FILTER_BLACKLIST:CUSTOM_COUNTFASTQ

- Output directories include:

  - cutadapt

## Alignment

- Samples are aligned using BWA; alignment stats are generated; samples are sorted and filtered

- Processes include:

  - ALIGN_GENOME:BWA_MEM
  - ALIGN_GENOME:SAMTOOLS_FLAGSTAT_ALIGN
  - ALIGN_GENOME:FILTER_QUALITY
  - ALIGN_GENOME:SAMTOOLS_SORT
  - ALIGN_GENOME:SAMTOOLS_FLAGSTAT_FILTER

- Output directories include:

  - bwa_mem
  - samtools_flagstat_align
  - samtools_filteraligned
  - samtools_sort
  - samtools_flagstat_filter

## Deduplicate

- Processes include:

  - DEDUPLICATE:MACS2_DEDUP
  - DEDUPLICATE:INDEX_SINGLE
  - DEDUPLICATE:PICARD_DEDUP
  - DEDUPLICATE:INDEX_PAIRED

- Output directories include:

## Quality Control

- Processes include:

  - PPQT_PROCESS
  - QC:FASTQC_RAW
  - QC:FASTQC_TRIMMED
  - QC:FASTQ_SCREE
  - QC:PRESEQ
  - QC:HANDLE_PRESEQ_ERROR
  - QC:PARSE_PRESEQ_LOG
  - QC:QC_STATS
  - QC:QC_TABLE

## Deeptools analysis

- Processes include:

  - QC:DEEPTOOLS:BAM_COVERAGE
  - QC:DEEPTOOLS:BIGWIG_SUM
  - QC:DEEPTOOLS:PLOT_CORRELATION
  - QC:DEEPTOOLS:PLOT_PCA
  - QC:DEEPTOOLS:NORMALIZE_INPUT
  - QC:DEEPTOOLS:BED_PROTEIN_CODING
  - QC:DEEPTOOLS:COMPUTE_MATRIX
  - QC:DEEPTOOLS:PLOT_HEATMAP
  - QC:DEEPTOOLS:PLOT_PROFILE
  - QC:DEEPTOOLS:PLOT_FINGERPRINT

## Peak calling

- Processes include:

  - PHANTOM_PEAKS
  - CALL_PEAKS:CALC_GENOME_FRAC
  - CALL_PEAKS:BAM_TO_BED
  - CALL_PEAKS:MACS_BROAD
  - CALL_PEAKS:MACS_NARROW
  - CALL_PEAKS:SICER
  - CALL_PEAKS:CONVERT_SICER
  - CALL_PEAKS:GEM
  - CALL_PEAKS:FILTER_GEM
  - CALL_PEAKS:FRACTION_IN_PEAKS
  - CALL_PEAKS:CONCAT_FRIPS
  - CALL_PEAKS:PLOT_FRIP
  - CALL_PEAKS:GET_PEAK_META
  - CALL_PEAKS:CONCAT_PEAK_META
  - CALL_PEAKS:PLOT_PEAK_WIDTHS

## Consensus Peaks

- Processes include:

  - CONSENSUS_PEAKS:CAT_CAT
  - CONSENSUS_PEAKS:SORT_BED
  - CONSENSUS_PEAKS:BEDTOOLS_MERGE
  - CONSENSUS_PEAKS:- CONSENSUS_PEAKS:\_OUT

## Annotate

- Processes include:

  - ANNOTATE:CHIPSEEKER_PEAKPLOT
  - ANNOTATE:CHIPSEEKER_ANNOTATE
  - ANNOTATE:CHIPSEEKER_PLOTLIST
  - ANNOTATE:HOMER_MOTIFS
  - ANNOTATE:MEME_AME

## Differential Analysis

- If there are more than 2 replicates per group then `diffbind` is performed; otherwise `manorm` pairewise analysis is performed

- Processes include:

  - DIFF:DIFFBIND:PREP_DIFFBIND
  - DIFF:DIFFBIND:DIFFBIND_RMD
  - DIFF:MANORM:MANORM_PAIRWISE
