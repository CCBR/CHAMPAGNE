## development version

- Support multiple replicates per sample and call consensus peaks. (#129)
- Increased default `q` for macs2 to `0.1`.

## CHAMPAGNE 0.2.1

- Fixed a bug in QC stats that mixed up the statistics for different samples. (#125)
- Fixed a bug in the CLI that added the `-profile` to the nextflow command even if it wasn't needed (#125).
- Report read counts between blacklist & filtering steps in the QC table. (#125)
- Run spooker on workflow completion (#126).

## CHAMPAGNE 0.2.0

### New features

- Implemented peak calling with sicer2, macs2, and gem. (#52)
- Added parameter options to skip QC, input normalization, and/or peak calling steps. (#72)
- Calculate and plot QC metrics for called peaks:
  - Fraction in Peaks (FRiP) (#89)
  - Jaccard index (#92)
  - Histogram of peak widths (#92)
- Added support for paired-end reads. (#105)
- Added an option to use a custom reference from a genome fasta, gtf, and blacklist file. (#105)
- Champagne CLI: (#112)
  - New `--mode` option for `champagne run` to execute the workflow locally ('local') or submit it as a slurm job ('slurm').
  - Option to override the path to the champagne `main.nf` file or specify the github repo (`CCBR/CHAMPAGNE`) instead.
    ```sh
    # use the default path
    champagne run ...
    # override the path
    champagne run path/to/champagne/main.nf
    # use a revision from github instead
    champagne run CCBR/CHAMPAGNE -r v0.1.0
    ```

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
- Renamed `champagne config` to `champagne init` to avoid clashing with `nextflow config`. (#112)

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
