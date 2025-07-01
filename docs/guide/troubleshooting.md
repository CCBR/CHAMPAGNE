# Troubleshooting

## View the log file

If you submitted the pipeline to slurm, there will be a slurm log file `log/`
with the name `log/slurm_${SLURM_JOB_ID}.log`.
Otherwise, it will be printed to standard output and standard error in your terminal.

## Try resubmitting

If you are running the pipeline on a cluster, try resubmitting the job.
Sometimes jobs fail due to temporary issues with the cluster or resources.

CHAMPAGNE uses `-resume` by default, so calling `champagne run` with the same
options as your original run will resume the pipeline from where it left off,
rather than starting over. If you _do_ want to start over, use `--forceall` with
`champagne run`.

## Getting Help

If you think your issue is a **bug**, open an
[issue](https://github.com/CCBR/CHAMPAGNE/issues) and include a minimal
reproducible example.

If you have a general **question** about the pipeline, ask it in
[discussions](https://github.com/CCBR/CHAMPAGNE/discussions).

**General Inquiries and Collaboration:** Please contact the CCBR Pipeliner team
at [CCBR_Pipeliner@mail.nih.gov](mailto:CCBR_Pipeliner@mail.nih.gov).
