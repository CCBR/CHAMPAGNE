#!/usr/bin/env bash
set -euo pipefail
module load ccbrpipeliner

CHAMPAGNE=/home/sovacoolkl/pipelines/CHAMPAGNE/champagne-dev-sovacool/bin/champagne
INDICES=/data/CCBR_Pipeliner/db/PipeDB/Indices
OUT=/data/$USER/champagne_hs1_chrR
READ_LENGTH=50

cat "$INDICES/hs1/genes.gtf" \
    "$INDICES/hs1_chrR/indexes/chrR_annotations.gtf" \
    | awk -F'\t' -v OFS='\t' '$9 !~ /transcript_id/ {$9 = $9 " transcript_id \"\";"} {print}' \
    | gzip -c > "$INDICES/hs1_chrR/hs1_chrR.genes.gtf.gz"

"$CHAMPAGNE" init --output "$OUT"
"$CHAMPAGNE" run \
    --output "$OUT" \
    --build_reference \
    --genome hs1_chrR \
    --genome_fasta "$INDICES/hs1_chrR/hs1_chrR.fa" \
    --genes_gtf "$INDICES/hs1_chrR/hs1_chrR.genes.gtf.gz" \
    --blacklist "$INDICES/hs1_chrR/indexes/hs1_chrR.blacklist.fa.gz" \
    --read_length "$READ_LENGTH"