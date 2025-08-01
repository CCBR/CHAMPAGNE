# How to set pipeline parameters

Any parameter can be set via the CLI using two hyphens (`--`) followed by the
parameter name and value. For example:

```sh
champagne run --output /data/$USER/champagne_project \
    --input assets/samplesheet_full_mm10.csv \
    --contrasts assets/contrasts_full_mm10.csv \
    --genome mm10 \
    --run_gem false \
    --run_chipseeker false \
    --run_qc true
```

Alternatively, you can create a YAML file with the parameters you want to set.
This is useful for managing multiple parameters or for sharing configurations
with others. Here's an example YAML file with some common parameters:

`assets/params.yml`

```YAML
input: './assets/samplesheet_full_mm10.csv'
contrasts: './assets/contrasts_full_mm10.csv'
genome: mm10
run_gem: false
run_chipseeker: false
run_qc: true
```

You can then use these parameters with the `-params-file` option:

```sh
champagne run --output /data/$USER/champagne_project \
    -params-file assets/params.yml
```

View the full list of pipeline parameters below.

<!-- This doc is generated by: nf-core pipelines schema docs. Edit parameter descriptions in nextflow_schema.json -->

# CCBR/CHAMPAGNE pipeline parameters

CHromAtin iMmuno PrecipitAtion sequencinG aNalysis pipEline

## Input/output options

The most commonly used pipeline options

| Parameter          | Description                                                                                                                                                                                                                                                                                                                                                                                  | Type     | Default                    | Required | Hidden |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | -------------------------- | -------- | ------ |
| `input`            | Path to comma-separated file containing information about the samples in the experiment. <details><summary>Help</summary><small>You will need to create a design file with information about the samples in your experiment before running the pipeline. Use this parameter to specify its location. It has to be a comma-separated file with 3 columns, and a header row.</small></details> | `string` |                            | True     |        |
| `contrasts`        | Optional contrasts specification for differential analysis                                                                                                                                                                                                                                                                                                                                   | `string` |                            |          |        |
| `genome`           | Reference genome (e.g. hg38, mm10). This can be a genome in conf/genomes.config, or see 'Custom genome options' to build a custom reference from a fasta & gtf file.                                                                                                                                                                                                                         | `string` |                            | True     |        |
| `outputDir`        |                                                                                                                                                                                                                                                                                                                                                                                              | `string` | ${launchDir}/results       |          | True   |
| `tracedir`         |                                                                                                                                                                                                                                                                                                                                                                                              | `string` | ${outputDir}/pipeline_info |          | True   |
| `publish_dir_mode` | How to publish files to the results directory. This parameter sets Nextflow's workflow.output.mode configuration option.                                                                                                                                                                                                                                                                     | `string` | link                       |          |        |

## Custom genome options

Use these to build a custom reference genome not already listed in conf/genomes.config. For an example, see conf/test.config.

| Parameter        | Description                                                                                                                                        | Type      | Default | Required | Hidden |
| ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ------- | -------- | ------ |
| `genome_fasta`   | Genome fasta file                                                                                                                                  | `string`  |         |          |        |
| `genes_gtf`      | Genome gtf file                                                                                                                                    | `string`  |         |          |        |
| `blacklist`      | Custom blacklisted sequences as a fasta file or bed file. These will be filtered out of the trimmed reads before aligning to the reference genome. | `string`  |         |          |        |
| `read_length`    | Read length used for counting unique kmers and computing the effective genome size.                                                                | `integer` |         |          |        |
| `rename_contigs` | File with map to translate chromosome names (see assets/R64-1-1_ensembl2UCSC.txt as an example)                                                    | `string`  |         |          |        |

## General parameters

| Parameter             | Description | Type      | Default | Required | Hidden |
| --------------------- | ----------- | --------- | ------- | -------- | ------ |
| `max_memory`          |             | `string`  | 224 GB  |          |        |
| `max_cpus`            |             | `integer` | 32      |          |        |
| `max_time`            |             | `string`  | 72 h    |          |        |
| `align_min_quality`   |             | `integer` | 6       |          |        |
| `min_fragment_length` |             | `integer` | 200     |          |        |

## Spike-in options

Options for experiments that use a spike-in genome

| Parameter                         | Description                                                                                                                                                                                                                                                                                                                                                         | Type      | Default   | Required | Hidden |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | --------- | -------- | ------ |
| `spike_genome`                    | Optional spike-in genome (e.g. dmelr6.32, ecoli_k12). If null, spike-in normalization will not be performed.                                                                                                                                                                                                                                                        | `string`  |           |          |        |
| `spike_norm_method`               | Method to compute scaling factors for spike-in normalization. "guenther" uses a simple fraction of the reads aligning to the spike-in genome as described in <https://doi.org/10.1016/j.celrep.2014.10.018>. "delorenzi" uses deepTools multiBamSummary with --scalingFactors, which is similar to the method described in <https://doi.org/10.1101/gr.168260.113>. | `string`  | delorenzi |          |        |
| `spike_deeptools_bin_size`        | When spike_norm_method is delorenzi, this sets --binSize in deepTools multiBamSummary                                                                                                                                                                                                                                                                               | `integer` | 5000      |          |        |
| `spike_deeptools_min_map_quality` | When spike_norm_method is delorenzi, this sets --minMappingQuality in deepTools multiBamSummary                                                                                                                                                                                                                                                                     | `integer` | 30        |          |        |

## QC options

| Parameter                   | Description                                                  | Type      | Default                    | Required | Hidden |
| --------------------------- | ------------------------------------------------------------ | --------- | -------------------------- | -------- | ------ |
| `deeptools_bin_size`        |                                                              | `integer` | 25                         |          |        |
| `deeptools_smooth_length`   |                                                              | `integer` | 75                         |          |        |
| `deeptools_normalize_using` | If using a spike-in genome, recommend setting this to "None" | `string`  | RPGC                       |          |        |
| `deeptools_excluded_chroms` |                                                              | `string`  | chrM chrX chrY             |          |        |
| `multiqc_config`            |                                                              | `string`  | assets/multiqc_config.yaml |          |        |
| `multiqc_logo`              |                                                              | `string`  | assets/ccbr_logo.png       |          |        |

## Peak callers

| Parameter           | Description | Type      | Default                                  | Required | Hidden |
| ------------------- | ----------- | --------- | ---------------------------------------- | -------- | ------ |
| `macs_narrow_q`     |             | `number`  | 0.01                                     |          |        |
| `macs_broad_q`      |             | `number`  | 0.01                                     |          |        |
| `macs_broad_cutoff` |             | `number`  | 0.01                                     |          |        |
| `gem_read_dists`    |             | `string`  | assets/gem/Read_Distribution_default.txt |          |        |
| `gem_fold`          |             | `integer` | 3                                        |          |        |
| `gem_k_min`         |             | `integer` | 6                                        |          |        |
| `gem_k_max`         |             | `integer` | 13                                       |          |        |
| `sicer_species`     |             | `string`  |                                          |          |        |

## motifs

| Parameter         | Description | Type      | Default                                                          | Required | Hidden |
| ----------------- | ----------- | --------- | ---------------------------------------------------------------- | -------- | ------ |
| `homer_de_novo`   |             | `boolean` | True                                                             |          |        |
| `homer_jaspar_db` |             | `string`  | assets/JASPAR2022_CORE_vertebrates_non-redundant_pfms_jaspar.txt |          |        |

## run control

Toggle various steps of the pipeline on/off

| Parameter              | Description | Type      | Default | Required | Hidden |
| ---------------------- | ----------- | --------- | ------- | -------- | ------ |
| `run_qc`               |             | `boolean` | True    |          |        |
| `run_deeptools`        |             | `boolean` | True    |          |        |
| `run_normalize_input`  |             | `boolean` | True    |          |        |
| `run_call_peaks`       |             | `boolean` | True    |          |        |
| `run_gem`              |             | `boolean` | True    |          |        |
| `run_sicer`            |             | `boolean` | True    |          |        |
| `run_macs_broad`       |             | `boolean` | True    |          |        |
| `run_macs_narrow`      |             | `boolean` | True    |          |        |
| `run_normalize_peaks`  |             | `boolean` |         |          |        |
| `run_chipseeker`       |             | `boolean` |         |          |        |
| `run_homer`            |             | `boolean` | True    |          |        |
| `run_meme`             |             | `boolean` | True    |          |        |
| `run_consensus_union`  |             | `boolean` | True    |          |        |
| `run_consensus_corces` |             | `boolean` | True    |          |        |

## Platform options

Options for the platform or HPC on which the pipeline is run. These are set by platform-specific profiles, e.g. conf/biowulf.config. If you are running the pipeline on biowulf, these will be set by CHAMPAGNE automatically.

| Parameter             | Description                                                                                   | Type     | Default | Required | Hidden |
| --------------------- | --------------------------------------------------------------------------------------------- | -------- | ------- | -------- | ------ |
| `index_dir`           | Absolute path to directory containing pre-built reference genomes.                            | `string` |         |          |        |
| `fastq_screen_conf`   | Path to the config file for fastq screen. See assets/fastq_screen_biowulf.conf as an example. | `string` |         |          |        |
| `fastq_screen_db_dir` | Path to the directory containing fastq screen databases.                                      | `string` |         |          |        |

## containers

| Parameter                  | Description | Type     | Default                                                      | Required | Hidden |
| -------------------------- | ----------- | -------- | ------------------------------------------------------------ | -------- | ------ |
| `containers_base`          |             | `string` | nciccbr/ccbr_ubuntu_base_20.04:v6.1                          |          |        |
| `containers_deeptools`     |             | `string` | nciccbr/ccbr_deeptools_3.5.3:v1                              |          |        |
| `containers_fastqc`        |             | `string` | nciccbr/ccrgb_qctools:v4.0                                   |          |        |
| `containers_fastq_screen`  |             | `string` | nciccbr/ccbr_fastq_screen_0.14.1:v1.0                        |          |        |
| `containers_frip`          |             | `string` | nciccbr/ccbr_frip:v1                                         |          |        |
| `containers_gem`           |             | `string` | nciccbr/ccbr_gem_3.4:v1                                      |          |        |
| `containers_macs2`         |             | `string` | nciccbr/ccbr_macs2_2.2.9.1:v1                                |          |        |
| `containers_multiqc`       |             | `string` | nciccbr/ccbr_multiqc_1.15:v1                                 |          |        |
| `containers_ngsqc`         |             | `string` | nciccbr/ccbr_ngsqc_0.31:v1                                   |          |        |
| `containers_phantom_peaks` |             | `string` | quay.io/biocontainers/phantompeakqualtools:1.2.2--hdfd78af_1 |          |        |
| `containers_picard`        |             | `string` | nciccbr/ccbr_picard_2.27.5:v1                                |          |        |
| `containers_preseq`        |             | `string` | nciccbr/ccbr_preseq_v2.0:v1                                  |          |        |
| `containers_r`             |             | `string` | nciccbr/ccbr_r_4.3.0:v1                                      |          |        |
| `containers_sicer`         |             | `string` | nciccbr/ccbr_sicer2_1.0.3:v1                                 |          |        |

## Other parameters

| Parameter         | Description | Type     | Default                    | Required | Hidden |
| ----------------- | ----------- | -------- | -------------------------- | -------- | ------ |
| `diffbind_report` |             | `string` | assets/diffbind_report.Rmd |          | True   |
