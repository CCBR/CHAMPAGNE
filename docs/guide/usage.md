# Getting Started with CHAMPAGNE

TODO intro paragraph

## Installation

CHAMPAGNE is installed on the Biowulf and FRCE clusters as part of the
`ccbrpipeliner` module.
If you'd like to run the pipeline in a different execution environment,
take a look at [how to run the nextflow pipeline directly](nextflow.md).

## Initialize

Copy the configuration files to your project directory

```sh
champagne init --output /data/$USER/champagne_project
```

or if you do not use `--output`, your current working directory will be used as default:

```sh
champagne init
```

## Prepare input files

### Sample manifest

The following columns are required:

- sample: sampleID; does not need to be a unique column
- rep: replicateID of sampleID; does not need to be a unique column
- fastq_1: absolute path to R1 of sampleID
- fastq_2: absolute path to R1 of sampleID
- antibody: -c sampleID for mac2; this must match a unique {sample}\_{rep} format
- control:

Example antibody / control format for a single-end project:

```
sample,rep,fastq_1,fastq_2,antibody,control
sample,1,/path/to/sample_1.R1.fastq.gz,,input_1,input_1
sample,2,/path/to/sample_2.R1.fastq.gz,,input_1,input_1
input,1,/path/to/sample1.R1.fastq.gz,,,
input,2,/path/to/sample1.R1.fastq.gz,,,
```

Example antibody / control format for a paired-end project:

```
sample,rep,fastq_1,fastq_2,antibody,control
sample,1,/path/to/sample_1.R1.fastq.gz,/path/to/sample_1.R2.fastq.gz,input_1,input_1
sample,2,/path/to/sample_2.R1.fastq.gz,/path/to/sample_1.R2.fastq.gz,input_1,input_1
input,1,/path/to/input_1.R1.fastq.gz,/path/to/input_1.R2.fastq.gz,,
input,2,/path/to/input_2.R1.fastq.gz,/path/to/input_2.R2.fastq.gz,,
```

### Contrasts (optional)

### Parameters file (optional)

## Run

TODO preview, stub, mode=slurm

TODO required params

Run preview to view processes that will run:

```sh
champagne run --output /data/$USER/champagne_project -profile test -preview
```

Launch a stub run to view processes that will run and download containers:

```sh
champagne run --output /data/$USER/champagne_project -profile test,singularity -stub
```

Run the test dataset using the test profile:

```sh
champagne run --output /data/$USER/champagne_project -profile test,singularity
```

or explicitly specify the nextflow output directory and input:

```sh
champagne run --output /data/$USER/champagne_project -profile singularity --outdir results/test --input assets/samplesheet_test.csv
```

### Custom reference genome

TODO different required params

Create and use a custom reference genome:

```sh
champagne run --output /data/$USER/champagne_project -profile test -entry MAKE_REFERENCE
champagne run --output /data/$USER/champagne_project -profile test -c results/test/genome/custom_genome.config
```
