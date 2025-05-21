## CHAMPAGNE development version

- CHAMPAGNE now depends on ccbr_tools v0.4 for updated jobby & spooker utilities. (#247, @kelly-sovacool)

### New features

- Contrasts are now specified as a TSV file instead of YAML. (#224, @kelly-sovacool)
  - See the example contrast sheets in `assets/`.
- New consensus peak method from Corces _et al._ ([doi:10.1126/science.aav1898](https://www.science.org/doi/10.1126/science.aav1898)). (#225, #246, @kelly-sovacool)
- CLI improvements
  - Use `nextflow run -resume` by default, or turn it off with `champagne run --forceall`. (#224, @kelly-sovacool)
  - Add `--output` argument for `champagne init` and `champagne run`. (#232, #233, @kelly-sovacool)
    - This is equivalent to the nextflow launchDir constant.
  - `--mode` now has `slurm` as the default. (#249, @kelly-sovacool)
- Improved nextflow options:
  - Set `publish_dir_mode` to `link` by default.
  - Set `process.cache` to `deep` by default rather than lenient. (#224, @kelly-sovacool)
  - Enable the nextflow timeline & trace reports by default. (#226, @kelly-sovacool)

### Bug fixes

- Refactor checks for the sample sheet & contrast sheet to prevent unnecessary re-running. (#224, @kelly-sovacool)
- Fix a file name clash during input pooling. (#224, @kelly-sovacool)
- Fix bug in MEME AME process that caused it not to run on all samples. (#234, @kelly-sovacool)
  - Also correct the motif rank calculation. (#234, @kopardev)

### Documentation

- Now using the readthedocs theme for the docs website. (#236, @kelly-sovacool)
- Improved help message for `champagne run`. (#249, @kelly-sovacool)

## CHAMPAGNE 0.4.1

- The CHAMPAGNE nextflow workflow now has a version entry in `nextflow.config`, in compliance with nf-core. (#213, @kelly-sovacool)
- Pool input (control) reads of the same sample name by default. Any inputs that should not be pooled must have different sample names in the samplesheet. (#214, @kelly-sovacool)
- Add histone samples to the `test_human` dataset. (#215, @kelly-sovacool)

## CHAMPAGNE 0.4.0

### New features

- Create a script (`bin/champagne`) to provide an interface to the champagne CLI that works out-of-the-box without the need to install the python package with `pip`. (#180, @kelly-sovacool)
  - However, any dependencies not in the Python Standard Library must be installed for this to work. See the dependencies list in `pyproject.toml`.
- Allow additional columns in the sample sheet beyond the minimum required header. (#176, @kelly-sovacool)
- Add a workflow entry point to download fastq files from SRA. (#176, @kelly-sovacool)
- Add `test_human` profile with chipseq data from ENCODE. (#176, @kelly-sovacool)

### Bug fixes

- Fix configuration files for compatibility with using the GitHub repo as the source. (#173, @kelly-sovacool)
  - These equivalent commands now work:
    ```sh
    nextflow run CCBR/CHAMPAGNE
    champagne run --main CCBR/CHAMPAGNE
    ```
- Allow multiple samples to use the same input. (#176, @kelly-sovacool)
- In the biowulf config profile, switch variable $SLURM_JOBID to $SLURM_JOB_ID. (@kelly-sovacool)
- Increase resource allocations for chipseeker and deeptools. (#192, @slsevilla)
- Check the validity of the contrastsheet earlier on in the workflow. (#192, @slsevilla; #200, @kelly-sovacool)
- Fix bug where `manorm` was using R1 twice instead of R1 and R2. (#206, @kelly-sovacool)

### Misc

- Change the peak widths histogram type from overlay to stack. (#176, @kelly-sovacool)
- Documentation improvements. (#192, @slsevilla)

## CHAMPAGNE 0.3.0

### New features

- Find motifs in the genome with Homer. (#142)
- Run motif enrichment analysis with MEME. (#142)
- Annotate peaks with chipseeker. (#142,#147,#157)
- Add preseq complexity curve and fastq screen to multiqc report. (#147)
- Support multiple replicates per sample and call consensus peaks on replicates. (#129)
  - Optionally normalize p-values with the [CCBR/consensus_peaks](https://github.com/CCBR/nf-modules/tree/60d50f4c45a50378cad70b49013f51750617caaa/subworkflows/CCBR/consensus_peaks) subworkflow.
- Implement differential peak calling. (#158)
  - Optionally specify contrasts via a YAML file. If no file is specified, differential analysis is not performed.
  - If any sample has only one replicate, run `MAnorm`, otherwise run `diffbind`.
- Print the recommended citation in bibtex format with `champagne --citation`. (#153)
  - CHAMPAGNE is also now archived in Zenodo with DOI `10.5281/zenodo.10516078`.
- The docs website now has a dropdown menu to select which version to view. The latest release is shown by default. (#170)

### Bug fixes

- Fix deepTools plots (#144):
  - Per sample fingerprint plots instead of per replicate.
  - Input normalized profile plots.
  - Protein-coding-only versions of plots.
  - Ensure sample IDs are sorted. (#150)
- Fix a bug where the wrong SICER output file was used for downstream analyses. (#155)
- Fix CLI profile on machines other than biowulf & FRCE. (#168)
- Fix broken bold styling in documentation website. (#53)

## CHAMPAGNE 0.2.2

- Fix permissions issues in the CLI. (#167)

## CHAMPAGNE 0.2.1

- Fix a bug in QC stats that mixed up the statistics for different samples. (#125)
- Fix a bug in the CLI that added the `-profile` to the nextflow command even if it wasn't needed (#125).
- Report read counts between blacklist & filtering steps in the QC table. (#125)
- Run spooker on workflow completion (#126).

## CHAMPAGNE 0.2.0

### New features

- Implement peak calling with sicer2, macs2, and gem. (#52)
- Add parameter options to skip QC, input normalization, and/or peak calling steps. (#72)
- Calculate and plot QC metrics for called peaks:
  - Fraction in Peaks (FRiP) (#89)
  - Jaccard index (#92)
  - Histogram of peak widths (#92)
- Add support for paired-end reads. (#105)
- Add an option to use a custom reference from a genome fasta, gtf, and blacklist file. (#105)
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
