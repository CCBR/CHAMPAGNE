# CHAMPAGNE Workflow Overview

![](/diagram/workflow.svg)

CHAMPAGNE is a comprehensive ChIP-seq analysis pipeline that integrates multiple preprocessing, quality control, peak calling, annotation, and downstream analysis steps. Below is a detailed breakdown of each workflow stage.

## Input Validation [INPUT_CHECK]

Validates the sample sheet and contrast sheet to ensure the samples and contrasts names are defined correctly.

## Adapter Trimming [CUTADAPT]

Removes sequencing adapters and low-quality bases from raw reads.

## Input Pooling [POOL_INPUTS]

Concatenates trimmed reads from multiple input files belonging to the same sample.

## Genome Preparation [PREPARE_GENOME]

Prepares genome information for a custom genome when given a fasta & gtf file.

- Generates reference genome files and indices
- Creates chromosome sizes, effective genome size, blacklist regions, and other reference data
- Outputs annotation files for downstream use

## Blacklist Filtering [FILTER_BLACKLIST]

Removes reads mapping to known problematic genomic regions (blacklisted regions).

## Genome Alignment [ALIGN_GENOME]

- Aligns reads to reference genome using BWA
- Filters alignments by quality score
- Sorts BAM files for downstream processing
- Generates flagstat metrics at alignment and filtering stages

## Deduplication [DEDUPLICATE]

- Removes PCR duplicates using MACS2 filterdup (single-end) or Picard MarkDuplicates (paired-end)
- Converts BAM files to tag-align format for MACS2/SICER peak calling
- Maintains BAM/BAMPE format for GEM peak calling
- Generates flagstat metrics for quality assessment

## Quality Metrics [PHANTOM_PEAKS]

- Calculates fragment length estimates and quality metrics using PhantomPeaks
- Assesses library complexity and cross-correlation

## Quality Control [QC]

- Runs FastQC on raw and trimmed reads for sequence quality assessment
- Runs FASTQ_SCREEN for contamination detection
- Estimates library complexity using PRESEQ
- Compiles alignment and deduplication statistics
- Generates comprehensive QC report for MultiQC

## Spike-in Normalization [ALIGN_SPIKEIN] _(Optional)_

Aligns reads to spike-in genome (e.g. Drosophila) for exogenous normalization and calculates normalization scaling factors using either the Guenther or deLorenzi method.
See [the spike-in normalization page](./spike-in.md) for more details.

## Genome Coverage Visualization [DEEPTOOLS]

- Generates genome-wide coverage bigWig files
- Creates input-normalized bigWig files (background subtraction)
- Produces correlation matrices and heatmaps
- Calculates fingerprint plots for quality assessment

## Peak Calling [CALL_PEAKS]

- Identifies enriched regions using multiple peak-calling algorithms:
    - MACS2 (broad and narrow)
    - GEM
    - SICER
- Calculates fraction of reads in peaks (FRiP) for quality assessment
- Computes Jaccard index for peak overlap between samples
- Analyzes peak width distributions
- Outputs peak files in BED format

## Consensus Peak Calling _(Optional)_

### Union Method [CONSENSUS_UNION]

- Merges peaks across replicates using union approach
- Retains all peaks detected in any replicate
- Annotates and performs motif analysis on consensus peaks

### Corces Method [CONSENSUS_CORCES]

- Merges peaks using the Corces algorithm (based on peak summits)
- More stringent consensus approach
- Annotates and performs motif analysis on consensus peaks

## Peak Annotation [ANNOTATE]

Uses ChIPseeker to assign genomic features to peaks and identify nearest genes

## Motif Discovery [MOTIFS]

Generates motif predictions and enrichment statistics and identifies transcription factors likely binding at detected peaks.

- HOMER performs reference and de novo motif discovery in peak sequences
- MEME-AME performs known motif enrichment analysis against genomic motif databases

## Differential Analysis [DIFF] _(Optional)_

Performs differential binding analysis when contrasts are provided using one of two methods:

- DiffBind, used when each sample has at least 2 replicates
- MAnorm, used when any sample has only 1 replicate

## Quality Report Aggregation [MULTIQC]

Compiles all quality metrics and statistics into an interactive HTML report summarizing all pipeline results
