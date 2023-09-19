## CHAMPAGNE development version

### New features

- Implemented peak calling with sicer2, macs2, and gem. (#52)
- Added parameter options to skip QC, input normalization, and/or peak calling steps. (#72)

### Bug fixes

- CLI:
  - Error when biowulf-specific environment variables are not defined. (#54)
  - The host is now correctly detected as biowulf via `scontrol`. (#75)
- Containers:
  - Containers are now specified in process definitions instead of `withName`/`withLabel` for better control. (#69)
    - Shared containers are specified as parameters in the config file `conf/containers.config`.
  - No longer use `--mount type=bind` or `--volume` for making directories available to processes in containers. Instead, use Nextflow's `Channel.fromPath` constructor with `type: 'dir'`. (#71)

### API-breaking changes

- An error is thrown when a required input file doesn't exist. (#71)
  - Previously, the workflow quietly didn't run the process(es) that required the missing file.

## CHAMPAGNE 0.1.0

### Quality control steps implemented for single-end reads

- Trim raw reads, FastQC on raw and trimmed reads, and FastQ Screen on trimmed reads.
- Exclude reads that align to blacklist regions, align remaining reads to the reference genome, and deduplicate.
- Preseq on aligned reads.
- Phantompeakqualtools on aligned and deduplicated reads.
- Process reads with deepTools: bam coverage to generate bigwigs for each sample, summarize all bigwigs, and compute matrices relative to TSSs and scaled to metagene regions.
- Generate plots with deepTools: PCA, profile, heatmap, spearman correlation, and fingerprint plots.
- Summarize all quality control steps in a MultiQC report.
- Input-normalize ChIP fragments for the next stage of the pipeline.
