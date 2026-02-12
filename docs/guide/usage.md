# Getting Started with CHAMPAGNE

<!--
TODO intro paragraph
-->

## Installation

For [Biowulf](#biowulf) users, CHAMPAGNE is installed in the
`ccbrpipeliner` module. There's no need to perform any other installation steps.

If you'd like to run the pipeline in a different execution environment,
take a look at [how to run the nextflow pipeline directly](/nextflow.md).

CHAMPAGNE depends on [Nextflow](https://www.nextflow.io/) version 25 or later
and Singularity or Docker.

### Biowulf

Champagne is available on [Biowulf](https://hpc.nih.gov/) in the `ccbrpipeliner` module.
You'll first need to start an interactive session, then load the module:

```sh
# start an interactive node
sinteractive --mem=2g --cpus-per-task=2 --gres=lscratch:200

# load the ccbrpipeliner module
module load ccbrpipeliner
```

## Help

Run `champagne --help` to see the available commands and options.

```
Usage: champagne [OPTIONS] COMMAND [ARGS]...

  CHromAtin iMmuno PrecipitAtion sequencinG aNalysis pipEline

  docs: https://ccbr.github.io/CHAMPAGNE

  For more options, run: champagne [command] --help

Options:
  -v, --version  Show the version and exit.
  --citation     Print the citation in bibtex format and exit.
  -h, --help     Show this message and exit.

Commands:
  run   Run the workflow
  init  Initialize the launch directory
```

## Initialize

Initialize your project directory:

```sh
champagne init --output /data/$USER/champagne_project
```

Or if you do not use `--output`, your current working directory will be used as default:

```sh
champagne init
```

## Prepare input files

### Sample manifest

This file is a CSV file that contains information about the samples to be processed.
It is passed to the `input` parameter.

The following columns are required:

- `sample`: sample ID; does not need to be a unique column.
- `rep`: replicate number of sample ID; does not need to be a unique column.
- `fastq_1`: absolute path to R1 of sample ID. Files can be in compressed (`.fastq.gz`, `.fq.gz`) or uncompressed (`.fastq`, `.fq`) format.
- `fastq_2`: absolute path to R2 of sample ID (optional, only for paired-end reads). Files can be in compressed (`.fastq.gz`, `.fq.gz`) or uncompressed (`.fastq`, `.fq`) format.
- `antibody`: name of the antibody used for the sample.
- `input`: the sampleID of the input control; this must match a sample in the sheet.

Example for a single-end project:

`samplesheet.csv`

```
sample,rep,fastq_1,fastq_2,antibody,control
sampleA,1,/path/to/sample_1.R1.fastq.gz,,Ab,inputA
sampleA,2,/path/to/sample_2.R1.fastq.gz,,Ab,inputA
inputA,1,/path/to/sample1.R1.fastq.gz,,,
inputA,2,/path/to/sample1.R1.fastq.gz,,,
```

Example for a paired-end project:

`samplesheet.csv`

```
sample,rep,fastq_1,fastq_2,antibody,control
sample1,1,/path/to/sample_1.R1.fastq.gz,/path/to/sample_1.R2.fastq.gz,Ab,input1
sample1,2,/path/to/sample_2.R1.fastq.gz,/path/to/sample_1.R2.fastq.gz,Ab,input1
input1,1,/path/to/input_1.R1.fastq.gz,/path/to/input_1.R2.fastq.gz,,
input1,2,/path/to/input_2.R1.fastq.gz,/path/to/input_2.R2.fastq.gz,,
```

For more examples, view the sample sheet files in the [`assets/` directory on
GitHub](https://github.com/CCBR/CHAMPAGNE/tree/main/assets).

### Contrasts (optional)

Contrasts are specified as a TSV file and is passed to the `contrasts` parameter.
Each row is a unique contrast for differential analysis.

Columns:

- `contrast_name`: name of the contrast. Must be unique and contain no spaces.
- `group1`: comma-separated list of sample IDs in group 1.
- `group2`: comma-separated list of sample IDs in group 2.

The following is an example contrast file with two contrasts

`assets/contrasts_full_mm10.tsv`

```
contrast_name	group1	group2
antibody	CTCF_ChIP_macrophage_p20,CTCF_ChIP_MEF_p20	CTCF_ChIP_macrophage_p3
celltype_macrophage_vs_fibroblast	CTCF_ChIP_macrophage_p20,CTCF_ChIP_macrophage_p3	CTCF_ChIP_MEF_p20
```

The sample sheet for this dataset contains all of the sample IDs specified in
the contrasts file.

`assets/samplesheet_full_mm10.csv`

```
sample,rep,fastq_1,fastq_2,antibody,input
CTCF_ChIP_macrophage_p20,1,/data/CCBR_Pipeliner/testdata/chipseq/SRR3081748_1.fastq.gz,,CTCF,WCE_p20
CTCF_ChIP_macrophage_p20,2,/data/CCBR_Pipeliner/testdata/chipseq/SRR3081749_1.fastq.gz,,CTCF,WCE_p20
CTCF_ChIP_macrophage_p3,1,/data/CCBR_Pipeliner/testdata/chipseq/SRR3081750_1.fastq.gz,,CTCF,WCE_p3
CTCF_ChIP_macrophage_p3,2,/data/CCBR_Pipeliner/testdata/chipseq/SRR3081751_1.fastq.gz,,CTCF,WCE_p3
CTCF_ChIP_MEF_p20,1,/data/CCBR_Pipeliner/testdata/chipseq/SRR3081752_1.fastq.gz,,CTCF,WCE_p20
CTCF_ChIP_MEF_p20,2,/data/CCBR_Pipeliner/testdata/chipseq/SRR3081753_1.fastq.gz,,CTCF,WCE_p20
WCE_p3,,/data/CCBR_Pipeliner/testdata/chipseq/SRR3081772_1.fastq.gz,,,
WCE_p20,,/data/CCBR_Pipeliner/testdata/chipseq/SRR3081773_1.fastq.gz,,,
```

### Parameters file (optional)

you can create a YAML file with the parameters you want to set.
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

You will then pass this file to the `-params-file` option when running the pipeline:

```sh
champagne run --output /data/$USER/champagne_project \
    -params-file assets/params.yml
```

## Run

`champagne run` is the main command to run the pipeline.
Here's the output of `champagne run --help`:

```
Usage: champagne run [OPTIONS] [NEXTFLOW_ARGS]...

  Run the workflow

  Note: you must first run `champagne init --output <output_dir>` to
  initialize the output directory.

  docs: https://ccbr.github.io/CHAMPAGNE

Options:
  --output DIRECTORY  Output directory path for champagne init & run.
                      Equivalent to nextflow launchDir. Defaults to your
                      current working directory.
  --mode TEXT         Run mode (slurm, local)  [default: slurm]
  -F, --forceall      Force all processes to run (i.e. do not use nextflow
                      -resume)
  -h, --help          Show this message and exit.

  Nextflow options:
    -profile <profile>    Nextflow profile to use (e.g. test)
    -params-file <file>   Nextflow params file to use (e.g. assets/params.yml)
    -preview              Preview the processes that will run without executing them

  EXAMPLES:
  Execute with slurm:
    champagne run --output path/to/outdir --mode slurm
  Preview the processes that will run:
    champagne run .--output path/to/outdir --mode local -preview
  Add nextflow args (anything supported by `nextflow run`):
    champagne run --output path/to/outdir --mode slurm -profile test
    champagne run --output path/to/outdir --mode slurm -profile test -params-file assets/params.yml
```

Any [nextflow argument](https://www.nextflow.io/docs/latest/reference/cli.html#run)
can also be passed to champagne run, such as `-profile`, `-preview`, or
`-params-file`. These are always prepended with a single hyphen.

[Pipeline parameters](./params.md) can also be passed via the command line.
These are always prepended with a double-hyphen.

### Preview

Run a local preview:

```sh
champagne run \
  --output /data/$USER/champagne_project \
  --input assets/samplesheet_test_mm10.csv \
  --contrasts assets/contrasts_test_mm10.tsv \
  --genome mm10 \
  --mode local \
  -preview
```

### Stub run

Launch a local stub run to view processes that will run, output blank files, and
download containers:

```sh
champagne run \
  --output /data/$USER/champagne_project \
  --input assets/samplesheet_test_mm10.csv \
  --contrasts assets/contrasts_test_mm10.tsv \
  --genome mm10 \
  --mode local \
  -stub
```

### Run with slurm

Launch a pipeline run with slurm:

```sh
champagne run \
  --output /data/$USER/champagne_project \
  --input assets/samplesheet_test_mm10.csv \
  --contrasts assets/contrasts_test_mm10.tsv \
  --genome mm10 \
  --mode slurm
```
