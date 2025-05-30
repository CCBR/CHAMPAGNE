# TODO Jotting notes here

## Samplemanifest

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
